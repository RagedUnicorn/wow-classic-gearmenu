
-- luacheck: globals CreateFrame ExecuteFrameScript CreateFromMixins PlaySound SOUNDKIT
-- luacheck: globals RGGM_ToggleDropDownMenu RGGM_CloseDropDownMenus RGGM_Create_UIDropDownCustomMenuEntry

local RGGM_DropDownMenuButtonMixin = {}

function RGGM_DropDownMenuButtonMixin:OnEnter(...)
  ExecuteFrameScript(self:GetParent(), "OnEnter", ...)
end

function RGGM_DropDownMenuButtonMixin:OnLeave(...)
  ExecuteFrameScript(self:GetParent(), "OnLeave", ...)
end

function RGGM_DropDownMenuButtonMixin:OnMouseDown()
  if self:IsEnabled() then
    RGGM_ToggleDropDownMenu(nil, nil, self:GetParent())
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

local RGGM_LargeDropDownMenuButtonMixin = CreateFromMixins(RGGM_DropDownMenuButtonMixin)

function RGGM_LargeDropDownMenuButtonMixin:OnMouseDown()
  if self:IsEnabled() then
    local parent = self:GetParent()
    RGGM_ToggleDropDownMenu(nil, nil, parent, parent, -8, 8)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

-- luacheck: ignore 241
local RGGM_DropDownExpandArrowMixin = {}

function RGGM_DropDownExpandArrowMixin:OnEnter()
  local level =  self:GetParent():GetParent():GetID() + 1

  RGGM_CloseDropDownMenus(level)

  if self:IsEnabled() then
    local listFrame = _G["RGGM_DropDownList" .. level]

    if not listFrame or not listFrame:IsShown() or select(2, listFrame:GetPoint()) ~= self then
      RGGM_ToggleDropDownMenu(level, self:GetParent().value, nil, nil, nil, nil, self:GetParent().menuList, self)
    end
  end
end

function RGGM_DropDownExpandArrowMixin:OnMouseDown()
  if self:IsEnabled() then
    RGGM_ToggleDropDownMenu(
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
end

-- luacheck: ignore 241
local RGGM_UIDropDownCustomMenuEntryMixin = {}

function RGGM_UIDropDownCustomMenuEntryMixin:GetPreferredEntryWidth()
  return self:GetWidth()
end

-- luacheck: ignore 212
function RGGM_UIDropDownCustomMenuEntryMixin:OnSetOwningButton()
  -- for derived objects to implement
end

function RGGM_UIDropDownCustomMenuEntryMixin:SetOwningButton(button)
  self:SetParent(button:GetParent())
  self.owningButton = button
  self:OnSetOwningButton()
end

function RGGM_UIDropDownCustomMenuEntryMixin:GetOwningDropdown()
  return self.owningButton:GetParent()
end

function RGGM_UIDropDownCustomMenuEntryMixin:SetContextData(contextData)
  self.contextData = contextData
end

function RGGM_UIDropDownCustomMenuEntryMixin:GetContextData()
  return self.contextData
end

function RGGM_Create_UIDropDownCustomMenuEntry(name, parent)
  local f = _G[name] or CreateFrame("Frame", name, parent or nil)
  f:EnableMouse(true)
  f:Hide()

  -- I am not 100% sure if below works for replacing the mixins
  f:SetScript("GetPreferredEntryWidth", function(self)
    return self:GetWidth()
  end)
  f:SetScript("SetOwningButton", function(self, button)
    self:SetParent(button:GetParent())
    self.owningButton = button
    self:OnSetOwningButton()
  end)
  f:SetScript("GetOwningDropdown", function(self)
    return self.owningButton:GetParent()
  end)
  f:SetScript("SetContextData", function(self, contextData)
    self.contextData = contextData
  end)
  f:SetScript("GetContextData", function(self)
    return self.contextData
  end)

  return f
end
