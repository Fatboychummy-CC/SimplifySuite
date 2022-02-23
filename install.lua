--- Installer file
-- @script install.lua
-- This file will install modules. It can also act as a rudimentary updater,
-- as it will remove files and re-add them with flag -f or --force.

local argparser = require "common.argparser"
local fileutil = require "common.fileutil"
local tprint = require "common.tabbedprint"
local logger = require "common.log"

local PACKAGE_ROOT = "https://raw.githubusercontent.com/Fatboychummy-CC/SimplifySuite/main/packages/"
local ALL_PACKAGES_URL = PACKAGE_ROOT .. "all_packages.csv?token=GHSAT0AAAAAABRQ3DWE4CICAIPJCZGPH5LUYQUH5WQ"
local log = logger.create("INST")

local args = argparser.parse(...)

local function printHelp()
  local prog = shell.getRunningProgram()
  term.setTextColor(colors.yellow)
  write("  > ")
  term.setTextColor(colors.lightGray)
  tprint.print(prog, "[flags] <'get-packages' / package[s]>")
  print()
  term.setTextColor(colors.orange)
  print("Flags:")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "-f/--force:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Force installation of the package, even if it already exists.")
  tprint.printAt(5, "This will delete the old package.")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "-v/--verbose:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Output extra information to the log. ")
  print()
  term.setTextColor(colors.orange)
  print("Arguments:")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "get-packages:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Grabs all available packages and lists them, sorted alphabetically by name.")
  term.setTextColor(colors.blue)
  tprint.printAt(3, "<package[s]>:")
  term.setTextColor(colors.white)
  tprint.printAt(5, "Install a package (or packages) with name given by the argument.")
end

local function getPackages()
  log:info("Getting list of all packages...")
  return fileutil.readCSV(ALL_PACKAGES_URL)
end

local function printPackages()
  local packages = getPackages()

  log:info("Determining longest package name.")
  local longest = 0
  for i = 2, #packages do
    if #packages[i][1] > longest then
      longest = #packages[i][1]
    end
  end

  log:info("Printing packages.")
  for i = 1, #packages do
    if i == 1 then term.setTextColor(colors.blue) else term.setTextColor(colors.white) end
    print(string.format(string.format("%%%ds , %%s", -longest), packages[i][1], packages[i][2]))
  end
end
if args.flags.h or args.flags.help or args.args.n == 0 then
  printHelp()
  return
end

local verbose = args.flags.v or args.flags.verbose
if not verbose then
  log.Level = 1
end

log:info("Verbose logging is on.")

if args.args[1] == "get-packages" then
  printPackages()
  return
end
