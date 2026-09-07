local EM=EquipMate
local L={}
EM.L=L
EM.locale=type(GetLocale)=="function" and GetLocale() or "enUS"

L.TITLE="EquipMate"
L.POPUP_NAME="Enter an outfit name"
L.POPUP_DELETE="Delete this outfit?"
L.POPUP_OVERWRITE="Overwrite \"%s\"?\nSave your currently equipped items to this outfit's selected slots."
L.POPUP_READ_ERROR="Could not read the outfit name field."
L.EQUIP="Equip"
L.SAVE="Save"
L.OVERWRITE="Overwrite"
L.ALL_SLOTS="All slots"
L.NO_SLOTS="No slots"
L.SLOT_INCLUDED_FMT="Included in %s"
L.SLOT_IGNORED_FMT="Not included in %s"
L.SLOT_INCLUDED_HELP="Click to leave this slot unchanged."
L.SLOT_IGNORED_HELP="Click to save the currently equipped item in this outfit."
L.SLOT_EMPTY_HELP="This outfit keeps this slot empty."
L.EMPTY="Empty"
L.ITEM_FMT="Item %s"
L.CONTEXT_PRESET_FMT="Automatic: %s"
L.OFF="Off"
L.RENAME="Rename"
L.DUPLICATE="Duplicate"
L.KEYBINDING_FMT="Keybinding: %s"
L.NONE="None"
L.DELETE="Delete"
L.NO_BINDING="No quick keybinding"
L.BINDING_FMT="Outfit binding %d"
L.TOOLTIP_KEYBINDING_FMT="Keybinding: %s"
L.SELECTED_FMT="[Selected] %s"
L.BINDING_CHAT_FMT="quick outfit binding %s for %s"
L.CLEARED="cleared"
L.RULE_TITLE="Automatic"
L.RULE_OFF="Off"
L.RULE_CATEGORY_GENERAL="General"
L.RULE_CATEGORY_TARGETS="Targets"
L.RULE_CATEGORY_PLACES="Places"
L.RULE_CATEGORY_FORMS="Forms"
L.RULE_CATEGORY_ASPECTS="Aspects"
L.PRESET_HELP_FMT="Automatically equips this outfit when %s is detected."
L.PRESET_OFF_HELP="Disables automatic equipping for this outfit."
L.ENHANCED_APIS_MISSING="No enhanced client API detected (ClassicAPI, nampower, or SuperWoW); using stock Vanilla compatibility."
L.SELECT_FIRST="Select an outfit first."
L.MATCHED_FMT="%d of %d slots equipped"
L.MISSING="Missing:"
L.AUTOMATIC_FMT="Automatic: %s"
L.CUSTOM_RULES_FMT="Custom automatic rules: %d"
L.BINDING_HEADER="EquipMate"
L.BINDING_OUTFIT_FMT="Toggle EquipMate outfit %d"
L.CREATURE_TYPES={Beast="Beast",Undead="Undead",Demon="Demon",Critter="Critter"}
L.ZONE_NAMES={
  City={"Ironforge","Darnassus","Stormwind","Stormwind City","Orgrimmar","Thunder Bluff","Undercity"},
  AV={"Alterac Valley"},AB={"Arathi Basin"},WSG={"Warsong Gulch"},
  Battleground={"Blood Ring","Sunnyglade Valley"},
  ArgentDawn={"Western Plaguelands","Eastern Plaguelands","Stratholme","Scholomance","Naxxramas"}
}
L.PRESET_LABELS={Boss="Boss",Lvl63="Level 63+",Trash="Trash",BeastTrash="Beast trash",
UndeadTrash="Undead trash",DemonTrash="Demon trash",Critter="Critter",Riding="Riding",
Dining="Dining",Battleground="Battleground",City="City",ArgentDawn="Argent Dawn",
AV="Alterac Valley",AB="Arathi Basin",WSG="Warsong Gulch",Instance="Instance",
Battle="Battle Stance",Defensive="Defensive Stance",Berserker="Berserker Stance",
Bear="Bear Form",Cat="Cat Form",Aquatic="Aquatic Form",Travel="Travel Form",
Moonkin="Moonkin Form",Shadowform="Shadowform",Stealth="Stealth",GhostWolf="Ghost Wolf",
Monkey="Aspect of the Monkey",Hawk="Aspect of the Hawk",Cheetah="Aspect of the Cheetah",
Pack="Aspect of the Pack",Beast="Aspect of the Beast",Wild="Aspect of the Wild",Evocate="Evocation"}

L.SLOT_LABELS={
  HeadSlot="Head",NeckSlot="Neck",ShoulderSlot="Shoulders",ShirtSlot="Shirt",
  ChestSlot="Chest",WaistSlot="Waist",LegsSlot="Legs",FeetSlot="Feet",
  WristSlot="Wrists",HandsSlot="Hands",Finger0Slot="Ring 1",Finger1Slot="Ring 2",
  Trinket0Slot="Trinket 1",Trinket1Slot="Trinket 2",BackSlot="Back",
  MainHandSlot="Main hand",SecondaryHandSlot="Off hand",RangedSlot="Ranged / Relic",
  TabardSlot="Tabard",AmmoSlot="Ammo"
}

function EM.LF(key,a,b,c,d)
  local value=L[key] or key
  if a~=nil then return string.format(value,a,b,c,d) end
  return value
end

function EM.ApplyLocalization()
  BINDING_HEADER_EQUIPMATE_TITLE=L.BINDING_HEADER
  local i
  for i=1,10 do setglobal("BINDING_NAME_EQUIPMATE_OUTFIT"..i,string.format(L.BINDING_OUTFIT_FMT,i)) end
  if EM.SlotLabels and L.SLOT_LABELS then
    local key,value
    for key,value in pairs(L.SLOT_LABELS) do EM.SlotLabels[key]=value end
  end
end

EM.ApplyLocalization()
