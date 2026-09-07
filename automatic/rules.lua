local EM = EquipMate
local L = EM.L
local Rules = {name = "Rules", activeIDs = {}, baseline = nil, lastReason = nil}
EM.Rules = Rules
EM.modules.Rules = Rules

Rules.presets = {
  Boss={priority=100}, Lvl63={priority=110}, Trash={priority=50},
  BeastTrash={priority=60}, UndeadTrash={priority=60}, DemonTrash={priority=60},
  Critter={priority=70}, Riding={priority=20}, Dining={priority=30},
  Battleground={priority=30}, City={priority=10}, ArgentDawn={priority=15},
  AV={priority=35}, AB={priority=35}, WSG={priority=35}, Instance={priority=5},
  Battle={priority=40}, Defensive={priority=40}, Berserker={priority=40},
  Bear={priority=40}, Cat={priority=40}, Aquatic={priority=40}, Travel={priority=40},
  Moonkin={priority=40}, Shadowform={priority=40}, Stealth={priority=40},
  GhostWolf={priority=40}, Monkey={priority=40}, Hawk={priority=40},
  Cheetah={priority=40}, Pack={priority=40}, Beast={priority=40}, Wild={priority=40},
  Evocate={priority=40}
}

Rules.namePresets = {
  ["riding"]="Riding", ["dining"]="Dining", ["battlegrounds"]="Battleground",
  ["battleground"]="Battleground", ["around town"]="City", ["argent dawn"]="ArgentDawn",
  ["alterac valley"]="AV", ["arathi basin"]="AB", ["warsong gulch"]="WSG",
  ["instance"]="Instance",
  ["battle stance"]="Battle", ["defensive stance"]="Defensive",
  ["berserker stance"]="Berserker", ["bear form"]="Bear", ["dire bear form"]="Bear",
  ["cat form"]="Cat", ["aquatic form"]="Aquatic", ["travel form"]="Travel",
  ["moonkin form"]="Moonkin", ["shadowform"]="Shadowform", ["stealth"]="Stealth",
  ["ghost wolf"]="GhostWolf", ["aspect of the monkey"]="Monkey",
  ["aspect of the hawk"]="Hawk", ["aspect of the cheetah"]="Cheetah",
  ["aspect of the pack"]="Pack", ["aspect of the beast"]="Beast",
  ["aspect of the wild"]="Wild", ["evocation"]="Evocate", ["evocate"]="Evocate"
}

Rules.auraPresets = {
  Shadowform="Spell_Shadow_Shadowform", GhostWolf="Spell_Nature_SpiritWolf",
  Monkey="Ability_Hunter_AspectOfTheMonkey", Hawk="Spell_Nature_RavenForm",
  Beast="Ability_Mount_Pinktiger", Cheetah="Ability_Mount_JungleTiger",
  Pack="Ability_Mount_WhiteTiger", Wild="Spell_Nature_ProtectionformNature",
  Evocate="Spell_Nature_Purge"
}

Rules.bossTrashNames = {
  ["Core Rager"]=true, ["Firesworn"]=true, ["Flamewaker"]=true,
  ["Flamewaker Protector"]=true, ["Flamewaker Healer"]=true,
  ["Flamewaker Elite"]=true, ["Flamewaker Priest"]=true,
  ["Razzashi Cobra"]=true, ["Zealot Zath"]=true, ["Zealot Lor'Khan"]=true,
  ["Witherbark Speaker"]=true, ["Vilebranch Speaker"]=true,
  ["Grethok the Controller"]=true, ["Blackwing Guardsman"]=true,
  ["Sartura's Royal Guard"]=true, ["Crypt Guard"]=true,
  ["Deathknight Understudy"]=true, ["Naxxramas Combat Dummy"]=true,
  ["Naxxramas Follower"]=true, ["Naxxramas Worshipper"]=true,
  ["Soldier of the Frozen Wastes"]=true, ["Soul Weaver"]=true,
  ["Unstoppable Abomination"]=true
}

local function zoneMatches(group, zone)
  local names=L.ZONE_NAMES and L.ZONE_NAMES[group] or {}
  local i
  for i=1,table.getn(names) do
    if zone==names[i] then return true end
  end
  return false
end

local function isBattlegroundZone(zone)
  return zoneMatches("AV",zone) or zoneMatches("AB",zone) or
    zoneMatches("WSG",zone) or zoneMatches("Battleground",zone)
end

function Rules:PresetForName(name)
  local mapped = self.namePresets[string.lower(name)]
  if mapped then return mapped end
  local key
  for key in pairs(self.presets) do
    if string.lower(key) == string.lower(name) then return key end
  end
  return nil
end

function Rules:Initialize()
  self.frame = CreateFrame("Frame", "EquipMateRulesFrame")
  self.frame:SetScript("OnEvent", function() Rules:OnEvent(event, arg1) end)
  local events = {"PLAYER_TARGET_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA",
    "PLAYER_AURAS_CHANGED", "UPDATE_SHAPESHIFT_FORMS", "UPDATE_SHAPESHIFT_FORM",
    "MIRROR_TIMER_START", "MIRROR_TIMER_STOP", "PLAYER_ENTERING_WORLD",
    "UNIT_HEALTH", "UNIT_MANA"}
  local i
  for i = 1, table.getn(events) do EM.RegisterEvent(self.frame, events[i]) end
  EM.On("OUTFITS_CHANGED", self, self.OnOutfitsChanged)
  EM.On("EQUIP_FINISHED", self, self.OnEquipFinished)
  EM.On("INVENTORY_UPDATED", self, self.OnInventoryUpdated)
end

function Rules:OnEvent(name, unit)
  if (name == "UNIT_HEALTH" or name == "UNIT_MANA") and unit ~= "player" then return end
  self:ScheduleEvaluation()
end
function Rules:OnOutfitsChanged()
  self.forceEvaluation = true
  self:ScheduleEvaluation()
end

function Rules:ScheduleEvaluation()
  EM.After(0.15, self, self.Evaluate, "rules-evaluate")
end

function Rules:OnInventoryUpdated()
  if self.automaticFailed then
    self.forceEvaluation = true
    self:ScheduleEvaluation()
  end
  if not self.baseline or table.getn(self.activeIDs)==0 or EM.Engine.transaction then return end
  local controlled={}
  local i,key
  for i=1,table.getn(self.activeIDs) do
    local outfit=EM.Outfits:Get(self.activeIDs[i])
    if outfit then for key in pairs(outfit.slots) do controlled[key]=true end end
  end
  for i=1,table.getn(EM.Slots) do
    key=EM.Slots[i].key
    if not controlled[key] then
      local item=EM.Inventory.equipped[key]
      self.baseline.slots[key]=item and EM.Items:ForOutfit(item) or {empty=true}
    end
  end
end

function Rules:GetFacts()
  local facts = {}
  facts.hasTarget = UnitExists("target") and true or false
  facts.targetGUID = EM.Capabilities:GetUnitGUID("target")
  facts.targetName = facts.hasTarget and UnitName("target") or nil
  facts.targetLevel = facts.hasTarget and UnitLevel("target") or nil
  facts.targetClassification = facts.hasTarget and UnitClassification("target") or nil
  facts.targetCreatureType = facts.hasTarget and UnitCreatureType("target") or nil
  facts.targetDead = facts.hasTarget and type(UnitIsDead) == "function" and UnitIsDead("target") and true or false
  if facts.hasTarget and EM.Capabilities.unitCreatureTypeID then
    local ok,value=pcall(UnitCreatureTypeID,"target")
    if ok then facts.targetCreatureTypeID=value end
  end
  if facts.hasTarget and EM.Capabilities.unitCreatureID then
    local ok,value=pcall(UnitCreatureID,"target")
    if ok then facts.targetCreatureID=value end
  end
  facts.combat = EM.Engine:InCombat() and true or false
  facts.zone = GetRealZoneText and GetRealZoneText() or GetZoneText()
  facts.subzone = GetSubZoneText and GetSubZoneText() or ""
  facts.pvpType = GetZonePVPInfo and GetZonePVPInfo() or nil
  local instanceResolved=false
  if EM.Capabilities.instanceInfo then
    local ok,_,instanceType=pcall(GetInstanceInfo)
    if ok then
      facts.instance = instanceType and instanceType ~= "none"
      facts.instanceType = instanceType
      instanceResolved=true
    end
  end
  if not instanceResolved and type(IsInInstance) == "function" then
    local ok,inInstance,instanceType=pcall(IsInInstance)
    if ok then
      facts.instance = inInstance and true or false
      facts.instanceType = instanceType
    end
  end
  if EM.Capabilities.mounted then
    local ok,value=pcall(IsMounted)
    facts.mounted=ok and value and true or false
  else facts.mounted=false end
  if EM.Capabilities.swimming then
    local ok,value=pcall(IsSwimming)
    facts.swimming=ok and value and true or false
  else facts.swimming=false end
  facts.form = GetShapeshiftForm and GetShapeshiftForm() or 0
  if facts.form and facts.form > 0 and type(GetShapeshiftFormInfo)=="function" then
    local texture, formName = GetShapeshiftFormInfo(facts.form)
    facts.formName = formName
    if texture then
      local _,_,short=string.find(texture,"([^\\/]+)$")
      facts.formTexture=short or texture
    end
  end
  facts.auraTextures = {}
  if type(UnitBuff) == "function" then
    local i
    for i = 1, 32 do
      local texture = UnitBuff("player", i)
      if not texture then break end
      if texture then
        local _, _, short = string.find(texture, "([^\\/]+)$")
        facts.auraTextures[short or texture] = true
      end
    end
  end
  facts.dining = facts.auraTextures["INV_Misc_Fork&Knife"] or facts.auraTextures["INV_Misc_Food_28"]
  if not facts.dining then
    local texture
    for texture in pairs(facts.auraTextures) do
      if string.find(texture, "INV_Drink") then facts.dining = true; break end
    end
  end
  if facts.dining then
    local healthFull = UnitHealth("player") > UnitHealthMax("player") * 0.99
    local manaFull = UnitPowerType("player") ~= 0 or
      UnitMana("player") > UnitManaMax("player") * 0.99
    if healthFull and manaFull then facts.dining = false end
  end
  return facts
end

function Rules:ValueMatches(actual, expected)
  if type(expected) == "table" then
    local i
    for i = 1, table.getn(expected) do
      if self:ValueMatches(actual, expected[i]) then return true end
    end
    return false
  end
  if type(actual) == "string" and type(expected) == "string" then
    return string.lower(actual) == string.lower(expected)
  end
  return actual == expected
end

function Rules:MatchesConditions(conditions, facts)
  local key, expected
  for key, expected in pairs(conditions or {}) do
    if key == "targetLevelMin" then
      if not facts.targetLevel or facts.targetLevel < expected then return false end
    elseif key == "targetLevelMax" then
      if not facts.targetLevel or facts.targetLevel > expected then return false end
    elseif key == "targetCreatureType" then
      if not self:ValueMatches(facts.targetCreatureTypeID or facts.targetCreatureType, expected) then return false end
    elseif key == "auraTexture" then
      if not facts.auraTextures[expected] then return false end
    elseif not self:ValueMatches(facts[key], expected) then
      return false
    end
  end
  return true
end

function Rules:MatchesPreset(name, facts)
  local creatureName = string.lower(facts.targetCreatureType or "")
  local function creatureIs(kind)
    return facts.targetCreatureTypeID==EM.CreatureTypeIDs[kind] or
      creatureName==string.lower(L.CREATURE_TYPES[kind])
  end
  local namedBossTrash = facts.targetName and self.bossTrashNames[facts.targetName]
  local targetAlive=facts.hasTarget and not facts.targetDead
  local boss = targetAlive and (facts.targetClassification == "worldboss" or facts.targetLevel == -1 or namedBossTrash)
  local critter = creatureIs("Critter")
  local trash = targetAlive and facts.targetLevel and facts.targetLevel > 0 and
    facts.targetLevel < 63 and not boss and not critter
  if name == "Boss" then return boss end
  if name == "Lvl63" then return targetAlive and
    (facts.targetLevel == -1 or facts.targetLevel >= 63 or namedBossTrash) end
  if name == "Trash" then return trash end
  if name == "Critter" then return targetAlive and critter end
  if name == "BeastTrash" then
    return trash and creatureIs("Beast")
  end
  if name == "UndeadTrash" then
    return trash and creatureIs("Undead")
  end
  if name == "DemonTrash" then
    return trash and creatureIs("Demon")
  end
  if name == "Riding" then return facts.mounted end
  if name == "Dining" then return facts.dining and true or false end
  if name == "Battleground" then
    return facts.instanceType == "pvp" or isBattlegroundZone(facts.zone)
  end
  if name == "AV" then return zoneMatches("AV",facts.zone) end
  if name == "AB" then return zoneMatches("AB",facts.zone) end
  if name == "WSG" then return zoneMatches("WSG",facts.zone) end
  if name == "Instance" then return facts.instance and facts.instanceType ~= "pvp" end
  if name == "City" then return zoneMatches("City",facts.zone) end
  if name == "ArgentDawn" then return zoneMatches("ArgentDawn",facts.zone) end
  local formPresets={Battle=true,Defensive=true,Berserker=true,Bear=true,Cat=true,
    Aquatic=true,Travel=true,Moonkin=true,Stealth=true}
  local formTextures={Battle="Ability_Warrior_OffensiveStance",
    Defensive="Ability_Warrior_DefensiveStance",Berserker="Ability_Racial_Avatar",
    Bear="Ability_Racial_BearForm",Cat="Ability_Druid_CatForm",
    Aquatic="Ability_Druid_AquaticForm",Travel="Ability_Druid_TravelForm",
    Moonkin="Spell_Nature_ForceOfNature",Stealth="Ability_Stealth"}
  if formPresets[name] then
    return facts.formTexture==formTextures[name] or
      self:ValueMatches(facts.formName,L.PRESET_LABELS[name])
  end
  if self.auraPresets[name] then return facts.auraTextures[self.auraPresets[name]] and true or false end
  return false
end

function Rules:OutfitMatch(outfit, facts)
  local battleground = facts.instanceType == "pvp" or isBattlegroundZone(facts.zone)
  if outfit.disableInBattleground and battleground then return false end
  if outfit.disableInInstance and facts.instance and not battleground then return false end
  if outfit.autoPreset and self:MatchesPreset(outfit.autoPreset, facts) then
    return true, self.presets[outfit.autoPreset].priority, outfit.autoPreset
  end
  local i, rule
  for i = 1, table.getn(outfit.rules or {}) do
    rule = outfit.rules[i]
    if self:MatchesConditions(rule.conditions, facts) then
      return true, rule.priority or 0, rule.name or "custom rule"
    end
  end
  return false
end

local function sortMatches(a, b)
  if a.priority == b.priority then return a.order < b.order end
  return a.priority < b.priority
end

function Rules:IDsEqual(matches)
  if table.getn(matches) ~= table.getn(self.activeIDs) then return false end
  local i
  for i = 1, table.getn(matches) do
    if matches[i].outfit.id ~= self.activeIDs[i] then return false end
  end
  return true
end

function Rules:DebugEvaluation(facts,matches)
  if not EM.DebugEnabled() then return end
  local matched={}
  local i
  for i=1,table.getn(matches) do
    table.insert(matched,matches[i].outfit.name.." via "..tostring(matches[i].reason))
  end
  local activeAuras={}
  local name,texture
  for name,texture in pairs(self.auraPresets) do
    if facts.auraTextures and facts.auraTextures[texture] then table.insert(activeAuras,name) end
  end
  table.sort(activeAuras)
  local travelForm=facts.formTexture=="Ability_Druid_TravelForm" or
    self:ValueMatches(facts.formName,L.PRESET_LABELS.Travel)
  local ghostWolf=facts.auraTextures and
    facts.auraTextures[self.auraPresets.GhostWolf]
  local context={
    "combat "..(facts.combat and "yes" or "no"),
    "zone "..tostring(facts.zone or "unknown"),
    "instance "..tostring(facts.instanceType or (facts.instance and "yes" or "no"))
  }
  if not travelForm and not ghostWolf then
    table.insert(context,1,"mounted "..(facts.mounted and "yes" or "no"))
  end
  if facts.form and facts.form>0 then
    table.insert(context,"form "..tostring(facts.formName or facts.formTexture or facts.form))
  end
  if facts.dining then table.insert(context,"dining yes") end
  if table.getn(activeAuras)>0 then table.insert(context,"auras "..table.concat(activeAuras,"+")) end
  if facts.hasTarget then
    local target=tostring(facts.targetName or "unknown")
    if facts.targetLevel then target=target.." lvl "..tostring(facts.targetLevel) end
    if facts.targetClassification and facts.targetClassification~="normal" then
      target=target.." "..facts.targetClassification
    end
    if facts.targetCreatureType then target=target.." "..facts.targetCreatureType end
    if facts.targetDead then target=target.." dead" end
    table.insert(context,"target "..target)
  else table.insert(context,"target none") end
  local summary=(table.getn(matched)>0 and table.concat(matched,", ") or "no matches")..
    "; "..table.concat(context,", ")
  if summary==self.debugLastEvaluation then return end
  self.debugLastEvaluation=summary
  EM.Debug("automatic check: "..summary)
end

function Rules:Evaluate()
  local facts = self:GetFacts()
  self.lastFacts = facts
  local matches = {}
  local i
  for i = 1, table.getn(EquipMateDB.order) do
    local outfit = EquipMateDB.outfits[EquipMateDB.order[i]]
    local matched, priority, reason = self:OutfitMatch(outfit, facts)
    if matched then
      table.insert(matches, {outfit=outfit, priority=priority, reason=reason, order=i})
    end
  end
  table.sort(matches, sortMatches)
  self:DebugEvaluation(facts,matches)
  if self:IDsEqual(matches) and not self.forceEvaluation then return end
  self.forceEvaluation = false
  if table.getn(matches) == 0 then
    self.activeIDs = {}
    self.lastReason = "No automatic conditions match"
    if self.baseline then
      EM.Engine:WearOutfit(self.baseline, "automatic", self.lastReason,
        "restore-automatic")
    end
    EM.Emit("RULES_CHANGED", self.lastReason)
    return
  end
  if not self.baseline then
    EM.Inventory:ScanAll("automatic-baseline")
    self.baseline = EM.Outfits:Snapshot("Pre-automatic equipment")
  end
  local overlays, reasons = {}, {}
  self.activeIDs = {}
  for i = 1, table.getn(matches) do
    table.insert(overlays, matches[i].outfit)
    table.insert(self.activeIDs, matches[i].outfit.id)
    table.insert(reasons, matches[i].outfit.name .. " (" .. matches[i].reason .. ")")
  end
  self.lastReason = table.concat(reasons, ", ")
  local compiled = EM.Outfits:Compile(self.baseline, overlays, "Automatic: " .. self.lastReason)
  EM.Engine:WearOutfit(compiled, "automatic", self.lastReason)
  EM.Emit("RULES_CHANGED", self.lastReason)
end

function Rules:OnEquipFinished(transaction, success)
  if transaction.source == "automatic" then
    self.automaticFailed = not success
    if success and transaction.mode == "restore-automatic" then self.baseline=nil end
  elseif transaction.source == "manual" and success then
    if table.getn(self.activeIDs) > 0 then
      EM.Inventory:ScanAll("manual-automatic-baseline")
      self.baseline = EM.Outfits:Snapshot("Pre-automatic equipment")
      self.forceEvaluation = true
      self:ScheduleEvaluation()
    else
      self.baseline = nil
    end
  end
end

function Rules:AddRule(outfitID, name, priority, conditions)
  local outfit = EM.Outfits:Get(outfitID)
  if not outfit then return nil, "Unknown outfit." end
  table.insert(outfit.rules, {name=name, priority=priority or 0, conditions=conditions})
  EM.Emit("OUTFITS_CHANGED", "rule", outfit.id)
  return true
end
