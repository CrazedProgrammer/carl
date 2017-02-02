--[[
carl version 0.1.0

The MIT License (MIT)
Copyright (c) 2017 CrazedProgrammer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local basePath = (shell and shell.dir().."/") or "./"
local args = {...}
local output, project, lib, traceMap = { }


local function resolvePath(path)
	if path:sub(1, 1) == "/" then
		return path
	else
		return basePath..path
	end
end

local function readLines(path)
	local lines, ok, iter = { }, pcall(io.lines, resolvePath(path))
	if not ok then return end
	for line in iter do
		lines[#lines + 1] = line
	end
	return lines
end

local function writeLines(path, lines)
	local handle = io.open(resolvePath(path), "w")
	if not handle then return false end
	handle:write(table.concat(lines, "\n"))
	handle:close()
	return true
end

local function trimWhitespace(str)
	while str:sub(1, 1) == " " or str:sub(1, 1) == "\t" do
		str = str:sub(2)
	end
	while str:sub(#str, #str) == " " or str:sub(#str, #str) == "\t" do
		str = str:sub(1, #str - 1)
	end
	return str
end



local function loadProject()
	local source = readLines("src/main.lua")
	if not source then
		source = readLines("src/lib.lua")
		if source then
			lib = true
		else
			print("Error: missing main source file \"src/main.lua\" or \"src/lib.lua\".")
			return false
		end
	end

	local cfg = readLines("Carl.cf")
	if not cfg then
		print("Warning: Carl.cf missing, using defaults.")
		project = {name = "prg", author = "<author>", version = "0.1.0"}
	else
		project = { }
		for i = 1, #cfg do
			cfg[i] = trimWhitespace(cfg[i])
			if cfg[i]:find("#") then
				cfg[i] = cfg[i]:sub(1, (cfg[i]:find("#")) - 1)
			end
			if cfg[i] ~= "" then
				local key = trimWhitespace(cfg[i]:sub(1, (cfg[i]:find("=")) - 1))
				local value = trimWhitespace(cfg[i]:sub((cfg[i]:find("=")) + 1))
				project[key] = value
			end
		end
		if not (project.name and project.author and project.version) then
			print("Error: missing project name, author or version.")
			return false
		end
	end

	return true
end

local function addSource(file)
	local source = readLines("src/"..file)
	if not source then
		print("Error: missing source file \""..file.."\".")
		return false
	end
	local ok, err = loadstring(table.concat(source), file)
	if not ok then
		print("Syntax error in \""..file.."\":")
		print(err)
	end
	for i = 1, #source do
		output[#output + 1] = source[i]
	end
	return true
end

local function buildProject()
	print("Building project...")
	if not loadProject() then
		return false
	end

	addSource(lib and "lib.lua" or "main.lua")

	writeLines("target/"..project.name, output)
	print("Done.")
	return true
end

local function runProject()
	local func = loadfile(resolvePath("target/"..project.name))
	local prgargs = { }
	for i = 2, #args do
		prgargs[i - 1] = args[i]
	end
	func(unpack(prgargs))
end

if #args == 0 then
	print("carl build")
	print("carl run [...]")
	print("carl trace <line>")
	return
end

if args[1] == "new" then
	newProject(args[2], args[3] and (args[3] == "--lib"))
elseif args[1] == "build" then
	if not buildProject() then
		print("Failed to build project.")
	end
elseif args[1] == "run" then
	if not buildProject() then
		print("Failed to build project.")
	else
		runProject()
	end
elseif args[1] == "trace" then
	if #args < 2 then
		print("carl trace <line>")
	elseif not buildProject() then
		print("Failed to build project.")
	end
else
	print("invalid subcommand \""..args[1].."\"")
end