--[[
    Profession Trainer

    Summons a temporary "Profession Trainer" NPC (model borrowed from the
    real Gelman Stonehand) that follows the player. See
    premium_npc_summon.lua for the actual summon/follow mechanic and
    premium_npc_access.lua for the enable/disable and per-account access
    checks applied below.

    Trigger: .premium_npc profession (dot-command, same mechanism as
    Paragon's/Prestige's own debug commands - fires via
    PLAYER_EVENT_ON_COMMAND, not a client slash command). Returning false
    once the command is recognized as ours suppresses the core's "unknown
    command" message - without it, the summon still works but the client
    also reports the command as not existing.

    Whatever this NPC teaches is configured entirely through the
    trainer/trainer_spell/creature_default_trainer tables against its own
    creature_template entry (900200, see sql/db-world/01_profession_trainer_npc.sql
    and 02_profession_trainer_spells.sql) - this file only owns the summon
    trigger itself, with no trainer-spell logic of its own.

    @module profession_trainer
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local CONFIG = PREMIUM_NPC_CONFIG.PROFESSION_TRAINER

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc profession" then
        return
    end

    local allowed, reason = IsPremiumNpcAllowed(player, CONFIG)
    if allowed then
        SummonPremiumNpc(player, CONFIG.NPC_ID, CONFIG.SUMMON_DURATION_SECONDS)
    else
        player:SendBroadcastMessage(reason)
    end

    return false
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND
