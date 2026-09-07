local EM = EquipMate

local Integration = {name="UIIntegration", provider=nil, providerName="default"}
EM.UIIntegration = Integration
EM.modules.UIIntegration = Integration

local Default = {name="default"}
local PFUI = {name="pfUI"}

local function safeCall(func, a, b, c, d, e)
  if type(func) ~= "function" then return false end
  return pcall(func, a, b, c, d, e)
end

local function resolveGlobal(name)
  if type(getglobal) == "function" then return getglobal(name) end
  return _G and _G[name] or nil
end

function Integration:HookScript(frame, scriptName, handler)
  if not frame or type(handler) ~= "function" then return false end
  if type(frame.HookScript) == "function" then
    local ok = pcall(frame.HookScript, frame, scriptName, function() handler(frame) end)
    if ok then return true end
  end
  if type(frame.GetScript) ~= "function" or type(frame.SetScript) ~= "function" then return false end
  local old = frame:GetScript(scriptName)
  frame:SetScript(scriptName, function()
    if old then old() end
    handler(frame)
  end)
  return true
end

function Default:GetCharacterFrame() return CharacterFrame end
function Default:GetPaperDollFrame() return PaperDollFrame end

function Default:AttachPanel(panel)
  panel:ClearAllPoints()
  -- The stock CharacterFrame artwork ends inside its logical right edge.
  -- Overlap that transparent margin so the visible borders meet cleanly.
  panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -34, -12)
end

function Default:PositionCharacterButton(button)
  button:ClearAllPoints()
  if CharacterHandsSlot then
    button:SetPoint("BOTTOM", CharacterHandsSlot, "TOP", 0, 4)
  else
    button:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -38, -32)
  end
end

function Default:StylePanel(frame)
  frame:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",
    edgeFile="Interface/DialogFrame/UI-DialogBox-Border", tile=true, tileSize=16,
    edgeSize=24, insets={left=5,right=5,top=5,bottom=5}})
  frame:SetBackdropColor(0.04,0.06,0.09,0.97)
end

function Default:StyleButton() end
function Default:StyleCharacterButton() end
function Default:StyleCloseButton() end
function Default:StylePopup() end

function Default:StyleListRow(row)
  row:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")
end

function Default:GetToggleTextures()
  return "Interface/Icons/INV_Misc_Gear_01", nil,
    "Interface/Buttons/ButtonHilight-Square"
end

function Default:SuppressRedundantManager() return false end
function PFUI:IsAvailable()
  if type(pfUI) ~= "table" or pfUI.disabled then return false end
  if type(pfUI.api) ~= "table" or type(pfUI.path) ~= "string" then return false end
  if not CharacterFrame or not PaperDollFrame then return false end
  if type(IsAddOnLoaded) == "function" and pfUI.name and not IsAddOnLoaded(pfUI.name) then return false end
  return true
end

function PFUI:GetCharacterFrame() return CharacterFrame end
function PFUI:GetPaperDollFrame() return PaperDollFrame end

function PFUI:GetBorderSize()
  local ok, raw, border = safeCall(pfUI.api.GetBorderSize)
  if ok then return raw, border end
  return 1, 1
end

function PFUI:AttachPanel(panel)
  local _, border = self:GetBorderSize()
  panel:ClearAllPoints()
  if CharacterFrame.backdrop then
    panel:SetPoint("TOPLEFT", CharacterFrame.backdrop, "TOPRIGHT", 2*border, -2)
  else
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 0, 0)
  end
end

function PFUI:PositionCharacterButton(button)
  button:ClearAllPoints()
  if CharacterHandsSlot then
    button:SetPoint("BOTTOM", CharacterHandsSlot, "TOP", 0, 4)
  elseif CharacterFrame.backdrop then
    button:SetPoint("TOPRIGHT", CharacterFrame.backdrop, "TOPRIGHT", -32, -32)
  else
    button:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -42, -42)
  end
end

function PFUI:StylePanel(frame)
  local styled = false
  if type(pfUI.api.CreateBackdrop) == "function" then
    styled = safeCall(pfUI.api.CreateBackdrop, frame, nil, nil, .9)
  end
  if styled and type(pfUI.api.CreateBackdropShadow) == "function" then
    safeCall(pfUI.api.CreateBackdropShadow, frame)
  end
  if not styled then Default:StylePanel(frame) end
end

function PFUI:StylePopup(frame)
  self:StylePanel(frame)
end

function PFUI:StyleButton(button)
  if not safeCall(pfUI.api.SkinButton, button) then Default:StyleButton(button) end
end

-- pfUI's own equipment toggle is a texture-only button, not a SkinButton.
function PFUI:StyleCharacterButton() end

function PFUI:StyleCloseButton(button, parent)
  if not safeCall(pfUI.api.SkinCloseButton, button, parent.backdrop or parent, -6, -6) then
    Default:StyleCloseButton(button, parent)
  end
end

function PFUI:StyleListRow(row)
  Default:StyleListRow(row)
end

function PFUI:GetToggleTextures()
  return pfUI.path .. "\\img\\UI-GearManager-Button",
    pfUI.path .. "\\img\\UI-GearManager-Button-Pushed",
    "Interface\\Buttons\\ButtonHilight-Square"
end

function PFUI:ForceHidden(frame)
  if not frame or frame._equipMateSuppressed then return end
  frame._equipMateSuppressed = true
  frame:Hide()
  Integration:HookScript(frame, "OnShow", function(target)
    if target:IsShown() then target:Hide() end
  end)
end

function PFUI:SuppressRedundantManager()
  local suppressed = false
  local toggle = resolveGlobal("pfEqMgrToggleButton")
  local panel = resolveGlobal("pfEquipmentManagerFrame")
  if toggle then self:ForceHidden(toggle); suppressed = true end
  if panel then self:ForceHidden(panel); suppressed = true end
  if type(pfUI.equipmentmanager) == "table" then
    pfUI.equipmentmanager.EquipMateReplacement = true
    pfUI.equipmentmanager.EquipMatePanel = EM.UI and EM.UI.frame or nil
  end
  return suppressed
end

function Integration:Initialize()
  local available=PFUI:IsAvailable()
  if available then
    self.provider = PFUI
    self.providerName = "pfUI"
  else
    self.provider = Default
    self.providerName = "default"
  end
end

function Integration:GetProvider()
  return self.provider or Default
end

function Integration:SuppressRedundantManager()
  local provider = self:GetProvider()
  local ok, result = pcall(provider.SuppressRedundantManager, provider)
  self.redundantSuppressed = ok and result and true or false
  return self.redundantSuppressed
end
