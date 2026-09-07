local EM = EquipMate
local Items = {}
EM.Items = Items

function Items:ParseLink(link)
  if not link then return nil end
  local _, _, itemString = string.find(link, "|H(item:[^|]+)|h")
  if not itemString then
    _, _, itemString = string.find(link, "^(item:.+)$")
  end
  if not itemString then return nil end
  local _, _, id, enchant, suffix, unique = string.find(itemString,
    "^item:(%-?%d+):?(%-?%d*):?(%-?%d*):?(%-?%d*)")
  if not id then return nil end
  return {
    id = tonumber(id), enchant = tonumber(enchant) or 0,
    suffix = tonumber(suffix) or 0, unique = tonumber(unique) or 0,
    itemString = itemString
  }
end

function Items:Signature(item)
  if not item then return "empty" end
  return tostring(item.id or 0) .. ":" .. tostring(item.enchant or 0) .. ":" ..
    tostring(item.suffix or 0) .. ":" .. tostring(item.unique or 0)
end

function Items:GetClassicLocation(location)
  if location.kind == "equipment" then
    return {equipmentSlotIndex = location.slot}
  end
  return {bagID = location.bag, slotIndex = location.slot}
end

function Items:FromLocation(location)
  local link, texture, count, locked
  if location.kind == "equipment" then
    link = GetInventoryItemLink("player", location.slot)
    texture = GetInventoryItemTexture("player", location.slot)
    count = GetInventoryItemCount("player", location.slot)
    if type(IsInventoryItemLocked) == "function" then
      locked = IsInventoryItemLocked(location.slot)
    end
  else
    link = GetContainerItemLink(location.bag, location.slot)
    texture, count, locked = GetContainerItemInfo(location.bag, location.slot)
  end
  if not link then return nil end
  local parsed = self:ParseLink(link)
  if not parsed then return nil end
  parsed.link = link
  parsed.texture = texture
  parsed.count = count or 1
  parsed.locked = locked and true or false
  parsed.location = EquipMate.Util.Copy(location)
  local name, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
  parsed.name = name
  parsed.equipLoc = equipLoc
  if EM.Capabilities.canUseItem then
    local ok,usable=pcall(C_PlayerInfo.CanUseItem,link)
    if ok then parsed.usable=usable and true or false end
  end
  if EM.Capabilities.itemGUID then
    local classicLocation = self:GetClassicLocation(location)
    local ok,guid=pcall(C_Item.GetItemGUID,classicLocation)
    if ok then parsed.guid=guid end
    if EM.Capabilities.itemLock then
      local lockOK,isLocked=pcall(C_Item.IsLocked,classicLocation)
      if lockOK and isLocked then parsed.locked=true end
    end
  end
  return parsed
end

function Items:ForOutfit(item)
  if not item then return nil end
  return {
    id=item.id, enchant=item.enchant or 0, suffix=item.suffix or 0,
    unique=item.unique or 0, link=item.link, name=item.name,
    texture=item.texture, guid=item.guid, equipLoc=item.equipLoc
  }
end

function Items:Matches(actual, desired)
  if not actual or not desired then return false end
  if desired.guid and actual.guid and desired.guid == actual.guid then return true end
  return self:Signature(actual) == self:Signature(desired)
end
