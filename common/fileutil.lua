--- A utility module for working with files.
-- @module fileutil
-- @author Fatboychummy

local expect = require "cc.expect".expect

local fileutil = {}

--- Grabs a file from a remote source, or local.
-- returns a filehandle which is unified between all, built for reading.
-- Handle-safe, reads information, closes, then returns a readable thing.
local function getFile(source)
  if http.checkURL(source) then
    local h, err = http.get(source)
    if not h then
      return false, err
    end

    local lines = {}
    for line in h.readLine do
      lines[#lines + 1] = line
    end
    h.close()

    local line = 0
    return {
      readLine = function()
        line = line + 1
        return lines[line]
      end,
      readAll = function()
        return table.concat(lines, '\n')
      end
    }
  end

  if not fs.exists(source) then
    return false, "File does not exist."
  end

  local lines = {}
  for line in io.lines(source) do
    lines[#lines + 1] = line
  end

  local line = 0
  return {
    readLine = function()
      line = line + 1
      return lines[line]
    end,
    readAll = function()
      return table.concat(lines, '\n')
    end
  }
end

--- This will read all of the contents of a file, returning it as a serialized table.
-- @tparam string source The name of the file to be read, or http location.
-- @treturn any The serialized data from the file.
-- @error File Not Found
-- @error Unknown Error
function fileutil.readAllSerialized(source)
  expect(1, source, "string")

  local handle, err = getFile(source)
  if not handle then
    error(err, 2)
  end

  return textutils.serialize(handle.readAll())
end

--- This will write some data to a file in a serialized format.
-- @tparam string filename The file to be written to.
-- @tparam any data The data to be written.
function fileutil.writeSerialized(filename, data)
  expect(1, filename, "string")

  local h, err = io.open(filename, 'w')
  if not h then
    error(string.format("Failed to open file '%s' for writing due to: %s", filename, err), 2)
  end

  h:write(textutils.serialize(data))
  h:close()
end

--- Read a CSV (Comma Seperated Variable) file into a table of tables.
-- @tparam string source The file to be read, or http location.
-- @treturn {{string, ...}, ...} CSV file as a table.
function fileutil.readCSV(source)
  expect(1, source, "string")

  local handle, err = getFile(source)
  if not handle then
    error(err, 2)
  end

  local lines = {}

  for line in handle.readLine do
    local data = {}

    for variable in line:gmatch("[^,]+") do
      data[#data + 1] = variable
    end

    lines[#lines + 1] = data
  end

  return lines
end

--- Write a CSV (Comma Seperated Variable) file from a table of information.
-- @tparam string filename The name of the file to write to.
-- @tparam {{string, ...}, ...} data The information to be written to the file, as CSV.
function fileutil.writeCSV(filename, data)
  expect(1, filename, "string")
  expect(2, data, "table")

  local h, err = io.open(filename, 'w')
  if not h then
    error("File failed to open for writing.", 2)
  end

  local function combine(line)
    return table.concat(line, ',') .. '\n'
  end

  for i = 1, #data do
    h:write(combine(data[i]))
  end

  h:close()
end

return fileutil
