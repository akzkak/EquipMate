local EM = EquipMate
local Generator = {name = "Generator"}
EM.Generator = Generator
EM.modules.Generator = Generator

Generator.profiles = {
  strength={ITEM_MOD_STRENGTH_SHORT=1}, agility={ITEM_MOD_AGILITY_SHORT=1},
  stamina={ITEM_MOD_STAMINA_SHORT=1}, intellect={ITEM_MOD_INTELLECT_SHORT=1},
  spirit={ITEM_MOD_SPIRIT_SHORT=1}, armor={RESISTANCE0_NAME=1},
  healing={ITEM_MOD_SPELL_HEALING_DONE_SHORT=1,ITEM_MOD_INTELLECT_SHORT=0.15,
    ITEM_MOD_SPIRIT_SHORT=0.1,ITEM_MOD_MANA_REGENERATION=0.5},
  spelldamage={ITEM_MOD_SPELL_DAMAGE_DONE_SHORT=1,ITEM_MOD_HIT_SPELL_RATING=12,
    ITEM_MOD_CRIT_SPELL_RATING=10,ITEM_MOD_INTELLECT_SHORT=0.1},
  melee={ITEM_MOD_ATTACK_POWER_SHORT=0.5,ITEM_MOD_STRENGTH_SHORT=1,
    ITEM_MOD_AGILITY_SHORT=0.7,ITEM_MOD_HIT_MELEE_RATING=12,
    ITEM_MOD_CRIT_MELEE_RATING=10,ITEM_MOD_DAMAGE_PER_SECOND_SHORT=2},
  ranged={ITEM_MOD_RANGED_ATTACK_POWER_SHORT=0.5,ITEM_MOD_ATTACK_POWER_SHORT=0.5,
    ITEM_MOD_AGILITY_SHORT=1,ITEM_MOD_HIT_RANGED_RATING=12,
    ITEM_MOD_CRIT_RANGED_RATING=10,ITEM_MOD_DAMAGE_PER_SECOND_SHORT=2},
  tank={ITEM_MOD_STAMINA_SHORT=1,RESISTANCE0_NAME=0.08,
    ITEM_MOD_DEFENSE_SKILL_RATING=8,ITEM_MOD_DODGE_RATING=12,
    ITEM_MOD_PARRY_RATING=12,ITEM_MOD_BLOCK_RATING=8,ITEM_MOD_BLOCK_VALUE=0.2},
  fireresist={RESISTANCE2_NAME=1}, natureresist={RESISTANCE3_NAME=1},
  frostresist={RESISTANCE4_NAME=1}, shadowresist={RESISTANCE5_NAME=1},
  arcaneresist={RESISTANCE6_NAME=1}
}

function Generator:Initialize() end

function Generator:Score(item, weights)
  local ok,stats=pcall(C_Item.GetItemStats,item.link or item.id)
  if not ok or type(stats)~="table" then return nil end
  local score = 0
  local key, weight
  for key, weight in pairs(weights) do score = score + (stats[key] or 0) * weight end
  return score
end

function Generator:BestForSlot(slotKey, weights, claimed)
  local allowed = EM.SlotEquipLocations[slotKey] or {}
  local best, bestScore
  local i
  for i = 1, table.getn(EM.Inventory.items) do
    local item = EM.Inventory.items[i]
    local locationKey = EM.Util.LocationKey(item.location)
    if allowed[item.equipLoc] and item.usable ~= false and not claimed[locationKey] then
      local score = self:Score(item, weights)
      if score and score > 0 and (not bestScore or score > bestScore) then
        best, bestScore = item, score
      end
    end
  end
  return best, bestScore
end

function Generator:BestWeaponSet(weights, claimed)
  local allowed = EM.SlotEquipLocations.MainHandSlot
  local bestMain, bestOff, bestTotal
  local i
  for i = 1, table.getn(EM.Inventory.items) do
    local main = EM.Inventory.items[i]
    local mainKey = EM.Util.LocationKey(main.location)
    if allowed[main.equipLoc] and main.usable ~= false and not claimed[mainKey] then
      local mainScore = self:Score(main, weights)
      if mainScore and mainScore > 0 then
        local off, offScore
        if main.equipLoc ~= "INVTYPE_2HWEAPON" then
          local temporary = EM.Util.Copy(claimed); temporary[mainKey] = true
          off, offScore = self:BestForSlot("SecondaryHandSlot", weights, temporary)
        end
        local total = mainScore + (offScore or 0)
        if not bestTotal or total > bestTotal then
          bestMain, bestOff, bestTotal = main, off, total
        end
      end
    end
  end
  return bestMain, bestOff
end

function Generator:Generate(profileName, outfitName)
  profileName = string.lower(EM.Util.Trim(profileName))
  local weights = self.profiles[profileName]
  if not weights then return nil, "Unknown profile. Use /equipmate profiles." end
  if not EM.Capabilities.itemStats then
    return nil, "Smart generation requires ClassicAPI C_Item.GetItemStats; normal outfits remain available."
  end
  local outfit, err = EM.Outfits:Create(outfitName, false)
  if not outfit then return nil, err end
  local claimed = {}
  local i
  for i = 1, table.getn(EM.Slots) do
    local slotKey = EM.Slots[i].key
    if slotKey ~= "MainHandSlot" and slotKey ~= "SecondaryHandSlot" and slotKey ~= "AmmoSlot" and
        slotKey ~= "ShirtSlot" and slotKey ~= "TabardSlot" then
      local item = self:BestForSlot(slotKey, weights, claimed)
      if item then
        outfit.slots[slotKey] = EM.Items:ForOutfit(item)
        claimed[EM.Util.LocationKey(item.location)] = true
      end
    end
  end
  local mainItem, offhandItem = self:BestWeaponSet(weights, claimed)
  if mainItem then
    outfit.slots.MainHandSlot = EM.Items:ForOutfit(mainItem)
    claimed[EM.Util.LocationKey(mainItem.location)] = true
  end
  if mainItem and mainItem.equipLoc == "INVTYPE_2HWEAPON" then
    outfit.slots.SecondaryHandSlot = {empty=true}
  elseif offhandItem then
    outfit.slots.SecondaryHandSlot = EM.Items:ForOutfit(offhandItem)
  end
  outfit.generatedProfile = profileName
  EM.Emit("OUTFITS_CHANGED", "generated", outfit.id)
  return outfit
end
