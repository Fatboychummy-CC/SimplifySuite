--[=====[1|Simplify-Suite]=====]

local remotes = {
  SuiteRoot = "https://raw.githubusercontent.com/Fatboychummy-CC/SimplifySuite/main/",
  AllRepos = "Repos/All.csv",
  Simplifile = "Simplifile"
}
local sources = {
  HTTP  = 0,
  LOCAL = 1
}
local LOCAL_CACHE_NAME = "/.SimplifySuiteCache"
local CACHE_EXPIRY_TIME = 1000 * 60 * 30 -- 30 minutes by default

local log = {
  Low = function(...)
    term.setTextColor(colors.gray)
    print(...)
  end,
  Normal = function(...)
    term.setTextColor(colors.white)
    print(...)
  end,
  Medium = function(...)
    term.setTextColor(colors.yellow)
    print(...)
  end,
  High = function(...)
    term.setTextColor(colors.red)
    print(...)
  end,
  Error = function(...)
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    print(...)
    term.setBackgroundColor(colors.black)
  end,
}
local oe = error
local function error(a)
  log.Error(a)
  oe("", 0)
end

-- download a single file and return it as an array of lines.
local function getLines(lineFunc)
  local lines = {n = 0}

  for line in lineFunc do
    lines.n = lines.n + 1
    lines[lines.n] = line
  end

  return lines
end
local function linedFile(source)
  if source.Source == sources.HTTP then
    local h, err = http.get(source.Address)
    if h then
      local lines = getLines(h.readLine)
      h.close()

      return true, lines
    end
    return false, {err, n = 1}
  elseif source.Source == sources.LOCAL then
    if h then
      return true, getLines(io.lines(source.Filename))
    end
    return false, {n = 0}
  end
end

local function downloadFile(source, destination)
  -- grab the file.
  local h = http.get(source)
  if not h then
    error("Failed to connect.")
  end
  local data = h.readAll()
  h.close()

  -- write the file
  local h2 = io.open(destination, 'w')
  if not h2 then
    error("Failed to open file for writing.")
  end
  h2:write(data):close()
end

-- remove spaces from a line of text.
local function trimWhitespace(line)
  return line:gsub(' ', "")
end

-- reads a remote CSV file.
local function readCSV(source)
  local data = {packages = {}}

  local ok, lines = linedFile(source)
  if not ok then error(lines) end

  for i = 2, lines.n do -- ignore the first line.
    local line = trimWhitespace(lines[i])
    local lineData = {}
    for value in line:gmatch("[^,]+") do
      lineData[#lineData + 1] = value
    end
    data[i - 1] = lineData
  end

  return data
end

local function getCache()
  if not _G._SimplifySuiteCache then
    _G._SimplifySuiteCache = {
      Remote = {Expiry = -math.huge},
      RemoteInfo = {}
      Local = {Expiry = -math.huge},
    }
  end

  return _G._SimplifySuiteCache
end

-- Open the cache file and read which packages are installed locally.
local function getLocalPackages(filename, force)
  local cache = getCache()
  if force or cache.Local.Expiry < os.epoch() then
    if force then
      log.Normal("Force updating the cache for local packages.")
    else
      log.Normal("Local cache is out-of-date, updating it.")
    end

    -- read local package information
    local data = readCSV {
      Source   = sources.LOCAL,
      Filename = LOCAL_CACHE_NAME
    }

    -- cache it in format we want.
    cache.Local.Packages = {}
    for i, item in ipairs(data) do
      -- format: {Build#, Package-Name}
      cache.Local.Packages[item[2]] = tonumber[item[1]]
    end
    cache.Local.Expiry = os.epoch() + CACHE_EXPIRY_TIME
  end

  return cache.Local
end

-- Grab remote package information.
local function getRemotePackages(force)
  local cache = getCache()
  if force or cache.Remote.Expiry < os.epoch() then
    if force then
      log.Normal("Force updating the cache for remote packages.")
    else
      log.Normal("Remote cache is out-of-date, updating it.")
    end

    -- download and parse the file
    local data = readCSV {
      Source  = sources.HTTP,
      Address = remotes.SuiteRoot .. remotes.AllRepos
    }

    -- update remote cache
    cache.Remote.Packages = {}
    for i, item in ipairs(data) do
      -- format: {Build#, Package-Name}
      cache.Remote.Packages[item[2]] = tonumber[item[1]]
    end
    cache.Remote.Expiry = os.epoch() + CACHE_EXPIRY_TIME
  end

  return cache.Remote
end

local function downloadPackageInfo(packageName, force)
  local address = string.format("%sRepos/%s.csv", remotes.SuiteRoot, packageName)
  log.Low("Downloading package information from", address)
  local data = readCSV {
    Source  = source.HTTP,
    Address = address
  }
  log.Low("Done.")

  return data
end

local function resolveDependencies(packageName, force, data)
  log.Normal("Resolving", packageName)
  data = data or {Files = {}, Depends = {}}
  local _data = downloadPackageInfo(packageName)

  -- for each returned dependency, assign the highest required build version needed.
  for k, v in pairs(_data) do
    if not data[k] or data[k] < v then
      data[k] = v
    end
  end

  --[[
    TYPE, FILENAME/MIN, REMOTE_LOCATION/PACKAGE
    DEP , 2           , Example-Dependency
    FILE,./echo.lua   , https://raw.githubusercontent.com/Fatboychummy-CC/SimplifySuite/main/Examples/echo.lua
  ]]
  if not data.Files[packageName] then
    data.Files[packageName] = {}
  end

  for _, item in ipairs(data) do
    if item[1] == "DEP" then
      log.Low("Found dependency", item[3])
      if data.Depends[item[3]] then
        if data.Depends[item[3]] < tonumber(item[2]) then
          data.Depends[item[3]] = tonumber(item[2])
        end
      else
        data.Depends[item[3]] = tonumber(item[2])
        resolveDependencies(item[2], force, data)
      end
    elseif item[1] == "FILE" then
      if data.Files[packageName][item[2]] then
        if data.Files[item[2]] ~= item[3] then
          error("Packages have conflicting files. Please install in seperate directories.")
        end
      else
        data.files[item[2]] = item[3]
      end
      if not data.Files[packageName][item[2]] then
        data.Files[packageName][item[2]] = item[3]
      end
    else
      error(string.format("Unknown specifier '%s' in file.", item[1]))
    end
  end

  return data
end

local function reinstallPackage(packageName, force)

end

-- Update a package.
local function updatePackage(packageName, force, dontDoDeps, data)
  local remotes = getRemotePackages(force).Packages
  local locals = getLocalPackages(LOCAL_CACHE_NAME, force)
  if not remotes.Packages[packageName] then
    return false, string.format("Could not find package '%s'.", packageName)
  end
  if not locals.Packages[packageName] then
    log.Medium("Package", packageName, "is not installed. It will be installed.")
  end
  if not force and remotes.Packages[packageName] == locals.Packages[packageName] then
    return false, string.format("Package '%s' is already up-to-date.", packageName)
  end
  if not force and remotes.Packages[packageName] < locals.Packages[packageName] then
    return false, string.format("Package '%s' is a higher version locally than the remote version. ", packageName)
  end

  -- all checks done, package on remote must be higher version than local.
  -- download package information and check dependencies
  log.Normal("Resolving Dependencies.")
  data = data or resolveDependencies(packageName, force)

  -- check all dependencies are installed (if we aren't doing this operation from a parent updatePackage call)
  if not dontDoDeps then
    for _packageName, version in pairs(data.Packages) do
      log.Normal("Checking package", _packageName, "(", version, ")")
      if updatePackage(_packageName, force, true, data) then
        log.Normal("Installed or updated", _packageName)
      else
        log.Medium("Skipped", _packageName)
      end
    end
  end

  -- install files required for this dependency.
  for filename, remoteAddress in pairs(data.Files[packageName])) do
    log.Low("Downloading", filename, "from", remoteAddress)
    downloadFile(remoteAddress, filename)
  end

  if not dontDoDeps then
    log.Normal("Done.")
  end
  return true
end

-- Install a package.
local function installPackage(packageName, force)
  local locals = getLocalPackages(LOCAL_CACHE_NAME, force)

  if locals.Packages[packageName] then
    return false, string.format("Package '%s' is already installed. To update it, use args \"--update (or -u)\".")
  end

  return updatePackage(packageName, force)
end

local parsers = {
  {"^%-%-(.-)=\"?\'?(.-)\'?\"?$", function(args, flag, data)

  end},
  {"^%-%-(.+)$", function(args, flag)

  end},
  {"^%-(.+)$", function(args, flag)

  end},
  {"^.+$", function(args, argument)

  end}
}

local function quotize(_args)
  local args = {}
  local n = 0
  local inDouble, inSingle, escape = false, false, 2

  -- check if a character is not escaped, and is equal to another character
  local function eqNoEscape(charA, charB)
    return escape == 0 and charA == charB
  end

  -- insert argument into thingy
  local function insert(thonk)
    n = n + 1
    args[n] = thonk
  end

  -- for each argument
  for _, arg in ipairs(_args) do
    local mark, hit = false, false

    -- if we're already inside quotes, note it for later.
    if inDouble or inSingle then
      mark = true
    end

    -- then check each character in a string for quotes.
    -- sure I could use patterns for this but I am too tired to figure out what
    -- kind of pattern I'd need for this.
    for char in string.gmatch(arg, ".") do
      if eqNoEscape(char, "\\") then
        escape = 2 -- mark that the next character is escaped.
      elseif inDouble and eqNoEscape(char, '"') then
        inDouble = false -- we aren't in double quotes
        hit = true -- mark that we should be at the end of the string.
      elseif inSingle and eqNoEscape(char, "'") then
        inSingle = false
        hit = true
      else
        if eqNoEscape(char, '"') then
          inDouble = true -- we entered a double quote
        elseif eqNoEscape(char, "'") then
          inSingle = true -- we entered a single quote
        elseif hit then
          error("Mismatching quotes.")
        end
      end

      escape = escape <= 0 and 0 or escape - 1
    end

    -- if we're still in quotes and we marked that we were in quotes before...
    if (inDouble or inSingle) and mark then
      args[n] = args[n] .. ' ' .. arg -- add this argument to the previous one, with a space.
    else -- otherwise just insert the argument normally.
      insert(arg)
    end
  end

  if inDouble or inSingle then
    error("Mismatching quotes.")
  end

  return args
end

local function parseArguments(...)
  local argsIn = quotize(table.pack(...))
  local args = {}

  for _, argument in ipairs(argsIn) do
    for _, parser in ipairs(parsers) do
      local data = table.pack(argument:match(parser[1]))
      if data[1] then
        parser[2](args, table.unpack(data, 1, data.n))
      end
    end
  end

  return args
end
