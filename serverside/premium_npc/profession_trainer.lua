--[[
    Profession Trainer

    Summons a temporary "Profession Trainer" NPC (model borrowed from the
    real Gelman Stonehand) that follows the player. See
    premium_npc_summon.lua for the actual summon/follow mechanic.

    Trigger: .premium_npc profession (dot-command, same mechanism as
    Paragon's/Prestige's own debug commands - fires via
    PLAYER_EVENT_ON_COMMAND, not a client slash command).

    Whatever this NPC teaches is configured entirely through standard
    npc_trainer rows against its own creature_template entry (900200, see
    sql/01_profession_trainer_npc.sql) - this file only owns the summon
    trigger itself, with no trainer-spell logic of its own.

    @module profession_trainer
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local NPC_ID = PREMIUM_NPC_CONFIG.PROFESSION_TRAINER.NPC_ID
local SUMMON_DURATION_SECONDS = PREMIUM_NPC_CONFIG.PROFESSION_TRAINER.SUMMON_DURATION_SECONDS

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc profession" then
        return
    end

    SummonPremiumNpc(player, NPC_ID, SUMMON_DURATION_SECONDS)
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND
