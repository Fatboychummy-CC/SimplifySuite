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
      if not data.Files[item[2]] then
        data.Files[item[2]] = item[3]
      else
        if data.Files[item[2]] ~= item[3] then
          error("Packages have conflicting files. Please install in seperate directories.")
        end
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
local function updatePackage(packageName, force)
  local remotes = getRemotePackages(force).Packages
  local locals = getLocalPackages(LOCAL_CACHE_NAME, force)
  if not remotes.Packages[packageName] then
    return false, string.format("Could not find package '%s'.", packageName)
  end
  if not locals.Packages[packageName] then
    return false, string.format("Package '%s' is not installed.", packageName)
  end
  if remotes.Packages[packageName] == locals.Packages[packageName] then
    return false, string.format("Package '%s' is already up-to-date.", packageName)
  end
  if remotes.Packages[packageName] < locals.Packages[packageName] then
    return false, string.format("Package '%s' is a higher version locally than the remote version. ", packageName)
  end

  -- all checks done, package on remote must be higher version than local.
  -- download package information and check dependencies
  log.Normal("Resolving Dependencies.")
  local data = resolveDependencies(packageName, force)

end

-- Install a package.
local function installPackage(packageName, force)
  local remotePackages = getRemotePackages(force).Packages
  local localPackages = getLocalPackages(LOCAL_CACHE_NAME, force)
end

local function parseArguments(...)
  local args = {}
end
