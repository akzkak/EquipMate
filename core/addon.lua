EquipMate = EquipMate or {}

local EM = EquipMate
EM.name = "EquipMate"
EM.version = "0.3.0"
EM.modules = EM.modules or {}
EM.listeners = EM.listeners or {}
EM.timers = EM.timers or {}
EM.initialized = false

BINDING_HEADER_EQUIPMATE_TITLE = "EquipMate"
BINDING_NAME_EQUIPMATE_TOGGLE = "Toggle EquipMate"
for i = 1, 10 do
  setglobal("BINDING_NAME_EQUIPMATE_OUTFIT" .. i, "Toggle EquipMate outfit " .. i)
end

function EM.Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff64d8ffEquipMate:|r " .. tostring(message))
  end
end

function EM.DebugEnabled()
  return EquipMateDB and EquipMateDB.options and EquipMateDB.options.debug == true
end

function EM.Debug(message)
  if EM.DebugEnabled() then
    EM.Print("|cffaaaaaaDebug: " .. tostring(message) .. "|r")
  end
end

function EM.On(name, owner, handler)
  if not EM.listeners[name] then EM.listeners[name] = {} end
  table.insert(EM.listeners[name], {owner = owner, handler = handler})
end

function EM.Emit(name, a, b, c, d)
  local listeners = EM.listeners[name]
  if not listeners then return end
  local i
  for i = 1, table.getn(listeners) do
    local listener = listeners[i]
    listener.handler(listener.owner, a, b, c, d)
  end
end

function EM.After(delay, owner, handler, key)
  if key then
    local i
    for i = table.getn(EM.timers), 1, -1 do
      if EM.timers[i].key == key then table.remove(EM.timers, i) end
    end
  end
  table.insert(EM.timers, {
    at = GetTime() + (delay or 0), owner = owner, handler = handler, key = key
  })
end

function EM.CancelTimer(key)
  local i
  for i = table.getn(EM.timers), 1, -1 do
    if EM.timers[i].key == key then table.remove(EM.timers, i) end
  end
end

local function EquipMate_OnUpdate()
  local now = GetTime()
  local i = 1
  while i <= table.getn(EM.timers) do
    local timer = EM.timers[i]
    if timer.at <= now then
      table.remove(EM.timers, i)
      timer.handler(timer.owner)
    else
      i = i + 1
    end
  end
end

function EM.RegisterEvent(frame, name)
  local ok = pcall(frame.RegisterEvent, frame, name)
  return ok
end

function EM.InitializeDatabase()
  if type(EquipMateDB) ~= "table" then EquipMateDB = {} end
  if type(EquipMateDB.version) ~= "number" then EquipMateDB.version = 1 end
  if type(EquipMateDB.nextOutfitID) ~= "number" or EquipMateDB.nextOutfitID < 1 or
      EquipMateDB.nextOutfitID ~= math.floor(EquipMateDB.nextOutfitID) then
    EquipMateDB.nextOutfitID = 1
  end
  if type(EquipMateDB.outfits) ~= "table" then EquipMateDB.outfits = {} end
  if type(EquipMateDB.order) ~= "table" then EquipMateDB.order = {} end
  if type(EquipMateDB.bindings) ~= "table" then EquipMateDB.bindings = {} end
  if type(EquipMateDB.options) ~= "table" then EquipMateDB.options = {} end
  if type(EquipMateDB.options.debug) ~= "boolean" then EquipMateDB.options.debug = false end
  -- Automatic behavior is controlled only by each outfit's presets and rules.
  EquipMateDB.options.autoSwitch = nil
  EquipMateDB.options.showMinimap = nil
end

function EM.Initialize()
  if EM.initialized then return end
  EM.InitializeDatabase()
  local order = {"Capabilities", "Inventory", "Outfits", "Generator", "Engine", "Rules", "UIIntegration", "UI", "Bindings"}
  local i
  for i = 1, table.getn(order) do
    local module = EM.modules[order[i]]
    if module and module.Initialize then module:Initialize() end
  end
  EM.initialized = true
  EM.Emit("READY")
  EM.Print("ready (" .. EM.Capabilities:Summary() .. ")")
end

EM.frame = CreateFrame("Frame", "EquipMateEventFrame")
EM.frame:SetScript("OnUpdate", EquipMate_OnUpdate)
EM.frame:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    EM.Initialize()
  elseif event == "PLAYER_ENTERING_WORLD" then
    if not EM.initialized then EM.Initialize() end
    if EM.Capabilities then EM.Capabilities:RunLoginCheck() end
  end
end)
EM.frame:RegisterEvent("VARIABLES_LOADED")
EM.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
