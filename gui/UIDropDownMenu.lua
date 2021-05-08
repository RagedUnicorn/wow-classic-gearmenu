--[[
  Custom implementation of Blizzard's UIDropDownMenu to avoid tainting issues
]]--

-- luacheck: globals CreateFrame GameFontDisableSmallLeft GameFontHighlightSmallLeft GameFontNormalSmallLeft
-- luacheck: globals issecure securecall table UIParent GetCVar GetCursorPosition GetScreenWidth GetScreenHeight
-- luacheck: globals max VIDEO_QUALITY_LABEL6 RGGM_uiDropdownMenu_InitializeHelper PlaySound CloseMenus
-- luacheck: globals GRAY_FONT_COLOR NORMAL_FONT_COLOR HIGHLIGHT_FONT_COLOR ColorPickerFrame ShowUIPanel

local mod = rggm
local me = {}
mod.uiDropdownMenu = me

me.tag = "UiDropDownMenu"

-- The current open menu
local uiDropdownMenuOpenMenu = nil
-- The current menu being initialized
local uiDropdownMenuInitMenu = nil

--[[
  Blizzard frame delegate
]]--
local uiDropdownMenuDelegate = CreateFrame("FRAME")

local uiDropdownMenuButtonHeight = 16
local uiDropdownMenuBorderHeight = 15
local uiDropdownMenuMinButtons = 8
local uiDropdownMenuMaxButtons = 8
local uiDropdownMenuLevel = 1
local uiDropdownMenuMaxLevels = 2
-- Current value of the open menu
local uiDropdownMenuValue = nil
-- Time to wait to hide the menu
local uiDropdownMenuShowTime = 2
-- List of open menus
local uiDropdownMenuOpenMenus = {}
local uiDropdownMenuButtonInfo = {}
local uiDropdownMenuSecureInfo = {}

--[[
  Create a new dropdown

  @param {string} name
  @param {table} parentFrame

  @return {table}
]]--
function me.CreateDropdown(name, parentFrame)
  local dropdown = CreateFrame(
    "Button",
    name,
    parentFrame,
    "RGGM_UIDropDownMenuTemplate"
  )

  return dropdown
end

--[[
  @return {number}
]]--
function me.GetUiDropdownMenuMaxButtons()
  return uiDropdownMenuMaxButtons
end

--[[
  Blizzard call UIDropDownMenuDelegate_OnAttributeChanged

  @param {table} self
  @param {string} attribute
  @param {table} value
]]--
function me.uiDropdownMenuDelegate_OnAttributeChanged (self, attribute, value)
  if attribute == "createframes" and value == true then
    me.uiDropdownMenu_CreateFrames(self:GetAttribute("createframes-level"), self:GetAttribute("createframes-index"))
  elseif attribute == "initmenu" then
    uiDropdownMenuInitMenu = value
  elseif attribute == "openmenu" then
    uiDropdownMenuOpenMenu = value
  end
end

-- register delegate script
uiDropdownMenuDelegate:SetScript("OnAttributeChanged", me.uiDropdownMenuDelegate_OnAttributeChanged)

--[[
  Blizzard call UIDropDownMenu_InitializeHelper

  @param {table} frame
]]--
function RGGM_uiDropdownMenu_InitializeHelper(frame)
  -- This deals with the potentially tainted stuff!
  if frame ~= uiDropdownMenuOpenMenu then
    uiDropdownMenuLevel = 1
  end

  -- Set the frame that's being intialized
  uiDropdownMenuDelegate:SetAttribute("initmenu", frame)

  -- Hide all the buttons
  local button, dropDownList

  for i = 1, uiDropdownMenuMaxLevels, 1 do
    dropDownList = _G["DropDownList" .. i]
    if i >= uiDropdownMenuLevel or frame ~= uiDropdownMenuOpenMenu then
      dropDownList.numButtons = 0
      dropDownList.maxWidth = 0

      for j = 1, uiDropdownMenuMaxButtons, 1 do
        button = _G["DropDownList" .. i .. "Button" .. j]
        button:Hide()
      end
      dropDownList:Hide()
    end
  end

  frame:SetHeight(uiDropdownMenuButtonHeight * 2)
end


--[[
  Blizzard call UIDropDownMenu_Initialize

  @param {table} frame
  @param {function} initFunction
  @param {string} displayMode
  @param {number} level
  @param {table} menuList
]]--
function me.uiDropdownMenu_Initialize(frame, initFunction, displayMode, level, menuList)
  frame.menuList = menuList

  securecall("RGGM_uiDropdownMenu_InitializeHelper", frame)

  -- Set the initialize function and call it. The initFunction populates the dropdown list.
  if initFunction then
    frame.initialize = initFunction
    initFunction(frame, level, frame.menuList)
  end

  --master frame
  if level == nil then
    level = 1
  end

  local dropDownList = _G["DropDownList"..level]
  dropDownList.dropdown = frame
  dropDownList.shouldRefresh = true

  -- Change appearance based on the displayMode
  if displayMode == "MENU" then
    local name = frame:GetName()
    _G[name.."Left"]:Hide()
    _G[name.."Middle"]:Hide()
    _G[name.."Right"]:Hide()
    _G[name.."ButtonNormalTexture"]:SetTexture("")
    _G[name.."ButtonDisabledTexture"]:SetTexture("")
    _G[name.."ButtonPushedTexture"]:SetTexture("")
    _G[name.."ButtonHighlightTexture"]:SetTexture("")

    local button = _G[name .. "Button"]
    button:ClearAllPoints()
    button:SetPoint("LEFT", name .. "Text", "LEFT", -9, 0)
    button:SetPoint("RIGHT", name .. "Text", "RIGHT", 6, 0)
    frame.displayMode = "MENU"
  end
end

--[[
  Blizzard call UIDropDownMenu_RefreshDropDownSize

  @param {table} self
]]--
function me.uiDropdownMenu_RefreshDropDownSize(self)
  self.maxWidth = me.uiDropdownMenu_GetMaxButtonWidth(self)
  self:SetWidth(self.maxWidth + 25)

  for i = 1, uiDropdownMenuMaxButtons, 1 do
    local icon = _G[self:GetName() .. "Button" .. i .. "Icon"]

    if icon.tFitDropDownSizeX then
      icon:SetWidth(self.maxWidth - 5)
    end
  end
end

--[[
  Blizzard call UIDropDownMenu_OnUpdate

  If dropdown is visible then see if its timer has expired, if so hide the frame

  @param {table} self
  @param {number} elapsed
]]--
function me.uiDropdownMenu_OnUpdate(self, elapsed)
  if self.shouldRefresh then
    me.uiDropdownMenu_GetMaxButtonWidth(self)
    self.shouldRefresh = false
  end

  if not self.showTimer or not self.isCounting then
    return
  elseif self.showTimer < 0 then
    self:Hide()
    self.showTimer = nil
    self.isCounting = nil
  else
    self.showTimer = self.showTimer - elapsed
  end
end

--[[
  Blizzard call UIDropDownMenu_StartCounting
]]--
function me.uiDropdownMenu_StartCounting(frame)
  if frame.parent then
    me.uiDropdownMenu_StartCounting(frame.parent)
  else
    frame.showTimer = uiDropdownMenuShowTime
    frame.isCounting = 1
  end
end

--[[
  Blizzard call UIDropDownMenu_StopCounting
]]--
function me.uiDropdownMenu_StopCounting(frame)
  if frame.parent then
    me.uiDropdownMenu_StopCounting(frame.parent)
  else
    frame.isCounting = nil
  end
end

--[[
  Blizzard call UIDropDownMenu_CreateInfo
]]--
function me.uiDropdownMenu_CreateInfo()
  -- Reuse the same table to prevent memory churn

  if issecure() then
    securecall(table.wipe, uiDropdownMenuSecureInfo)
    return uiDropdownMenuSecureInfo
  else
    return table.wipe(uiDropdownMenuButtonInfo)
  end
end

--[[
  Blizzard call UIDropDownMenu_CreateFrames

  @param {number} level
  @param {number} index
]]--
function me.uiDropdownMenu_CreateFrames(level, index)
  while level > uiDropdownMenuMaxLevels do
    uiDropdownMenuMaxLevels = uiDropdownMenuMaxLevels + 1

    local newList = CreateFrame(
      "Button",
      "DropDownList" .. uiDropdownMenuMaxLevels,
      nil,
      "UIDropDownListTemplate"
    )
    newList:SetFrameStrata("FULLSCREEN_DIALOG")
    newList:SetToplevel(true)
    newList:Hide()
    newList:SetID(uiDropdownMenuMaxLevels)
    newList:SetWidth(180)
    newList:SetHeight(10)

    for i = uiDropdownMenuMinButtons + 1, uiDropdownMenuMaxButtons do
      local newButton = CreateFrame(
        "Button",
        "DropDownList" .. uiDropdownMenuMaxLevels .. "Button" .. i,
        newList,
        "UIDropDownMenuButtonTemplate"
      )
      newButton:SetID(i)
    end
  end

  while index > uiDropdownMenuMaxButtons do
    uiDropdownMenuMaxButtons = uiDropdownMenuMaxButtons + 1

    for i = 1, uiDropdownMenuMaxLevels do
      local newButton = CreateFrame(
        "Button",
        "DropDownList" .. i .. "Button" .. uiDropdownMenuMaxButtons,
        _G["DropDownList" .. i],
        "UIDropDownMenuButtonTemplate"
      )
      newButton:SetID(uiDropdownMenuMaxButtons)
    end
  end
end

--[[
  Blizzard call UIDropDownMenu_AddSeparator

  @param {table} info
  @param {number} level
]]--
function me.uiDropdownMenu_AddSeparator(info, level)
  info.text = nil
  info.hasArrow = false
  info.dist = 0
  info.isTitle = true
  info.isUninteractable = true
  info.notCheckable = true
  info.iconOnly = true
  info.icon = "Interface\\Common\\UI-TooltipDivider-Transparent"
  info.tCoordLeft = 0
  info.tCoordRight = 1
  info.tCoordTop = 0
  info.tCoordBottom = 1
  info.tSizeX = 0
  info.tSizeY = 8
  info.tFitDropDownSizeX = true
  info.iconInfo = {
    tCoordLeft = info.tCoordLeft,
    tCoordRight = info.tCoordRight,
    tCoordTop = info.tCoordTop,
    tCoordBottom = info.tCoordBottom,
    tSizeX = info.tSizeX,
    tSizeY = info.tSizeY,
    tFitDropDownSizeX = info.tFitDropDownSizeX
  }

  me.uiDropdownMenu_AddButton(info, level)
end

--[[
  Blizzard call UIDropDownMenu_AddButton

  @param {table} info
  @param {number} level
]]--
function me.uiDropdownMenu_AddButton(info, level)
  if not level then
    level = 1
  end

  local listFrame = _G["DropDownList" .. level]
  local index = listFrame and (listFrame.numButtons + 1) or 1
  local width

  uiDropdownMenuDelegate:SetAttribute("createframes-level", level)
  uiDropdownMenuDelegate:SetAttribute("createframes-index", index)
  uiDropdownMenuDelegate:SetAttribute("createframes", true)

  listFrame = listFrame or _G["DropDownList" .. level]
  local listFrameName = listFrame:GetName()

  -- Set the number of buttons in the listframe
  listFrame.numButtons = index
  local button = _G[listFrameName .. "Button" .. index]
  local normalText = _G[button:GetName() .. "NormalText"]
  local icon = _G[button:GetName() .. "Icon"]
  -- This button is used to capture the mouse OnEnter/OnLeave events if the dropdown button is disabled,
  -- since a disabled button doesn't receive any events. This is used specifically for drop down menu time outs
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
    if info.icon then
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

    me.uiDropdownMenu_SetIconImage(icon, info.icon, info.iconInfo)
    icon:ClearAllPoints()
    icon:SetPoint("LEFT")
  end

  -- Pass through attributes
  button.func = info.func
  button.owner = info.owner
  button.hasOpacity = info.hasOpacity
  button.opacity = info.opacity
  button.opacityFunc = info.opacityFunc
  button.cancelFunc = info.cancelFunc
  button.swatchFunc = info.swatchFunc
  button.keepShownOnClick = info.keepShownOnClick
  button.tooltipTitle = info.tooltipTitle
  button.tooltipText = info.tooltipText
  button.arg1 = info.arg1
  button.arg2 = info.arg2
  button.hasArrow = info.hasArrow
  button.hasColorSwatch = info.hasColorSwatch
  button.notCheckable = info.notCheckable
  button.menuList = info.menuList
  button.tooltipWhileDisabled = info.tooltipWhileDisabled
  button.tooltipOnButton = info.tooltipOnButton
  button.noClickSound = info.noClickSound
  button.padding = info.padding

  if info.value then
    button.value = info.value
  elseif info.text then
    button.value = info.text
  else
    button.value = nil
  end

  -- Show the expand arrow if it has one
  if info.hasArrow then
    _G[listFrameName .. "Button" .. index .. "ExpandArrow"]:Show()
  else
    _G[listFrameName .. "Button" .. index .. "ExpandArrow"]:Hide()
  end
  button.hasArrow = info.hasArrow

  -- If not checkable move everything over to the left to fill in the gap where the check would be
  local xPos = 5
  local yPos = -((button:GetID() - 1) * uiDropdownMenuButtonHeight) - uiDropdownMenuBorderHeight
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
  local frame = uiDropdownMenuOpenMenu

  if frame and frame.displayMode == "MENU" then
    if not info.notCheckable then
      xPos = xPos - 6
    end
  end

  -- If no open frame then set the frame to the currently initialized frame
  frame = frame or uiDropdownMenuInitMenu

  if info.leftPadding then
    xPos = xPos + info.leftPadding
  end

  button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", xPos, yPos)

  -- See if button is selected by id or name
  if frame then
    if me.uiDropdownMenu_GetSelectedName(frame) then
      if button:GetText() == me.uiDropdownMenu_GetSelectedName(frame) then
        info.checked = 1
      end
    elseif me.uiDropdownMenu_GetSelectedID(frame) then
      if button:GetID() == me.uiDropdownMenu_GetSelectedID(frame) then
        info.checked = 1
      end
    elseif me.uiDropdownMenu_GetSelectedValue(frame) then
      if button.value == me.uiDropdownMenu_GetSelectedValue(frame) then
        info.checked = 1
      end
    end
  end

  if not info.notCheckable then
    if info.disabled then
      _G[listFrameName .. "Button" .. index .. "Check"]:SetDesaturated(true)
      _G[listFrameName .. "Button" .. index .. "Check"]:SetAlpha(0.5)
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:SetDesaturated(true)
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:SetAlpha(0.5)
    else
      _G[listFrameName .. "Button" .. index .. "Check"]:SetDesaturated(false)
      _G[listFrameName .. "Button" .. index .. "Check"]:SetAlpha(1)
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:SetDesaturated(false)
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:SetAlpha(1)
    end

    if info.isNotRadio then
      _G[listFrameName .. "Button" .. index .. "Check"]:SetTexCoord(0.0, 0.5, 0.0, 0.5)
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:SetTexCoord(0.5, 1.0, 0.0, 0.5)
    else
      _G[listFrameName .. "Button" .. index .. "Check"]:SetTexCoord(0.0, 0.5, 0.5, 1.0)
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:SetTexCoord(0.5, 1.0, 0.5, 1.0)
    end

    -- Checked can be a function now
    local checked = info.checked
    if type(checked) == "function" then
      checked = checked(button)
    end

    -- Show the check if checked
    if checked then
      button:LockHighlight()
      _G[listFrameName .. "Button" .. index .. "Check"]:Show()
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:Hide()
    else
      button:UnlockHighlight()
      _G[listFrameName .. "Button" .. index .. "Check"]:Hide()
      _G[listFrameName .. "Button" .. index .. "UnCheck"]:Show()
    end
  else
    _G[listFrameName .. "Button" .. index .. "Check"]:Hide()
    _G[listFrameName .. "Button" .. index .. "UnCheck"]:Hide()
  end
  button.checked = info.checked

  -- If has a colorswatch, show it and vertex color it
  local colorSwatch = _G[listFrameName .. "Button" .. index .. "ColorSwatch"]

  if info.hasColorSwatch then
    _G["DropDownList" .. level .. "Button" .. index .. "ColorSwatch" .. "NormalTexture"]
      :SetVertexColor(info.r, info.g, info.b)
    button.r = info.r
    button.g = info.g
    button.b = info.b
    colorSwatch:Show()
  else
    colorSwatch:Hide()
  end

  width = max(me.uiDropdown_GetButtonWidth(button), info.minWidth or 0)
  --Set maximum button width
  if width > listFrame.maxWidth then
    listFrame.maxWidth = width
  end

  -- Set the height of the listframe
  listFrame:SetHeight((index * uiDropdownMenuButtonHeight) + (uiDropdownMenuBorderHeight * 2))

  button:Show()
end

--[[
  Blizzard call UIDropDownMenu_GetMaxButtonWidth
]]--
function me.uiDropdownMenu_GetMaxButtonWidth(self)
  local maxWidth = 0

  for i = 1, self.numButtons do
    local button = _G[self:GetName() .. "Button" .. i]
    if button:IsShown() then
      local width = me.uiDropdown_GetButtonWidth(button)
      if width > maxWidth then
        maxWidth = width
      end
    end
  end

  return maxWidth
end

--[[
  Blizzard call UIDropDownMenu_GetButtonWidth

  @param {table} button
]]--
function me.uiDropdown_GetButtonWidth(button)
  local width
  local buttonName = button:GetName()
  local icon = _G[buttonName.."Icon"]
  local normalText = _G[buttonName.."NormalText"]

  if button.iconOnly and icon then
    width = icon:GetWidth()
  elseif normalText and normalText:GetText() then
    width = normalText:GetWidth() + 40

    if button.icon then
      -- Add padding for the icon
      width = width + 10
    end
  else
    return 0
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

  return width
end

--[[
  Blizzard call UIDropDownMenu_Refresh

  @param {table} frame
  @param {boolean} useValue
  @param {number} dropDownLevel
]]--
function me.uiDropdownMenu_Refresh(frame, useValue, dropdownLevel)
  local button, checked, checkImage, uncheckImage, width
  local maxWidth = 0
  local somethingChecked = nil

  if not dropdownLevel then
    dropdownLevel = uiDropdownMenuLevel
  end

  local listFrame = _G["DropDownList"..dropdownLevel]
  listFrame.numButtons = listFrame.numButtons or 0
  -- Just redraws the existing menu
  for i = 1, uiDropdownMenuMaxButtons do
    button = _G["DropDownList" .. dropdownLevel .. "Button" .. i]
    checked = nil

    if i <= listFrame.numButtons then
      -- See if checked or not
      if me.uiDropdownMenu_GetSelectedName(frame) then
        if button:GetText() == me.uiDropdownMenu_GetSelectedName(frame) then
          checked = 1
        end
      elseif me.uiDropdownMenu_GetSelectedID(frame) then
        if button:GetID() == me.uiDropdownMenu_GetSelectedID(frame) then
          checked = 1
        end
      elseif me.uiDropdownMenu_GetSelectedValue(frame) then
        if button.value == me.uiDropdownMenu_GetSelectedValue(frame) then
          checked = 1
        end
      end
    end

    if button.checked and type(button.checked) == "function" then
      checked = button.checked(button)
    end

    if not button.notCheckable and button:IsShown() then
      -- If checked show check image
      checkImage = _G["DropDownList" .. dropdownLevel .. "Button" .. i .. "Check"]
      uncheckImage = _G["DropDownList" .. dropdownLevel .. "Button" .. i .. "UnCheck"]

      if checked then
        somethingChecked = true
        local icon = _G[frame:GetName() .. "Icon"]

        if button.iconOnly and icon and button.icon then
          me.uiDropdownMenu_SetIconImage(icon, button.icon, button.iconInfo)
        elseif useValue then
          me.uiDropdownMenu_SetText(frame, button.value)
          icon:Hide()
        else
          me.uiDropdownMenu_SetText(frame, button:GetText())
          icon:Hide()
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
      width = me.uiDropdown_GetButtonWidth(button)
      if ( width > maxWidth ) then
        maxWidth = width
      end
    end
  end

  if somethingChecked == nil then
    me.uiDropdownMenu_SetText(frame, VIDEO_QUALITY_LABEL6)
  end

  if not frame.noResize then
    for i = 1, uiDropdownMenuMaxButtons do
      button = _G["DropDownList" .. dropdownLevel .. "Button" .. i]
      button:SetWidth(maxWidth)
    end
    me.uiDropdownMenu_RefreshDropDownSize(_G["DropDownList" .. dropdownLevel])
  end
end

--[[
  Blizzard call UIDropDownMenu_RefreshAll

  @param {table} frame
  @param {boolean} useValue
]]--
function me.uiDropdownMenu_RefreshAll(frame, useValue)
  for dropdownLevel = uiDropdownMenuLevel, 2, -1 do
    local listFrame = _G["DropDownList" .. dropdownLevel]

    if listFrame:IsShown() then
      me.uiDropdownMenu_Refresh(frame, nil, dropdownLevel)
    end
  end
  -- useValue is the text on the dropdown, only needs to be set once
  me.uiDropdownMenu_Refresh(frame, useValue, 1)
end

--[[
  Blizzard call UIDropDownMenu_SetIconImage

  @param {table} icon
  @param {string} texture
  @param {table} info
]]--
function me.uiDropdownMenu_SetIconImage(icon, texture, info)
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

--[[
  Blizzard call UIDropDownMenu_SetSelectedName

  @param {table} frame
  @param {string} name
  @param {boolean} useValue
]]--
function me.uiDropdownMenu_SetSelectedName(frame, name, useValue)
  frame.selectedName = name
  frame.selectedID = nil
  frame.selectedValue = nil
  me.uiDropdownMenu_Refresh(frame, useValue)
end

--[[
  Blizzard call UIDropDownMenu_SetSelectedValue

  @param {table} frame
  @param {string} name
  @param {boolean} useValue
]]--
function me.uiDropdownMenu_SetSelectedValue(frame, value, useValue)
  -- useValue will set the value as the text, not the name
  frame.selectedName = nil
  frame.selectedID = nil
  frame.selectedValue = value
  me.uiDropdownMenu_Refresh(frame, useValue)
end

--[[
  Blizzard call UIDropDownMenu_SetSelectedID

  @param {table} frame
  @param {number} id
  @param {boolean} useValue
]]--
function me.uiDropdownMenu_SetSelectedID(frame, id, useValue)
  frame.selectedID = id
  frame.selectedName = nil
  frame.selectedValue = nil
  me.uiDropdownMenu_Refresh(frame, useValue)
end

--[[
  Blizzard call UIDropDownMenu_GetSelectedName

  @param {table} frame

  @return {string}
]]--
function me.uiDropdownMenu_GetSelectedName(frame)
  return frame.selectedName
end

--[[
  Blizzard call UIDropDownMenu_GetSelectedID

  @param {table} frame

  @return {number}
]]--
function me.uiDropdownMenu_GetSelectedID(frame)
  if frame.selectedID then
    return frame.selectedID
  else
    -- If no explicit selectedID then try to send the id of a selected value or name
    local button

    for i = 1, uiDropdownMenuMaxButtons do
      button = _G["DropDownList" .. uiDropdownMenuLevel .. "Button" .. i]
      -- See if checked or not
      if me.uiDropdownMenu_GetSelectedName(frame) then
        if button:GetText() == me.uiDropdownMenu_GetSelectedName(frame) then
          return i
        end
      elseif me.uiDropdownMenu_GetSelectedValue(frame) then
        if button.value == me.uiDropdownMenu_GetSelectedValue(frame) then
          return i
        end
      end
    end
  end
end

--[[
  Blizzard call UIDropDownMenu_GetSelectedValue

  @param {table} frame

  @return {number}
]]--
function me.uiDropdownMenu_GetSelectedValue(frame)
  return frame.selectedValue
end

--[[
  Blizzard call UIDropDownMenuButton_OnClick

  @param {table} self
]]--
function me.uiDropdownMenuButton_OnClick(self)
  local checked = self.checked

  if type(checked) == "function" then
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

  if type(self.checked) ~= "function" then
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
    PlaySound("UChatScrollButton")
  end
end

--[[

  Blizzard call HideDropDownMenu

  @param {number} level
]]--
function me.HideDropDownMenu(level)
  local listFrame = _G["DropDownList" .. level]
  listFrame:Hide()
end


--[[
  Blizzard call ToggleDropDownMenu

  @param {number} level
  @param {number} value
  @param {table} dropDownFrame
  @param {string} anchorName
  @param {number} xOffset
  @param {number} yOffset
  @param {table} menuList
  @param {table} button
  @param {number} autoHideDelay
]]--
function me.ToggleDropDownMenu(
  level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay)

  if not level then
    level = 1
  end

  uiDropdownMenuDelegate:SetAttribute("createframes-level", level)
  uiDropdownMenuDelegate:SetAttribute("createframes-index", 0)
  uiDropdownMenuDelegate:SetAttribute("createframes", true)
  uiDropdownMenuLevel = level
  uiDropdownMenuValue = value

  local listFrame = _G["DropDownList" .. level]
  local listFrameName = "DropDownList" .. level
  local tempFrame
  local point, relativePoint, relativeTo

  if not dropDownFrame then
    tempFrame = button:GetParent()
  else
    tempFrame = dropDownFrame
  end

  if listFrame:IsShown() and (uiDropdownMenuOpenMenu == tempFrame) then
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
      uiDropdownMenuDelegate:SetAttribute("openmenu", dropDownFrame)
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
          relativeTo = uiDropdownMenuOpenMenu:GetName() .. "Left"
        end

        if dropDownFrame.relativePoint then
          relativePoint = dropDownFrame.relativePoint
        end
      elseif anchorName == "cursor" then
        relativeTo = nil

        local cursorX, cursorY = GetCursorPosition()

        cursorX = cursorX / uiScale
        cursorY =  cursorY / uiScale

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
        dropDownFrame = uiDropdownMenuOpenMenu
      end

      listFrame:ClearAllPoints()
      -- If this is a dropdown button, not the arrow anchor it to itself
      if string.sub(button:GetParent():GetName(), 0,12) == "DropDownList"
        and string.len(button:GetParent():GetName()) == 13 then
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
      _G[listFrameName.."Backdrop"]:Hide()
      _G[listFrameName.."MenuBackdrop"]:Show()
    else
      _G[listFrameName.."Backdrop"]:Show()
      _G[listFrameName.."MenuBackdrop"]:Hide()
    end

    dropDownFrame.menuList = menuList
    me.uiDropdownMenu_Initialize(dropDownFrame, dropDownFrame.initialize, nil, level, menuList)
    -- If no items in the drop down don't show it
    if listFrame.numButtons == 0 then
      return
    end

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
      listFrame.parentLevel = tonumber(string.match(anchorFrame:GetName(), "DropDownList(%d+)"))
      listFrame.parentID = anchorFrame:GetID()
      listFrame:SetPoint(point, anchorFrame, relativePoint, xOffset, yOffset)
    end

    if autoHideDelay and tonumber(autoHideDelay) then
      listFrame.showTimer = autoHideDelay
      listFrame.isCounting = 1
    end
  end
end

--[[
  Blizzard call CloseDropDownMenus

  @param {number} level
]]--
function me.CloseDropDownMenus(level)
  if not level then
    level = 1
  end
  for i = level, uiDropdownMenuMaxLevels do
    _G["DropDownList" .. i]:Hide()
  end
end

--[[
  Blizzard call UIDropDownMenu_OnHide
]]--
function me.uiDropdownMenu_OnHide(self)
  local id = self:GetID()

  if self.onHide then
    self.onHide(id + 1)
    self.onHide = nil
  end

  me.CloseDropDownMenus(id + 1)
  uiDropdownMenuOpenMenus[id] = nil

  if id == 1 then
    uiDropdownMenuOpenMenu = nil
  end
end

--[[
  Blizzard call UIDropDownMenu_SetWidth

  @param {table} frame
  @param {number} width
  @param {number} padding
]]--
function me.uiDropdownMenu_SetWidth(frame, width, padding)
  _G[frame:GetName() .. "Middle"]:SetWidth(width)
  local defaultPadding = 25

  if padding then
    frame:SetWidth(width + padding)
  else
    frame:SetWidth(width + defaultPadding + defaultPadding)
  end

  if padding then
    _G[frame:GetName() .. "Text"]:SetWidth(width)
  else
    _G[frame:GetName() .. "Text"]:SetWidth(width - defaultPadding)
  end

  frame.noResize = 1
end

--[[
  Blizzard call UIDropDownMenu_SetButtonWidth

  @param {table} frame
  @param {number} width
]]--
function me.uiDropdownMenu_SetButtonWidth(frame, width)
  if width == "TEXT" then
    width = _G[frame:GetName() .. "Text"]:GetWidth()
  end

  _G[frame:GetName() .. "Button"]:SetWidth(width)
  frame.noResize = 1
end

--[[
  Blizzard call UIDropDownMenu_SetText

  @param {table} frame
  @param {string} text
]]--
function me.uiDropdownMenu_SetText(frame, text)
  local filterText = _G[frame:GetName() .. "Text"]
  filterText:SetText(text)
end

--[[
  Blizzard call UIDropDownMenu_GetText

  @param {table} frame

  @return {string}
]]--
function me.uiDropdownMenu_GetText(frame)
  local filterText = _G[frame:GetName() .. "Text"]
  return filterText:GetText()
end

--[[
  Blizzard call UIDropDownMenu_ClearAll

  @param {table} frame
]]--
function me.uiDropdownMenu_ClearAll(frame)
  -- Previous code refreshed the menu quite often and was a performance bottleneck
  frame.selectedID = nil
  frame.selectedName = nil
  frame.selectedValue = nil
  me.uiDropdownMenu_SetText(frame, "")

  local button, checkImage, uncheckImage

  for i = 1, uiDropdownMenuMaxButtons do
    button = _G["DropDownList" .. uiDropdownMenuLevel .. "Button" .. i]
    button:UnlockHighlight()

    checkImage = _G["DropDownList" .. uiDropdownMenuLevel .. "Button" .. i .. "Check"]
    checkImage:Hide()
    uncheckImage = _G["DropDownList" .. uiDropdownMenuLevel .. "Button" .. i .. "UnCheck"]
    uncheckImage:Hide()
  end
end

--[[
  Blizzard call UIDropDownMenu_JustifyText

  @param {table} frame
  @param {string} justification
]]--
function me.uiDropdownMenu_JustifyText(frame, justification)
  local text = _G[frame:GetName() .. "Text"]
  text:ClearAllPoints()

  if justification == "LEFT" then
    text:SetPoint("LEFT", frame:GetName() .. "Left", "LEFT", 27, 2)
    text:SetJustifyH("LEFT")
  elseif justification == "RIGHT" then
    text:SetPoint("RIGHT", frame:GetName() .. "Right", "RIGHT", -43, 2)
    text:SetJustifyH("RIGHT")
  elseif justification == "CENTER" then
    text:SetPoint("CENTER", frame:GetName() .. "Middle", "CENTER", -5, 2)
    text:SetJustifyH("CENTER")
  end
end

--[[
  Blizzard call UIDropDownMenu_SetAnchor

  @param {table} dropdown
  @param {number} xOffset
  @param {number} yOffset
  @param {string} point
  @param {string} relativeTo
  @param {string} relativePoint

]]--
function me.uiDropdownMenu_SetAnchor(dropdown, xOffset, yOffset, point, relativeTo, relativePoint)
  dropdown.xOffset = xOffset
  dropdown.yOffset = yOffset
  dropdown.point = point
  dropdown.relativeTo = relativeTo
  dropdown.relativePoint = relativePoint
end

--[[
  Blizzard call UIDropDownMenu_GetCurrentDropDown

  @return {table}
]]--
function me.uiDropdownMenu_GetCurrentDropDown()
  if uiDropdownMenuOpenMenu then
    return uiDropdownMenuOpenMenu
  elseif uiDropdownMenuInitMenu then
    return uiDropdownMenuInitMenu
  end
end

--[[
  Blizzard call UIDropDownMenuButton_GetChecked

  @param {table} self

  @return {boolean}
]]--
function me.uiDropdownMenuButton_GetChecked(self)
  return _G[self:GetName() .. "Check"]:IsShown()
end

--[[
  Blizzard call UIDropDownMenuButton_GetName

  @param {table} self

  @return {string}
]]--
function me.uiDropdownMenuButton_GetName(self)
  return _G[self:GetName() .. "NormalText"]:GetText()
end

--[[
  Blizzard call UIDropDownMenuButton_OpenColorPicker

  @param {table} self
  @param {table} button
]]--
function me.uiDropdownMenuButton_OpenColorPicker(self, button)
  CloseMenus()
  if not button then
    button = self
  end
  uiDropdownMenuValue = button.value
  me.OpenColorPicker(button)
end

--[[
  Blizzard call UIDropDownMenu_DisableButton

  @param {number} level
  @param {number} id
]]--
function me.uiDropdownMenu_DisableButton(level, id)
  _G["DropDownList" .. level .. "Button" .. id]:Disable()
end

--[[
  Blizzard call UIDropDownMenu_EnableButton

  @param {number} level
  @param {number} id
]]--
function me.uiDropdownMenu_EnableButton(level, id)
  _G["DropDownList" .. level .. "Button" .. id]:Enable()
end

--[[
  Blizzard call UIDropDownMenu_SetButtonText

  @param {number} level
  @param {number} id
  @param {string} text
  @param {string} colorCode
]]--
function me.uiDropdownMenu_SetButtonText(level, id, text, colorCode)
  local button = _G["DropDownList" .. level .. "Button" .. id]

  if colorCode then
    button:SetText(colorCode .. text .. "|r")
  else
    button:SetText(text)
  end
end

--[[
  Blizzard call UIDropDownMenu_SetButtonNotClickable

  @param {number} level
  @param {number} id
]]--
function me.uiDropdownMenu_SetButtonNotClickable(level, id)
  _G["DropDownList" .. level .. "Button" .. id]:SetDisabledFontObject(GameFontHighlightSmallLeft)
end

--[[
  Blizzard call UIDropDownMenu_SetButtonClickable

  @param {number} level
  @param {number} id
]]--
function me.uiDropdownMenu_SetButtonClickable(level, id)
  _G["DropDownList" .. level .. "Button" .. id]:SetDisabledFontObject(GameFontDisableSmallLeft)
end


--[[
  Blizzard call UIDropDownMenu_DisableDropDown

  @param {table} dropdown
]]--
function me.uiDropdownMenu_DisableDropDown(dropdown)
  local label = _G[dropdown:GetName() .. "Label"]

  if label then
    label:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
  end

  _G[dropdown:GetName() .. "Text"]
    :SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
  _G[dropdown:GetName() .. "Button"]:Disable()
  dropdown.isDisabled = 1
end

--[[
  Blizzard call UIDropDownMenu_EnableDropDown

  @param {table} dropdown
]]--
function me.uiDropdownMenu_EnableDropDown(dropdown)
  local label = _G[dropdown:GetName() .. "Label"]

  if label then
    label:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
  end

  _G[dropdown:GetName() .. "Text"]
    :SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
  _G[dropdown:GetName() .. "Button"]:Enable()
  dropdown.isDisabled = nil
end

--[[
  Blizzard call UIDropDownMenu_IsEnabled

  @param {table} dropdown
]]--
function me.uiDropdownMenu_IsEnabled(dropdown)
  return not dropdown.isDisabled
end

--[[
  Blizzard call UIDropDownMenu_GetValue

  @param {number} id
]]--
function me.uiDropdownMenu_GetValue(id)
  --Only works if the dropdown has just been initialized, lame, I know =(
  local button = _G["DropDownList1Button" .. id]

  if button then
    return _G["DropDownList1Button" .. id].value
  else
    return nil
  end
end

--[[
  Blizzard call OpenColorPicker

  @param {table} info
]]--
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

--[[
  Blizzard call ColorPicker_GetPreviousValues

  @return {number, number, number}
]]--
function me.ColorPicker_GetPreviousValues()
  return ColorPickerFrame.previousValues.r, ColorPickerFrame.previousValues.g, ColorPickerFrame.previousValues.b
end
