--[[
  MIT License

  Copyright (c) 2020 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- luacheck: globals STANDARD_TEXT_FONT

local mod = rggm
local me = {}

mod.aboutContent = me

me.tag = "AboutContent"

--[[
  Main tab for addon - show about content

  @param {table} frame
]]--
function me.BuildAboutContent(frame)
  local ragedUnicornLogo  = frame:CreateTexture(RGGM_CONSTANTS.ELEMENT_ABOUT_LOGO, "ARTWORK")
  ragedUnicornLogo:SetPoint("TOP", 0, -20)
  ragedUnicornLogo:SetSize(256, 256)
  ragedUnicornLogo:SetTexture("Interface\\AddOns\\GearMenu\\assets\\logo_ragedunicorn")

  local authorFontString = frame:CreateFontString(RGGM_CONSTANTS.ELEMENT_ABOUT_AUTHOR_FONT_STRING, "OVERLAY")
  authorFontString:SetFont(STANDARD_TEXT_FONT, 15)
  authorFontString:SetPoint("TOP", 0, -300)
  authorFontString:SetText(rggm.L["author"])

  local emailFontString = frame:CreateFontString(RGGM_CONSTANTS.ELEMENT_ABOUT_EMAIL_FONT_STRING, "OVERLAY")
  emailFontString:SetFont(STANDARD_TEXT_FONT, 15)
  emailFontString:SetPoint("TOP", 0, -320)
  emailFontString:SetText(rggm.L["email"])

  local versionFontString = frame:CreateFontString(RGGM_CONSTANTS.ELEMENT_ABOUT_VERSION_FONT_STRING, "OVERLAY")
  versionFontString:SetFont(STANDARD_TEXT_FONT, 15)
  versionFontString:SetPoint("TOP", 0, -340)
  versionFontString:SetText(rggm.L["version"])

  local issueFontString = frame:CreateFontString(RGGM_CONSTANTS.ELEMENT_ABOUT_ISSUES_FONT_STRING, "OVERLAY")
  issueFontString:SetFont(STANDARD_TEXT_FONT, 15)
  issueFontString:SetPoint("TOP", 0, -360)
  issueFontString:SetText(rggm.L["issues"])
end
