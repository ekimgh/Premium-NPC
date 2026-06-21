--[[
    Heirloom Vendor

    Summons a temporary "Heirloom Vendor" NPC (model borrowed from the real
    Enchanter Isian) that follows the player. See premium_npc_summon.lua
    for the actual summon/follow mechanic and premium_npc_access.lua for
    the enable/disable and per-account access checks applied below.

    Trigger: .premium_npc heirloom (dot-command, same mechanism as the
    Profession Trainer's).

    Sells every heirloom-quality item in the game (real ones plus this
    server's own custom additions) at its normal in-game gold price, with
    no extra currency or unlock gating - entirely configured through the
    standard npc_vendor table against its own creature_template entry
    (900201, see sql/db-world/04_heirloom_vendor.sql). This file only owns
    the summon trigger itself, with no vendor logic of its own.

    @module heirloom_vendor
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local CONFIG = PREMIUM_NPC_CONFIG.HEIRLOOM_VENDOR

--- Checks access and summons the Heirloom Vendor if allowed, messaging
-- the player either way. Shared by the .premium_npc heirloom command and
-- premium_menu_item.lua's item-based menu.
function TryHeirloomVendor(player)
    local allowed, reason = IsPremiumNpcAllowed(player, CONFIG)
    if allowed then
        SummonPremiumNpc(player, CONFIG.NPC_ID, CONFIG.SUMMON_DURATION_SECONDS)
    else
        player:SendBroadcastMessage(reason)
    end
end

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc heirloom" then
        return
    end

    TryHeirloomVendor(player)
    return false
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND
