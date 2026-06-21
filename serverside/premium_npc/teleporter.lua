--[[
    Teleporter

    Summons a temporary Teleporter NPC next to the player. Unlike the
    other premium NPCs, this one's own gossip menu is built in Lua rather
    than reusing native trainer/vendor data: clicking it lists the
    player's own faction's major cities (PREMIUM_NPC_CONFIG.TELEPORTER.DESTINATIONS,
    see premium_npc_config.lua), and selecting one teleports the player
    there directly. See premium_npc_summon.lua for the summon/follow
    mechanic and premium_npc_access.lua for the enable/disable and
    per-account access checks applied below.

    Trigger: .premium_npc teleporter

    @module teleporter
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local CONFIG = PREMIUM_NPC_CONFIG.TELEPORTER

--- Checks access and summons the Teleporter if allowed, messaging the
-- player either way. Shared by the .premium_npc teleporter command and
-- premium_menu_item.lua's item-based menu.
function TryTeleporter(player)
    local allowed, reason = IsPremiumNpcAllowed(player, CONFIG)
    if allowed then
        SummonPremiumNpc(player, CONFIG.NPC_ID, CONFIG.SUMMON_DURATION_SECONDS)
    else
        player:SendBroadcastMessage(reason)
    end
end

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc teleporter" then
        return
    end

    TryTeleporter(player)
    return false
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND

local function OnGossipHello(event, player, creature)
    local destinations = CONFIG.DESTINATIONS[player:GetTeam()]
    for index, destination in ipairs(destinations) do
        player:GossipMenuAddItem(0, destination.name, 0, index)
    end
    player:GossipSendMenu(900202, creature) -- sql/db-world/05_teleporter.sql
end

local function OnGossipSelect(event, player, creature, sender, intid)
    local destination = CONFIG.DESTINATIONS[player:GetTeam()][intid]

    if destination then
        player:GossipComplete()
        player:Teleport(destination.map, destination.x, destination.y, destination.z, destination.o)

        -- MoveFollow can't carry a creature across a map boundary - left
        -- alone, it's stranded on whichever map the player teleported
        -- away from, and (since premium_npc_summon.lua's
        -- despawn-on-resummon check only looks at the player's *current*
        -- map) the next summon can't find it to clean it up either. Its
        -- job is done once the player has actually teleported, so
        -- despawn it directly here instead of relying on it following.
        creature:DespawnOrUnsummon(0)
    end

    return false
end

RegisterCreatureGossipEvent(CONFIG.NPC_ID, 1, OnGossipHello) -- GOSSIP_EVENT_ON_HELLO
RegisterCreatureGossipEvent(CONFIG.NPC_ID, 2, OnGossipSelect) -- GOSSIP_EVENT_ON_SELECT
