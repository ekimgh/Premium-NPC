--[[
    Premium NPC Summon

    Shared "summon a temporary, follow-you-around NPC" mechanic. Each NPC
    type's own file just calls SummonPremiumNpc with its own entry ID and
    duration - this is the one place the actual summon/follow logic lives.

    Only one premium NPC can be active per player at a time, regardless of
    type: summoning any of them despawns whichever one (of any type) that
    player already has out, then spawns the new one fresh.

    @module premium_npc_summon
]]

-- player guid -> currently active summoned Creature (any NPC type)
local activeSummon = {}

local TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT = 4

--- Summons a temporary, non-attackable copy of the given creature entry
-- next to the player, following them until it despawns after
-- durationSeconds out of combat. If the player already has a premium NPC
-- of any type active, it's despawned first.
-- @param player Player The player to summon the NPC for/next to
-- @param entry number The creature_template entry to summon
-- @param durationSeconds number How long the summon lasts before despawning
-- @return boolean success
function SummonPremiumNpc(player, entry, durationSeconds)
    local guid = player:GetGUIDLow()

    local existing = activeSummon[guid]
    if existing and existing:IsInWorld() then
        existing:DespawnOrUnsummon(0)
    end

    local npc = player:SpawnCreature(
        entry,
        player:GetX(), player:GetY(), player:GetZ(), player:GetO(),
        TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT,
        durationSeconds * 1000
    )
    if not npc then
        activeSummon[guid] = nil
        return false
    end

    npc:SetFaction(player:GetFaction())
    npc:MoveFollow(player, 2, 0)

    activeSummon[guid] = npc
    return true
end
