local discordia = require("discordia")
local http = require("coro-http")
local json = require("json")
local Config = require("config")
local Obfuscator = require("obfuscator")

discordia.extensions()
local client = discordia.Client()

local API = "https://discord.com/api/v10"

local function apiRequest(method, endpoint, body)
    local headers = {
        {"Authorization", "Bot " .. Config.BOT_TOKEN},
        {"Content-Type", "application/json"},
        {"User-Agent", "DiscordBot (Lunaris, 2.0)"}
    }
    local payload = body and json.encode(body) or nil
    local code, resBody = http.request(method, API .. endpoint, headers, payload)
    return code, json.decode(resBody)
end

local function registerSlashCommand()
    local code = apiRequest("PUT",
        "/applications/" .. Config.APPLICATION_ID .. "/commands",
        {
            name = "obfuscate",
            description = "Obfuscate a Luau script with Lunaris",
            options = {{name = "file", description = "Lua/Luau/TXT file to obfuscate", type = 11, required = true}}
        })
    print("[Lunaris] Slash command registered:", code == 200 or code == 201)
end

client:on("ready", function()
    print("[Lunaris] Connected as " .. client.user.tag)
    registerSlashCommand()
end)

client:on("interactionCreate", function(interaction)
    if interaction.type ~= discordia.enums.interactionType.applicationCommand then return end
    if interaction.data.name ~= "obfuscate" then return end

    interaction:deferReply()

    local attId = interaction.data.options[1].value
    local resolved = interaction.data.resolved.attachments[attId]
    if not resolved then
        return interaction:followupReply({content = "❌ Could not resolve attachment."})
    end

    local ext = (resolved.filename:match("%.([^.]+)$") or ""):lower()
    if not Config.SUPPORTED_EXTENSIONS[ext] then
        return interaction:followupReply({content = "❌ Unsupported extension `." .. ext .. "`"})
    end
    if resolved.size > Config.MAX_FILE_SIZE then
        return interaction:followupReply({content = "❌ File too large (" .. math.ceil(resolved.size/1024) .. "KB)"})
    end

    local dlCode, dlBody = http.request("GET", resolved.url)
    if dlCode ~= 200 then
        return interaction:followupReply({content = "❌ Failed to download file."})
    end

    local output, err = Obfuscator.obfuscate(dlBody)
    if not output then
        return interaction:followupReply({content = "❌ " .. err})
    end

    local outName = "Lunaris_" .. resolved.filename:gsub("%.[^.]+$", "") .. "_obfuscated.txt"
    interaction:followupReply({
        content = "✅ **" .. resolved.filename .. "** obfuscated!",
        attachments = {{filename = outName, content = output}}
    })
end)

return client
