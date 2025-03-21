package.path = package.path .. ";./?.lua"

local fs = require "wst.fs"


local last_sentence_display_time = 1 --sec

local useless_lines_starts = {
    "%[ar:", "%[al:", "%[ti:", "%[au:", "%[length:", "%[by:", "%[offset:", "%[re:", "%[ve:"
}

local function is_not_useless(lrc_line)
    local id = string.sub(lrc_line, 1, 8)
    local is_useless
    for i, v in ipairs(useless_lines_starts) do
        if string.find(id, v) then
            is_useless = true
            break
        end
    end

    return not is_useless or lrc_line

end

local function parse_lrc(T_lrc)
    local T_parsed_lrc= {}
    local time, content, raw_time, time_code_length

    for i, v in ipairs(T_lrc) do
        if is_not_useless(v) then
            time_code_length = string.find(v, "%]")
            break
        end
    end
    for i, v in ipairs(T_lrc) do
        if v ~= "" and is_not_useless(v) then
            time = string.sub(v, 2, time_code_length - 1)
            raw_time = string.sub(v, 1, time_code_length)
            if #v > time_code_length then -- not necessary, Lua can handle this.
                content = string.sub(v, time_code_length + 1, -1)
            else
                content = ""
            end
            table.insert(T_parsed_lrc, {time = time, raw_time = raw_time, content = content})
        end
    end
    return T_parsed_lrc
end


local time = {

    tosec = function(hr, min, sec, mil)
        return hr*3600 + min*60 + sec + mil/1000
    end,

    tounit = function(sec)
        local ret = {}
        ret.hr = sec // 3600
        ret.min = sec % 3600 // 60
        ret.sec = sec % 60 // 1
        ret.mil = sec * 1000 - math.floor(sec) * 1000
        return ret
    end,

    format_digit = function(time)
        return string.format("%02d", time)
    end,

    format_mil = function(mil)
        return string.format("%03d", mil)
    end,

    lrc2sec = function(lrc_timecode)
    end,

    sec2lrc = function(self, sec, mil_length)
        local u = self.tounit(sec)
        return
        self.format_digit(u.hr*60 + u.min) .. ":" ..
        self.format_digit(u.sec) .. "." ..
        (mil_length == 3 and self.format_mil(u.mil)
        or self.format_digit(math.floor((u.mil + 5) / 10)))
    end,

    srt2sec = function(srt_timecode)
        local hr, min, sec, mil
        hr = string.sub(srt_timecode, 1, 2)
        min = string.sub(srt_timecode, 4, 5)
        sec = string.sub(srt_timecode, 7, 8)
        mil = string.sub(srt_timecode, 10, 12)
        return hr*3600 + min*60 + sec + mil/1000, {hr, min, sec, mil}
    end,

    sec2srt = function(self, sec)
        local u = self.tounit(sec)
        -- return
        -- self.format_digit(u.hr) .. ":" ..
        -- self.format_digit(u.min) .. ":" ..
        -- self.format_digit(u.sec) .. "," ..
        -- self.format_mil(u.mil)

        return string.format("%s:%s:%s,%s",
            self.format_digit(u.hr),
            self.format_digit(u.min),
            self.format_digit(u.sec),
            self.format_mil(u.mil)
        )

    end
}


local function lrc_timecode_to_srt(lrc_timecode)
    local srt_timecode
    local min = tonumber(string.sub(lrc_timecode, 1, 2))
    local hr = min // 60
    if hr == 0 then
        srt_timecode = "00:" .. lrc_timecode
    else
        srt_timecode = time.format_digit(hr) .. ":" ..
        time.format_digit(min - hr * 60) .. string.sub(lrc_timecode, 3, -1)
    end
    srt_timecode = string.gsub(srt_timecode, "%.", ",", 1)
    --#region not reviewed fix
    srt_timecode = srt_timecode .. "0"
    --#endregion
    return srt_timecode
end


local function transform_lrc_to_srt(T_parsed_lrc)
    local T_srt = {}
    local to = " --> "
    local index, time_, endtime, content
    for i, v in ipairs(T_parsed_lrc) do
        index = i
        if i ~= #T_parsed_lrc then
            endtime = lrc_timecode_to_srt(T_parsed_lrc[i + 1].time)
        else
            endtime = time:sec2srt(time.srt2sec(lrc_timecode_to_srt(v.time)) + last_sentence_display_time)
        end
        time_ = lrc_timecode_to_srt(v.time) .. to .. endtime
        content = v.content
        --#region avoiding empty line
        if content == "" then content = "." end
        --#endregion
        table.insert(T_srt,
            {
                index = index,
                time = time_,
                content = content
            }
        )
    end
    return T_srt
end


local function format_srt(T_srt)
    local srt_text = {}
    for i, v in ipairs(T_srt) do
        table.insert(srt_text, v.index)
        table.insert(srt_text, v.time)
        table.insert(srt_text, v.content)
        table.insert(srt_text, "")
    end
    return srt_text
end



local function main(filename)
    local f<close> = io.open(filename or io.read("l"), "r")
    fs.writetofile(
        format_srt(transform_lrc_to_srt(parse_lrc(fs.split(f:read("*a"))))),
        "output.srt"
    )
    print("done.")
end


main(arg[1])


