--- Installer file
-- @script install.lua
-- This file will install modules. It can also act as a rudimentary updater,
-- as it will remove files and re-add them with flag -f or --force.

local argparser = require "common.argparser"
local fileutil = require "common.fileutil"
local tprint = require "common.tabbedprint"

local args = argparser.parse(...)

local function printHelp()
  local prog = shell.getRunningProgram()
  term.setTextColor(colors.yellow)
  write("  > ")
  term.setTextColor(colors.lightGray)
  tprint.print(prog, "[flags] <'get-modules' / module[s]>")
  print()
  term.setTextColor(colors.orange)
  print("Flags:")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "-f/--force:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Force installation of the module, even if it already exists.")
  tprint.printAt(5, "This will delete the old module.")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "-v/--verbose:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Output extra information to the log. ")
  print()
  term.setTextColor(colors.orange)
  print("Arguments:")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "get-modules:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Grabs all available modules and lists them, sorted alphabetically by name.")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "<module>:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Install a module with name given by the argument.")
end

if args.flags.h or args.flags.help or args.args.n == 0 then
  printHelp()
end
