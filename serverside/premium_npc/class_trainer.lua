--[[
    Class Trainer

    Summons a temporary class trainer NPC next to the player, matched to
    the player's own class and faction via PREMIUM_NPC_CONFIG.CLASS_TRAINER.ENTRIES
    (see premium_npc_config.lua). See premium_npc_summon.lua for the
    actual summon/follow mechanic and premium_npc_access.lua for the
    enable/disable and per-account access checks applied below.

    Trigger: .premium_npc class

    This file only owns the summon trigger itself - which real creature
    gets summoned, and everything it teaches/offers once summoned, is
    entirely real, existing AzerothCore data (see the ENTRIES table's
    comment in premium_npc_config.lua), not custom Lua logic.

    @module class_trainer
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local CONFIG = PREMIUM_NPC_CONFIG.CLASS_TRAINER

--- Checks access and summons the player's own class's trainer if
-- allowed, messaging the player either way. Shared by the .premium_npc
-- class command and premium_menu_item.lua's item-based menu.
function TryClassTrainer(player)
    local allowed, reason = IsPremiumNpcAllowed(player, CONFIG)
    if allowed then
        local byTeam = CONFIG.ENTRIES[player:GetClass()]
        local entry = byTeam and byTeam[player:GetTeam()]
        if entry then
            SummonPremiumNpc(player, entry, CONFIG.SUMMON_DURATION_SECONDS)
        else
            player:SendBroadcastMessage("No class trainer is configured for your class.")
        end
    else
        player:SendBroadcastMessage(reason)
    end
end

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc class" then
        return
    end

    TryClassTrainer(player)
    return false
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND
