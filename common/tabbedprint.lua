--- Like print, but will tab each line forward so that it's level with the current cursor position (or given x value)

local expect = require "cc.expect".expect
local strings = require "cc.strings"

local tabbedprint = {}

--- See module information
-- @param ... The information to be printed.
function tabbedprint.print(...)
  local x, y = term.getCursorPos()
  local mX = term.getSize()
  local width = mX - x
  local arguments = table.pack(...)

  for i, thing in ipairs(arguments) do
    arguments[i] = tostring(thing)
  end

  local text = table.concat(arguments, ' ')
  local split = strings.wrap(text, width)

  for i, str in ipairs(split) do
    local _x, _y = term.getCursorPos()
    term.setCursorPos(x, _y)
    print(str)
  end
end

--- See module information
-- @tparam number x The left x position that the text is aligned to.
function tabbedprint.printAt(x, ...)
  expect(1, x, "number")
  if x <= 0 then
    error(string.format("Bad argument #1: Expected number > 0, got %d", x), 2)
  end

  local _, y = term.getCursorPos()
  term.setCursorPos(x, y)
  tabbedprint.print(...)
end

return tabbedprint
