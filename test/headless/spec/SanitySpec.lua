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
  Sanity check that the busted harness is wired correctly: the bootstrap globals are present and the
  pure modules (Constants, Logger) loaded headlessly with no WoW client running.
]]--

-- busted extends `assert` with .same / .equal / etc. at runtime; luacheck
-- cannot verify those fields statically. Suppress warning 143 (accessing
-- undefined field of a global variable) for this file.
-- luacheck: globals describe it
-- luacheck: ignore 143

describe("test harness", function()
  it("creates the rggm namespace", function()
    assert.is_table(rggm)
  end)

  it("shims the addon environment", function()
    assert.is_table(RGGM_ENVIRONMENT)
    assert.are.equal(4, RGGM_ENVIRONMENT.LOG_LEVEL)
  end)

  it("loads code/Constants.lua (defines RGGM_CONSTANTS)", function()
    assert.is_table(RGGM_CONSTANTS)
    assert.are.equal("GearMenu", RGGM_CONSTANTS.ADDON_NAME)
  end)

  it("loads code/Logger.lua (defines rggm.logger)", function()
    assert.is_table(rggm.logger)
    assert.is_function(rggm.logger.LogDebug)
    assert.are.equal(RGGM_ENVIRONMENT.LOG_LEVEL, rggm.logger.logLevel)
  end)
end)
