-- Run from the addon root with Lua 5.1. WoW equipment moves are simulated.
EquipMate = {modules={}}
local EM = EquipMate
function EM.On() end
function EM.Emit() end
function EM.RegisterEvent() end
function EM.CancelTimer() end
function EM.Debug() end
function EM.Print() end
function GetTime() return 0 end
function CreateFrame() return {SetScript=function() end} end

dofile("core/util.lua")
dofile("core/constants.lua")
dofile("equipment/items.lua")
dofile("equipment/outfits.lua")
EM.Inventory = {equipped={}, ScanAll=function() end}

local function loadEngine()
  dofile("equipment/engine.lua")
  local engine = EM.Engine
  function engine:DebugStart() end
  function engine:DebugFinish() end
  function engine:Step()
    local key, item
    for key, item in pairs(self.transaction.outfit.slots) do
      EM.Inventory.equipped[key] = not item.empty and EM.Util.Copy(item) or nil
    end
    self:Finish(true, "simulated equipment verified")
  end
  engine:Initialize()
  return engine
end

EquipMateDB = {outfits={
  [1]={id=1, name="Pickaxe", slots={MainHandSlot={id=2901}}},
  [2]={id=2, name="Trinket", slots={Trinket0Slot={id=11122}}}
}}
EM.Inventory.equipped = {MainHandSlot={id=100}, Trinket0Slot={id=200}}
local engine = loadEngine()
assert(engine:Toggle(1))
assert(EM.Inventory.equipped.MainHandSlot.id == 2901)
assert(EquipMateDB.manualState.baseline.slots.MainHandSlot.id == 100)

-- Logout saves the latest uncontrolled-slot changes as well as active layers.
EM.Inventory.equipped.HeadSlot = {id=300}
engine:UpdateManualBaseline()
engine:OnGameEvent("PLAYER_LOGOUT")
EquipMateDB = EM.Util.Copy(EquipMateDB) -- simulate SavedVariables round-trip
EM.Inventory.equipped = {} -- item cache need not be ready during initialization
engine = loadEngine()
assert(engine.manualBaseline.slots.MainHandSlot.id == 100)
assert(engine.manualBaseline.slots.HeadSlot.id == 300)
assert(engine.transaction == nil) -- login must not start equipment moves
-- By the user's first toggle, the equipment scan sees the worn pickaxe.
EM.Inventory.equipped = {MainHandSlot={id=2901}, Trinket0Slot={id=200}, HeadSlot={id=300}}
assert(engine:Toggle(1))
assert(EM.Inventory.equipped.MainHandSlot.id == 100)
assert(EM.Inventory.equipped.HeadSlot.id == 300)
assert(EquipMateDB.manualState == nil)

-- Reload with overlapping lifetime of two independently toggleable layers.
engine:Toggle(1)
engine:Toggle(2)
engine:OnGameEvent("PLAYER_LOGOUT")
engine = loadEngine()
engine:Toggle(1)
assert(EM.Inventory.equipped.MainHandSlot.id == 100)
assert(EM.Inventory.equipped.Trinket0Slot.id == 11122)
engine:Toggle(2)
assert(EM.Inventory.equipped.Trinket0Slot.id == 200)
assert(EquipMateDB.manualState == nil)

-- Deleted, duplicate, and invalid saved outfit IDs are not restored.
engine:Toggle(1)
engine:Toggle(2)
local saved = EM.Util.Copy(EquipMateDB.manualState)
EquipMateDB.manualState.overlays = {999, 1, 1, "bad"}
engine = loadEngine()
assert(table.getn(engine.manualOverlays) == 1 and engine.manualOverlays[1] == 1)
EquipMateDB.manualState.overlays = {999}
engine = loadEngine()
assert(engine.manualBaseline == nil and EquipMateDB.manualState == nil)

-- Incomplete snapshots must not turn missing login data into unequip requests.
EquipMateDB.manualState = saved
EquipMateDB.manualState.baseline.slots.MainHandSlot = nil
engine = loadEngine()
assert(engine.manualBaseline == nil and EquipMateDB.manualState == nil)

-- Manually replacing weapons while the outfit is marked active must make the
-- next press equip the outfit and capture the new return weapon, not restore
-- the stale baseline. Include the original no-op activation reported in-game.
EM.Inventory.equipped.MainHandSlot = {id=2901}
engine:Toggle(1)
EM.Inventory.equipped.MainHandSlot = {id=100}
engine:Toggle(1)
assert(EM.Inventory.equipped.MainHandSlot.id == 2901,
  "first press after a manual replacement must equip the pickaxe")
assert(EquipMateDB.manualState.baseline.slots.MainHandSlot.id == 100,
  "new return weapon must replace stale pickaxe baseline")
engine:OnGameEvent("PLAYER_LOGOUT")
engine = loadEngine()
engine:Toggle(1)
assert(EM.Inventory.equipped.MainHandSlot.id == 100,
  "toggle after relog must restore the manually selected weapon")

-- An upper layer hiding a lower one's weapon is not a manual replacement.
EquipMateDB.outfits[3] = {id=3, name="Other weapon", slots={MainHandSlot={id=400}}}
engine:Toggle(1)
engine:Toggle(3)
engine:Toggle(1)
assert(EM.Inventory.equipped.MainHandSlot.id == 400)
assert(table.getn(engine.manualOverlays) == 1 and engine.manualOverlays[1] == 3)
engine:Toggle(3)
assert(EM.Inventory.equipped.MainHandSlot.id == 100)

-- A manual replacement after a real swap also starts a new toggle cycle.
engine:Toggle(1)
EM.Inventory.equipped.MainHandSlot = {id=500}
engine:Toggle(1)
assert(EM.Inventory.equipped.MainHandSlot.id == 2901)
engine:Toggle(1)
assert(EM.Inventory.equipped.MainHandSlot.id == 500)

-- Existing deletion handling still restores equipment and clears persisted state.
EM.Inventory.equipped.MainHandSlot = {id=100}
engine:Toggle(1)
EquipMateDB.outfits[1] = nil
engine:OnOutfitsChanged("deleted", 1)
assert(EM.Inventory.equipped.MainHandSlot.id == 100)
assert(EquipMateDB.manualState == nil)
print("manual toggle persistence checks passed")
