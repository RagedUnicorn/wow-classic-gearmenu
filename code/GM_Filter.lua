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

local mod = rggm
local me = {}

mod.filter = me

local filters = {}

--[[
  Register a new pattern in the form of a string to the filterlist. A pattern can be a simple string
  or a regular expression to filter for.

  @param {String} name
    Name of the filter for easy deregistering
  @param {string} pattern
    A pattern (regular expression) or a simple string to filter for
]]--
function me.RegisterFilter(name, pattern)
  local filter = {
    ["name"] = name,
    ["filter"] = pattern
  }

  table.insert(filters, filter)
end

--[[
  Deregister a previously filtered tag in the form of a string from the filterlist.
  If the tag is not filtered this has no effect.

  @param {string} name
    A name name to filter
]]--
function me.DeregisterFilter(name)
  for i = 1, table.getn(filters) do
    if filters[i].name == name then
      table.remove(filters, i)
      break
    end
  end
end

--[[
  @param {string} tag

  @return {boolean}
    true - if the tag should be filtered
    false - if the tag should not be filtered
]]--
function me.ShouldFilterTag(tag)
  for i = 1, table.getn(filters) do
    if string.match(tag, filters[i].filter) then
      return true
    end
  end

  return false
end
