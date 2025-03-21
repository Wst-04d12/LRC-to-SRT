---@diagnostic disable: deprecated
---@class fs file system lib
local fs = {}

local load = load or loadstring
table.unpack = table.unpack or unpack

---parse txt by lines
---@param fileName string
---@param fileType string
---@return table|nil
local function txt_to_table(fileName, fileType)
    if not (type(fileName) == "string") then
        fileName = tostring(fileName)
    end
    local extName = ""
    if not fileType then
        extName = ".txt"
    else
        if not (type(fileType) == "string") then
            fileType = tostring(fileType)
        end
        extName = "." .. fileType
    end
    local absName = fileName .. extName

    local target_file = io.open(absName, "r")
    if target_file == nil then
        print(absName .. ": No such file or directory")
        os.execute("pause")
    else
        io.close(target_file)
        local rtnstr = {}
        local line_num = 1
        --print("Reading ".. absName .. "........")
        for line in io.lines(absName) do
            table.insert(rtnstr, line_num, line)
            line_num = line_num + 1
        end
        --print("Done!")
        --table.remove(rtnstr)
        return rtnstr
    end
end
---Trans a Table to a Multiple-Lines String, each line contains a single value from the table
---@param str_tbl table
---@return string
local function format(str_tbl)
    local rtnstr = ""
    for _i, v in pairs(str_tbl) do
        rtnstr = rtnstr .. v .. "\n"
    end
    rtnstr = string.sub(rtnstr, 1, -2)
    return rtnstr
end


---
---@param str string|table
---@param absname string
---@return boolean
local function writetofile(str, absname)
    local f = io.open(absname, "w+")
    if type(str) == "table" then
        str = format(str)
    end
    f:write(str)
    f:close()
    return true
end


---
---@param tbl table
local function showinput(tbl)
    for i, v in pairs(tbl) do
        print(i, v)
    end
end

---
---@param str string
---@return table|nil
local function str_to_table(str) --parse csv
    if str == nil or type(str) ~= "string" then
        return
    end

    return {load("return " .. str)()}
end

---
---@param str string
---@return table
local function split(str)
    local t = {}
    for chunk in string.gmatch(str, "[^\n]+") do
        table.insert(t, chunk)
    end
    return t
end

--[[return {
    txt_to_table = txt_to_table,
    format = format,
    writetofile = writetofile,
    showinput = showinput,
    str_to_table = str_to_table,
    split = split
}]]

local function x_csv_load(str_tbl) --parse csv
    if str_tbl == nil or type(str_tbl) ~= "table" then
        return
    end

    if not string.find(str_tbl[1], "\"") then
        return
    end

    local parsed_csv = {}

    local category = assert(load(string.format("return { %s }", str_tbl[1])))()
    local width = #category

    for i = 1, width do
        parsed_csv[category[i]] = {}  --creating subtables for each category
    end
    for line = 2, #str_tbl do
        local parsed_line = {load("return " .. str_tbl[line])()}
        for i = 1, width do
            parsed_csv[category[i]][line - 1] = parsed_line[i]
        end
    end

    return parsed_csv
    --return {load("return " .. str)()}
end

---@param str string
---@return table
local function split_crlf(str)
    local tbl = {}
    for line in string.gmatch(str, "[^\r\n]+") do
        table.insert(tbl, line)
    end
    return tbl
end

fs.txt_to_table = txt_to_table
fs.format = format
fs.writetofile = writetofile
fs.showinput = showinput
fs.str_to_table = str_to_table
fs.split = split
fs.x_csv_load = x_csv_load
fs.split_crlf = split_crlf
return fs
