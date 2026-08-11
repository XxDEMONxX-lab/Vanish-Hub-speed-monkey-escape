-- app.lua | Lunaris Obfuscator Entry Point
local Config = require("config")

assert(Config.BOT_TOKEN ~= "YOUR_DISCORD_BOT_TOKEN_HERE",
    "[Lunaris] Set BOT_TOKEN in config.lua!")
assert(Config.APPLICATION_ID ~= "YOUR_APPLICATION_ID_HERE",
    "[Lunaris] Set APPLICATION_ID in config.lua!")

print("[Lunaris] Starting Lunaris Obfuscator v2.0...")
local client = require("bot")
client:run("Bot " .. Config.BOT_TOKEN)
