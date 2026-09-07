local EM = EquipMate
local Engine = {name = "Engine", transaction = nil, manualOverlays = {}, bankOrigins = {}}
EM.Engine = Engine
EM.modules.Engine = Engine

function Engine:Initialize()
  EM.On("INVENTORY_UPDATED", self, self.OnInventoryUpdated)
  EM.On("OUTFITS_CHANGED", self, self.OnOutfitsChanged)
  self.frame = CreateFrame("Frame", "EquipMateEngineFrame")
  self.frame:SetScript("OnEvent", function() Engine:OnGameEvent(event) end)
  EM.RegisterEvent(self.frame, "PLAYER_REGEN_ENABLED")
  EM.RegisterEvent(self.frame, "CURSOR_UPDATE")
end

function Engine:OnOutfitsChanged(action, outfitID)
  if action ~= "deleted" then return end
  local pending=self.transaction and self.transaction.source=="manual" and
    self.transaction.outfitID==outfitID
  if not pending and not EM.Util.TableContains(self.manualOverlays,outfitID) then return end
  if pending then self:Cancel("outfit deleted") end
  local ids = {}
  local i
  for i = 1, table.getn(self.manualOverlays) do
    if self.manualOverlays[i] ~= outfitID then table.insert(ids, self.manualOverlays[i]) end
  end
  if not self.manualBaseline then self.manualOverlays = ids; return end
  if table.getn(ids) == 0 then
    self:WearOutfit(self.manualBaseline, "manual", "active outfit deleted", "restore-manual", {})
  else
    self:WearOutfit(self:CompileManual(ids, "After deleting outfit"), "manual",
      "active outfit deleted", "wear-manual", ids)
  end
end

function Engine:OnGameEvent()
  if self.transaction then EM.After(0.05, self, self.Step, "engine-step") end
end

function Engine:OnInventoryUpdated()
  if self.transaction then
    EM.After(0.05, self, self.Step, "engine-step")
  else
    self:UpdateManualBaseline()
  end
end

function Engine:UpdateManualBaseline()
  if not self.manualBaseline or table.getn(self.manualOverlays) == 0 then return end
  if EM.Rules and table.getn(EM.Rules.activeIDs or {}) > 0 then return end
  local controlled = {}
  local j, key
  for j = 1, table.getn(self.manualOverlays) do
    local active = EM.Outfits:Get(self.manualOverlays[j])
    if active then for key in pairs(active.slots) do controlled[key] = true end end
  end
  local i
  for i = 1, table.getn(EM.Slots) do
    key = EM.Slots[i].key
    if not controlled[key] then
      local item = EM.Inventory.equipped[key]
      self.manualBaseline.slots[key] = item and EM.Items:ForOutfit(item) or {empty=true}
    end
  end
end

function Engine:Wear(id, source, reason)
  local outfit = EM.Outfits:Get(id)
  if not outfit then return nil, "Unknown outfit." end
  if self.transaction then self:Cancel("superseded") end
  EM.Inventory:ScanAll("wear-start")
  source = source or "manual"
  if source == "manual" then
    if not self.manualBaseline then
      self.manualBaseline = EM.Outfits:Snapshot("Pre-manual equipment")
    end
    local ids = EM.Util.Copy(self.manualOverlays)
    if self:IsFullOutfit(outfit) then ids = {outfit.id}
    elseif not EM.Util.TableContains(ids, outfit.id) then table.insert(ids, outfit.id) end
    local compiled = self:CompileManual(ids, outfit.name)
    compiled.id = outfit.id
    return self:WearOutfit(compiled, source, reason, "wear-manual", ids)
  end
  return self:WearOutfit(outfit, source, reason)
end

function Engine:Toggle(id, source)
  local outfit = EM.Outfits:Get(id)
  if not outfit then return nil, "Unknown outfit." end
  if EM.Util.TableContains(self.manualOverlays, outfit.id) and self.manualBaseline then
    if self.transaction then self:Cancel("superseded") end
    EM.Inventory:ScanAll("toggle-start")
    local ids = {}
    local i
    for i = 1, table.getn(self.manualOverlays) do
      if self.manualOverlays[i] ~= outfit.id then table.insert(ids, self.manualOverlays[i]) end
    end
    if table.getn(ids) == 0 then
      return self:WearOutfit(self.manualBaseline, source or "manual", "toggle off", "restore-manual", {})
    end
    local compiled = self:CompileManual(ids, "Without " .. outfit.name)
    return self:WearOutfit(compiled, source or "manual", "toggle off", "wear-manual", ids)
  end
  return self:Wear(id, source or "manual", "toggle on")
end

function Engine:IsFullOutfit(outfit)
  local i
  for i = 1, table.getn(EM.Slots) do
    if not outfit.slots[EM.Slots[i].key] then return false end
  end
  return true
end

function Engine:CompileManual(ids, name)
  local overlays = {}
  local i
  for i = 1, table.getn(ids) do
    local outfit = EM.Outfits:Get(ids[i])
    if outfit then table.insert(overlays, outfit) end
  end
  return EM.Outfits:Compile(self.manualBaseline, overlays, name)
end

function Engine:WearOutfit(outfit, source, reason, mode, manualIDs)
  if self.transaction then self:Cancel("superseded") end
  self.transaction = {
    outfitID=outfit.id, outfit=outfit, source=source or "manual", reason=reason,
    mode=mode, manualIDs=manualIDs,
    started=GetTime(), deadline=GetTime()+15, attempts=0, lastAction=nil,
    debugChangedSlots={}
  }
  self:DebugStart(self.transaction)
  EM.Emit("EQUIP_STARTED", outfit, self.transaction)
  self:Step()
  return true
end

function Engine:Cancel(reason)
  local transaction = self.transaction
  self.transaction = nil
  EM.CancelTimer("engine-step")
  if transaction then
    self:DebugFinish(transaction,"cancelled",reason)
    EM.Emit("EQUIP_CANCELLED", transaction, reason)
  end
end

function Engine:Finish(success, details)
  local transaction = self.transaction
  if not transaction then return end
  self.transaction = nil
  EM.CancelTimer("engine-step")
  if success and transaction.source == "manual" then
    if transaction.mode == "restore-manual" then
      self.manualOverlays = {}
      self.manualBaseline = nil
    elseif transaction.mode == "wear-manual" then
      self.manualOverlays = transaction.manualIDs or {transaction.outfitID}
    end
  elseif not success and transaction.source=="manual" and table.getn(self.manualOverlays)==0 then
    self.manualBaseline=nil
  end
  local completedOutfit = transaction.outfit or EM.Outfits:Get(transaction.outfitID)
  if success then self:ApplyVisibility(completedOutfit) end
  EM.Emit("EQUIP_FINISHED", transaction, success, details)
  self:DebugFinish(transaction,success and "complete" or "failed",details)
  if not success then
    EM.Print("could not complete outfit: " .. tostring(details))
  end
end

function Engine:DebugContext(transaction)
  local source=transaction.source or "manual"
  if source=="automatic" then
    if transaction.mode=="restore-automatic" then return "automatic restore" end
    return transaction.reason and ("automatic: "..transaction.reason) or "automatic"
  end
  if transaction.mode=="restore-manual" then return "manual restore" end
  if source=="manual" and transaction.reason then return "manual: "..transaction.reason end
  return source
end

function Engine:DebugStart(transaction)
  if not EM.DebugEnabled() then return end
  local outfit=transaction.outfit or EM.Outfits:Get(transaction.outfitID)
  if not outfit then return end
  local resolved=EM.Inventory:Resolve(outfit)
  local needed=resolved.required-resolved.matched
  local sources={bag=0,bank=0,equipment=0,unequip=0,missing=0}
  local i
  for i=1,table.getn(EM.Slots) do
    local entry=resolved.slots[EM.Slots[i].key]
    if entry then
      local correct=entry.desired.empty and not entry.actual or
        not entry.desired.empty and EM.Inventory:MatchesDesired(entry.actual,entry.desired)
      if not correct then
        if entry.desired.empty then sources.unequip=sources.unequip+1
        elseif not entry.found then sources.missing=sources.missing+1
        else
          local kind=entry.found.location and entry.found.location.kind
          if sources[kind]~=nil then sources[kind]=sources[kind]+1 end
        end
      end
    end
  end
  local parts={}
  local order={{"bag","bag"},{"bank","bank"},{"equipment","equipped"},
    {"unequip","unequip"},{"missing","missing"}}
  for i=1,table.getn(order) do
    local count=sources[order[i][1]]
    if count>0 then table.insert(parts,order[i][2].." "..count) end
  end
  if table.getn(parts)==0 then table.insert(parts,"no moves") end
  local cursor=CursorHasItem() and "; cursor occupied" or ""
  transaction.debugNeeded=needed
  EM.Debug("swap start ["..self:DebugContext(transaction).."]: "..tostring(outfit.name)..
    "; "..needed.." of "..resolved.required.." slots need changes; "..
    table.concat(parts,", ").."; bank "..(EM.Inventory.bankOpen and "open" or "closed")..
    "; combat "..(self:InCombat() and "yes" or "no")..cursor)
end

function Engine:RecordDebugAction(action)
  local transaction=self.transaction
  if not transaction or not action then return end
  local function record(one)
    if one.target then transaction.debugChangedSlots[one.target.key]=true end
  end
  if action.kind=="equip-bank-batch" then
    local limit=action.completed or table.getn(action.actions or {})
    local i
    for i=1,limit do record(action.actions[i]) end
  else record(action) end
end

function Engine:DebugFinish(transaction,state,details)
  if not EM.DebugEnabled() or not transaction then return end
  local outfit=transaction.outfit or EM.Outfits:Get(transaction.outfitID)
  local changed=0
  local key
  for key in pairs(transaction.debugChangedSlots or {}) do changed=changed+1 end
  if state=="complete" and transaction.debugNeeded then changed=transaction.debugNeeded end
  local elapsed=math.max(0,GetTime()-(transaction.started or GetTime()))
  local result=state=="complete" and "swap complete" or state=="failed" and "swap failed" or
    "swap cancelled"
  local suffix=state=="complete" and tostring(details or "verified") or tostring(details or "unknown reason")
  EM.Debug(result.." ["..self:DebugContext(transaction).."]: "..
    tostring(outfit and outfit.name or "unknown outfit").."; "..changed..
    (changed==1 and " slot changed" or " slots changed").."; "..
    string.format("%.1fs",elapsed).."; "..suffix)
end

function Engine:ApplyVisibility(outfit)
  if not outfit or not outfit.visibility then return end
  if outfit.visibility.helm ~= nil and type(ShowHelm) == "function" then
    ShowHelm(outfit.visibility.helm and 1 or 0)
  end
  if outfit.visibility.cloak ~= nil and type(ShowCloak) == "function" then
    ShowCloak(outfit.visibility.cloak and 1 or 0)
  end
end

function Engine:InCombat()
  if EM.Capabilities.inCombatLockdown then
    local ok,inCombat=pcall(InCombatLockdown)
    if ok then return inCombat and true or false end
  end
  return UnitAffectingCombat("player")
end

function Engine:IsCombatSlot(slotInfo)
  return slotInfo.id == 0 or slotInfo.id == 16 or slotInfo.id == 17 or slotInfo.id == 18
end

function Engine:ItemIdentity(item)
  if item and item.guid then return "g:"..item.guid end
  return "s:"..EM.Items:Signature(item)
end

function Engine:RememberBankOrigin(action, source)
  if source.kind~="bank" then return end
  self.bankOrigins[action.target.key]={bag=source.bag,slot=source.slot,
    identity=self:ItemIdentity(action.found)}
end

function Engine:GetBankOrigin(slotInfo, item)
  local origin=self.bankOrigins[slotInfo.key]
  if not origin or origin.identity~=self:ItemIdentity(item) then return nil end
  if GetContainerItemLink(origin.bag,origin.slot) then return nil end
  return origin.bag,origin.slot
end

function Engine:BankEquipActions(resolved)
  local actions = {}
  local i
  for i = 1, table.getn(EM.Slots) do
    local slotInfo = EM.Slots[i]
    local entry = resolved.slots[slotInfo.key]
    if entry and entry.desired and not entry.desired.empty and entry.found and
        entry.found.location.kind == "bank" and
        not EM.Inventory:MatchesDesired(entry.actual, entry.desired) and
        not entry.found.locked and not (entry.actual and entry.actual.locked) and
        (not self:InCombat() or self:IsCombatSlot(slotInfo)) then
      table.insert(actions, {
        kind="equip", target=slotInfo, found=entry.found, desired=entry.desired
      })
    end
  end
  return actions
end

function Engine:NextAction(outfit, resolved)
  local blocked, i
  local main = resolved.slots.MainHandSlot
  local off = resolved.slots.SecondaryHandSlot
  if off and off.desired and off.desired.empty and off.actual then
    local offSlot = EM.SlotByKey.SecondaryHandSlot
    if not self:InCombat() or self:IsCombatSlot(offSlot) then
      if off.actual.locked then return nil, "item is locked" end
      if EM.Inventory.bankOpen then
        local bank, bankSlot=self:GetBankOrigin(offSlot,off.actual)
        if not bank then bank,bankSlot=EM.Inventory:FindEmptyBankSlot() end
        if bank then
          return {kind="unequip-bank",target=offSlot,actual=off.actual,
            bankDestination={bag=bank,slot=bankSlot}}
        end
      end
      return {kind="unequip", target=offSlot, actual=off.actual}
    end
  end
  for i = 1, table.getn(EM.Slots) do
    local slotInfo = EM.Slots[i]
    local entry = resolved.slots[slotInfo.key]
    if entry then
      local correct
      if entry.desired.empty then correct = not entry.actual
      else correct = EM.Inventory:MatchesDesired(entry.actual, entry.desired) end
      if not correct then
        if self:InCombat() and not self:IsCombatSlot(slotInfo) then
          blocked = "waiting for combat to end"
        elseif entry.desired.empty then
          if entry.actual and entry.actual.locked then blocked = "item is locked"
          else return {kind="unequip", target=slotInfo, actual=entry.actual} end
        elseif not entry.found then
          blocked = "missing " .. (entry.desired.name or entry.desired.link or ("item " .. entry.desired.id))
        elseif entry.found.locked or (entry.actual and entry.actual.locked) then
          blocked = "item is locked"
        elseif entry.found.location.kind == "bank" then
          if EM.Inventory.bankOpen then
            local actions = self:BankEquipActions(resolved)
            if table.getn(actions) > 0 then
              return {kind="equip-bank-batch", target=actions[1].target, actions=actions}
            end
          end
          blocked = "item is in the bank"
        else
          return {kind="equip", target=slotInfo, found=entry.found, desired=entry.desired}
        end
      end
    end
  end
  return nil, blocked
end

function Engine:Step()
  local transaction = self.transaction
  if not transaction then return end
  if GetTime() > transaction.deadline or transaction.attempts >= 80 then
    self:Finish(false, transaction.lastBlocked or "transaction timed out")
    return
  end
  local outfit = transaction.outfit or EM.Outfits:Get(transaction.outfitID)
  if not outfit then self:Finish(false, "outfit was deleted") return end
  local resolved = EM.Inventory:Resolve(outfit)
  local pending=transaction.pendingBankClear
  if pending then
    local actual=EM.Inventory.equipped[pending.slotKey]
    local bankItem=EM.Inventory.bagItems["b:"..pending.bag..":"..pending.slot]
    local equipmentConfirmed=not actual or self:ItemIdentity(actual)~=pending.identity
    local bankConfirmed=bankItem and self:ItemIdentity(bankItem)==pending.identity
    if not equipmentConfirmed or not bankConfirmed then
      transaction.lastBlocked="waiting for the off-hand bank transfer"
      EM.After(0.15,self,self.FallbackRefresh,"engine-step")
      return
    end
    transaction.pendingBankClear=nil
    self.bankOrigins[pending.slotKey]=nil
  end
  if resolved.state == "equipped" or resolved.required == 0 then
    self:Finish(true, "verified")
    return
  end
  local action, blocked = self:NextAction(outfit, resolved)
  if not action then
    transaction.lastBlocked = blocked or "no safe action"
    if transaction.lastActionAt and GetTime() - transaction.lastActionAt < 0.6 then
      EM.After(0.2, self, self.FallbackRefresh, "engine-step")
    elseif blocked == "waiting for combat to end" or blocked == "item is locked" then
      EM.After(0.25, self, self.Step, "engine-step")
    else
      self:Finish(false, transaction.lastBlocked)
    end
    return
  end
  if CursorHasItem() then
    transaction.lastBlocked = "the cursor is holding an item"
    EM.After(0.25, self, self.Step, "engine-step")
    return
  end
  local ok, err = self:Execute(action)
  if not ok then
    transaction.lastBlocked = err
    if err == "no free bag slot" then self:Finish(false, err)
    else EM.After(0.2, self, self.FallbackRefresh, "engine-step") end
    return
  end
  self:RecordDebugAction(action)
  transaction.attempts = transaction.attempts + 1
  if action.completed and action.completed > 1 then
    transaction.attempts = transaction.attempts + action.completed - 1
  end
  transaction.lastAction = action.kind .. ":" .. action.target.key
  transaction.lastActionAt = GetTime()
  EM.After(0.35, self, self.FallbackRefresh, "engine-step")
end

function Engine:FallbackRefresh()
  if not self.transaction then return end
  EM.Inventory:ScanAll("engine-fallback")
end

function Engine:ValidateContainerEquip(action)
  local source = action.found.location
  if source.kind == "bank" and not EM.Inventory.bankOpen then
    return nil, "the bank was closed"
  end
  local currentLink = GetContainerItemLink(source.bag, source.slot)
  local current = currentLink and EM.Items:ParseLink(currentLink)
  if not current or not EM.Items:Matches(current, action.desired) then
    return nil, "the item moved before it could be equipped"
  end
  if EM.Capabilities.itemGUID and action.found.guid then
    local ok, guid = pcall(C_Item.GetItemGUID, EM.Items:GetClassicLocation(source))
    if not ok or guid ~= action.found.guid then
      return nil, "the item instance moved before it could be equipped"
    end
  end
  if EM.Capabilities.itemLock then
    local sourceLocation = EM.Items:GetClassicLocation(source)
    local targetLocation = EM.Items:GetClassicLocation({kind="equipment",slot=action.target.id})
    local sourceOK, sourceLocked = pcall(C_Item.IsLocked, sourceLocation)
    local targetOK, targetLocked = pcall(C_Item.IsLocked, targetLocation)
    if sourceOK and sourceLocked or targetOK and targetLocked then
      return nil, "item is locked"
    end
  end
  return true
end

function Engine:ExecuteContainerEquip(action)
  local targetID = action.target.id
  local source = action.found.location
  local valid, validationError = self:ValidateContainerEquip(action)
  if not valid then return nil, validationError end
  -- Deliberately positional even with ClassicAPI: C_Item.PickupItem searches
  -- carried items by identity and does not accept or search bank locations.
  PickupContainerItem(source.bag,source.slot)
  if not CursorHasItem() then return nil, "could not pick up the item" end
  if type(EquipCursorItem) == "function" then EquipCursorItem(targetID)
  else PickupInventoryItem(targetID) end
  -- Some 1.12 clients leave the displaced item on the cursor instead of
  -- returning it to the picked-up bank/bag slot automatically.
  if CursorHasItem() then PickupContainerItem(source.bag,source.slot) end
  if CursorHasItem() then
    if type(ClearCursor) == "function" then ClearCursor() end
    return nil, "server did not accept the swap"
  end
  self:RememberBankOrigin(action,source)
  return true
end

function Engine:Execute(action)
  local targetID = action.target.id
  if action.kind == "unequip" then
    local bag, slot = EM.Inventory:FindEmptyBagSlot()
    if not bag then return nil, "no free bag slot" end
    PickupInventoryItem(targetID)
    if CursorHasItem() then PickupContainerItem(bag, slot) end
    return true
  end
  if action.kind == "unequip-bank" then
    local destination=action.bankDestination
    if GetContainerItemLink(destination.bag,destination.slot) then
      return nil, "the reserved bank slot is no longer empty"
    end
    PickupInventoryItem(targetID)
    if not CursorHasItem() then return nil, "could not pick up the off-hand item" end
    PickupContainerItem(destination.bag,destination.slot)
    if CursorHasItem() then
      PickupInventoryItem(targetID)
      return nil, "server did not accept the off-hand bank transfer"
    end
    self.transaction.pendingBankClear={slotKey=action.target.key,
      bag=destination.bag,slot=destination.slot,identity=self:ItemIdentity(action.actual)}
    return true
  end
  if action.kind == "equip-bank-batch" then
    local completed, i = 0, 1
    for i = 1, table.getn(action.actions) do
      local ok, err = self:ExecuteContainerEquip(action.actions[i])
      if not ok then
        if completed == 0 then return nil, err end
        action.completed = completed
        action.partialError = err
        return true
      end
      completed = completed + 1
    end
    action.completed = completed
    return true
  end
  local source = action.found.location
  local candidates = EM.Inventory.bySignature[EM.Items:Signature(action.desired)] or {}
  if EM.Capabilities.atomicEquip and source.kind == "bag" and table.getn(candidates) == 1 then
    local ok=pcall(C_Item.EquipItemByName,action.found.link or action.found.id,targetID)
    if ok then return true end
  end
  if source.kind == "equipment" then
    PickupInventoryItem(source.slot)
    PickupInventoryItem(targetID)
    if CursorHasItem() then PickupInventoryItem(source.slot) end
  else
    return self:ExecuteContainerEquip(action)
  end
  if CursorHasItem() then
    if type(ClearCursor) == "function" then ClearCursor() end
    return nil, "server did not accept the swap"
  end
  return true
end
