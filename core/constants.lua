local EM = EquipMate

EM.Slots = {
  {key="HeadSlot", id=1}, {key="NeckSlot", id=2},
  {key="ShoulderSlot", id=3}, {key="ShirtSlot", id=4},
  {key="ChestSlot", id=5}, {key="WaistSlot", id=6},
  {key="LegsSlot", id=7}, {key="FeetSlot", id=8},
  {key="WristSlot", id=9}, {key="HandsSlot", id=10},
  {key="Finger0Slot", id=11}, {key="Finger1Slot", id=12},
  {key="Trinket0Slot", id=13}, {key="Trinket1Slot", id=14},
  {key="BackSlot", id=15}, {key="MainHandSlot", id=16},
  {key="SecondaryHandSlot", id=17}, {key="RangedSlot", id=18},
  {key="TabardSlot", id=19}, {key="AmmoSlot", id=0}
}

EM.SlotByKey = {}
EM.SlotByID = {}
local i
for i = 1, table.getn(EM.Slots) do
  local slot = EM.Slots[i]
  EM.SlotByKey[slot.key] = slot
  EM.SlotByID[slot.id] = slot
end

EM.SlotLabels = {
  HeadSlot="Head", NeckSlot="Neck", ShoulderSlot="Shoulders", ShirtSlot="Shirt",
  ChestSlot="Chest", WaistSlot="Waist", LegsSlot="Legs", FeetSlot="Feet",
  WristSlot="Wrists", HandsSlot="Hands", Finger0Slot="Ring 1",
  Finger1Slot="Ring 2", Trinket0Slot="Trinket 1", Trinket1Slot="Trinket 2",
  BackSlot="Back", MainHandSlot="Main hand", SecondaryHandSlot="Off hand",
  RangedSlot="Ranged / Relic", TabardSlot="Tabard", AmmoSlot="Ammo"
}

EM.CreatureTypeIDs = {Beast=1, Dragonkin=2, Demon=3, Elemental=4, Giant=5,
  Undead=6, Humanoid=7, Critter=8, Mechanical=9, NotSpecified=10, Totem=11}

EM.SpecialtyBagIDs = {
  [21340]=true,[21341]=true,[21342]=true,[22243]=true,[22244]=true,
  [2102]=true,[7279]=true,[8218]=true,[7372]=true,[3574]=true,[3604]=true,
  [5441]=true,[2663]=true,[19320]=true,[19319]=true,[7371]=true,[3573]=true,
  [7278]=true,[2101]=true,[11362]=true,[8217]=true,[3605]=true,[2662]=true,
  [5439]=true,[18714]=true,[22246]=true,[22248]=true,[22249]=true,
  [22250]=true,[22251]=true,[22252]=true
}

EM.SlotEquipLocations = {
  HeadSlot={INVTYPE_HEAD=true}, NeckSlot={INVTYPE_NECK=true},
  ShoulderSlot={INVTYPE_SHOULDER=true}, ShirtSlot={INVTYPE_BODY=true},
  ChestSlot={INVTYPE_CHEST=true,INVTYPE_ROBE=true}, WaistSlot={INVTYPE_WAIST=true},
  LegsSlot={INVTYPE_LEGS=true}, FeetSlot={INVTYPE_FEET=true},
  WristSlot={INVTYPE_WRIST=true}, HandsSlot={INVTYPE_HAND=true},
  Finger0Slot={INVTYPE_FINGER=true}, Finger1Slot={INVTYPE_FINGER=true},
  Trinket0Slot={INVTYPE_TRINKET=true}, Trinket1Slot={INVTYPE_TRINKET=true},
  BackSlot={INVTYPE_CLOAK=true},
  MainHandSlot={INVTYPE_WEAPON=true,INVTYPE_WEAPONMAINHAND=true,INVTYPE_2HWEAPON=true},
  SecondaryHandSlot={INVTYPE_WEAPON=true,INVTYPE_WEAPONOFFHAND=true,
    INVTYPE_SHIELD=true,INVTYPE_HOLDABLE=true},
  RangedSlot={INVTYPE_RANGED=true,INVTYPE_RANGEDRIGHT=true,INVTYPE_THROWN=true,INVTYPE_RELIC=true},
  TabardSlot={INVTYPE_TABARD=true}, AmmoSlot={INVTYPE_AMMO=true}
}
