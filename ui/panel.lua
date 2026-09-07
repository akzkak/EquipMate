local EM = EquipMate
local L = EM.L
local LF = EM.LF
local UI = {name = "UI", outfitOffset = 0}
EM.UI = UI
EM.modules.UI = UI

local MAIN_PANEL_WIDTH = 206
local MAIN_ROW_WIDTH = MAIN_PANEL_WIDTH - 28
local TOOLTIP_SLOT_ORDER = {
  "HeadSlot","NeckSlot","ShoulderSlot","BackSlot","ChestSlot","ShirtSlot",
  "TabardSlot","WristSlot","HandsSlot","WaistSlot","LegsSlot","FeetSlot",
  "Finger0Slot","Finger1Slot","Trinket0Slot","Trinket1Slot",
  "MainHandSlot","SecondaryHandSlot","RangedSlot","AmmoSlot"
}
local RULE_CATEGORIES = {
  {key="general",label="RULE_CATEGORY_GENERAL",presets={false,"Riding","Dining","Evocate"}},
  {key="targets",label="RULE_CATEGORY_TARGETS",
    presets={"Boss","Lvl63","Trash","BeastTrash","UndeadTrash","DemonTrash","Critter"}},
  {key="places",label="RULE_CATEGORY_PLACES",
    presets={"City","Instance","Battleground","AV","AB","WSG","ArgentDawn"}},
  {key="forms",label="RULE_CATEGORY_FORMS",
    presets={"Battle","Defensive","Berserker","Bear","Cat","Aquatic","Travel","Moonkin",
      "Shadowform","Stealth","GhostWolf"}},
  {key="aspects",label="RULE_CATEGORY_ASPECTS",
    presets={"Monkey","Hawk","Cheetah","Pack","Beast","Wild"}}
}

local function presetText(name)
  return name and L.PRESET_LABELS and L.PRESET_LABELS[name] or name
end

function UI:GetStatusColor(status)
  if status and status.state=="equipped" then return .35,1,.45 end
  if status and (table.getn(status.missing or {})>0 or
      (not EM.Inventory.bankOpen and table.getn(status.banked or {})>0)) then
    return 1,.25,.25
  end
  if status and status.required and status.matched<status.required then return 1,.82,.25 end
  return .9,.9,.9
end

local function makeButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(height)
  button:SetText(text)
  local provider = EM.UIIntegration and EM.UIIntegration:GetProvider()
  if provider and provider.StyleButton then provider:StyleButton(button) end
  return button
end

local function addTooltipItem(item,defaultRed,defaultGreen,defaultBlue)
  if item and item.link then
    GameTooltip:AddLine(item.link)
    return
  end
  local cachedName,cachedLink,quality
  if item and item.id and type(GetItemInfo)=="function" then
    cachedName,cachedLink,quality=GetItemInfo("item:"..tostring(item.id))
    if cachedLink and string.find(cachedLink,"|Hitem:",1,true) then
      GameTooltip:AddLine(cachedLink)
      return
    end
  end
  local red,green,blue=defaultRed or 1,defaultGreen or 1,defaultBlue or 1
  if quality and type(GetItemQualityColor)=="function" then
    red,green,blue=GetItemQualityColor(quality)
  end
  GameTooltip:AddLine(item and (item.name or cachedName or LF("ITEM_FMT",item.id)) or L.EMPTY,
    red,green,blue)
end

local function showTooltipAbove(owner)
  if type(GameTooltip.SetFrameStrata)=="function" then
    GameTooltip:SetFrameStrata("TOOLTIP")
  end
  if type(GameTooltip.SetFrameLevel)=="function" and owner and
      type(owner.GetFrameLevel)=="function" then
    GameTooltip:SetFrameLevel((owner:GetFrameLevel() or 0)+20)
  end
  GameTooltip:Show()
end

function UI:Initialize()
  self.provider = EM.UIIntegration:GetProvider()
  self:CreatePopups()
  self:CreateWindow()
  self:CreateSlotEditor()
  self:CreateContextMenu()
  self:CreateBindingMenu()
  self:CreateRuleMenu()
  self:CreateCharacterButton()
  self:InstallCharacterLifecycle()
  EM.UIIntegration:SuppressRedundantManager()
  EM.After(0.25, self, self.SuppressRedundantManager, "ui-integration-late")
  EM.On("OUTFITS_CHANGED", self, self.Refresh)
  EM.On("OUTFIT_STATUS_CHANGED", self, self.Refresh)
  EM.On("EQUIP_STARTED", self, self.Refresh)
  EM.On("EQUIP_FINISHED", self, self.Refresh)
  EM.On("RULES_CHANGED", self, self.Refresh)
end

function UI:SuppressRedundantManager()
  EM.UIIntegration:SuppressRedundantManager()
end

function UI:CreatePopups()
  StaticPopupDialogs["EQUIPMATE_NAME"] = {
    text=L.POPUP_NAME, button1=ACCEPT, button2=CANCEL, hasEditBox=1,
    maxLetters=40, timeout=0, whileDead=1, hideOnEscape=1,
    OnAccept=function()
      UI:AcceptPopupName(this)
    end,
    EditBoxOnEnterPressed=function()
      local parent = this:GetParent()
      UI:AcceptName(this:GetText())
      parent:Hide()
    end
  }
  StaticPopupDialogs["EQUIPMATE_DELETE"] = {
    text=L.POPUP_DELETE, button1=DELETE, button2=CANCEL,
    timeout=0, whileDead=1, hideOnEscape=1,
    OnAccept=function()
      local id=UI.pendingDelete
      UI.pendingDelete=nil
      if id then EM.Outfits:Delete(id) end
    end,
    OnCancel=function() UI.pendingDelete=nil end
  }
  StaticPopupDialogs["EQUIPMATE_OVERWRITE"] = {
    text=L.POPUP_OVERWRITE, button1=L.OVERWRITE, button2=CANCEL,
    timeout=0, whileDead=1, hideOnEscape=1,
    OnAccept=function()
      local id=UI.pendingSave
      UI.pendingSave=nil
      if id and EM.Outfits:Get(id) then EM.Outfits:UpdateFromEquipped(id) end
    end,
    OnCancel=function() UI.pendingSave=nil end
  }
end

function UI:FindPopupEditBox(source)
  local candidate=source
  local depth=0
  while candidate and depth<3 do
    if candidate.editBox and type(candidate.editBox.GetText)=="function" then return candidate.editBox end
    if candidate.EditBox and type(candidate.EditBox.GetText)=="function" then return candidate.EditBox end
    if type(candidate.GetName)=="function" then
      local name=candidate:GetName()
      if name then
        local named=getglobal(name.."EditBox")
        if named and type(named.GetText)=="function" then return named end
      end
    end
    candidate=type(candidate.GetParent)=="function" and candidate:GetParent() or nil
    depth=depth+1
  end
  local i
  for i=1,4 do
    local named=getglobal("StaticPopup"..i.."EditBox")
    if named and type(named.GetText)=="function" and
      (type(named.IsShown)~="function" or named:IsShown()) then return named end
  end
  return nil
end

function UI:AcceptPopupName(source)
  local edit=self:FindPopupEditBox(source)
  if not edit then EM.Print(L.POPUP_READ_ERROR); return end
  self:AcceptName(edit:GetText())
end

function UI:PromptName(action)
  self.nameAction = action
  StaticPopup_Show("EQUIPMATE_NAME")
end

function UI:AcceptName(name)
  local result, err
  local action=self.nameAction
  self.nameAction=nil
  if action == "create" then result, err = EM.Outfits:Create(name, true)
  elseif action == "empty" then result, err = EM.Outfits:Create(name, false)
  elseif action == "duplicate" and EM.Outfits.selectedID then
    result, err = EM.Outfits:Duplicate(EM.Outfits.selectedID, name)
  elseif action == "rename" and EM.Outfits.selectedID then
    result, err = EM.Outfits:Rename(EM.Outfits.selectedID, name)
  end
  if not result and err then EM.Print(err) end
  self:Refresh()
end

function UI:CreateWindow()
  local characterFrame = self.provider:GetCharacterFrame()
  local frame = CreateFrame("Frame", "EquipMateFrame", characterFrame)
  self.frame = frame
  frame:SetWidth(MAIN_PANEL_WIDTH); frame:SetHeight(238)
  self.provider:AttachPanel(frame)
  self.provider:StylePanel(frame)
  frame:EnableMouse(true)
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseDown",function()
    UI:HidePopupMenus()
    if arg1=="LeftButton" then UI:SelectOutfit(nil) end
  end)
  frame:SetScript("OnMouseWheel", function()
    local maximum=math.max(0,table.getn(EquipMateDB.order)-table.getn(UI.outfitRows or {}))
    UI.outfitOffset=math.max(0,math.min(maximum,(UI.outfitOffset or 0)-arg1))
    UI:Refresh()
  end)
  frame:SetScript("OnShow", function()
    UI.provider:AttachPanel(this)
    UI:Refresh()
  end)
  frame:SetScript("OnHide", function()
    if UI.ruleMenu then UI.ruleMenu:Hide() end
    if UI.contextMenu then UI.contextMenu:Hide() end
    if UI.bindingMenu then UI.bindingMenu:Hide() end
    UI:RefreshSlotEditor()
  end)
  frame:SetFrameStrata("HIGH"); frame:Hide()

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.title=title
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -13); title:SetText(L.TITLE)
  self.rangeText=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  self.rangeText:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-38,-17)
  self.rangeText:SetWidth(52); self.rangeText:SetJustifyH("RIGHT")
  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
  close:SetScript("OnClick", function() UI:ClosePanel() end)
  self.provider:StyleCloseButton(close, frame)

  self.equipButton=makeButton(frame,L.EQUIP,86,24)
  self.equipButton:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-40)
  self.equipButton:SetScript("OnClick",function()
    UI:HidePopupMenus()
    if EM.Outfits.selectedID then EM.Engine:Wear(EM.Outfits.selectedID) end
  end)
  self.saveButton=makeButton(frame,L.SAVE,86,24)
  self.saveButton:SetPoint("LEFT",self.equipButton,"RIGHT",6,0)
  self.saveButton:SetScript("OnClick",function()
    UI:HidePopupMenus()
    if EM.Outfits.selectedID then
      local outfit=EM.Outfits:Get(EM.Outfits.selectedID)
      if outfit then
        UI.pendingSave=outfit.id
        StaticPopup_Show("EQUIPMATE_OVERWRITE",outfit.name)
      end
    else UI:PromptName("create") end
  end)

  self.outfitRows = {}
  local i
  for i = 1, 7 do
    local row = CreateFrame("Button", nil, frame)
    row.outfitRowIndex=i
    row:SetWidth(MAIN_ROW_WIDTH); row:SetHeight(22)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -70 - (i-1)*23)
    self.provider:StyleListRow(row)
    row.selection=row:CreateTexture(nil,"BACKGROUND")
    row.selection:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
    row.selection:SetAllPoints(row); row.selection:SetBlendMode("ADD"); row.selection:Hide()
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row, "LEFT", 4, 0); row.text:SetWidth(MAIN_ROW_WIDTH-36); row.text:SetJustifyH("LEFT")
    row.menu = makeButton(row, "...", 19, 17)
    row.menu:SetPoint("RIGHT", row, "RIGHT", -3, 0)
    row.menu:SetScript("OnClick", function()
      local owner=this:GetParent()
      if owner.outfitID then UI:ToggleContextMenu(owner.outfitID, owner) end
    end)
    row:SetScript("OnClick", function()
      if arg1 == "RightButton" then UI:ToggleContextMenu(this.outfitID, this)
      else
        UI:HidePopupMenus()
        if EM.Outfits.selectedID==this.outfitID then UI:SelectOutfit(nil)
        else UI:SelectOutfit(this.outfitID) end
      end
    end)
    row:SetScript("OnDoubleClick", function() if this.outfitID then EM.Engine:Wear(this.outfitID) end end)
    row:SetScript("OnEnter", function()
      UI.tooltipRow=this
      UI:ShowOutfitTooltip(this)
    end)
    row:SetScript("OnLeave", function()
      if UI.tooltipRow==this then UI.tooltipRow=nil end
      GameTooltip:Hide()
    end)
    self.outfitRows[i] = row
  end

  self:Refresh()
end

function UI:CreateSlotEditor()
  local paperDoll=self.provider:GetPaperDollFrame()
  self.slotControls={}

  local header=CreateFrame("Frame","EquipMateSlotEditorHeader",paperDoll)
  self.slotEditorHeader=header
  header:SetWidth(176); header:SetHeight(52)
  header:SetPoint("TOP",paperDoll,"TOP",0,-35)

  header.all=makeButton(header,L.ALL_SLOTS,76,19)
  header.all:SetPoint("TOPLEFT",header,"TOPLEFT",9,-26)
  header.all:SetScript("OnClick",function() UI:SetAllOutfitSlots(true) end)

  header.none=makeButton(header,L.NO_SLOTS,76,19)
  header.none:SetPoint("TOPRIGHT",header,"TOPRIGHT",-9,-26)
  header.none:SetScript("OnClick",function() UI:SetAllOutfitSlots(false) end)
  header:Hide()

  self:EnsureSlotControls()
end

function UI:EnsureSlotControls()
  if not self.slotControls then return end
  local i
  for i=1,table.getn(EM.Slots) do
    local slotInfo=EM.Slots[i]
    if not self.slotControls[slotInfo.key] then
      local slotFrame=getglobal("Character"..slotInfo.key)
      if slotFrame then
        local control=CreateFrame("Button",nil,slotFrame)
        control.slotKey=slotInfo.key
        control:SetWidth(22); control:SetHeight(22)
        control:SetPoint("TOPLEFT",slotFrame,"TOPLEFT",-2,3)
        if type(control.SetFrameLevel)=="function" and type(slotFrame.GetFrameLevel)=="function" then
          control:SetFrameLevel((slotFrame:GetFrameLevel() or 0)+20)
        end
        control:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        control:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        control:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight","ADD")
        control.check=control:CreateTexture(nil,"OVERLAY")
        control.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        control.check:SetAllPoints(control)
        control:RegisterForClicks("LeftButtonUp")
        control:SetScript("OnClick",function() UI:ToggleOutfitSlot(this.slotKey) end)
        control:SetScript("OnEnter",function() UI:ShowSlotControlTooltip(this) end)
        control:SetScript("OnLeave",function() GameTooltip:Hide() end)
        control:Hide()
        self.slotControls[slotInfo.key]=control
      end
    end
  end
end

function UI:SetAllOutfitSlots(included)
  local id=EM.Outfits.selectedID
  if not id then return end
  EM.Outfits:SetAllSlotsIncluded(id,included)
  self:Refresh()
end

function UI:ToggleOutfitSlot(slotKey)
  local outfit=EM.Outfits:Get(EM.Outfits.selectedID)
  if not outfit or not slotKey then return end
  EM.Outfits:SetSlot(outfit.id,slotKey,outfit.slots[slotKey] and "ignore" or "current")
  self:Refresh()
end

function UI:ShowSlotControlTooltip(control)
  local outfit=EM.Outfits:Get(EM.Outfits.selectedID)
  if not outfit or not control or not control.slotKey then return end
  local key=control.slotKey
  local desired=outfit.slots[key]
  GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
  GameTooltip:SetText(EM.SlotLabels[key] or key,1,1,1)
  if desired then
    GameTooltip:AddLine(LF("SLOT_INCLUDED_FMT",outfit.name),.35,1,.45)
    if desired.empty then GameTooltip:AddLine(L.SLOT_EMPTY_HELP,1,.82,.25,true)
    else addTooltipItem(desired,.9,.9,.9) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.SLOT_INCLUDED_HELP,.8,.8,.8,true)
  else
    GameTooltip:AddLine(LF("SLOT_IGNORED_FMT",outfit.name),.7,.7,.7)
    GameTooltip:AddLine(L.SLOT_IGNORED_HELP,.8,.8,.8,true)
  end
  showTooltipAbove(control)
end

function UI:RefreshSlotEditor()
  if not self.slotEditorHeader then return end
  self:EnsureSlotControls()
  local outfit=EM.Outfits:Get(EM.Outfits.selectedID)
  local visible=outfit and self.frame and self.frame:IsShown()
  if visible then
    self.slotEditorHeader:Show()
  else
    self.slotEditorHeader:Hide()
  end
  local key,control
  for key,control in pairs(self.slotControls or {}) do
    if visible then
      if type(control.SetFrameLevel)=="function" and control:GetParent() and
          type(control:GetParent().GetFrameLevel)=="function" then
        control:SetFrameLevel((control:GetParent():GetFrameLevel() or 0)+20)
      end
      if outfit.slots[key] then control.check:Show() else control.check:Hide() end
      control:Show()
    else
      control:Hide()
    end
  end
end

function UI:CreateContextMenu()
  local dismiss=CreateFrame("Button","EquipMateContextDismiss",UIParent)
  self.contextDismiss=dismiss
  dismiss:SetPoint("TOPLEFT",UIParent,"TOPLEFT",0,0)
  dismiss:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",0,0)
  dismiss:SetFrameStrata("MEDIUM")
  dismiss:EnableMouse(true)
  dismiss:RegisterForClicks("LeftButtonUp","RightButtonUp")
  dismiss:SetScript("OnClick",function() UI:HidePopupMenus() end)
  dismiss:Hide()

  local menu=CreateFrame("Frame","EquipMateContextMenu",UIParent)
  self.contextMenu=menu
  menu:SetWidth(128); menu:SetHeight(148)
  menu:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",
    edgeFile="Interface/Tooltips/UI-Tooltip-Border",tile=true,tileSize=16,
    edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
  menu:SetBackdropColor(.03,.04,.07,.98); menu:SetFrameStrata("TOOLTIP")
  menu:SetScript("OnHide",function() if UI.contextDismiss then UI.contextDismiss:Hide() end end)
  menu:Hide()
  self.provider:StylePopup(menu)
  self.contextRows={}
  local i
  for i=1,5 do
    local row=CreateFrame("Button",nil,menu)
    row:SetWidth(112); row:SetHeight(22)
    row:SetPoint("TOPLEFT",menu,"TOPLEFT",12,-12-(i-1)*24)
    self.provider:StyleListRow(row)
    row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.text:SetPoint("LEFT",row,"LEFT",5,0); row.text:SetWidth(102); row.text:SetJustifyH("LEFT")
    row:SetScript("OnClick",function() UI:RunContextAction(this.action,this) end)
    self.contextRows[i]=row
  end
end

function UI:HideContextMenu()
  if self.contextMenu then self.contextMenu:Hide() end
  if self.contextDismiss then self.contextDismiss:Hide() end
end

function UI:HidePopupMenus()
  if self.contextMenu then self.contextMenu:Hide() end
  if self.ruleMenu then self.ruleMenu:Hide() end
  if self.bindingMenu then self.bindingMenu:Hide() end
  if self.contextDismiss then self.contextDismiss:Hide() end
end

function UI:ToggleContextMenu(id,anchor)
  if self.contextMenu and self.contextMenu:IsShown() and self.contextOutfitID==id then
    self:HideContextMenu()
  else
    self:ShowContextMenu(id,anchor)
  end
end

function UI:PositionPopup(menu,anchor)
  menu:ClearAllPoints()
  if anchor and anchor.outfitRowIndex and anchor.outfitRowIndex>5 then
    menu:SetPoint("BOTTOMLEFT",anchor,"BOTTOMRIGHT",4,0)
  else
    menu:SetPoint("TOPLEFT",anchor or self.frame,"TOPRIGHT",4,0)
  end
end

function UI:ShowContextMenu(id,anchor)
  local outfit=EM.Outfits:Get(id)
  if not outfit then return end
  self:HidePopupMenus()
  EM.Outfits.selectedID=id
  self.contextOutfitID=id
  self.contextAnchor=anchor
  local binding=self:GetBindingForOutfit(id)
  local choices={
    {label=LF("CONTEXT_PRESET_FMT",presetText(outfit.autoPreset) or L.OFF),action="preset"},
    {label=LF("KEYBINDING_FMT",binding and tostring(binding) or L.NONE),action="bind"},
    {label=L.RENAME,action="rename"},
    {label=L.DUPLICATE,action="duplicate"},
    {label=L.DELETE,action="delete"},
  }
  local i
  local widest=0
  for i=1,table.getn(self.contextRows) do
    local row=self.contextRows[i]
    local choice=choices[i]
    row.action=choice and choice.action
    if choice then
      row.text:SetText(choice.label)
      if type(row.text.GetStringWidth)=="function" then
        widest=math.max(widest,row.text:GetStringWidth() or 0)
      end
      row:Show()
    else row:Hide() end
  end
  local menuWidth=math.max(128,math.min(240,math.ceil(widest)+28))
  self.contextMenu:SetWidth(menuWidth)
  for i=1,table.getn(self.contextRows) do
    self.contextRows[i]:SetWidth(menuWidth-24)
    self.contextRows[i].text:SetWidth(menuWidth-34)
  end
  self:PositionPopup(self.contextMenu,anchor)
  self.contextDismiss:Show()
  self.contextMenu:Show()
  self:Refresh()
end

function UI:RunContextAction(action)
  local id=self.contextOutfitID
  local anchor=self.contextAnchor or self.frame
  if not id or not action then return end
  self.contextMenu:Hide()
  if action=="preset" then self:ShowRuleMenu(anchor)
  elseif action=="rename" then self:PromptName("rename")
  elseif action=="duplicate" then self:PromptName("duplicate")
  elseif action=="bind" then self:ShowBindingMenu(id,anchor)
  elseif action=="delete" then
    self.pendingDelete=id; StaticPopup_Show("EQUIPMATE_DELETE")
  end
  self:Refresh()
end

function UI:GetBindingForOutfit(id)
  local i
  for i=1,10 do if EquipMateDB.bindings[i]==id then return i end end
  return nil
end

function UI:GetOutfitBindingText(id)
  local index=self:GetBindingForOutfit(id)
  if not index then return nil end
  if type(GetBindingKey)=="function" then
    local first,second=GetBindingKey("EQUIPMATE_OUTFIT"..index)
    if first and second then return first..", "..second end
    if first then return first end
    if second then return second end
  end
  return LF("BINDING_FMT",index)
end

function UI:CreateBindingMenu()
  local menu=CreateFrame("Frame","EquipMateBindingMenu",UIParent)
  self.bindingMenu=menu
  menu:SetWidth(220); menu:SetHeight(286)
  menu:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",
    edgeFile="Interface/Tooltips/UI-Tooltip-Border",tile=true,tileSize=16,
    edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
  menu:SetBackdropColor(.03,.04,.07,.98); menu:SetFrameStrata("TOOLTIP")
  menu:SetScript("OnHide",function() if UI.contextDismiss then UI.contextDismiss:Hide() end end)
  menu:Hide()
  self.provider:StylePopup(menu)
  self.bindingRows={}
  local i
  for i=0,10 do
    local row=CreateFrame("Button",nil,menu)
    row:SetWidth(196); row:SetHeight(22)
    row:SetPoint("TOPLEFT",menu,"TOPLEFT",12,-11-i*24)
    self.provider:StyleListRow(row)
    row.bindingIndex=i
    row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.text:SetPoint("LEFT",row,"LEFT",5,0); row.text:SetWidth(186); row.text:SetJustifyH("LEFT")
    row:SetScript("OnClick",function() UI:ChooseBinding(this.bindingIndex) end)
    self.bindingRows[i+1]=row
  end
end

function UI:ShowBindingMenu(id,anchor)
  self:HidePopupMenus()
  self.bindingOutfitID=id
  local current=self:GetBindingForOutfit(id)
  local i
  for i=0,10 do
    local label=i==0 and L.NO_BINDING or LF("BINDING_FMT",i)
    if (i==0 and not current) or i==current then label=LF("SELECTED_FMT",label) end
    self.bindingRows[i+1].text:SetText(label)
  end
  self:PositionPopup(self.bindingMenu,anchor)
  self.contextDismiss:Show()
  self.bindingMenu:Show()
end

function UI:ChooseBinding(index)
  local id=self.bindingOutfitID
  if not id then return end
  local i
  for i=1,10 do if EquipMateDB.bindings[i]==id then EquipMateDB.bindings[i]=nil end end
  if index and index>0 then EquipMateDB.bindings[index]=id end
  self.bindingMenu:Hide()
  EM.Print(LF("BINDING_CHAT_FMT",index and index>0 and index or L.CLEARED,EM.Outfits:Get(id).name))
end

function UI:CreateRuleMenu()
  local frame = CreateFrame("Frame", "EquipMateRuleMenu", UIParent)
  self.ruleMenu = frame
  frame:SetWidth(240); frame:SetHeight(335)
  frame:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",
    edgeFile="Interface/Tooltips/UI-Tooltip-Border", tile=true, tileSize=16,
    edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
  frame:SetBackdropColor(.03,.04,.07,.98); frame:SetFrameStrata("TOOLTIP"); frame:Hide()
  frame:SetScript("OnHide",function() if UI.contextDismiss then UI.contextDismiss:Hide() end end)
  self.provider:StylePopup(frame)
  local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
  title:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-12); title:SetText(L.RULE_TITLE)
  self.ruleCategoryRows={}
  local i
  for i=1,table.getn(RULE_CATEGORIES) do
    local row=CreateFrame("Button",nil,frame)
    row:SetWidth(88); row:SetHeight(26)
    row:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-39-(i-1)*30)
    self.provider:StyleListRow(row)
    row.category=RULE_CATEGORIES[i]
    row.selection=row:CreateTexture(nil,"BACKGROUND")
    row.selection:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
    row.selection:SetAllPoints(row); row.selection:SetBlendMode("ADD"); row.selection:Hide()
    row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.text:SetPoint("LEFT",row,"LEFT",5,0); row.text:SetWidth(78); row.text:SetJustifyH("LEFT")
    row.text:SetText(L[row.category.label])
    row:SetScript("OnClick",function()
      UI.ruleCategory=this.category.key
      UI:RefreshRuleMenu()
    end)
    self.ruleCategoryRows[i]=row
  end
  self.ruleRows={}
  for i=1,11 do
    local row=CreateFrame("Button",nil,frame)
    row:SetWidth(118); row:SetHeight(24)
    row:SetPoint("TOPLEFT",frame,"TOPLEFT",110,-39-(i-1)*26)
    self.provider:StyleListRow(row)
    row.selection=row:CreateTexture(nil,"BACKGROUND")
    row.selection:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
    row.selection:SetAllPoints(row); row.selection:SetBlendMode("ADD"); row.selection:Hide()
    row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.text:SetPoint("LEFT",row,"LEFT",5,0); row.text:SetWidth(108); row.text:SetJustifyH("LEFT")
    row:SetScript("OnClick",function() UI:ChooseRulePreset(this.choice) end)
    row:SetScript("OnEnter",function()
      if not this.choice then return end
      GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
      GameTooltip:SetText(this.choice.label)
      if this.choice.preset then
        GameTooltip:AddLine(LF("PRESET_HELP_FMT",this.choice.label),1,1,1,true)
      else
        GameTooltip:AddLine(L.PRESET_OFF_HELP,1,1,1,true)
      end
      showTooltipAbove(this)
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.ruleRows[i]=row
  end
end

function UI:GetRuleCategory(key)
  local i
  for i=1,table.getn(RULE_CATEGORIES) do
    local category=RULE_CATEGORIES[i]
    if category.key==key then return category end
    local j
    for j=1,table.getn(category.presets) do
      if category.presets[j]==key then return category end
    end
  end
  return RULE_CATEGORIES[1]
end

function UI:ShowRuleMenu(anchor)
  local selected=EM.Outfits:Get(EM.Outfits.selectedID)
  if not selected then EM.Print(L.SELECT_FIRST); return end
  self:HidePopupMenus()
  self.ruleCategory=self:GetRuleCategory(selected.autoPreset).key
  self:PositionPopup(self.ruleMenu,anchor)
  self:RefreshRuleMenu()
  self.contextDismiss:Show()
  self.ruleMenu:Show()
end

function UI:RefreshRuleMenu()
  local selected=EM.Outfits:Get(EM.Outfits.selectedID)
  local category=self:GetRuleCategory(self.ruleCategory)
  local i
  for i=1,table.getn(self.ruleCategoryRows) do
    local row=self.ruleCategoryRows[i]
    if row.category.key==category.key then row.selection:Show() else row.selection:Hide() end
  end
  for i=1,table.getn(self.ruleRows) do
    local row=self.ruleRows[i]
    local preset=category.presets[i]
    local choice
    if preset==false then choice={label=L.RULE_OFF,preset=false}
    elseif preset then choice={label=presetText(preset),preset=preset} end
    row.choice=choice
    if choice then
      local active=selected and ((choice.preset==false and not selected.autoPreset) or
        choice.preset==selected.autoPreset)
      row.text:SetText(choice.label)
      if active then row.selection:Show() else row.selection:Hide() end
      row:Show()
    else row.selection:Hide(); row:Hide() end
  end
end

function UI:ChooseRulePreset(choice)
  local selected=EM.Outfits:Get(EM.Outfits.selectedID)
  if not selected or not choice then return end
  selected.autoPreset=choice.preset or nil
  EM.Emit("OUTFITS_CHANGED","preset",selected.id)
  EM.Rules:ScheduleEvaluation()
  self.ruleMenu:Hide()
  self:Refresh()
end

function UI:CreateCharacterButton()
  local parent = self.provider:GetPaperDollFrame()
  local button = CreateFrame("Button", "EquipMateCharacterButton", parent)
  self.characterButton = button
  button:SetWidth(28); button:SetHeight(28)
  self.provider:PositionCharacterButton(button)
  button:SetFrameStrata("HIGH")
  local normal, pushed, highlight = self.provider:GetToggleTextures()
  if normal then button:SetNormalTexture(normal) end
  if pushed and type(button.SetPushedTexture) == "function" then button:SetPushedTexture(pushed) end
  if highlight then button:SetHighlightTexture(highlight, "ADD") end
  self.provider:StyleCharacterButton(button)
  button:RegisterForClicks("LeftButtonUp")
  button:SetScript("OnClick", function() UI:TogglePanel() end)
end

function UI:InstallCharacterLifecycle()
  local character = self.provider:GetCharacterFrame()
  local equipment = self.provider:GetPaperDollFrame()
  EM.UIIntegration:HookScript(character, "OnHide", function() UI:ClosePanel() end)
  if equipment and equipment~=character then
    EM.UIIntegration:HookScript(equipment, "OnHide", function() UI:ClosePanel() end)
  end
  EM.UIIntegration:HookScript(character, "OnShow", function()
    UI.provider:PositionCharacterButton(UI.characterButton)
    UI:Refresh()
  end)
end

function UI:ShowPanel()
  local character = self.provider:GetCharacterFrame()
  local equipment = self.provider:GetPaperDollFrame()
  if not character:IsShown() or equipment and not equipment:IsShown() then
    if type(ToggleCharacter) == "function" then
      ToggleCharacter("PaperDollFrame")
    elseif type(ShowUIPanel) == "function" then
      ShowUIPanel(character)
      if equipment then equipment:Show() end
    else
      character:Show()
      if equipment then equipment:Show() end
    end
  end
  -- Opening the manager is a fresh browsing action. Do not carry an outfit
  -- selection (and its Character-panel editing controls) over from the last time
  -- the panel was open.
  EM.Outfits.selectedID=nil
  self.provider:AttachPanel(self.frame)
  self:Refresh()
  self.frame:Show()
end

function UI:ClosePanel()
  if self.frame then self.frame:Hide() end
end

function UI:TogglePanel()
  if self.frame:IsShown() then self:ClosePanel() else self:ShowPanel() end
end

function UI:SelectOutfit(id)
  EM.Outfits.selectedID = id
  self:Refresh()
end

function UI:ShowOutfitTooltip(row)
  if not row.outfitID then return end
  local outfit = EM.Outfits:Get(row.outfitID)
  local status = EM.Outfits:Status(row.outfitID)
  local red,green,blue=self:GetStatusColor(status)
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(outfit.name,red,green,blue)
  GameTooltip:AddLine(LF("MATCHED_FMT",status.matched,status.required), 1, 1, 1)
  local i
  local missingSlots={}
  for i = 1, table.getn(TOOLTIP_SLOT_ORDER) do
    local slotKey=TOOLTIP_SLOT_ORDER[i]
    local resolved=status.slots[slotKey]
    if resolved then
      local desired=resolved.desired
      if not desired.empty and not resolved.found and
          not EM.Inventory:MatchesDesired(resolved.actual,desired) then
        table.insert(missingSlots,{key=slotKey,desired=desired})
      end
    end
  end
  if table.getn(missingSlots)>0 then GameTooltip:AddLine(L.MISSING,1,.3,.3) end
  for i = 1, table.getn(missingSlots) do
    local missing=missingSlots[i]
    addTooltipItem(missing.desired,1,.3,.3)
  end
  local bindingText=self:GetOutfitBindingText(row.outfitID)
  local customRuleCount=table.getn(outfit.rules or {})
  if outfit.autoPreset or bindingText or customRuleCount>0 then
    GameTooltip:AddLine(" ")
  end
  if outfit.autoPreset then GameTooltip:AddLine(LF("AUTOMATIC_FMT",presetText(outfit.autoPreset)), 0.4, 0.85, 1) end
  if bindingText then
    GameTooltip:AddLine(LF("TOOLTIP_KEYBINDING_FMT",bindingText),0.4,0.85,1)
  end
  if customRuleCount>0 then
    GameTooltip:AddLine(LF("CUSTOM_RULES_FMT",customRuleCount),.4,.85,1)
  end
  showTooltipAbove(row)
end

function UI:Refresh()
  if not self.frame then return end
  local count=table.getn(EquipMateDB.order)
  local visible=table.getn(self.outfitRows)
  self.outfitOffset=math.max(0,math.min(self.outfitOffset or 0,math.max(0,count-visible)))
  if self.rangeText then
    if count>visible then
      local first=(self.outfitOffset or 0)+1
      local last=math.min(count,(self.outfitOffset or 0)+visible)
      self.rangeText:SetText(first.."-"..last.." / "..count)
    else self.rangeText:SetText("") end
  end
  local selected=EM.Outfits:Get(EM.Outfits.selectedID)
  self:RefreshSlotEditor()
  if self.equipButton and type(self.equipButton.Enable)=="function" then
    if selected then self.equipButton:Enable() else self.equipButton:Disable() end
    self.saveButton:Enable()
  end
  local i
  for i = 1, table.getn(self.outfitRows) do
    local row = self.outfitRows[i]
    local id = EquipMateDB.order[i + self.outfitOffset]
    local outfit = id and EquipMateDB.outfits[id]
    row.outfitID = id
    if outfit then
      row:Show(); row.text:SetText(outfit.name)
      local status = EM.Outfits:Status(id)
      if id==EM.Outfits.selectedID then row.selection:Show() else row.selection:Hide() end
      row.text:SetTextColor(self:GetStatusColor(status))
    else row.selection:Hide(); row:Hide() end
  end
  local tooltipRow=self.tooltipRow
  if tooltipRow then
    if tooltipRow.outfitID and tooltipRow:IsShown() then
      self:ShowOutfitTooltip(tooltipRow)
    else
      self.tooltipRow=nil
    end
  end
end

function EM.ToggleUI()
  if not EM.UI or not EM.UI.frame then return end
  EM.UI:TogglePanel()
end
