local EM = EquipMate
local Outfits = {name = "Outfits", selectedID = nil}
EM.Outfits = Outfits
EM.modules.Outfits = Outfits

function Outfits:Initialize()
  self:RepairOrder()
  EM.On("INVENTORY_UPDATED", self, self.OnInventoryUpdated)
end

function Outfits:RepairOrder()
  local clean, seen = {}, {}
  local i, id, outfit, maximumID
  maximumID = 0
  for id, outfit in pairs(EquipMateDB.outfits) do
    if type(id) ~= "number" or id < 1 or id ~= math.floor(id) or
        type(outfit) ~= "table" or type(outfit.name) ~= "string" then
      EquipMateDB.outfits[id] = nil
    else
      outfit.name=EM.Util.Trim(outfit.name)
      if outfit.name=="" then outfit.name="Outfit "..id end
      if type(outfit.slots) ~= "table" then outfit.slots = {} end
      local key, desired
      for key, desired in pairs(outfit.slots) do
        if not EM.SlotByKey[key] or type(desired) ~= "table" or
            (not desired.empty and type(desired.id) ~= "number") then
          outfit.slots[key] = nil
        elseif desired.empty then
          outfit.slots[key] = {empty=true}
        end
      end
      local validRules = {}
      if type(outfit.rules) == "table" then
        local rule
        for i = 1, table.getn(outfit.rules) do
          rule = outfit.rules[i]
          if type(rule) == "table" and type(rule.conditions) == "table" then
            rule.priority = tonumber(rule.priority) or 0
            rule.enabled = nil
            table.insert(validRules, rule)
          end
        end
      end
      outfit.rules = validRules
      outfit.enabled = nil
      if outfit.autoPreset and (not EM.Rules or not EM.Rules.presets[outfit.autoPreset]) then
        outfit.autoPreset = nil
      end
      outfit.disableInBattleground = outfit.disableInBattleground == true or nil
      outfit.disableInInstance = outfit.disableInInstance == true or nil
      if type(outfit.visibility) == "table" then
        if type(outfit.visibility.helm) ~= "boolean" then outfit.visibility.helm = nil end
        if type(outfit.visibility.cloak) ~= "boolean" then outfit.visibility.cloak = nil end
        if outfit.visibility.helm == nil and outfit.visibility.cloak == nil then
          outfit.visibility = nil
        end
      else
        outfit.visibility = nil
      end
      outfit.id = id
      if id > maximumID then maximumID = id end
    end
  end
  for i = 1, table.getn(EquipMateDB.order) do
    id = EquipMateDB.order[i]
    if EquipMateDB.outfits[id] and not seen[id] then
      table.insert(clean, id)
      seen[id] = true
    end
  end
  for id in pairs(EquipMateDB.outfits) do
    if not seen[id] then table.insert(clean, id) end
  end
  EquipMateDB.order = clean
  if EquipMateDB.nextOutfitID <= maximumID then EquipMateDB.nextOutfitID = maximumID + 1 end
  local bound,cleanBindings = {},{}
  for i = 1, 10 do
    id = EquipMateDB.bindings[i]
    if EquipMateDB.outfits[id] and not bound[id] then
      cleanBindings[i]=id
      bound[id] = true
    end
  end
  EquipMateDB.bindings=cleanBindings
end

function Outfits:NameExists(name, exceptID)
  local id, outfit
  local needle = string.lower(EM.Util.Trim(name))
  for id, outfit in pairs(EquipMateDB.outfits) do
    if id ~= exceptID and string.lower(outfit.name) == needle then return true end
  end
  return false
end

function Outfits:Create(name, capture)
  name = EM.Util.Trim(name)
  if name == "" then return nil, "An outfit needs a name." end
  if self:NameExists(name) then return nil, "That outfit name is already in use." end
  local id = EquipMateDB.nextOutfitID
  EquipMateDB.nextOutfitID = id + 1
  local outfit = {id=id, name=name, slots={}, rules={}, createdAt=time()}
  if EM.Rules and EM.Rules.PresetForName then
    outfit.autoPreset = EM.Rules:PresetForName(name)
  end
  if capture then self:CaptureInto(outfit) end
  EquipMateDB.outfits[id] = outfit
  table.insert(EquipMateDB.order, id)
  self.selectedID = id
  EM.Emit("OUTFITS_CHANGED", "created", id)
  return outfit
end

function Outfits:CreateNaked(name)
  local outfit, err = self:Create(name, false)
  if not outfit then return nil, err end
  local i
  for i = 1, table.getn(EM.Slots) do outfit.slots[EM.Slots[i].key] = {empty=true} end
  EM.Emit("OUTFITS_CHANGED", "naked", outfit.id)
  return outfit
end

function Outfits:Get(idOrName)
  if type(idOrName) == "number" then return EquipMateDB.outfits[idOrName] end
  local id, outfit
  local name = string.lower(EM.Util.Trim(idOrName))
  for id, outfit in pairs(EquipMateDB.outfits) do
    if string.lower(outfit.name) == name then return outfit end
  end
  return nil
end

function Outfits:CaptureInto(outfit)
  -- A click can beat the equipment-change event which normally refreshes the cache.
  -- Read the live character slots before persisting a full snapshot.
  EM.Inventory:ScanAll("outfit-capture")
  outfit.slots = {}
  local i
  for i = 1, table.getn(EM.Slots) do
    local slotInfo = EM.Slots[i]
    local item = EM.Inventory.equipped[slotInfo.key]
    if item then
      outfit.slots[slotInfo.key] = EM.Items:ForOutfit(item)
    else
      outfit.slots[slotInfo.key] = {empty=true}
    end
  end
  if type(ShowingHelm) == "function" or type(ShowingCloak) == "function" then
    outfit.visibility = {
      helm=type(ShowingHelm) == "function" and ShowingHelm() and true or false,
      cloak=type(ShowingCloak) == "function" and ShowingCloak() and true or false
    }
  end
  outfit.updatedAt = time()
end

function Outfits:UpdateFromEquipped(id)
  local outfit = self:Get(id)
  if not outfit then return nil, "Unknown outfit." end
  EM.Inventory:ScanAll("outfit-update")
  local i
  for i = 1, table.getn(EM.Slots) do
    local key = EM.Slots[i].key
    if outfit.slots[key] then
      local item = EM.Inventory.equipped[key]
      outfit.slots[key] = item and EM.Items:ForOutfit(item) or {empty=true}
    end
  end
  if outfit.visibility then
    if type(ShowingHelm) == "function" then outfit.visibility.helm = ShowingHelm() and true or false end
    if type(ShowingCloak) == "function" then outfit.visibility.cloak = ShowingCloak() and true or false end
  end
  outfit.updatedAt = time()
  EM.Emit("OUTFITS_CHANGED", "updated", id)
  return outfit
end

function Outfits:Duplicate(id, newName)
  local source = self:Get(id)
  if not source then return nil, "Unknown outfit." end
  local result, err = self:Create(newName or (source.name .. " Copy"), false)
  if not result then return nil, err end
  result.slots = EM.Util.Copy(source.slots)
  result.rules = EM.Util.Copy(source.rules or {})
  result.autoPreset = source.autoPreset
  result.disableInBattleground = source.disableInBattleground
  result.disableInInstance = source.disableInInstance
  result.visibility = EM.Util.Copy(source.visibility)
  result.generatedProfile = source.generatedProfile
  EM.Emit("OUTFITS_CHANGED", "duplicated", result.id)
  return result
end

function Outfits:Rename(id, name)
  local outfit = self:Get(id)
  name = EM.Util.Trim(name)
  if not outfit then return nil, "Unknown outfit." end
  if name == "" or self:NameExists(name, outfit.id) then return nil, "Invalid or duplicate name." end
  outfit.name = name
  EM.Emit("OUTFITS_CHANGED", "renamed", outfit.id)
  return outfit
end

function Outfits:Delete(id)
  local outfit = self:Get(id)
  if not outfit then return nil, "Unknown outfit." end
  EquipMateDB.outfits[outfit.id] = nil
  local i
  for i = table.getn(EquipMateDB.order), 1, -1 do
    if EquipMateDB.order[i] == outfit.id then table.remove(EquipMateDB.order, i) end
  end
  for i = 1, 10 do
    if EquipMateDB.bindings[i] == outfit.id then EquipMateDB.bindings[i] = nil end
  end
  if self.selectedID == outfit.id then self.selectedID = nil end
  EM.Emit("OUTFITS_CHANGED", "deleted", outfit.id)
  return true
end

function Outfits:SetSlot(id, slotKey, mode)
  local outfit = self:Get(id)
  if not outfit or not EM.SlotByKey[slotKey] then return nil, "Unknown outfit or slot." end
  if mode == "ignore" then
    outfit.slots[slotKey] = nil
  elseif mode == "empty" then
    outfit.slots[slotKey] = {empty=true}
  elseif mode == "current" then
    EM.Inventory:ScanAll("slot-current")
    local item = EM.Inventory.equipped[slotKey]
    outfit.slots[slotKey] = item and EM.Items:ForOutfit(item) or {empty=true}
  else
    return nil, "Slot mode must be current, empty, or ignore."
  end
  outfit.updatedAt = time()
  EM.Emit("OUTFITS_CHANGED", "slot", outfit.id)
  return true
end

function Outfits:SetAllSlotsIncluded(id, included)
  local outfit = self:Get(id)
  if not outfit then return nil, "Unknown outfit." end
  if included then
    -- Keep already-saved choices intact. "All slots" only captures slots which
    -- were previously left alone, so the action can never silently replace a
    -- saved item with whatever happens to be equipped right now.
    EM.Inventory:ScanAll("slots-all")
    local i
    for i = 1, table.getn(EM.Slots) do
      local key = EM.Slots[i].key
      if not outfit.slots[key] then
        local item = EM.Inventory.equipped[key]
        outfit.slots[key] = item and EM.Items:ForOutfit(item) or {empty=true}
      end
    end
  else
    outfit.slots = {}
  end
  outfit.updatedAt = time()
  EM.Emit("OUTFITS_CHANGED", included and "slots-all" or "slots-none", outfit.id)
  return true
end

function Outfits:ControlledSlotCount(id)
  local outfit = self:Get(id)
  if not outfit then return 0 end
  local count = 0
  local i
  for i = 1, table.getn(EM.Slots) do
    if outfit.slots[EM.Slots[i].key] then count = count + 1 end
  end
  return count
end

function Outfits:Status(id)
  local outfit = self:Get(id)
  if not outfit then return nil end
  return EM.Inventory:Resolve(outfit)
end

function Outfits:Snapshot(name)
  local outfit = {name=name or "Equipment snapshot", slots={}, rules={}, ephemeral=true}
  local i
  for i = 1, table.getn(EM.Slots) do
    local key = EM.Slots[i].key
    local item = EM.Inventory.equipped[key]
    outfit.slots[key] = item and EM.Items:ForOutfit(item) or {empty=true}
  end
  if type(ShowingHelm) == "function" or type(ShowingCloak) == "function" then
    outfit.visibility = {}
    if type(ShowingHelm) == "function" then outfit.visibility.helm = ShowingHelm() and true or false end
    if type(ShowingCloak) == "function" then outfit.visibility.cloak = ShowingCloak() and true or false end
  end
  return outfit
end

function Outfits:Compile(base, overlays, name)
  local result = EM.Util.Copy(base)
  result.name = name or "Compiled outfit"
  result.ephemeral = true
  local i, key, value
  for i = 1, table.getn(overlays or {}) do
    for key, value in pairs(overlays[i].slots or {}) do
      result.slots[key] = EM.Util.Copy(value)
    end
    if overlays[i].visibility then result.visibility = EM.Util.Copy(overlays[i].visibility) end
  end
  return result
end

function Outfits:OnInventoryUpdated()
  EM.Emit("OUTFIT_STATUS_CHANGED")
end

function Outfits:GetUnusedItems()
  local used = {}
  local id, outfit, key, desired
  for id, outfit in pairs(EquipMateDB.outfits) do
    local claimed = {}
    for key, desired in pairs(outfit.slots) do
      if not desired.empty then
        local item = EM.Inventory:Find(desired, claimed)
        if item then
          local locationKey = EM.Util.LocationKey(item.location)
          claimed[locationKey] = true
          used[locationKey] = true
        end
      end
    end
  end
  local result = {}
  local i
  for i = 1, table.getn(EM.Inventory.items) do
    local item = EM.Inventory.items[i]
    if item.equipLoc and item.equipLoc ~= "INVTYPE_AMMO" and
        not used[EM.Util.LocationKey(item.location)] then table.insert(result, item) end
  end
  return result
end
