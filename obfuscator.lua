local Obfuscator = {}
local Config = require("config")

local KEYWORDS = {
    ["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
    ["end"]=true,["false"]=true,["for"]=true,["function"]=true,["if"]=true,
    ["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,
    ["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,["until"]=true,
    ["while"]=true,["continue"]=true,["type"]=true,["export"]=true
}

local function tokenize(source)
    local tokens, pos, len = {}, 1, #source
    while pos <= len do
        local ws = source:match("^([ \t\r\n]*%-%-[^\n]*\n?)", pos) or source:match("^([ \t\r\n]+)", pos)
        if ws then
            table.insert(tokens, { type = "ws", value = ws }); pos = pos + #ws
        elseif source:sub(pos, pos):match("[\"']") then
            local q, str = source:sub(pos, pos), source:sub(pos, pos); pos = pos + 1
            while pos <= len do
                local c = source:sub(pos, pos); str = str .. c; pos = pos + 1
                if c == "\\" and pos <= len then str = str .. source:sub(pos, pos); pos = pos + 1
                elseif c == q then break end
            end
            table.insert(tokens, { type = "string", value = str })
        elseif source:sub(pos):match("^[%a_][%w_]*") then
            local id = source:match("^[%a_][%w_]*", pos)
            table.insert(tokens, { type = KEYWORDS[id] and "keyword" or "ident", value = id }); pos = pos + #id
        elseif source:sub(pos):match("^%d") or source:sub(pos, pos+1) == "0x" then
            local num = source:match("^0x[%da-fA-F]+", pos) or source:match("^%d+%.?%d*[eE]?[+-]?%d*", pos)
            table.insert(tokens, { type = "number", value = num }); pos = pos + #num
        else
            table.insert(tokens, { type = "symbol", value = source:sub(pos, pos) }); pos = pos + 1
        end
    end
    return tokens
end

local function genName(seed)
    local c, n = "Il1O0", "_L"
    for i = 1, 12 do n = n .. c:sub(((seed*31+i*17)%#c)+1, ((seed*31+i*17)%#c)+1) end
    return n
end

function Obfuscator.obfuscate(source)
    if type(source) ~= "string" or #source == 0 then return nil, "Empty source" end
    local ok, result = pcall(function()
        local tokens = tokenize(source)
        local map, cnt = {}, 0
        for _, t in ipairs(tokens) do
            if t.type == "ident" and not map[t.value] then cnt = cnt + 1; map[t.value] = genName(cnt) end
        end
        local parts = {}
        for _, t in ipairs(tokens) do
            if t.type == "ident" and map[t.value] then table.insert(parts, map[t.value])
            elseif t.type == "string" then
                local inner = t.value:sub(2, -2)
                if #inner > 0 and #inner < 200 then
                    local b = {}; for i = 1, #inner do table.insert(b, string.byte(inner, i)) end
                    table.insert(parts, "string.char(" .. table.concat(b, ",") .. ")")
                else table.insert(parts, t.value) end
            else table.insert(parts, t.value) end
        end
        return Config.WATERMARK .. table.concat(parts)
    end)
    if not ok then return nil, tostring(result) end
    return result
end

return Obfuscator
