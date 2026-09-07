local EM = EquipMate
local C = {name = "Capabilities"}
EM.Capabilities = C
EM.modules.Capabilities = C

local function hasFunction(container, name)
  return type(container) == "table" and type(container[name]) == "function"
end

function C:EventExists(name)
  if self.eventValidation then
    local ok,valid=pcall(C_EventUtils.IsEventValid,name)
    if ok then return valid and true or false end
  end
  local probe = CreateFrame("Frame")
  local ok = pcall(probe.RegisterEvent, probe, name)
  if ok then probe:UnregisterEvent(name) end
  return ok
end

function C:Initialize()
  self.classicAPI = hasFunction(C_Item, "GetItemGUID") and hasFunction(C_Item, "GetItemLocation")
  self.itemGUID = self.classicAPI
  self.itemLock = hasFunction(C_Item, "IsLocked")
  self.itemPickup = hasFunction(C_Item, "PickupItem")
  self.itemStats = hasFunction(C_Item, "GetItemStats")
  self.canUseItem = hasFunction(C_PlayerInfo, "CanUseItem")
  self.atomicEquip = hasFunction(C_Item, "EquipItemByName")
  self.containerFreeSlots = hasFunction(C_Container, "GetContainerNumFreeSlots")
  self.eventValidation = hasFunction(C_EventUtils, "IsEventValid")
  self.classicAPIAvailable = self.itemGUID or self.itemLock or self.itemPickup or
    self.itemStats or self.canUseItem or self.atomicEquip or self.containerFreeSlots or
    self.eventValidation
  self.playerEquipmentChanged = self:EventExists("PLAYER_EQUIPMENT_CHANGED")
  self.bagUpdateDelayed = self:EventExists("BAG_UPDATE_DELAYED")
  self.unitCreatureTypeID = type(UnitCreatureTypeID) == "function"
  self.unitCreatureID = type(UnitCreatureID) == "function"
  self.modernUnitGUID = type(UnitGUID) == "function"
  self.nampowerUnitGUID = type(GetUnitGUID) == "function"
  local exists, guid
  if type(UnitExists) == "function" then
    local ok
    ok,exists,guid=pcall(UnitExists,"player")
    if not ok then exists,guid=nil,nil end
  end
  self.superWoWUnitGUID = exists and type(guid) == "string" or false
  self.mounted = type(IsMounted) == "function"
  self.swimming = type(IsSwimming) == "function"
  self.instanceInfo = type(GetInstanceInfo) == "function"
  self.inCombatLockdown = type(InCombatLockdown) == "function"
end

function C:HasEnhancedClientAPI()
  return self.classicAPI or self.classicAPIAvailable or self.modernUnitGUID or
    self.nampowerUnitGUID or self.superWoWUnitGUID
end

function C:RunLoginCheck()
  if self.loginChecked then return end
  self.loginChecked = true
  if not self:HasEnhancedClientAPI() then EM.Print(EM.L.ENHANCED_APIS_MISSING) end
end

function C:GetUnitGUID(unit)
  local ok,guid
  if self.modernUnitGUID then
    ok,guid=pcall(UnitGUID,unit)
    if ok and guid then return guid end
  end
  if self.nampowerUnitGUID then
    ok,guid=pcall(GetUnitGUID,unit)
    if ok and guid then return guid end
  end
  local exists
  ok,exists,guid=pcall(UnitExists,unit)
  if not ok then return nil end
  if exists and type(guid) == "string" then return guid end
  return nil
end

function C:Summary()
  if self.classicAPI then return "ClassicAPI enhanced inventory" end
  if self.classicAPIAvailable then return "ClassicAPI enhancements" end
  if self.nampowerUnitGUID then return "stock inventory + nampower context" end
  if self.superWoWUnitGUID then return "stock inventory + SuperWoW context" end
  return "stock Vanilla compatibility"
end
