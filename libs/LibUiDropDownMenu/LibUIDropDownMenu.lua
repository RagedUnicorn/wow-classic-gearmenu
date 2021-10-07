-- luacheck: globals GameTooltip GameTooltip_SetTitle GameTooltip_AddNormalLine CloseMenus SOUNDKIT ColorPickerFrame
-- luacheck: globals GameTooltip_AddInstructionLine GameTooltip_AddColoredLine RED_FONT_COLOR GameFontDisableSmallLeft
-- luacheck: globals GameFontHighlightSmallLeft GameFontNormalSmallLeft VIDEO_QUALITY_LABEL6 UIParent GRAY_FONT_COLOR
-- luacheck: globals NORMAL_FONT_COLOR HIGHLIGHT_FONT_COLOR TOOLTIP_DEFAULT_COLOR TOOLTIP_DEFAULT_BACKGROUND_COLOR
-- luacheck: globals PlaySound CreateFrame GetCVar GetScreenHeight GetScreenWidth GetCursorPosition ShowUIPanel
-- luacheck: globals securecall

local mod = rggm
local me = {}
mod.libUiDropDownMenu = me

me.tag = "LibUIDropDownMenu"

--[[
  Globals
]]--
local uiDropDownMenuMaxButtons = 1
local uiDropDownMenuMaxLevels = 2
local uiDropDownMenuButtonHeight = 16
local uiDropDownMenuBorderHeight = 15
-- The current open menu

local uiDropDownMenuOpenMenu = nil
-- The current menu being initialized
local uiDropDownMenuInitMenu = nil
-- Current level shown of the open menu
local uiDropDownMenuMenuLevel = 1
-- Current value of the open menu
-- luacheck: ignore 231
local uiDropDownMenuMenuValue = nil
-- Default dropdown text height
-- luacheck: ignore 231
local uiDropDownMenuDefaultTextHeight = nil
-- List of open menus
-- luacheck: ignore 241
local openDropDownMenus = {}

local uIDropDownMenuDelegate = CreateFrame("FRAME")

function me.UiDropDownMenuDelegate_OnAttributeChanged(self, attribute, value)
  if attribute == "createframes" and value == true then
    me.UiDropDownMenu_CreateFrames(self:GetAttribute("createframes-level"), self:GetAttribute("createframes-index"))
  elseif attribute == "initmenu" then
    uiDropDownMenuInitMenu = value
  elseif attribute == "openmenu" then
    uiDropDownMenuOpenMenu = value
  end
end

uIDropDownMenuDelegate:SetScript("OnAttributeChanged", me.UiDropDownMenuDelegate_OnAttributeChanged)

function me.UiDropDownMenu_InitializeHelper(frame)
  -- This deals with the potentially tainted stuff!
  if frame ~= uiDropDownMenuOpenMenu then
    uiDropDownMenuMenuLevel = 1
  end

  -- Set the frame that's being intialized
  uIDropDownMenuDelegate:SetAttribute("initmenu", frame)

  -- Hide all the buttons
  local button, dropDownList

  for i = 1, uiDropDownMenuMaxLevels, 1 do
    dropDownList = _G["RGGM_DropDownList" .. i]

    if i >= uiDropDownMenuMenuLevel or frame ~= uiDropDownMenuOpenMenu then
      dropDownList.numButtons = 0
      dropDownList.maxWidth = 0

      for j = 1 , uiDropDownMenuMaxButtons, 1 do
        button = _G["RGGM_DropDownList" .. i .. "Button" .. j]
        button:Hide()
      end

      dropDownList:Hide()
    end
  end

  frame:SetHeight(uiDropDownMenuButtonHeight * 2)
end

-- //////////////////////////////////////////////////////////////
-- L_UIDropDownMenuButtonTemplate
local function create_UIDropDownMenuButton(name, parent)
  local f = CreateFrame("Button", name, parent or nil)
  f:SetWidth(100)
  f:SetHeight(16)
  f:SetFrameLevel(f:GetParent():GetFrameLevel() + 2)

  f.Highlight = f:CreateTexture(name .. "Highlight", "BACKGROUND")
  f.Highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  f.Highlight:SetBlendMode("ADD")
  f.Highlight:SetAllPoints()
  f.Highlight:Hide()

  f.Check = f:CreateTexture(name .. "Check", "ARTWORK")
  f.Check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
  f.Check:SetSize(16, 16)
  f.Check:SetPoint("LEFT", f, 0, 0)
  f.Check:SetTexCoord(0, 0.5, 0.5, 1)

  f.UnCheck = f:CreateTexture(name .. "UnCheck", "ARTWORK")
  f.UnCheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
  f.UnCheck:SetSize(16, 16)
  f.UnCheck:SetPoint("LEFT", f, 0, 0)
  f.UnCheck:SetTexCoord(0.5, 1, 0.5, 1)

  f.Icon = f:CreateTexture(name .. "Icon", "ARTWORK")
  f.Icon:SetSize(16, 16)
  f.Icon:SetPoint("RIGHT", f, 0, 0)
  f.Icon:Hide()

  -- ColorSwatch
  local fcw = CreateFrame("Button", name .. "ColorSwatch", f, nil)
  fcw:SetPoint("RIGHT", f, -6, 0)
  fcw:Hide()
  fcw:SetSize(16, 16)
  fcw.SwatchBg = fcw:CreateTexture(name .. "ColorSwatchSwatchBg", "BACKGROUND")
  fcw.SwatchBg:SetVertexColor(1, 1, 1)
  fcw.SwatchBg:SetWidth(14)
  fcw.SwatchBg:SetHeight(14)
  fcw.SwatchBg:SetPoint("CENTER", fcw, 0, 0)

  local button1NormalTexture = fcw:CreateTexture(name .. "ColorSwatchNormalTexture")
  button1NormalTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
  button1NormalTexture:SetAllPoints()
  fcw:SetNormalTexture(button1NormalTexture)

  fcw:SetScript("OnClick", function(self)
    CloseMenus()
    me.CreateUiDropDownMenuButton_OpenColorPicker(self:GetParent())
  end)

  fcw:SetScript("OnEnter", function(self)
    me.CloseDropDownMenus(self:GetParent():GetParent():GetID() + 1)
    _G[self:GetName() .. "SwatchBg"]:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
  end)

  fcw:SetScript("OnLeave", function(self)
    _G[self:GetName() .. "SwatchBg"]
      :SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
  end)

  f.ColorSwatch = fcw

  -- ExpandArrow
  local fea = CreateFrame("Button", name .. "ExpandArrow", f)
  fea:SetSize(16, 16)
  fea:SetPoint("RIGHT", f, 0, 0)
  fea:Hide()

  local button2NormalTexture = fea:CreateTexture(name .. "ExpandArrowNormalTexture")
  button2NormalTexture:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
  button2NormalTexture:SetAllPoints()
  fea:SetNormalTexture(button2NormalTexture)

  fea:SetScript("OnMouseDown", function(self)
    if self:IsEnabled() then
      me.ToggleDropDownMenu(
        self:GetParent():GetParent():GetID() + 1,
        self:GetParent().value,
        nil,
        nil,
        nil,
        nil,
        self:GetParent().menuList,
        self
      )
    end
  end)

  fea:SetScript("OnEnter", function(self)
    local level =  self:GetParent():GetParent():GetID() + 1
    me.CloseDropDownMenus(level)
    if self:IsEnabled() then
      local listFrame = _G["RGGM_DropDownList" .. level]
      if ( not listFrame or not listFrame:IsShown() or select(2, listFrame:GetPoint()) ~= self ) then
        me.ToggleDropDownMenu(level, self:GetParent().value, nil, nil, nil, nil, self:GetParent().menuList, self)
      end
    end
  end)

  fea:SetScript("OnLeave", function() end)

  f.ExpandArrow = fea

  -- InvisibleButton
  local fib = CreateFrame("Button", name .. "InvisibleButton", f)
  fib:Hide()
  fib:SetPoint("TOPLEFT", f, 0, 0)
  fib:SetPoint("BOTTOMLEFT", f, 0, 0)
  fib:SetPoint("RIGHT", fcw, "LEFT", 0, 0)

  fib:SetScript("OnEnter", function(self)
    me.UiDropDownMenuButtonInvisibleButton_OnEnter(self)
  end)

  fib:SetScript("OnLeave", function(self)
    me.UiDropDownMenuButtonInvisibleButton_OnLeave(self)
  end)

  f.invisibleButton = fib

  -- UIDropDownMenuButton Scripts
  f:SetScript("OnClick", function(self, button, down)
    me.UiDropDownMenuButton_OnClick(self, button, down)
  end)

  f:SetScript("OnEnter", function(self)
    me.UiDropDownMenuButton_OnEnter(self)
  end)

  f:SetScript("OnLeave", function(self)
    me.UiDropDownMenuButton_OnLeave(self)
  end)

  f:SetScript("OnEnable", function(self)
    self.invisibleButton:Hide()
  end)

  f:SetScript("OnDisable", function(self)
    self.invisibleButton:Show()
  end)

  local text1 = f:CreateFontString(name .. "NormalText")
  f:SetFontString(text1)
  text1:SetPoint("LEFT", f, -5, 0)
  f:SetNormalFontObject("GameFontHighlightSmallLeft")
  f:SetHighlightFontObject("GameFontHighlightSmallLeft")
  f:SetDisabledFontObject("GameFontDisableSmallLeft")

  return f
end

-- //////////////////////////////////////////////////////////////
-- L_UIDropDownListTemplate
local function creatre_UIDropDownList(name, parent)
  local f = _G[name] or CreateFrame("Button", name)
  f:SetParent(parent or nil)
  f:Hide()
  f:SetFrameStrata("DIALOG")
  f:EnableMouse(true)

  f.Border = _G[name .. "Border"] or CreateFrame("Frame", name .. "Border", f, "BackdropTemplate")
  f.Border:SetAllPoints()
  f.Border:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 9, },
  })

  f.MenuBackdrop= _G[name .. "MenuBackdrop"] or CreateFrame("Frame", name .. "MenuBackdrop", f, "BackdropTemplate")
  f.MenuBackdrop:SetAllPoints()
  f.MenuBackdrop:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 5, right = 4, top = 4, bottom = 4, },
  })
  f.MenuBackdrop:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
  f.MenuBackdrop:SetBackdropColor(
    TOOLTIP_DEFAULT_BACKGROUND_COLOR.r,
    TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
    TOOLTIP_DEFAULT_BACKGROUND_COLOR.b
  )

  f.Button1 = _G[name .. "Button1"] or create_UIDropDownMenuButton(name .. "Button1", f)
  f.Button1:SetID(1)

  f:SetScript("OnClick", function(self)
    self:Hide()
  end)
  f:SetScript("OnUpdate", function(self, elapsed)
    me.UiDropDownMenu_OnUpdate(self, elapsed)
  end)
  f:SetScript("OnShow", function(self)
    me.UiDropDownMenu_OnShow(self)
  end)
  f:SetScript("OnHide", function(self)
    me.UiDropDownMenu_OnHide(self)
  end)

  return f
end

-- //////////////////////////////////////////////////////////////
-- L_UIDropDownMenuTemplate
local function create_UIDropDownMenu(name, parent)
  local f

  if type(name) == "table" then
    f = name
    name = f:GetName()
  else
    f = CreateFrame("Frame", name, parent or nil)
  end

  f:SetSize(40, 32)

  f.Left = f:CreateTexture(name .. "Left", "ARTWORK")
  f.Left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
  f.Left:SetSize(25, 64)
  f.Left:SetPoint("TOPLEFT", f, 0, 17)
  f.Left:SetTexCoord(0, 0.1953125, 0, 1)

  f.Middle = f:CreateTexture(name .. "Middle", "ARTWORK")
  f.Middle:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
  f.Middle:SetSize(115, 64)
  f.Middle:SetPoint("LEFT", f.Left, "RIGHT")
  f.Middle:SetTexCoord(0.1953125, 0.8046875, 0, 1)

  f.Right = f:CreateTexture(name .. "Right", "ARTWORK")
  f.Right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
  f.Right:SetSize(25, 64)
  f.Right:SetPoint("LEFT", f.Middle, "RIGHT")
  f.Right:SetTexCoord(0.8046875, 1, 0, 1)

  f.Text = f:CreateFontString(name .. "Text", "ARTWORK", "GameFontHighlightSmall")
  f.Text:SetWordWrap(false)
  f.Text:SetJustifyH("RIGHT")
  f.Text:SetSize(0, 10)
  f.Text:SetPoint("RIGHT", f.Right, -43, 2)

  f.Icon = f:CreateTexture(name .. "Icon", "OVERLAY")
  f.Icon:Hide()
  f.Icon:SetSize(16, 16)
  f.Icon:SetPoint("LEFT", 30, 2)

  f.Button = CreateFrame("Button", name .. "Button", f)
  f.Button:SetMotionScriptsWhileDisabled(true)
  f.Button:SetSize(24, 24)
  f.Button:SetPoint("TOPRIGHT", f.Right, -16, -18)

  f.Button.NormalTexture = f.Button:CreateTexture(name .. "NormalTexture")
  f.Button.NormalTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  f.Button.NormalTexture:SetSize(24, 24)
  f.Button.NormalTexture:SetPoint("RIGHT", f.Button, 0, 0)
  f.Button:SetNormalTexture(f.Button.NormalTexture)

  f.Button.PushedTexture = f.Button:CreateTexture(name .. "PushedTexture")
  f.Button.PushedTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
  f.Button.PushedTexture:SetSize(24, 24)
  f.Button.PushedTexture:SetPoint("RIGHT", f.Button, 0, 0)
  f.Button:SetPushedTexture(f.Button.PushedTexture)

  f.Button.DisabledTexture = f.Button:CreateTexture(name .. "DisabledTexture")
  f.Button.DisabledTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
  f.Button.DisabledTexture:SetSize(24, 24)
  f.Button.DisabledTexture:SetPoint("RIGHT", f.Button, 0, 0)
  f.Button:SetDisabledTexture(f.Button.DisabledTexture)

  f.Button.HighlightTexture = f.Button:CreateTexture(name .. "HighlightTexture")
  f.Button.HighlightTexture:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
  f.Button.HighlightTexture:SetSize(24, 24)
  f.Button.HighlightTexture:SetPoint("RIGHT", f.Button, 0, 0)
  f.Button.HighlightTexture:SetBlendMode("ADD")
  f.Button:SetHighlightTexture(f.Button.HighlightTexture)

  -- Button Script
  f.Button:SetScript("OnEnter", function(self)
    local myscript = self:GetParent():GetScript("OnEnter")

    if myscript ~= nil then
      myscript(self:GetParent())
    end
  end)

  f.Button:SetScript("OnLeave", function(self)
    local myscript = self:GetParent():GetScript("OnLeave")

    if myscript ~= nil then
      myscript(self:GetParent())
    end
  end)

  f.Button:SetScript("OnMouseDown", function(self)
    if self:IsEnabled() then
      me.ToggleDropDownMenu(nil, nil, self:GetParent())
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
  end)

  f:SetScript("OnHide", function()
    me.CloseDropDownMenus()
  end)

  return f
end
-- End of frame templates
-- //////////////////////////////////////////////////////////////

-- //////////////////////////////////////////////////////////////
-- Handling two frames from LibUIDropDownMenu.xml
local RGGM_DropDownList1, RGGM_DropDownList2
do
  RGGM_DropDownList1 = creatre_UIDropDownList("RGGM_DropDownList1")
  RGGM_DropDownList1:SetToplevel(true)
  RGGM_DropDownList1:SetFrameStrata("FULLSCREEN_DIALOG")
  RGGM_DropDownList1:Hide()
  RGGM_DropDownList1:SetID(1)
  RGGM_DropDownList1:SetSize(180, 10)

  local _, fontHeight = _G["RGGM_DropDownList1Button1NormalText"]:GetFont()
  uiDropDownMenuDefaultTextHeight = fontHeight

  RGGM_DropDownList2 = creatre_UIDropDownList("RGGM_DropDownList2")
  RGGM_DropDownList2:SetToplevel(true)
  RGGM_DropDownList2:SetFrameStrata("FULLSCREEN_DIALOG")
  RGGM_DropDownList2:Hide()
  RGGM_DropDownList2:SetID(2)
  RGGM_DropDownList2:SetSize(180, 10)
end

-- //////////////////////////////////////////////////////////////
-- Global function to replace L_UIDropDownMenuTemplate
function me.CreateUiDropDownMenu(name, parent)
    return create_UIDropDownMenu(name, parent)
end

local function GetChild(frame, name, key)
  if frame[key] then
    return frame[key]
  elseif name then
    return _G[name .. key]
  end

  return nil
end

function me.UiDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList)
  frame.menuList = menuList

  securecall(me.UiDropDownMenu_InitializeHelper, frame)

  -- Set the initialize function and call it.  The initFunction populates the dropdown list.
  if initFunction then
    me.UiDropDownMenu_SetInitializeFunction(frame, initFunction)
    initFunction(frame, level, frame.menuList)
  end

  --master frame
  if level == nil then
    level = 1
  end

  local dropDownList = _G["RGGM_DropDownList" .. level]
  dropDownList.dropdown = frame
  dropDownList.shouldRefresh = true

  me.UiDropDownMenu_SetDisplayMode(frame, displayMode)
end

function me.UiDropDownMenu_SetInitializeFunction(frame, initFunction)
  frame.initialize = initFunction
end

function me.UiDropDownMenu_SetDisplayMode(frame, displayMode)
  -- Change appearance based on the displayMode
  -- Note: this is a one time change based on previous behavior.
  if displayMode == "MENU" then
    local name = frame:GetName()
    GetChild(frame, name, "Left"):Hide()
    GetChild(frame, name, "Middle"):Hide()
    GetChild(frame, name, "Right"):Hide()

    local button = GetChild(frame, name, "Button")
    local buttonName = button:GetName()
    GetChild(button, buttonName, "NormalTexture"):SetTexture(nil)
    GetChild(button, buttonName, "DisabledTexture"):SetTexture(nil)
    GetChild(button, buttonName, "PushedTexture"):SetTexture(nil)
    GetChild(button, buttonName, "HighlightTexture"):SetTexture(nil)

    local text = GetChild(frame, name, "Text")

    button:ClearAllPoints()
    button:SetPoint("LEFT", text, "LEFT", -9, 0)
    button:SetPoint("RIGHT", text, "RIGHT", 6, 0)
    frame.displayMode = "MENU"
  end
end

function me.UiDropDownMenu_RefreshDropDownSize(self)
  self.maxWidth = me.UiDropDownMenu_GetMaxButtonWidth(self)
  self:SetWidth(self.maxWidth + 25)

  for i = 1, uiDropDownMenuMaxButtons, 1 do
    local icon = _G[self:GetName() .. "Button" .. i .. "Icon"]

    if icon.tFitDropDownSizeX then
      icon:SetWidth(self.maxWidth - 5)
    end
  end
end

-- If dropdown is visible then see if its timer has expired, if so hide the frame
function me.UiDropDownMenu_OnUpdate(self)
  if self.shouldRefresh then
    me.UiDropDownMenu_RefreshDropDownSize(self)
    self.shouldRefresh = false
  end
end

function me.UiDropDownMenuButtonInvisibleButton_OnEnter(self)
  me.CloseDropDownMenus(self:GetParent():GetParent():GetID() + 1)

  local parent = self:GetParent()

  if parent.tooltipTitle and parent.tooltipWhileDisabled then
    if parent.tooltipOnButton then
      local tooltip = GameTooltip

      tooltip:SetOwner(parent, "ANCHOR_RIGHT")
      GameTooltip_SetTitle(tooltip, parent.tooltipTitle)

      if parent.tooltipInstruction then
        GameTooltip_AddInstructionLine(tooltip, parent.tooltipInstruction)
      end

      if parent.tooltipText then
        GameTooltip_AddNormalLine(tooltip, parent.tooltipText, true)
      end

      if parent.tooltipWarning then
        GameTooltip_AddColoredLine(tooltip, parent.tooltipWarning, RED_FONT_COLOR, true)
      end

      tooltip:Show()
    end
  end
end

function me.UiDropDownMenuButtonInvisibleButton_OnLeave()
  GameTooltip:Hide()
end

function me.UiDropDownMenuButton_OnEnter(self)
  if self.hasArrow then
    local level =  self:GetParent():GetID() + 1
    local listFrame = _G["RGGM_DropDownList" .. level]

    if not listFrame or not listFrame:IsShown() or select(2, listFrame:GetPoint()) ~= self then
      me.ToggleDropDownMenu(self:GetParent():GetID() + 1, self.value, nil, nil, nil, nil, self.menuList, self)
    end
  else
    me.CloseDropDownMenus(self:GetParent():GetID() + 1)
  end

  self.Highlight:Show()

  if self.tooltipTitle and not self.noTooltipWhileEnabled then
    if self.tooltipOnButton then
      local tooltip = GameTooltip

      tooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip_SetTitle(tooltip, self.tooltipTitle)

      if self.tooltipText then
        GameTooltip_AddNormalLine(tooltip, self.tooltipText, true)
      end
      tooltip:Show()
    end
  end

  if self.mouseOverIcon ~= nil then
    self.Icon:SetTexture(self.mouseOverIcon)
    self.Icon:Show()
  end
end

function me.UiDropDownMenuButton_OnLeave(self)
  self.Highlight:Hide()
  GameTooltip:Hide()

  if self.mouseOverIcon ~= nil then
    if self.icon ~= nil then
      self.Icon:SetTexture(self.icon)
    else
      self.Icon:Hide()
    end
  end
end

function me.UiDropDownMenu_CreateInfo()
  return {}
end

function me.UiDropDownMenu_CreateFrames(level, index)
  while level > uiDropDownMenuMaxLevels do
    uiDropDownMenuMaxLevels = uiDropDownMenuMaxLevels + 1
    local newList = creatre_UIDropDownList("RGGM_DropDownList" .. uiDropDownMenuMaxLevels)

    newList:SetFrameStrata("FULLSCREEN_DIALOG")
    newList:SetToplevel(true)
    newList:Hide()
    newList:SetID(uiDropDownMenuMaxLevels)
    newList:SetWidth(180)
    newList:SetHeight(10)

    for i = 1, uiDropDownMenuMaxButtons do
      local newButton = create_UIDropDownMenuButton(
        "RGGM_DropDownList" .. uiDropDownMenuMaxLevels .. "Button" .. i,
        newList
      )
      newButton:SetID(i)
    end
  end

  while index > uiDropDownMenuMaxButtons do
    uiDropDownMenuMaxButtons = uiDropDownMenuMaxButtons + 1

    for i = 1, uiDropDownMenuMaxLevels do
      local newButton = create_UIDropDownMenuButton(
        "RGGM_DropDownList" .. i .. "Button" .. uiDropDownMenuMaxButtons,
        _G["RGGM_DropDownList" .. i]
      )
      newButton:SetID(uiDropDownMenuMaxButtons)
    end
  end
end

function me.UiDropDownMenu_AddSeparator(level)
  local separatorInfo = {
    hasArrow = false,
    dist = 0,
    isTitle = true,
    isUninteractable = true,
    notCheckable = true,
    iconOnly = true,
    icon = "Interface\\Common\\UI-TooltipDivider-Transparent",
    tCoordLeft = 0,
    tCoordRight = 1,
    tCoordTop = 0,
    tCoordBottom = 1,
    tSizeX = 0,
    tSizeY = 8,
    tFitDropDownSizeX = true,
    iconInfo = {
      tCoordLeft = 0,
      tCoordRight = 1,
      tCoordTop = 0,
      tCoordBottom = 1,
      tSizeX = 0,
      tSizeY = 8,
      tFitDropDownSizeX = true
    },
  }

  me.UiDropDownMenu_AddButton(separatorInfo, level)
end

function me.UiDropDownMenu_AddSpace(level)
  local spaceInfo = {
    hasArrow = false,
    dist = 0,
    isTitle = true,
    isUninteractable = true,
    notCheckable = true,
  }

  me.UiDropDownMenu_AddButton(spaceInfo, level)
end

function me.UiDropDownMenu_AddButton(info, level)
  --[[
  Might to uncomment this if there are performance issues
  if ( not uiDropDownMenuOpenMenu ) then
    return
  end
  ]]
  if not level then
    level = 1
  end

  local listFrame = _G["RGGM_DropDownList" .. level]
  local index = listFrame and (listFrame.numButtons + 1) or 1
  local width

  uIDropDownMenuDelegate:SetAttribute("createframes-level", level)
  uIDropDownMenuDelegate:SetAttribute("createframes-index", index)
  uIDropDownMenuDelegate:SetAttribute("createframes", true)

  listFrame = listFrame or _G["RGGM_DropDownList" .. level]
  local listFrameName = listFrame:GetName()

  -- Set the number of buttons in the listframe
  listFrame.numButtons = index

  local button = _G[listFrameName .. "Button" .. index]
  local normalText = _G[button:GetName() .. "NormalText"]
  local icon = _G[button:GetName() .. "Icon"]
  --[[
    This button is used to capture the mouse OnEnter/OnLeave events if the dropdown button is disabled,
    since a disabled button doesn't receive any events
  ]]--
  -- This is used specifically for drop down menu time outs
  local invisibleButton = _G[button:GetName() .. "InvisibleButton"]

  -- Default settings
  button:SetDisabledFontObject(GameFontDisableSmallLeft)
  invisibleButton:Hide()
  button:Enable()

  -- If not clickable then disable the button and set it white
  if info.notClickable then
    info.disabled = true
    button:SetDisabledFontObject(GameFontHighlightSmallLeft)
  end

  -- Set the text color and disable it if its a title
  if info.isTitle then
    info.disabled = true
    button:SetDisabledFontObject(GameFontNormalSmallLeft)
  end

  -- Disable the button if disabled and turn off the color code
  if info.disabled then
    button:Disable()
    invisibleButton:Show()
    info.colorCode = nil
  end

  -- If there is a color for a disabled line, set it
  if info.disablecolor then
    info.colorCode = info.disablecolor
  end

  -- Configure button
  if info.text then
    -- look for inline color code this is only if the button is enabled
    if info.colorCode then
      button:SetText(info.colorCode .. info.text .. "|r")
    else
      button:SetText(info.text)
    end

    -- Set icon
    if info.icon or info.mouseOverIcon then
      icon:SetSize(16,16)
      icon:SetTexture(info.icon)
      icon:ClearAllPoints()
      icon:SetPoint("RIGHT")

      if info.tCoordLeft then
        icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom)
      else
        icon:SetTexCoord(0, 1, 0, 1)
      end
      icon:Show()
    else
      icon:Hide()
    end

    -- Check to see if there is a replacement font
    if info.fontObject then
      button:SetNormalFontObject(info.fontObject)
      button:SetHighlightFontObject(info.fontObject)
    else
      button:SetNormalFontObject(GameFontHighlightSmallLeft)
      button:SetHighlightFontObject(GameFontHighlightSmallLeft)
    end
  else
    button:SetText("")
    icon:Hide()
  end

  button.iconOnly = nil
  button.icon = nil
  button.iconInfo = nil

  if info.iconInfo then
    icon.tFitDropDownSizeX = info.iconInfo.tFitDropDownSizeX
  else
    icon.tFitDropDownSizeX = nil
  end

  if info.iconOnly and info.icon then
    button.iconOnly = true
    button.icon = info.icon
    button.iconInfo = info.iconInfo

    me.UiDropDownMenu_SetIconImage(icon, info.icon, info.iconInfo)
    icon:ClearAllPoints()
    icon:SetPoint("LEFT")
  end

  -- Pass through attributes
  button.func = info.func
  button.funcOnEnter = info.funcOnEnter
  button.funcOnLeave = info.funcOnLeave
  button.owner = info.owner
  button.hasOpacity = info.hasOpacity
  button.opacity = info.opacity
  button.opacityFunc = info.opacityFunc
  button.cancelFunc = info.cancelFunc
  button.swatchFunc = info.swatchFunc
  button.keepShownOnClick = info.keepShownOnClick
  button.tooltipTitle = info.tooltipTitle
  button.tooltipText = info.tooltipText
  button.tooltipInstruction = info.tooltipInstruction
  button.tooltipWarning = info.tooltipWarning
  button.arg1 = info.arg1
  button.arg2 = info.arg2
  button.hasArrow = info.hasArrow
  button.hasColorSwatch = info.hasColorSwatch
  button.notCheckable = info.notCheckable
  button.menuList = info.menuList
  button.tooltipWhileDisabled = info.tooltipWhileDisabled
  button.noTooltipWhileEnabled = info.noTooltipWhileEnabled
  button.tooltipOnButton = info.tooltipOnButton
  button.noClickSound = info.noClickSound
  button.padding = info.padding
  button.icon = info.icon
  button.mouseOverIcon = info.mouseOverIcon
  button.ignoreAsMenuSelection = info.ignoreAsMenuSelection

  if info.value then
    button.value = info.value
  elseif info.text then
    button.value = info.text
  else
    button.value = nil
  end

  local expandArrow = _G[listFrameName .. "Button" .. index .. "ExpandArrow"]
  expandArrow:SetShown(info.hasArrow)
  expandArrow:SetEnabled(not info.disabled)

  -- If not checkable move everything over to the left to fill in the gap where the check would be
  local xPos = 5
  local yPos = -((button:GetID() - 1) * uiDropDownMenuButtonHeight) - uiDropDownMenuBorderHeight
  local displayInfo = normalText

  if info.iconOnly then
    displayInfo = icon
  end

  displayInfo:ClearAllPoints()
  if info.notCheckable then
    if info.justifyH and info.justifyH == "CENTER" then
      displayInfo:SetPoint("CENTER", button, "CENTER", -7, 0)
    else
      displayInfo:SetPoint("LEFT", button, "LEFT", 0, 0)
    end
    xPos = xPos + 10

  else
    xPos = xPos + 12
    displayInfo:SetPoint("LEFT", button, "LEFT", 20, 0)
  end

  -- Adjust offset if displayMode is menu
  local frame = uiDropDownMenuOpenMenu
  if frame and frame.displayMode == "MENU" then
    if not info.notCheckable then
      xPos = xPos - 6
    end
  end

  -- If no open frame then set the frame to the currently initialized frame
  frame = frame or uiDropDownMenuInitMenu

  if info.leftPadding then
    xPos = xPos + info.leftPadding
  end
  button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", xPos, yPos)

  -- See if button is selected by id or name
  if frame then
    if me.UiDropDownMenu_GetSelectedName(frame) then
      if button:GetText() == me.UiDropDownMenu_GetSelectedName(frame) then
        info.checked = 1
      end
    elseif me.UiDropDownMenu_GetSelectedID(frame) then
      if button:GetID() == me.UiDropDownMenu_GetSelectedID(frame) then
        info.checked = 1
      end
    elseif me.UiDropDownMenu_GetSelectedValue(frame) then
      if button.value == me.UiDropDownMenu_GetSelectedValue(frame) then
        info.checked = 1
      end
    end
  end

  if not info.notCheckable then
    local check = _G[listFrameName .. "Button" .. index .. "Check"]
    local uncheck = _G[listFrameName .. "Button" .. index .. "UnCheck"]

    if info.disabled then
      check:SetDesaturated(true)
      check:SetAlpha(0.5)
      uncheck:SetDesaturated(true)
      uncheck:SetAlpha(0.5)
    else
      check:SetDesaturated(false)
      check:SetAlpha(1)
      uncheck:SetDesaturated(false)
      uncheck:SetAlpha(1)
    end

    if info.customCheckIconAtlas or info.customCheckIconTexture then
      check:SetTexCoord(0, 1, 0, 1)
      uncheck:SetTexCoord(0, 1, 0, 1)

      if info.customCheckIconAtlas then
        check:SetAtlas(info.customCheckIconAtlas)
        uncheck:SetAtlas(info.customUncheckIconAtlas or info.customCheckIconAtlas)
      else
        check:SetTexture(info.customCheckIconTexture)
        uncheck:SetTexture(info.customUncheckIconTexture or info.customCheckIconTexture)
      end
    elseif info.isNotRadio then
      check:SetTexCoord(0.0, 0.5, 0.0, 0.5)
      check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
      uncheck:SetTexCoord(0.5, 1.0, 0.0, 0.5)
      uncheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
    else
      check:SetTexCoord(0.0, 0.5, 0.5, 1.0)
      check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
      uncheck:SetTexCoord(0.5, 1.0, 0.5, 1.0)
      uncheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
    end

    -- Checked can be a function now
    local checked = info.checked

    if type(checked) == "function" then
      checked = checked(button)
    end

    -- Show the check if checked
    if checked then
      button:LockHighlight()
      check:Show()
      uncheck:Hide()
    else
      button:UnlockHighlight()
      check:Hide()
      uncheck:Show()
    end
  else
    _G[listFrameName .. "Button" .. index .. "Check"]:Hide()
    _G[listFrameName .. "Button" .. index .. "UnCheck"]:Hide()
  end

  button.checked = info.checked

  -- If has a colorswatch, show it and vertex color it
  local colorSwatch = _G[listFrameName .. "Button" .. index .. "ColorSwatch"]

  if info.hasColorSwatch then
    _G["RGGM_DropDownList" .. level .. "Button" .. index .. "ColorSwatch" .. "NormalTexture"]
      :SetVertexColor(info.r, info.g, info.b)
    button.r = info.r
    button.g = info.g
    button.b = info.b
    colorSwatch:Show()
  else
    colorSwatch:Hide()
  end

  me.UiDropDownMenu_CheckAddCustomFrame(listFrame, button, info)

  button:SetShown(button.customFrame == nil)

  button.minWidth = info.minWidth

  width = math.max(me.UiDropDownMenu_GetButtonWidth(button), info.minWidth or 0)
  --Set maximum button width
  if width > listFrame.maxWidth then
    listFrame.maxWidth = width
  end

  -- Set the height of the listframe
  listFrame:SetHeight((index * uiDropDownMenuButtonHeight) + (uiDropDownMenuBorderHeight * 2))
end

function me.UiDropDownMenu_CheckAddCustomFrame(self, button, info)
  local customFrame = info.customFrame
  button.customFrame = customFrame

  if customFrame then
    customFrame:SetOwningButton(button)
    customFrame:ClearAllPoints()
    customFrame:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    customFrame:Show()

    me.UiDropDownMenu_RegisterCustomFrame(self, customFrame)
  end
end

function me.UiDropDownMenu_RegisterCustomFrame(self, customFrame)
  self.customFrames = self.customFrames or {}
  table.insert(self.customFrames, customFrame)
end

function me.UiDropDownMenu_GetMaxButtonWidth(self)
  local maxWidth = 0

  for i = 1, self.numButtons do
    local button = _G[self:GetName() .. "Button" .. i]
    local width = me.UiDropDownMenu_GetButtonWidth(button)

    if width > maxWidth then
      maxWidth = width
    end
  end
  return maxWidth
end

function me.UiDropDownMenu_GetButtonWidth(button)
  local minWidth = button.minWidth or 0

  if button.customFrame and button.customFrame:IsShown() then
    return math.max(minWidth, button.customFrame:GetPreferredEntryWidth())
  end

  if not button:IsShown() then
    return 0
  end

  local width
  local buttonName = button:GetName()
  local icon = _G[buttonName .. "Icon"]
  local normalText = _G[buttonName .. "NormalText"]

  if button.iconOnly and icon then
    width = icon:GetWidth()
  elseif normalText and normalText:GetText() then
    width = normalText:GetWidth() + 40

    if button.icon then
      -- Add padding for the icon
      width = width + 10
    end
  else
    return minWidth
  end

  -- Add padding if has and expand arrow or color swatch
  if button.hasArrow or button.hasColorSwatch then
    width = width + 10
  end

  if button.notCheckable then
    width = width - 30
  end

  if button.padding then
    width = width + button.padding
  end

  return math.max(minWidth, width)
end

function me.UiDropDownMenu_Refresh(frame, useValue, dropdownLevel)
  local maxWidth = 0
  local somethingChecked = nil

  if not dropdownLevel then
    dropdownLevel = uiDropDownMenuMenuLevel
  end

  local listFrame = _G["RGGM_DropDownList" .. dropdownLevel]
  listFrame.numButtons = listFrame.numButtons or 0
  -- Just redraws the existing menu
  for i = 1, uiDropDownMenuMaxButtons do
    local button = _G["RGGM_DropDownList" .. dropdownLevel .. "Button" .. i]
    local checked = nil

    if i <= listFrame.numButtons then
      -- See if checked or not
      if me.UiDropDownMenu_GetSelectedName(frame) then
        if button:GetText() == me.UiDropDownMenu_GetSelectedName(frame) then
          checked = 1
        end
      elseif me.UiDropDownMenu_GetSelectedID(frame) then
        if button:GetID() == me.UiDropDownMenu_GetSelectedID(frame) then
          checked = 1
        end
      elseif me.UiDropDownMenu_GetSelectedValue(frame) then
        if button.value == me.UiDropDownMenu_GetSelectedValue(frame) then
          checked = 1
        end
      end
    end

    if button.checked and type(button.checked) == "function" then
      checked = button.checked(button)
    end

    if not button.notCheckable and button:IsShown() then
      -- If checked show check image
      local checkImage = _G["RGGM_DropDownList" .. dropdownLevel .. "Button" .. i .. "Check"]
      local uncheckImage = _G["RGGM_DropDownList" .. dropdownLevel .. "Button" .. i .. "UnCheck"]

      if checked then
        if not button.ignoreAsMenuSelection then
          somethingChecked = true
          local icon = GetChild(frame, frame:GetName(), "Icon")

          if button.iconOnly and icon and button.icon then
            me.UiDropDownMenu_SetIconImage(icon, button.icon, button.iconInfo)
          elseif useValue then
            me.UiDropDownMenu_SetText(frame, button.value)
            icon:Hide()
          else
            me.UiDropDownMenu_SetText(frame, button:GetText())
            icon:Hide()
          end
        end

        button:LockHighlight()
        checkImage:Show()
        uncheckImage:Hide()
      else
        button:UnlockHighlight()
        checkImage:Hide()
        uncheckImage:Show()
      end
    end

    if button:IsShown() then
      local width = me.UiDropDownMenu_GetButtonWidth(button)

      if width > maxWidth then
        maxWidth = width
      end
    end
  end

  if somethingChecked == nil then
    me.UiDropDownMenu_SetText(frame, VIDEO_QUALITY_LABEL6)
    local icon = GetChild(frame, frame:GetName(), "Icon")
    icon:Hide()
  end

  if not frame.noResize then
    for i = 1, uiDropDownMenuMaxButtons do
      local button = _G["RGGM_DropDownList" .. dropdownLevel .. "Button" .. i]
      button:SetWidth(maxWidth)
    end

    me.UiDropDownMenu_RefreshDropDownSize(_G["RGGM_DropDownList" .. dropdownLevel])
  end
end

function me.UiDropDownMenu_RefreshAll(frame, useValue)
  for dropdownLevel = uiDropDownMenuMenuLevel, 2, -1 do
    local listFrame = _G["RGGM_DropDownList" .. dropdownLevel]

    if listFrame:IsShown() then
      me.UiDropDownMenu_Refresh(frame, nil, dropdownLevel)
    end
  end
  -- useValue is the text on the dropdown, only needs to be set once
  me.UiDropDownMenu_Refresh(frame, useValue, 1)
end

function me.UiDropDownMenu_SetIconImage(icon, texture, info)
  icon:SetTexture(texture)

  if info.tCoordLeft then
    icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom)
  else
    icon:SetTexCoord(0, 1, 0, 1)
  end

  if info.tSizeX then
    icon:SetWidth(info.tSizeX)
  else
    icon:SetWidth(16)
  end

  if info.tSizeY then
    icon:SetHeight(info.tSizeY)
  else
    icon:SetHeight(16)
  end

  icon:Show()
end

function me.UiDropDownMenu_SetSelectedName(frame, name, useValue)
  frame.selectedName = name
  frame.selectedID = nil
  frame.selectedValue = nil
  me.UiDropDownMenu_Refresh(frame, useValue)
end

function me.UiDropDownMenu_SetSelectedValue(frame, value, useValue)
  -- useValue will set the value as the text, not the name
  frame.selectedName = nil
  frame.selectedID = nil
  frame.selectedValue = value
  me.UiDropDownMenu_Refresh(frame, useValue)
end

function me.UiDropDownMenu_SetSelectedID(frame, id, useValue)
  frame.selectedID = id
  frame.selectedName = nil
  frame.selectedValue = nil
  me.UiDropDownMenu_Refresh(frame, useValue)
end

function me.UiDropDownMenu_GetSelectedName(frame)
  return frame.selectedName
end

function me.UiDropDownMenu_GetSelectedID(frame)
  if frame.selectedID then
    return frame.selectedID
  else
    -- If no explicit selectedID then try to send the id of a selected value or name
    local listFrame = _G["RGGM_DropDownList" .. uiDropDownMenuMenuLevel]

    for i = 1, listFrame.numButtons do
      local button = _G["RGGM_DropDownList" .. uiDropDownMenuMenuLevel .. "Button" .. i]
      -- See if checked or not
      if me.UiDropDownMenu_GetSelectedName(frame) then
        if button:GetText() == me.UiDropDownMenu_GetSelectedName(frame) then
          return i
        end
      elseif me.UiDropDownMenu_GetSelectedValue(frame) then
        if button.value == me.UiDropDownMenu_GetSelectedValue(frame) then
          return i
        end
      end
    end
  end
end

function me.UiDropDownMenu_GetSelectedValue(frame)
  return frame.selectedValue
end

function me.UiDropDownMenuButton_OnClick(self)
  local checked = self.checked

  if type (checked) == "function" then
    checked = checked(self)
  end

  if self.keepShownOnClick then
    if not self.notCheckable then
      if checked then
        _G[self:GetName() .. "Check"]:Hide()
        _G[self:GetName() .. "UnCheck"]:Show()
        checked = false
      else
        _G[self:GetName() .. "Check"]:Show()
        _G[self:GetName() .. "UnCheck"]:Hide()
        checked = true
      end
    end
  else
    self:GetParent():Hide()
  end

  if type (self.checked) ~= "function" then
    self.checked = checked
  end

  -- saving this here because func might use a dropdown, changing this self's attributes
  local playSound = true

  if self.noClickSound then
    playSound = false
  end

  local func = self.func

  if func then
    func(self, self.arg1, self.arg2, checked)
  else
    return
  end

  if playSound then
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
  end
end

function me.HideUiDropDownMenu(level)
  local listFrame = _G["RGGM_DropDownList" .. level]
  listFrame:Hide()
end

function me.ToggleDropDownMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button)
  if not level then
    level = 1
  end

  uIDropDownMenuDelegate:SetAttribute("createframes-level", level)
  uIDropDownMenuDelegate:SetAttribute("createframes-index", 0)
  uIDropDownMenuDelegate:SetAttribute("createframes", true)
  uiDropDownMenuMenuLevel = level
  uiDropDownMenuMenuValue = value

  local listFrameName = "RGGM_DropDownList" .. level
  local listFrame = _G[listFrameName]
  local tempFrame
  local point, relativePoint, relativeTo

  if not dropDownFrame then
    tempFrame = button:GetParent()
  else
    tempFrame = dropDownFrame
  end

  if listFrame:IsShown() and (uiDropDownMenuOpenMenu == tempFrame) then
    listFrame:Hide()
  else
    -- Set the dropdownframe scale
    local uiScale
    local uiParentScale = UIParent:GetScale()

    if GetCVar("useUIScale") == "1" then
      uiScale = tonumber(GetCVar("uiscale"))

      if uiParentScale < uiScale then
        uiScale = uiParentScale
      end
    else
      uiScale = uiParentScale
    end

    listFrame:SetScale(uiScale)

    -- Hide the listframe anyways since it is redrawn OnShow()
    listFrame:Hide()

    -- Frame to anchor the dropdown menu to
    local anchorFrame

    -- Display stuff
    -- Level specific stuff
    if level == 1 then
      uIDropDownMenuDelegate:SetAttribute("openmenu", dropDownFrame)
      listFrame:ClearAllPoints()
      -- If there's no specified anchorName then use left side of the dropdown menu
      if not anchorName then
        -- See if the anchor was set manually using setanchor
        if dropDownFrame.xOffset then
          xOffset = dropDownFrame.xOffset
        end

        if dropDownFrame.yOffset then
          yOffset = dropDownFrame.yOffset
        end

        if dropDownFrame.point then
          point = dropDownFrame.point
        end

        if dropDownFrame.relativeTo then
          relativeTo = dropDownFrame.relativeTo
        else
          relativeTo = GetChild(uiDropDownMenuOpenMenu, uiDropDownMenuOpenMenu:GetName(), "Left")
        end

        if dropDownFrame.relativePoint then
          relativePoint = dropDownFrame.relativePoint
        end
      elseif anchorName == "cursor" then
        relativeTo = nil
        local cursorX, cursorY = GetCursorPosition()
        cursorX = cursorX/uiScale
        cursorY =  cursorY/uiScale

        if not xOffset then
          xOffset = 0
        end

        if not yOffset then
          yOffset = 0
        end

        xOffset = cursorX + xOffset
        yOffset = cursorY + yOffset
      else
        -- See if the anchor was set manually using setanchor
        if dropDownFrame.xOffset then
          xOffset = dropDownFrame.xOffset
        end

        if dropDownFrame.yOffset then
          yOffset = dropDownFrame.yOffset
        end

        if dropDownFrame.point then
          point = dropDownFrame.point
        end

        if dropDownFrame.relativeTo then
          relativeTo = dropDownFrame.relativeTo
        else
          relativeTo = anchorName
        end

        if dropDownFrame.relativePoint then
          relativePoint = dropDownFrame.relativePoint
        end
      end

      if not xOffset or not yOffset then
        xOffset = 8
        yOffset = 22
      end

      if not point then
        point = "TOPLEFT"
      end

      if not relativePoint then
        relativePoint = "BOTTOMLEFT"
      end

      listFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    else
      if not dropDownFrame then
        dropDownFrame = uiDropDownMenuOpenMenu
      end

      listFrame:ClearAllPoints()
      -- If this is a dropdown button, not the arrow anchor it to itself
      if string.sub(button:GetParent():GetName(), 0,14) == "RGGM_DropDownList"
        and string.len(button:GetParent():GetName()) == 15 then
        anchorFrame = button
      else
        anchorFrame = button:GetParent()
      end

      point = "TOPLEFT"
      relativePoint = "TOPRIGHT"
      listFrame:SetPoint(point, anchorFrame, relativePoint, 0, 0)
    end

    -- Change list box appearance depending on display mode
    if dropDownFrame and dropDownFrame.displayMode == "MENU" then
      _G[listFrameName .. "Border"]:Hide()
      _G[listFrameName .. "MenuBackdrop"]:Show()
    else
      _G[listFrameName .. "Border"]:Show()
      _G[listFrameName .. "MenuBackdrop"]:Hide()
    end

    dropDownFrame.menuList = menuList
    me.UiDropDownMenu_Initialize(dropDownFrame, dropDownFrame.initialize, nil, level, menuList)
    -- If no items in the drop down don't show it
    if listFrame.numButtons == 0 then
      return
    end

    listFrame.onShow = dropDownFrame.listFrameOnShow

    -- Check to see if the dropdownlist is off the screen, if it is anchor it to the top of the dropdown button
    listFrame:Show()
    -- Hack since GetCenter() is returning coords relative to 1024x768
    local x, y = listFrame:GetCenter()
    -- Hack will fix this in next revision of dropdowns
    if not x or not y then
      listFrame:Hide()
      return
    end

    listFrame.onHide = dropDownFrame.onHide


    --  We just move level 1 enough to keep it on the screen. We don't necessarily change the anchors.
    if level == 1 then
      local offLeft = listFrame:GetLeft() / uiScale
      local offRight = (GetScreenWidth() - listFrame:GetRight()) / uiScale
      local offTop = (GetScreenHeight() - listFrame:GetTop()) / uiScale
      local offBottom = listFrame:GetBottom() / uiScale

      local xAddOffset, yAddOffset = 0, 0

      if offLeft < 0 then
        xAddOffset = -offLeft
      elseif offRight < 0 then
        xAddOffset = offRight
      end

      if offTop < 0 then
        yAddOffset = offTop
      elseif offBottom < 0 then
        yAddOffset = -offBottom
      end

      listFrame:ClearAllPoints()

      if anchorName == "cursor" then
        listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset)
      else
        listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset)
      end
    else
      -- Determine whether the menu is off the screen or not
      local offscreenY, offscreenX

      if (y - listFrame:GetHeight() / 2) < 0 then
        offscreenY = 1
      end

      if listFrame:GetRight() > GetScreenWidth() then
        offscreenX = 1
      end

      if offscreenY and offscreenX then
        point = string.gsub(point, "TOP(.*)", "BOTTOM%1")
        point = string.gsub(point, "(.*)LEFT", "%1RIGHT")
        relativePoint = string.gsub(relativePoint, "TOP(.*)", "BOTTOM%1")
        relativePoint = string.gsub(relativePoint, "(.*)RIGHT", "%1LEFT")
        xOffset = -11
        yOffset = -14
      elseif offscreenY then
        point = string.gsub(point, "TOP(.*)", "BOTTOM%1")
        relativePoint = string.gsub(relativePoint, "TOP(.*)", "BOTTOM%1")
        xOffset = 0
        yOffset = -14
      elseif offscreenX then
        point = string.gsub(point, "(.*)LEFT", "%1RIGHT")
        relativePoint = string.gsub(relativePoint, "(.*)RIGHT", "%1LEFT")
        xOffset = -11
        yOffset = 14
      else
        xOffset = 0
        yOffset = 14
      end

      listFrame:ClearAllPoints()
      listFrame.parentLevel = tonumber(string.match(anchorFrame:GetName(), "RGGM_DropDownList(%d+)"))
      listFrame.parentID = anchorFrame:GetID()
      listFrame:SetPoint(point, anchorFrame, relativePoint, xOffset, yOffset)
    end
  end
end

function me.CloseDropDownMenus(level)
  if not level then
    level = 1
  end

  for i = level, uiDropDownMenuMaxLevels do
    _G["RGGM_DropDownList" .. i]:Hide()
  end
end

local function UiDropDownMenu_ContainsMouse()
  for i = 1, uiDropDownMenuMaxLevels do
    local dropdown = _G["RGGM_DropDownList" .. i]

    if dropdown:IsShown() and dropdown:IsMouseOver() then
      return true
    end
  end

  return false
end

function me.UiDropDownMenu_HandleGlobalMouseEvent(button, event)
  if event == "GLOBAL_MOUSE_DOWN" and (button == "LeftButton" or button == "RightButton") then
    if not UiDropDownMenu_ContainsMouse() then
      me.CloseDropDownMenus()
    end
  end
end

function me.UiDropDownMenu_OnShow(self)
  if self.onShow then
    self.onShow()
    self.onShow = nil
  end

  for i = 1, uiDropDownMenuMaxButtons do
    if not self.noResize then
      _G[self:GetName() .. "Button" .. i]:SetWidth(self.maxWidth)
    end
  end

  if not self.noResize then
    self:SetWidth(self.maxWidth + 25)
  end

  if self:GetID() > 1 then
    self.parent = _G["RGGM_DropDownList" .. (self:GetID() - 1)]
  end
end

function me.UiDropDownMenu_OnHide(self)
  local id = self:GetID()

  if self.onHide then
    self.onHide(id + 1)
    self.onHide = nil
  end

  me.CloseDropDownMenus(id+1)
  openDropDownMenus[id] = nil

  if id == 1 then
    uiDropDownMenuOpenMenu = nil
  end

  if self.customFrames then
    for _, frame in ipairs(self.customFrames) do
      frame:Hide()
    end

    self.customFrames = nil
  end
end

function me.UiDropDownMenu_SetWidth(frame, width, padding)
  local frameName = frame:GetName()
	local defaultPadding = 25
  GetChild(frame, frameName, "Middle"):SetWidth(width)

  if padding then
    frame:SetWidth(width + padding)
  else
    frame:SetWidth(width + defaultPadding + defaultPadding)
  end

  if padding then
    GetChild(frame, frameName, "Text"):SetWidth(width)
  else
    GetChild(frame, frameName, "Text"):SetWidth(width - defaultPadding)
  end

  frame.noResize = 1
end

function me.UiDropDownMenu_SetButtonWidth(frame, width)
  local frameName = frame:GetName()

  if width == "TEXT" then
    width = GetChild(frame, frameName, "Text"):GetWidth()
  end

  GetChild(frame, frameName, "Button"):SetWidth(width)
  frame.noResize = 1
end

function me.UiDropDownMenu_SetText(frame, text)
  local frameName = frame:GetName()
  GetChild(frame, frameName, "Text"):SetText(text)
end

function me.UiDropDownMenu_GetText(frame)
  local frameName = frame:GetName()
  return GetChild(frame, frameName, "Text"):GetText()
end

function me.UiDropDownMenu_ClearAll(frame)
  -- Previous code refreshed the menu quite often and was a performance bottleneck
  frame.selectedID = nil
  frame.selectedName = nil
  frame.selectedValue = nil
  me.UiDropDownMenu_SetText(frame, "")

  local button, checkImage, uncheckImage

  for i = 1, uiDropDownMenuMaxButtons do
    button = _G["RGGM_DropDownList" .. uiDropDownMenuMenuLevel .. "Button" .. i]
    button:UnlockHighlight()

    checkImage = _G["RGGM_DropDownList" .. uiDropDownMenuMenuLevel .. "Button" .. i .. "Check"]
    checkImage:Hide()
    uncheckImage = _G["RGGM_DropDownList" .. uiDropDownMenuMenuLevel .. "Button" .. i .. "UnCheck"]
    uncheckImage:Hide()
  end
end

function me.UiDropDownMenu_JustifyText(frame, justification, customXOffset)
  local frameName = frame:GetName()
  local text = GetChild(frame, frameName, "Text")
  text:ClearAllPoints()

  if justification == "LEFT" then
    text:SetPoint("LEFT", GetChild(frame, frameName, "Left"), "LEFT", customXOffset or 27, 2)
    text:SetJustifyH("LEFT")
  elseif justification == "RIGHT" then
    text:SetPoint("RIGHT", GetChild(frame, frameName, "Right"), "RIGHT", customXOffset or -43, 2)
    text:SetJustifyH("RIGHT")
  elseif justification == "CENTER" then
    text:SetPoint("CENTER", GetChild(frame, frameName, "Middle"), "CENTER", customXOffset or -5, 2)
    text:SetJustifyH("CENTER")
  end
end

function me.UiDropDownMenu_SetAnchor(dropdown, xOffset, yOffset, point, relativeTo, relativePoint)
  dropdown.xOffset = xOffset
  dropdown.yOffset = yOffset
  dropdown.point = point
  dropdown.relativeTo = relativeTo
  dropdown.relativePoint = relativePoint
end

function me.UiDropDownMenu_GetCurrentDropDown()
  if uiDropDownMenuOpenMenu then
    return uiDropDownMenuOpenMenu
  elseif uiDropDownMenuInitMenu then
    return uiDropDownMenuInitMenu
  end
end

function me.UiDropDownMenuButton_GetChecked(self)
  return _G[self:GetName() .. "Check"]:IsShown()
end

function me.UiDropDownMenuButton_GetName(self)
  return _G[self:GetName() .. "NormalText"]:GetText()
end

function me.CreateUiDropDownMenuButton_OpenColorPicker(self, button)
  securecall("CloseMenus")

  if not button then
    button = self
  end

  uiDropDownMenuMenuValue = button.value
  me.OpenColorPicker(button)
end

function me.UiDropDownMenu_DisableButton(level, id)
  _G["RGGM_DropDownList" .. level .. "Button" .. id]:Disable()
end

function me.UiDropDownMenu_EnableButton(level, id)
  _G["RGGM_DropDownList" .. level .. "Button" .. id]:Enable()
end

function me.UiDropDownMenu_SetButtonText(level, id, text, colorCode)
  local button = _G["RGGM_DropDownList" .. level .. "Button" .. id]

  if colorCode then
    button:SetText(colorCode .. text .. "|r")
  else
    button:SetText(text)
  end
end

function me.UiDropDownMenu_SetButtonNotClickable(level, id)
  _G["RGGM_DropDownList" .. level .. "Button" .. id]:SetDisabledFontObject(GameFontHighlightSmallLeft)
end

function me.UiDropDownMenu_SetButtonClickable(level, id)
  _G["RGGM_DropDownList" .. level .. "Button" .. id]:SetDisabledFontObject(GameFontDisableSmallLeft)
end

function me.UiDropDownMenu_DisableDropDown(dropDown)
  local dropDownName = dropDown:GetName()
  local label = GetChild(dropDown, dropDownName, "Label")

  if label then
    label:SetVertexColor(GRAY_FONT_COLOR:GetRGB())
  end

  GetChild(dropDown, dropDownName, "Icon"):SetVertexColor(GRAY_FONT_COLOR:GetRGB())
  GetChild(dropDown, dropDownName, "Text"):SetVertexColor(GRAY_FONT_COLOR:GetRGB())
  GetChild(dropDown, dropDownName, "Button"):Disable()
  dropDown.isDisabled = 1
end

function me.UiDropDownMenu_EnableDropDown(dropDown)
  local dropDownName = dropDown:GetName()
  local label = GetChild(dropDown, dropDownName, "Label")

  if label then
    label:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
  end

  GetChild(dropDown, dropDownName, "Icon"):SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB())
  GetChild(dropDown, dropDownName, "Text"):SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB())
  GetChild(dropDown, dropDownName, "Button"):Enable()
  dropDown.isDisabled = nil
end

function me.UiDropDownMenu_IsEnabled(dropDown)
  return not dropDown.isDisabled
end

function me.UiDropDownMenu_GetValue(id)
  local button = _G["RGGM_DropDownList1Button" .. id]

  if button then
    return _G["RGGM_DropDownList1Button" .. id].value
  else
    return nil
  end
end

function me.OpenColorPicker(info)
  ColorPickerFrame.func = info.swatchFunc
  ColorPickerFrame.hasOpacity = info.hasOpacity
  ColorPickerFrame.opacityFunc = info.opacityFunc
  ColorPickerFrame.opacity = info.opacity
  ColorPickerFrame.previousValues = {r = info.r, g = info.g, b = info.b, opacity = info.opacity}
  ColorPickerFrame.cancelFunc = info.cancelFunc
  ColorPickerFrame.extraInfo = info.extraInfo
  -- This must come last, since it triggers a call to ColorPickerFrame.func()
  ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
  ShowUIPanel(ColorPickerFrame)
end

function me.ColorPicker_GetPreviousValues()
  return ColorPickerFrame.previousValues.r, ColorPickerFrame.previousValues.g, ColorPickerFrame.previousValues.b
end
