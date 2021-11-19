--[=====[3|Example-Dependency]=====]
-- Change the number above locally, then update (with cache force refresh if needed) to cause it to update.

-- This is an example "repository" - pretend this file is a single repo on github.
local printer = {}

function printer.print(...)
  local old = term.getTextColor()
  term.setTextColor(math.random(1, 15))
  print(...)
  term.setTextColor(old)
end

return printer
