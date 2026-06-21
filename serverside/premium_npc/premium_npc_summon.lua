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

-- player guid -> currently active summoned NPC's ObjectGuid (any NPC type)
--
-- Stores the GUID, not the Creature object itself: calling any method on a
-- Lua reference to an already-despawned creature throws a hard error in
-- ALE ("bad self ... invalidated object"), it doesn't return nil/false.
-- Map:GetWorldObject(guid) is the safe way to re-resolve it later - it
-- returns nil on its own if the object's gone, no error.
local activeSummonGuid = {}

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

    local existingGuid = activeSummonGuid[guid]
    if existingGuid then
        local existing = player:GetMap():GetWorldObject(existingGuid)
        if existing then
            existing:DespawnOrUnsummon(0)
        end
    end

    local npc = player:SpawnCreature(
        entry,
        player:GetX(), player:GetY(), player:GetZ(), player:GetO(),
        TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT,
        durationSeconds * 1000
    )
    if not npc then
        activeSummonGuid[guid] = nil
        return false
    end

    npc:SetFaction(player:GetFaction())
    npc:MoveFollow(player, 2, 0)

    activeSummonGuid[guid] = npc:GetGUID()
    return true
end
