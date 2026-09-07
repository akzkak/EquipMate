local EM = EquipMate
local Inventory = {name = "Inventory", bankOpen = false, revision = 0}
EM.Inventory = Inventory
EM.modules.Inventory = Inventory

function Inventory:Initialize()
  self.equipped = {}
  self.bagItems = {}
  self.items = {}
  self.byGUID = {}
  self.bySignature = {}
  self.frame = CreateFrame("Frame", "EquipMateInventoryFrame")
  self.frame:SetScript("OnEvent", function()
    Inventory:OnEvent(event, arg1, arg2)
  end)
  EM.RegisterEvent(self.frame, "BAG_UPDATE")
  EM.RegisterEvent(self.frame, "UNIT_INVENTORY_CHANGED")
  EM.RegisterEvent(self.frame, "BANKFRAME_OPENED")
  EM.RegisterEvent(self.frame, "BANKFRAME_CLOSED")
  EM.RegisterEvent(self.frame, "PLAYER_ENTERING_WORLD")
  if EM.Capabilities.bagUpdateDelayed then EM.RegisterEvent(self.frame, "BAG_UPDATE_DELAYED") end
  if EM.Capabilities.playerEquipmentChanged then EM.RegisterEvent(self.frame, "PLAYER_EQUIPMENT_CHANGED") end
  self:ScanAll("initialize")
end

function Inventory:OnEvent(name, a)
  if name == "BANKFRAME_OPENED" then
    self.bankOpen = true
    self:ScheduleScan("bank-open")
  elseif name == "BANKFRAME_CLOSED" then
    self.bankOpen = false
    self:ScheduleScan("bank-close")
  elseif name == "PLAYER_EQUIPMENT_CHANGED" then
    self:ScheduleEquipmentSlot(a)
  elseif name == "UNIT_INVENTORY_CHANGED" then
    if not a or a == "player" then
      if EM.Capabilities.playerEquipmentChanged then self:ScheduleEquipmentSlot(0)
      else self:ScheduleAllEquipment() end
    end
  elseif name == "BAG_UPDATE_DELAYED" then
    self:ScheduleDirtyBags("bags-delayed")
  elseif name == "BAG_UPDATE" then
    self:MarkBagDirty(a)
    if not EM.Capabilities.bagUpdateDelayed then self:ScheduleDirtyBags("bag-" .. tostring(a)) end
  elseif name == "PLAYER_ENTERING_WORLD" then
    self:ScheduleScan("enter-world")
  end
end

function Inventory:ScheduleEquipmentSlot(slotID)
  if not EM.SlotByID[slotID] then return end
  if not self.dirtyEquipment then self.dirtyEquipment = {} end
  self.dirtyEquipment[slotID] = true
  EM.After(0.02, self, self.RunDirtyEquipment, "equipment-scan")
end

function Inventory:ScheduleAllEquipment()
  local i
  for i = 1, table.getn(EM.Slots) do self:ScheduleEquipmentSlot(EM.Slots[i].id) end
end

function Inventory:RunDirtyEquipment()
  local slotID
  for slotID in pairs(self.dirtyEquipment or {}) do
    local slotInfo = EM.SlotByID[slotID]
    self.equipped[slotInfo.key] = EM.Items:FromLocation({kind="equipment", slot=slotID})
  end
  self.dirtyEquipment = {}
  self:RebuildIndexes()
  self:Publish("equipment-slots")
end

function Inventory:MarkBagDirty(bag)
  if type(bag) ~= "number" then return end
  if not self.dirtyBags then self.dirtyBags = {} end
  self.dirtyBags[bag] = true
end

function Inventory:ScheduleDirtyBags(reason)
  self.pendingBagReason = reason
  EM.After(0.02, self, self.RunDirtyBags, "bag-scan")
end

function Inventory:RunDirtyBags()
  local bag
  for bag in pairs(self.dirtyBags or {}) do
    if bag >= 0 and bag <= 4 or self.bankOpen and (bag == -1 or bag >= 5 and bag <= 10) then
      self:ScanBag(bag)
    end
  end
  self.dirtyBags = {}
  self:RebuildIndexes()
  self:Publish(self.pendingBagReason or "bags")
end

function Inventory:ScheduleScan(reason)
  self.pendingReason = reason
  EM.After(0.05, self, self.RunScheduledScan, "inventory-scan")
end

function Inventory:RunScheduledScan()
  self:ScanAll(self.pendingReason)
end

function Inventory:AddItem(item)
  table.insert(self.items, item)
  if item.guid then self.byGUID[item.guid] = item end
  local signature = EM.Items:Signature(item)
  if not self.bySignature[signature] then self.bySignature[signature] = {} end
  table.insert(self.bySignature[signature], item)
end

function Inventory:RebuildIndexes()
  self.items = {}
  self.byGUID = {}
  self.bySignature = {}
  local i, item
  for i = 1, table.getn(EM.Slots) do
    item = self.equipped[EM.Slots[i].key]
    if item then self:AddItem(item) end
  end
  local key
  for key, item in pairs(self.bagItems) do self:AddItem(item) end
end

function Inventory:Publish(reason)
  self.revision = self.revision + 1
  self.lastReason = reason
  -- Routine bag and equipment publications are deliberately silent in debug
  -- mode: one outfit swap can generate many of them without adding useful
  -- troubleshooting context. Bank availability is a meaningful state change.
  if reason == "bank-open" then
    EM.Debug("bank opened; " .. table.getn(self.items) .. " items tracked")
  elseif reason == "bank-close" then
    EM.Debug("bank closed; " .. table.getn(self.items) .. " items tracked")
  end
  EM.Emit("INVENTORY_UPDATED", self.revision, reason)
end

function Inventory:ScanAll(reason)
  self.equipped = {}
  self.bagItems = {}
  self.items = {}
  self.byGUID = {}
  self.bySignature = {}
  local i, bag, slot
  for i = 1, table.getn(EM.Slots) do
    local slotInfo = EM.Slots[i]
    local item = EM.Items:FromLocation({kind="equipment", slot=slotInfo.id})
    self.equipped[slotInfo.key] = item
  end
  for bag = 0, 4 do self:ScanBag(bag) end
  if self.bankOpen then
    self:ScanBag(-1)
    for bag = 5, 10 do self:ScanBag(bag) end
  end
  self:RebuildIndexes()
  self:Publish(reason)
end

function Inventory:ScanBag(bag)
  local prefix = "b:" .. bag .. ":"
  local key
  for key in pairs(self.bagItems) do
    if string.sub(key, 1, string.len(prefix)) == prefix then self.bagItems[key] = nil end
  end
  local count = GetContainerNumSlots(bag) or 0
  local slot
  for slot = 1, count do
    local kind = (bag == -1 or bag >= 5) and "bank" or "bag"
    local item = EM.Items:FromLocation({kind=kind, bag=bag, slot=slot})
    if item then self.bagItems[EM.Util.LocationKey(item.location)] = item end
  end
end

function Inventory:GetGUIDLocation(guid)
  if not EM.Capabilities.itemGUID then return nil end
  local ok,location=pcall(C_Item.GetItemLocation,guid)
  if ok then return location end
  return nil
end

function Inventory:Find(desired, claimed)
  local item
  if desired.guid then
    item = self.byGUID[desired.guid]
    if item and not claimed[EM.Util.LocationKey(item.location)] then return item end
    if EM.Capabilities.itemGUID then
      local classicLocation = self:GetGUIDLocation(desired.guid)
      if classicLocation then
        local location
        if classicLocation.equipmentSlotIndex then
          location = {kind="equipment", slot=classicLocation.equipmentSlotIndex}
        elseif classicLocation.bagID ~= nil and classicLocation.slotIndex then
          local bag = classicLocation.bagID
          location = {kind=(bag == -1 or bag >= 5) and "bank" or "bag",
            bag=bag, slot=classicLocation.slotIndex}
        end
        if location and not claimed[EM.Util.LocationKey(location)] then
          item = EM.Util.Copy(desired)
          item.location = location
          item.guid = desired.guid
          if EM.Capabilities.itemLock then
            local ok,isLocked=pcall(C_Item.IsLocked,classicLocation)
            if ok then item.locked=isLocked and true or false end
          end
          return item
        end
      end
    end
  end
  local candidates = self.bySignature[EM.Items:Signature(desired)] or {}
  local i
  for i = 1, table.getn(candidates) do
    item = candidates[i]
    if not claimed[EM.Util.LocationKey(item.location)] then return item end
  end
  return nil
end

function Inventory:MatchesDesired(actual, desired)
  if not actual or not desired then return false end
  if desired.guid and (self.byGUID[desired.guid] or self:GetGUIDLocation(desired.guid)) then
    return actual.guid == desired.guid
  end
  return EM.Items:Matches(actual, desired)
end

function Inventory:Resolve(outfit)
  local result = {slots={}, missing={}, banked={}, matched=0, required=0}
  local claimed = {}
  local i
  for i = 1, table.getn(EM.Slots) do
    local slotInfo = EM.Slots[i]
    local desired = outfit.slots[slotInfo.key]
    if desired then
      result.required = result.required + 1
      if desired.empty then
        if not self.equipped[slotInfo.key] then result.matched = result.matched + 1 end
        result.slots[slotInfo.key] = {desired=desired, actual=self.equipped[slotInfo.key]}
      else
        local found = self:Find(desired, claimed)
        if found then claimed[EM.Util.LocationKey(found.location)] = true end
        result.slots[slotInfo.key] = {
          desired=desired, actual=self.equipped[slotInfo.key], found=found
        }
        if self:MatchesDesired(self.equipped[slotInfo.key], desired) then
          result.matched = result.matched + 1
        elseif not found then
          table.insert(result.missing, {slot=slotInfo.key, item=desired})
        elseif found.location.kind == "bank" then
          table.insert(result.banked, {slot=slotInfo.key, item=desired})
        end
      end
    end
  end
  if result.required == 0 then result.state = "empty"
  elseif result.matched == result.required then result.state = "equipped"
  elseif result.matched > 0 then result.state = "partial"
  else result.state = "not-equipped" end
  return result
end

function Inventory:FindEmptyBagSlot()
  local bag, slot
  for bag = 0, 4 do
    if self:IsGeneralBag(bag) then
      local count = GetContainerNumSlots(bag) or 0
      for slot = 1, count do
        if not GetContainerItemLink(bag, slot) then return bag, slot end
      end
    end
  end
  return nil
end

function Inventory:FindEmptyBankSlot()
  if not self.bankOpen then return nil end
  local bag, slot, index
  for index = 0, 6 do
    if index == 0 then bag = -1 else bag = index + 4 end
    if self:IsGeneralBankBag(bag) then
      local count = GetContainerNumSlots(bag) or 0
      for slot = 1, count do
        if not GetContainerItemLink(bag, slot) then return bag, slot end
      end
    end
  end
  return nil
end

function Inventory:IsGeneralBankBag(bag)
  if bag == -1 then return true end
  if EM.Capabilities.containerFreeSlots then
    local ok,_,bagType=pcall(C_Container.GetContainerNumFreeSlots,bag)
    if ok and bagType and bagType ~= 0 then return false end
  end
  local link = GetInventoryItemLink("player", 63 + bag)
  local parsed = link and EM.Items:ParseLink(link)
  return not parsed or not EM.SpecialtyBagIDs[parsed.id]
end

function Inventory:IsGeneralBag(bag)
  if bag == 0 then return true end
  if EM.Capabilities.containerFreeSlots then
    local ok,_,bagType=pcall(C_Container.GetContainerNumFreeSlots,bag)
    if ok and bagType and bagType ~= 0 then return false end
  end
  local link = GetInventoryItemLink("player", 19 + bag)
  local parsed = link and EM.Items:ParseLink(link)
  return not parsed or not EM.SpecialtyBagIDs[parsed.id]
end
