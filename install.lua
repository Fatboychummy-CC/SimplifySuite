--- Installer file
-- @script install.lua
-- This file will install modules. It can also act as a rudimentary updater,
-- as it will remove files and re-add them when needed.

local argparser = require "common.argparser"
local fileutil = require "common.fileutil"
