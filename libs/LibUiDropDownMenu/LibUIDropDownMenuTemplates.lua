-- luacheck: globals CreateFrame ExecuteFrameScript CreateFromMixins PlaySound SOUNDKIT

local mod = rggm
local me = {}
mod.libUIDropDownMenuTemplates = me

me.tag = "LibUIDropDownMenuTemplates"

local DropDownMenuButtonMixin = {}

function DropDownMenuButtonMixin:OnEnter(...)
  ExecuteFrameScript(self:GetParent(), "OnEnter", ...)
end

function DropDownMenuButtonMixin:OnLeave(...)
  ExecuteFrameScript(self:GetParent(), "OnLeave", ...)
end

function DropDownMenuButtonMixin:OnMouseDown()
  if self:IsEnabled() then
    mod.libUIDropDownMenu.ToggleDropDownMenu(nil, nil, self:GetParent())
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

local LargeDropDownMenuButtonMixin = CreateFromMixins(DropDownMenuButtonMixin)

function LargeDropDownMenuButtonMixin:OnMouseDown()
  if self:IsEnabled() then
    local parent = self:GetParent()
    mod.libUIDropDownMenu.ToggleDropDownMenu(nil, nil, parent, parent, -8, 8)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

-- luacheck: ignore 241
local DropDownExpandArrowMixin = {}

function DropDownExpandArrowMixin:OnEnter()
  local level =  self:GetParent():GetParent():GetID() + 1

  mod.libUIDropDownMenu.CloseDropDownMenus(level)

  if self:IsEnabled() then
    local listFrame = _G["RGGM_DropDownList" .. level]

    if not listFrame or not listFrame:IsShown() or select(2, listFrame:GetPoint()) ~= self then
      mod.libUIDropDownMenu.ToggleDropDownMenu(
        level,
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
end

function DropDownExpandArrowMixin:OnMouseDown()
  if self:IsEnabled() then
    mod.libUIDropDownMenu.ToggleDropDownMenu(
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

local UiDropDownCustomMenuEntryMixin = {}

function UiDropDownCustomMenuEntryMixin:GetPreferredEntryWidth()
  return self:GetWidth()
end

-- luacheck: ignore 212
function UiDropDownCustomMenuEntryMixin:OnSetOwningButton()
  -- for derived objects to implement
end

function UiDropDownCustomMenuEntryMixin:SetOwningButton(button)
  self:SetParent(button:GetParent())
  self.owningButton = button
  self:OnSetOwningButton()
end

function UiDropDownCustomMenuEntryMixin:GetOwningDropdown()
  return self.owningButton:GetParent()
end

function UiDropDownCustomMenuEntryMixin:SetContextData(contextData)
  self.contextData = contextData
end

function UiDropDownCustomMenuEntryMixin:GetContextData()
  return self.contextData
end

function me.Create_UIDropDownCustomMenuEntry(name, parent)
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
