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
    and 02_profession_trainer_spells.sql) - this file has no trainer-spell
    logic of its own beyond the workaround below.

    Workaround: the server only ever sends the trainer's spell list once,
    when the window is first opened (core's own WorldSession::SendTrainerList,
    called from CMSG_TRAINER_LIST) - it never resends it after a successful
    teach. The client is left to recolor the remaining entries on its own
    from locally-tracked state, and on a full profession's recipe list this
    is unreliable - other recipes can show green (available) after learning
    one, even though the actual purchase still correctly fails server-side
    (Trainer::CanTeachSpell re-checks fresh, so nothing is exploitable, it's
    a display bug only). Forcing a fresh SendTrainerList after every learn
    makes the client redraw with current, correct data instead.

    @module profession_trainer
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local CONFIG = PREMIUM_NPC_CONFIG.PROFESSION_TRAINER

--- Checks access and summons the Profession Trainer if allowed, messaging
-- the player either way. Shared by the .premium_npc profession command
-- and premium_menu_item.lua's item-based menu.
function TryProfessionTrainer(player)
    local allowed, reason = IsPremiumNpcAllowed(player, CONFIG)
    if allowed then
        SummonPremiumNpc(player, CONFIG.NPC_ID, CONFIG.SUMMON_DURATION_SECONDS)
    else
        player:SendBroadcastMessage(reason)
    end
end

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc profession" then
        return
    end

    TryProfessionTrainer(player)
    return false
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND

--- Closes the trainer window immediately after any spell is learned, so
-- stale/incorrectly-colored entries never linger - see the workaround
-- note above. Tried resending the list in place first (with and without
-- a delay) to refresh it without closing, but the client only ever
-- redraws a trainer list once per "session" - it silently ignores a
-- second one sent into an already-open window, so the colors stayed
-- wrong either way. An immediate resend reliably closes the window
-- instead (most likely the client reacting to an unprompted list arriving
-- mid-transaction), and a fresh open afterward is confirmed to always
-- show correct colors, so this leans into that rather than fighting it -
-- the recipe list is large enough on this trainer that leaving it open
-- with wrong colors is worse than having to reopen it. Fires for every
-- spell learn, not just ones taught here; harmless if the player's
-- premium NPC isn't actually a Profession Trainer they're currently
-- looking at, since SendTrainerList has no visible effect if that
-- window isn't open.
local function OnPlayerLearnSpell(event, player, spellId)
    local npcGuid = GetActivePremiumNpcGuid(player)
    if not npcGuid then
        return
    end

    local npc = player:GetMap():GetWorldObject(npcGuid)
    if not npc or npc:GetEntry() ~= CONFIG.NPC_ID or not npc:IsTrainer() then
        return
    end

    player:SendTrainerList(npc)
end

RegisterPlayerEvent(44, OnPlayerLearnSpell) -- PLAYER_EVENT_ON_LEARN_SPELL
