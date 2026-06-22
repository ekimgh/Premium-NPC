--[[
    Glyph Vendor

    Summons a temporary "Glyph Vendor" NPC (model borrowed from the real
    Inscription Supplies vendor Librarian Ingram) that follows the player.
    See premium_npc_summon.lua for the actual summon/follow mechanic and
    premium_npc_access.lua for the enable/disable and per-account access
    checks applied below.

    Trigger: .premium_npc glyph (dot-command, same mechanism as the other
    NPC types').

    Sells every real glyph in the game at its normal in-game gold price,
    with no extra currency or unlock gating - entirely configured through
    the standard npc_vendor table, same as Heirloom Vendor. Unlike
    Heirloom Vendor, this NPC type has one creature_template entry per
    class (PREMIUM_NPC_CONFIG.GLYPH_VENDOR.ENTRIES, see
    sql/db-world/07_glyph_vendor.sql) rather than a single shared entry:
    VendorItemData::GetItemCount() (core's CreatureData.h) returns uint8,
    so one creature's *stored* npc_vendor list silently truncates at 255
    total rows, well below all ten classes' glyphs combined (353). Same
    per-class ENTRIES pattern Class Trainer uses, just keyed by class only
    - glyphs aren't faction-specific. This file only owns the summon
    trigger itself, with no vendor logic of its own.

    @module glyph_vendor
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local CONFIG = PREMIUM_NPC_CONFIG.GLYPH_VENDOR

--- Checks access and summons the player's own class's Glyph Vendor if
-- allowed, messaging the player either way. Shared by the .premium_npc
-- glyph command and premium_menu_item.lua's item-based menu.
function TryGlyphVendor(player)
    local allowed, reason = IsPremiumNpcAllowed(player, CONFIG)
    if allowed then
        local entry = CONFIG.ENTRIES[player:GetClass()]
        if entry then
            SummonPremiumNpc(player, entry, CONFIG.SUMMON_DURATION_SECONDS)
        else
            player:SendBroadcastMessage("No glyph vendor is configured for your class.")
        end
    else
        player:SendBroadcastMessage(reason)
    end
end

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc glyph" then
        return
    end

    TryGlyphVendor(player)
    return false
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND
