--- A utility module which will parse arguments given to a program.
-- @module argparser
-- @author Fatboychummy

local argparser = {}

-- @table parsers The different parser function which check for arguments or flags.
local parsers = {
  {
    "^%-%-(.-)=(.+)",
    function(self, flag, value) -- Parse flags like "--flag=value"
      self.flags[flag] = value
    end
  },
  {
    "^%-%-(.+)",
    function(self, flag) -- Parse flags like "--flag"
      self.flags[flag] = true
    end
  },
  {
    "^%-(.+)",
    function(self, flag) -- Parse flags like "-fabc"
      for char in flag:gmatch(".") do
        self.flags[char] = true
      end
    end
  },
  {
    ".+",
    function(self, arg) -- Parse normal arguments
      self.args.n = self.args.n + 1
      self.args[self.args.n] = arg
    end
  }
}
parsers.n = #parsers

--- Parse the given arguments.
-- @tparam any ... Arguments given to the program.
-- @treturn args Parsed arguments as a table, key "flags" holds any "-xyz" flags, key "args" hold the rest.
function argparser.parse(...)
  -- @type args The returned table of arguments and flags
  local args = {
    flags = {},    -- The flags given by the user.
    args = {n = 0} -- The normal arguments given by the user.
  }

  local input = table.pack(...)

  -- for each input argument
  for i = 1, input.n do
    -- and for each parser
    for j = 1, parsers.n do
      -- attempt to parse the current input argument using current parser
      local matches = table.pack(input[i]:match(parsers[j][1]))
      if matches[1] then -- if passed:
        -- run the parser, and go to the next argument.
        parsers[j][2](args, table.unpack(matches, 1, matches.n))
        break
      end
    end
  end

  return args
end

return argparser
