# main.py
import discord
from discord.ext import commands
from discord import app_commands
import io
import os
from datetime import datetime

from config import (
    BOT_TOKEN, BOT_NAME, BOT_COLOR, ERROR_COLOR, SUCCESS_COLOR,
    MAX_FILE_SIZE_KB, SUPPORTED_EXTENSIONS, ACTIVITY_TYPE, ACTIVITY_TEXT
)
from obfuscator import LuauObfuscator

# Intents
intents = discord.Intents.default()
intents.message_content = True

bot = commands.Bot(command_prefix="!", intents=intents)
obfuscator = LuauObfuscator()


@bot.event
async def on_ready():
    activity = discord.Activity(
        type=getattr(discord.ActivityType, ACTIVITY_TYPE, discord.ActivityType.watching),
        name=ACTIVITY_TEXT
    )
    await bot.change_presence(activity=activity)
    try:
        synced = await bot.tree.sync()
        print(f"✅ {BOT_NAME} online | Synced {len(synced)} commands")
    except Exception as e:
        print(f"❌ Sync failed: {e}")


def create_embed(title: str, description: str, color: int, footer: str = None) -> discord.Embed:
    """Create a consistent aesthetic embed."""
    embed = discord.Embed(title=title, description=description, color=color)
    embed.set_author(name=BOT_NAME, icon_url=bot.user.avatar.url if bot.user.avatar else None)
    embed.timestamp = datetime.utcnow()
    if footer:
        embed.set_footer(text=footer)
    return embed


@bot.tree.command(name="obfuscate", description="🔒 Obfuscate a Luau script with Demon Engine")
@app_commands.describe(file="Upload your .lua / .luau / .txt file")
async def obfuscate(interaction: discord.Interaction, file: discord.Attachment):
    await interaction.response.defer(ephemeral=True)

    # Validate extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in SUPPORTED_EXTENSIONS:
        embed = create_embed(
            "❌ Unsupported File",
            f"Supported extensions: `{', '.join(SUPPORTED_EXTENSIONS)}`\nYou uploaded: `{ext}`",
            ERROR_COLOR
        )
        return await interaction.followup.send(embed=embed, ephemeral=True)

    # Validate size
    if file.size > MAX_FILE_SIZE_KB * 1024:
        embed = create_embed(
            "❌ File Too Large",
            f"Maximum file size is **{MAX_FILE_SIZE_KB}KB**.\nYour file: **{file.size // 1024}KB**",
            ERROR_COLOR
        )
        return await interaction.followup.send(embed=embed, ephemeral=True)

    try:
        # Read and obfuscate
        raw = await file.read()
        source = raw.decode("utf-8", errors="replace")
        obfuscated = obfuscator.obfuscate(source)

        # Create output file as .txt
        output_name = f"demon_{os.path.splitext(file.filename)[0]}.txt"
        buffer = io.BytesIO(obfuscated.encode("utf-8"))
        discord_file = discord.File(buffer, filename=output_name)

        embed = create_embed(
            "🔒 Obfuscation Complete",
            f"**Original:** `{file.filename}`\n"
            f"**Output:** `{output_name}`\n"
            f"**Size:** `{len(obfuscated)} chars`\n"
            f"**Engine:** Demon Obfuscator v2.0",
            SUCCESS_COLOR,
            footer=f"Requested by {interaction.user.display_name}"
        )

        await interaction.followup.send(embed=embed, file=discord_file, ephemeral=True)

    except RuntimeError as e:
        embed = create_embed("⚠️ Obfuscation Error", str(e), ERROR_COLOR)
        await interaction.followup.send(embed=embed, ephemeral=True)
    except Exception as e:
        embed = create_embed("💀 Fatal Error", f"Unexpected error: `{str(e)}`", ERROR_COLOR)
        await interaction.followup.send(embed=embed, ephemeral=True)


@bot.tree.command(name="info", description="ℹ️ Information about Demon Obfuscator")
async def info(interaction: discord.Interaction):
    embed = create_embed(
        "👿 Demon Obfuscator",
        "**Advanced Luau Script Protection**\n\n"
        "• String Encoding & Encryption\n"
        "• Variable Renaming\n"
        "• Junk Code Injection\n"
        "• Control Flow Flattening\n"
        "• Custom Watermarking\n\n"
        f"**Supported:** `{', '.join(SUPPORTED_EXTENSIONS)}`\n"
        f"**Max Size:** `{MAX_FILE_SIZE_KB}KB`",
        BOT_COLOR,
        footer="Demon Obfuscator v2.0 | Use /obfuscate to protect your scripts"
    )
    await interaction.response.send_message(embed=embed)


@bot.tree.command(name="help", description="📖 How to use Demon Obfuscator")
async def help_cmd(interaction: discord.Interaction):
    embed = create_embed(
        "📖 Command Reference",
        "`/obfuscate :file` — Obfuscate a Luau script\n"
        "`/info` — Bot information & features\n"
        "`/help` — Show this message\n"
        "`/stats` — Bot statistics\n\n"
        "**Tips:**\n"
        "• Upload `.lua`, `.luau`, or `.txt` files\n"
        "• Output is always `.txt` for safety\n"
        "• All operations are ephemeral (private)",
        BOT_COLOR
    )
    await interaction.response.send_message(embed=embed)


@bot.tree.command(name="stats", description="📊 Bot statistics")
async def stats(interaction: discord.Interaction):
    embed = create_embed(
        "📊 Statistics",
        f"**Servers:** `{len(bot.guilds)}`\n"
        f"**Users:** `{sum(g.member_count for g in bot.guilds)}`\n"
        f"**Latency:** `{round(bot.latency * 1000)}ms`\n"
        f"**Uptime:** Since last restart",
        BOT_COLOR
    )
    await interaction.response.send_message(embed=embed)


if __name__ == "__main__":
    if BOT_TOKEN == "YOUR_DISCORD_BOT_TOKEN_HERE":
        print("❌ Set your bot token in config.py first!")
    else:
        bot.run(BOT_TOKEN)
