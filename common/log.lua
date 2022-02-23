--- Log library for helpful output.
-- @module log

local log = {}

local function writeLog(logObj, level, ...)
  local arguments = table.pack(...)
  for i = 1, arguments.n do
    arguments[i] = tostring(arguments[i])
  end
  local text = table.concat(arguments, ' ')

  local time = os.epoch("utc") - logObj.StartTime

  print(string.format("[%s][%s][%d]: %s", level, logObj.Name, time, text))
end

local _LOG_IDENTIFIER = {}
local function checkself(self)
  if type(self) ~= "table" or self.__IDENTIFIER ~= _LOG_IDENTIFIER then
    error("Expected ':' when calling method on Logger object.", 3)
  end
end

--- Create a new log system
-- @tparam string name The name of this log system.
-- @treturn Logger
function log.create(name)
  -- @type Logger
  local logger = {
    Name = name, -- The name of this log, displayed in the output.
    Level = 0, -- Logging level: 0 = all, 1 = warns/errors, 2 = errors only
    __IDENTIFIER = _LOG_IDENTIFIER, -- This allows us to check for the usage of ':', and throw an error when it's missing.
    StartTime = os.epoch("utc")
  }

  function logger:info(...)
    checkself(self)

    if self.Level == 0 then
      writeLog(self, "INFO", ...)
    end
  end
  function logger:warn(...)
    checkself(self)

    if self.Level < 3 then
      local old = term.getTextColor()
      term.setTextColor(colors.yellow)
      writeLog(self, "WARN", ...)
      term.setTextColor(old)
    end
  end
  function logger:error(...)
    checkself(self)

    local old = term.getTextColor()
    term.setTextColor(colors.red)
    writeLog(self, "ERR ", ...)
    term.setTextColor(old)
    error("", 0)
  end
  function logger:trace(...)
    checkself(self)

    if self.Level == 0 then
      local old = term.getTextColor()
      term.setTextColor(colors.orange)
      writeLog(self, "TRCE", ...)
      term.setTextColor(old)
    end
  end

  return logger
end

return log
