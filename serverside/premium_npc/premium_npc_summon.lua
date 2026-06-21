--[[
    Premium NPC Summon

    Shared "summon a temporary, follow-you-around NPC" mechanic, used by
    every premium NPC type (Profession Trainer today, more planned). Each
    NPC type's own file just calls SummonPremiumNpc with its own entry ID
    and duration - this is the one place the actual summon/follow/cooldown
    logic lives, kept in one place specifically because the plan is to add
    more of these.

    Mirrors mod-roguelite's RogueliteHeirloomVendor.cpp::SummonHeirloomVendor
    (same TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT pattern, same
    cooldown-equals-duration reasoning: by the time a re-summon is allowed,
    the previous one has necessarily already despawned on its own timer).

    @module premium_npc_summon
]]

-- guid -> { [entry] = lastSummonAtEpochSeconds }
local lastSummonAt = {}

local TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT = 4

--- Summons a temporary, non-attackable copy of the given creature entry
-- next to the player, following them until it despawns after
-- durationSeconds out of combat. Returns false (and messages the player)
-- if one of this same entry is already out and still on cooldown.
-- @param player Player The player to summon the NPC for/next to
-- @param entry number The creature_template entry to summon
-- @param durationSeconds number How long the summon lasts before despawning
-- @return boolean success
function SummonPremiumNpc(player, entry, durationSeconds)
    local guid = player:GetGUIDLow()
    local now = os.time()

    if not lastSummonAt[guid] then
        lastSummonAt[guid] = {}
    end

    local last = lastSummonAt[guid][entry]
    if last and now < last + durationSeconds then
        player:SendBroadcastMessage(
            "That NPC is still out. Try again in " .. (last + durationSeconds - now) .. " second(s)."
        )
        return false
    end

    local npc = player:SpawnCreature(
        entry,
        player:GetX(), player:GetY(), player:GetZ(), player:GetO(),
        TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT,
        durationSeconds * 1000
    )
    if not npc then
        return false
    end

    npc:SetFaction(player:GetFaction())
    npc:MoveFollow(player, 2, 0)

    lastSummonAt[guid][entry] = now
    return true
end
