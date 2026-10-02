--[[
  MIT License

  Copyright (c) 2026 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

--[[
  Spec for the recording frames of WowStubs.stubs.FrameRegistry: Show / Hide run the OnShow /
  OnHide script the way the client does, so visibility-driven code paths can be tested headlessly.
]]--

local wowStubs = require("WowStubs")

describe("WowStubs frame registry", function()
  local frame
  local fired

  before_each(function()
    frame = wowStubs.stubs.FrameRegistry().CreateFrame("Frame", "GM_TestFrame")
    fired = {}

    frame:SetScript("OnShow", function(self) fired[#fired + 1] = { "OnShow", self } end)
    frame:SetScript("OnHide", function(self) fired[#fired + 1] = { "OnHide", self } end)
  end)

  it("starts shown and does not fire OnShow for a Show on a shown frame", function()
    frame:Show()

    assert.is_false(frame.hidden)
    assert.are.same({}, fired)
  end)

  it("fires OnHide once with the frame as self, however often Hide is called", function()
    frame:Hide()
    frame:Hide()

    assert.is_true(frame.hidden)
    assert.are.equal(1, #fired)
    assert.are.equal("OnHide", fired[1][1])
    assert.are.equal(frame, fired[1][2])
  end)

  it("fires OnShow once when a hidden frame is shown again", function()
    frame:Hide()
    frame:Show()
    frame:Show()

    assert.is_false(frame.hidden)
    assert.are.equal(2, #fired)
    assert.are.equal("OnShow", fired[2][1])
    assert.are.equal(frame, fired[2][2])
  end)

  it("only toggles the visibility of a frame without scripts", function()
    local plain = wowStubs.stubs.FrameRegistry().CreateFrame("Frame")

    assert.has_no.errors(function()
      plain:Hide()
      plain:Show()
    end)
    assert.is_false(plain.hidden)
  end)
end)
