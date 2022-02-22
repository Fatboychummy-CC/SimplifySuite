--- A utility module for working with files.
-- @module fileutil
-- @author Fatboychummy

local expect = require "cc.expect".expect

local fileutil = {}

--- This will read all of the contents of a file, returning it as a serialized table.
-- @tparam string filename The name of the file to be read.
-- @treturn any The serialized data from the file.
-- @error File Not Found
-- @error Unknown Error
function fileutil.readAllSerialized(filename)
  expect(1, filename, "string")

  if not fs.exists(filename) then
    error(string.format("File not found: %s", filename), 2)
  end

  local h, err = io.open(filename, 'r')
  if not h then
    error(string.format("Unknown error when opening file for reading: %s", err), 2)
  end

  local data = h:read("*a")
  h:close()

  return textutils.serialize(data)
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

--- This will download a file from a remote location (over http[s]) and return the contents.
-- @tparam string remote The remote location to download file from.
-- @treturn string The contents of the file.
-- @error checkURL failed.
-- @error Failed to Connect
function fileutil.getRemoteFile(remote)
  expect(1, remote, "string")

  local ok, err = http.checkURL(remote)
  if not ok then
    error(string.format("checkURL failed: %s", err), 2)
  end

  local h, err = http.get(remote)
  if not h then
    error(string.format("Failed to connect to %s: %s", remote, err), 2)
  end

  local data = h.readAll()
  h.close()

  return data
end

return fileutil
