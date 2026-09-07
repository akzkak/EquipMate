local EM = EquipMate
local Bindings = {name = "Bindings"}
EM.Bindings = Bindings
EM.modules.Bindings = Bindings

function Bindings:Initialize()
  SLASH_EQUIPMATE1 = "/equipmate"
  SlashCmdList["EQUIPMATE"] = function(message) Bindings:Command(message) end
end

function Bindings:FindSlot(text)
  local needle = string.lower(EM.Util.Trim(text))
  local i
  for i = 1, table.getn(EM.Slots) do
    local key = EM.Slots[i].key
    local short = string.gsub(string.lower(key), "slot$", "")
    local label = string.lower(EM.SlotLabels[key])
    if needle == string.lower(key) or needle == short or needle == label then return key end
  end
  return nil
end

function Bindings:SelectedOrNamed(name)
  if name and name ~= "" then return EM.Outfits:Get(name) end
  return EM.Outfits:Get(EM.Outfits.selectedID)
end

function Bindings:Help()
  EM.Print("/equipmate create <name>, empty <name>, naked <name>, select <name>, wear <name>, toggle <name>")
  EM.Print("/equipmate update [name], rename <new name>, duplicate <new name>, delete [name]")
  EM.Print("/equipmate slot <slot> current|empty|ignore, bind <1-10> [name]")
  EM.Print("/equipmate preset <context>|off (Boss, Trash, Riding, Dining, forms, zones, etc.)")
  EM.Print("/equipmate restrict bg|instance on|off (selected automatic outfit)")
  EM.Print("/equipmate visibility helm|cloak show|hide|inherit (selected outfit)")
  EM.Print("/equipmate rule <priority> <fact> <value>, rules, clearrules (uses selected outfit)")
  EM.Print("/equipmate profiles, generate <profile> <outfit name> (ClassicAPI structured stats)")
  EM.Print("/equipmate why, list, unused, status, debug on|off")
end

function Bindings:Command(message)
  local command, rest = EM.Util.SplitFirst(message)
  if command == "" or command == "show" then EM.ToggleUI(); return end
  if command == "help" then self:Help(); return end
  if command == "list" then
    local i
    for i = 1, table.getn(EquipMateDB.order) do
      local outfit = EquipMateDB.outfits[EquipMateDB.order[i]]
      local status = EM.Outfits:Status(outfit.id)
      EM.Print(i .. ". " .. outfit.name .. " - " .. status.state)
    end
    return
  end
  if command == "unused" then
    local items = EM.Outfits:GetUnusedItems()
    local i
    EM.Print(table.getn(items) .. " equippable carried items are not used by an outfit:")
    for i = 1, table.getn(items) do EM.Print(items[i].link or items[i].name or ("item " .. items[i].id)) end
    return
  end
  if command == "create" or command == "empty" then
    local outfit, err = EM.Outfits:Create(rest, command == "create")
    if outfit then EM.Print("created " .. outfit.name) else EM.Print(err) end
    return
  end
  if command == "naked" then
    local outfit, err = EM.Outfits:CreateNaked(rest)
    if outfit then EM.Print("created " .. outfit.name) else EM.Print(err) end
    return
  end
  if command == "profiles" then
    local names = {}
    local name
    for name in pairs(EM.Generator.profiles) do table.insert(names, name) end
    table.sort(names)
    EM.Print("generation profiles: " .. table.concat(names, ", "))
    return
  end
  if command == "generate" then
    local profile, name = EM.Util.SplitFirst(rest)
    local outfit, err = EM.Generator:Generate(profile, name)
    if outfit then EM.Print("generated " .. outfit.name .. " using " .. profile)
    else EM.Print(err) end
    return
  end
  if command == "select" then
    local outfit = EM.Outfits:Get(rest)
    if outfit then EM.Outfits.selectedID=outfit.id; EM.UI:Refresh(); EM.Print("selected " .. outfit.name)
    else EM.Print("Unknown outfit: " .. rest) end
    return
  end
  if command == "wear" or command == "toggle" then
    local outfit = EM.Outfits:Get(rest)
    if not outfit then EM.Print("Unknown outfit: " .. rest); return end
    local ok, err
    if command == "toggle" then ok, err = EM.Engine:Toggle(outfit.id) else ok, err = EM.Engine:Wear(outfit.id) end
    if not ok and err then EM.Print(err) end
    return
  end
  if command == "update" then
    local outfit = self:SelectedOrNamed(rest)
    if outfit then EM.Outfits:UpdateFromEquipped(outfit.id); EM.Print("updated " .. outfit.name)
    else EM.Print("Select an outfit first.") end
    return
  end
  if command == "rename" then
    local outfit = self:SelectedOrNamed("")
    local result, err = outfit and EM.Outfits:Rename(outfit.id, rest)
    if result then EM.Print("renamed outfit to " .. result.name) else EM.Print(err or "Select an outfit first.") end
    return
  end
  if command == "duplicate" then
    local outfit = self:SelectedOrNamed("")
    local result, err = outfit and EM.Outfits:Duplicate(outfit.id, rest)
    if result then EM.Print("created " .. result.name) else EM.Print(err or "Select an outfit first.") end
    return
  end
  if command == "delete" then
    local outfit = self:SelectedOrNamed(rest)
    if outfit then local name=outfit.name; EM.Outfits:Delete(outfit.id); EM.Print("deleted " .. name)
    else EM.Print("Unknown outfit.") end
    return
  end
  if command == "slot" then
    local slotText, mode = EM.Util.SplitFirst(rest)
    local slotKey = self:FindSlot(slotText)
    local outfit = self:SelectedOrNamed("")
    if not slotKey then EM.Print("Unknown slot: " .. slotText)
    elseif not outfit then EM.Print("Select an outfit first.")
    else
      local result, err = EM.Outfits:SetSlot(outfit.id, slotKey, string.lower(mode))
      if not result then EM.Print(err) end
    end
    return
  end
  if command == "bind" then
    local indexText, name = EM.Util.SplitFirst(rest)
    local index = tonumber(indexText)
    local outfit = self:SelectedOrNamed(name)
    if not index or index < 1 or index > 10 or index~=math.floor(index) then
      EM.Print("Binding index must be a whole number from 1 through 10.")
    elseif not outfit then EM.Print("Select or name an outfit.")
    else
      local i
      for i=1,10 do
        if EquipMateDB.bindings[i]==outfit.id then EquipMateDB.bindings[i]=nil end
      end
      EquipMateDB.bindings[index]=outfit.id
      EM.Print("binding " .. index .. " now toggles " .. outfit.name)
    end
    return
  end
  if command == "preset" then
    local outfit = self:SelectedOrNamed("")
    if not outfit then EM.Print("Select an outfit first."); return end
    local preset=EM.Rules:PresetForName(rest)
    if string.lower(rest) == "off" then outfit.autoPreset=nil
    elseif preset then outfit.autoPreset=preset
    else EM.Print("Unknown automatic preset."); return end
    EM.Emit("OUTFITS_CHANGED", "preset", outfit.id)
    EM.Print("automatic preset for " .. outfit.name .. ": " .. (outfit.autoPreset or "off"))
    return
  end
  if command == "restrict" then
    local scope, setting = EM.Util.SplitFirst(rest)
    local outfit = self:SelectedOrNamed("")
    if not outfit then EM.Print("Select an outfit first."); return end
    setting=string.lower(setting)
    if setting~="on" and setting~="off" then
      EM.Print("Usage: /equipmate restrict bg|instance on|off"); return
    end
    local disabled = setting == "on"
    if scope == "bg" then outfit.disableInBattleground = disabled
    elseif scope == "instance" then outfit.disableInInstance = disabled
    else EM.Print("Usage: /equipmate restrict bg|instance on|off"); return end
    EM.Emit("OUTFITS_CHANGED", "restriction", outfit.id)
    EM.Print(scope .. " restriction " .. (disabled and "enabled" or "disabled") .. " for " .. outfit.name)
    return
  end
  if command == "visibility" then
    local part, setting = EM.Util.SplitFirst(rest)
    local outfit = self:SelectedOrNamed("")
    if not outfit then EM.Print("Select an outfit first."); return end
    if part ~= "helm" and part ~= "cloak" then
      EM.Print("Usage: /equipmate visibility helm|cloak show|hide|inherit"); return
    end
    if not outfit.visibility then outfit.visibility = {} end
    if setting == "show" then outfit.visibility[part] = true
    elseif setting == "hide" then outfit.visibility[part] = false
    elseif setting == "inherit" then outfit.visibility[part] = nil
    else EM.Print("Usage: /equipmate visibility helm|cloak show|hide|inherit"); return end
    EM.Emit("OUTFITS_CHANGED", "visibility", outfit.id)
    return
  end
  if command == "rule" then
    local priorityText, tail = EM.Util.SplitFirst(rest)
    local fact, valueText = EM.Util.SplitFirst(tail)
    local priority = tonumber(priorityText)
    local outfit = self:SelectedOrNamed("")
    local factMap = {targetclassification="targetClassification", targetcreaturetype="targetCreatureType",
      targetlevelmin="targetLevelMin", targetlevelmax="targetLevelMax", combat="combat",
      zone="zone", subzone="subzone", instance="instance", instancetype="instanceType",
      mounted="mounted", swimming="swimming", form="form", formname="formName",
      auratexture="auraTexture"}
    fact = factMap[fact]
    if not outfit then EM.Print("Select an outfit first."); return end
    if not priority or not fact or valueText == "" then
      EM.Print("Usage: /equipmate rule <priority> <fact> <value>"); return
    end
    local value = valueText
    if fact == "targetLevelMin" or fact == "targetLevelMax" or fact == "form" then
      value = tonumber(valueText)
      if not value then EM.Print(fact .. " requires a number."); return end
    elseif fact == "targetCreatureType" and tonumber(valueText) then value = tonumber(valueText)
    elseif string.lower(valueText) == "true" or string.lower(valueText) == "on" then value = true
    elseif string.lower(valueText) == "false" or string.lower(valueText) == "off" then value = false end
    local conditions = {}; conditions[fact] = value
    EM.Rules:AddRule(outfit.id, fact .. " = " .. valueText, priority, conditions)
    EM.Print("added automatic rule to " .. outfit.name)
    return
  end
  if command == "rules" or command == "clearrules" then
    local outfit = self:SelectedOrNamed("")
    if not outfit then EM.Print("Select an outfit first."); return end
    if command == "clearrules" then
      outfit.rules = {}; EM.Emit("OUTFITS_CHANGED", "rules-cleared", outfit.id)
      EM.Print("cleared custom rules for " .. outfit.name)
    else
      local i
      EM.Print(outfit.name .. " preset: " .. (outfit.autoPreset or "off"))
      for i = 1, table.getn(outfit.rules) do
        EM.Print(i .. ". [" .. (outfit.rules[i].priority or 0) .. "] " .. outfit.rules[i].name)
      end
    end
    return
  end
  if command == "why" then
    EM.Print(EM.Rules.lastReason or "No automatic change has been evaluated yet.")
    return
  end
  if command == "status" then
    local outfit = self:SelectedOrNamed(rest)
    if not outfit then EM.Print("Select or name an outfit."); return end
    local status = EM.Outfits:Status(outfit.id)
    EM.Print(outfit.name .. ": " .. status.state .. " (" .. status.matched .. "/" .. status.required .. ")")
    local i
    for i = 1, table.getn(status.missing) do
      EM.Print("missing " .. EM.SlotLabels[status.missing[i].slot] .. ": " ..
        (status.missing[i].item.name or ("item " .. status.missing[i].item.id)))
    end
    for i = 1, table.getn(status.banked) do
      EM.Print("banked " .. EM.SlotLabels[status.banked[i].slot] .. ": " ..
        (status.banked[i].item.name or ("item " .. status.banked[i].item.id)))
    end
    return
  end
  if command == "debug" then
    local setting=string.lower(EM.Util.Trim(rest))
    if setting=="on" then
      EquipMateDB.options.debug=true
      local tracked=EM.Inventory and EM.Inventory.items and table.getn(EM.Inventory.items) or 0
      local bank=EM.Inventory and EM.Inventory.bankOpen and "open" or "closed"
      EM.Print("debug logging enabled ("..EM.Capabilities:Summary()..", "..tracked..
        " items tracked, bank "..bank..")")
      EM.Print("Reproduce the problem, then use /equipmate debug off and share the EquipMate messages.")
      if EM.Rules then
        EM.Rules.debugLastEvaluation=nil
        EM.Rules:ScheduleEvaluation()
      end
      return
    elseif setting=="off" then EquipMateDB.options.debug=false
    else
      EM.Print("debug logging is " .. (EquipMateDB.options.debug and "enabled" or "disabled") ..
        " (usage: /equipmate debug on|off)")
      return
    end
    EM.Print("debug logging disabled")
    return
  end
  self:Help()
end

function EM.WearBoundOutfit(index)
  local id = EquipMateDB and EquipMateDB.bindings and EquipMateDB.bindings[index]
  if not id then EM.Print("No outfit is assigned to binding " .. index); return end
  local ok, err = EM.Engine:Toggle(id, "manual")
  if not ok and err then EM.Print(err) end
end
