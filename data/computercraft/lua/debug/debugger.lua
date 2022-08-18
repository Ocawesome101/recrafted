local colors = require "colors"
local fs = require "fs"
local multishell = require "multishell"
local shell = require "shell"
local term = require "term"
local textutils = require "textutils"
local pretty = require "cc.pretty"

multishell.setTitle(multishell.getCurrent(), "Debugger")
local ok, err = pcall(function()
local history = {}
local function split(inputstr, sep)
    sep = sep or "%s"
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
    return t
end
term.setTextColor(colors.yellow)
print("CraftOS-PC Debugger")
local advanceTemp
while true do
    debugger.waitForBreak()
    if advanceTemp then debugger.unsetBreakpoint(advanceTemp); advanceTemp = nil end
    local info = debugger.getInfo()
    if string.sub(info.source, -8) == "bios.lua" then info.source = "@/bios.lua" end
    term.setTextColor(colors.blue)
    print("Break at " .. (info.short_src or "?") .. ":" .. (info.currentline or "?") .. " (" .. (info.name or "?") .. "): " .. debugger.getReason())
    if info.source and info.currentline and fs.exists(string.sub(info.source, 2)) then
        local file = fs.open(string.sub(info.source, 2), "r")
        for i = 1, info.currentline - 1 do file.readLine() end
        term.setTextColor(colors.lime)
        io.write("--> ")
        term.setTextColor(colors.white)
        local str = string.gsub(file.readLine(), "^[ \t]+", "")
        print(str)
        file.close()
    end
    local loop = true
    while loop do
        term.setTextColor(colors.yellow)
        io.write("(ccdb) ")
        term.setTextColor(colors.white)
        local cmd = io.read()
        if cmd == "" then cmd = history[#history]
        else table.insert(history, cmd) end
        local action = split(cmd)
        if action[1] == "step" or action[1] == "s" then debugger.step(action[2] and tonumber(action[2])); loop = false
        elseif action[1] == "finish" or action[1] == "fin" then debugger.stepOut(); loop = false
        elseif action[1] == "continue" or action[1] == "c" then debugger.continue(); loop = false
        elseif action[1] == "b" or action[1] == "break" then print("Breakpoint " .. debugger.setBreakpoint(string.sub(action[2], 1, string.find(action[2], ":") - 1), tonumber(string.sub(action[2], string.find(action[2], ":") + 1))) .. " set at " .. string.sub(action[2], 1, string.find(action[2], ":") - 1) .. ":" .. string.sub(action[2], string.find(action[2], ":") + 1))
        elseif action[1] == "breakpoint" and action[2] == "set" then print("Breakpoint " .. debugger.setBreakpoint(string.sub(action[3], 1, string.find(action[3], ":") - 1), tonumber(string.sub(action[3], string.find(action[3], ":") + 1))) .. " set at " .. string.sub(action[3], 1, string.find(action[3], ":") - 1) .. ":" .. string.sub(action[3], string.find(action[3], ":") + 1))
        elseif action[1] == "catch" then
            if action[2] == "catch" or action[2] == "error" or action[2] == "throw" then debugger.catch("error")
            elseif action[2] == "load" then debugger.catch("load")
            elseif action[2] == "exec" or action[2] == "run" then debugger.catch("run")
            elseif action[2] == "resume" then debugger.catch("resume")
            elseif action[2] == "yield" then debugger.catch("yield") end
        elseif action[1] == "clear" then debugger.unsetBreakpoint(tonumber(action[2]))
        elseif action[1] == "delete" then
            if action[2] == "catch" then
                if action[2] == "catch" or action[2] == "error" or action[2] == "throw" then debugger.uncatch("error")
                elseif action[2] == "load" then debugger.uncatch("load")
                elseif action[2] == "exec" or action[2] == "run" then debugger.uncatch("run")
                elseif action[2] == "resume" then debugger.uncatch("resume")
                elseif action[2] == "yield" then debugger.uncatch("yield") end
            else debugger.unsetBreakpoint(tonumber(action[2])) end
        elseif action[1] == "edit" and debugger.getInfo().source and fs.exists(string.sub(debugger.getInfo().source, 2)) then shell.run("edit", debugger.getInfo().source)
        elseif action[1] == "advance" then
            advanceTemp = debugger.setBreakpoint(string.sub(action[2], 1, string.find(action[2], ":") - 1), tonumber(string.sub(action[2], string.find(action[2], ":") + 1)))
            debugger.continue()
            loop = false
        elseif action[1] == "info" then
            if action[2] == "breakpoints" then
                local breakpoints = debugger.listBreakpoints()
                local keys = {}
                for k,v in pairs(breakpoints) do table.insert(keys, k) end
                table.sort(keys)
                local lines = {}
                for _,i in ipairs(keys) do table.insert(lines, {i, breakpoints[i].file, breakpoints[i].line}) end
                textutils.tabulate(colors.blue, {"ID", "File", "Line"}, colors.white, table.unpack(lines))
            elseif action[2] == "frame" then
                term.setTextColor(colors.blue)
                print("Break at " .. (info.short_src or "?") .. ":" .. (info.currentline or "?") .. " (" .. (info.name or "?") .. "): " .. debugger.getReason())
                if info.source and info.currentline and fs.exists(string.sub(info.source, 2)) then
                    local file = fs.open(string.sub(info.source, 2), "r")
                    for i = 1, info.currentline - 1 do file.readLine() end
                    term.setTextColor(colors.lime)
                    io.write("--> ")
                    term.setTextColor(colors.white)
                    local str = string.gsub(file.readLine(), "^[ \t]+", "")
                    print(str)
                    file.close()
                end
            elseif action[2] == "locals" then
                local lines = {}
                for k,v in pairs(debugger.getLocals()) do table.insert(lines, {k, tostring(v)}) end
                textutils.tabulate(colors.blue, {"Name", "Value"}, colors.white, table.unpack(lines))
            end
        elseif action[1] == "print" or action[1] == "p" then 
            table.remove(action, 1)
            local s = table.concat(action, " ")
            local forcePrint = false
            local sf, func, e = s, load( s, "lua", "t", {} )
            local sf2, func2, e2 = "return _echo("..s..");", load("return _echo("..s..");", "lua", "t", {})
            if not func then if func2 then func, sf, e, forcePrint = func2, sf2, nil, true end
            elseif func2 then func, sf = func2, sf2 end
            if func then
                local res = table.pack(debugger.run(sf))
                if res[1] then
                    for n = 2, res.n do
                        local value = res[n]
                        pretty.pretty_print(value)
                        if n <= (forcePrint and 2 or 0) then break end
                    end
                else io.stderr:write(res[2] .. "\n") end
            else io.stderr:write(e .. "\n") end
        elseif action[1] == "backtrace" or action[1] == "bt" then print(({debugger.run("return debug.traceback()")})[2])
        elseif action[1] == "help" then
            textutils.pagedPrint([[Available commands:
advance -- Run to a position in a file in the format <file>:<line>
backtrace (bt) -- Show a traceback
break (b) -- Set a breakpoint in the format <file>:<line>
breakpoint set -- Set a breakpoint in the format <file>:<line>
catch -- Set a breakpoint on special calls
catch error -- Break on error
catch load -- Break on loading APIs/require
catch resume -- Break on resuming coroutine
catch run -- Break on running a program
catch yield -- Break on yielding coroutine
clear -- Clear a breakpoint
continue (c) -- Continue execution
edit -- Edit the currently running program
delete -- Clear a breakpoint
delete catch error -- Stop breaking on error
delete catch load -- Stop breaking on loading APIs/require
delete catch run -- Stop breaking on running a program
finish (fin) -- Step to the end of the current function
info -- List info about the running program
info breakpoints -- List all current breakpoints
info frame -- List the status of the program
info locals -- List all available locals
print (p) -- Run an expression and print the result a la lua.lua
step (s) -- Step a number of lines]], 4)
        else io.stderr:write("Error: Invalid command\n") end
    end
    os.queueEvent("debugger_done")
end
end)
if not ok then io.stderr:write(err .. "\n") end
while os.pullEvent() do end