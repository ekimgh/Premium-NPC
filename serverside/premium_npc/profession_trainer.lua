--[[
    Profession Trainer

    Summons a temporary profession trainer NPC that follows the player,
    picked by profession key rather than a single fixed entry - see
    PREMIUM_NPC_CONFIG.PROFESSION_TRAINER.PROFESSIONS in premium_npc_config.lua
    for the full key -> creature_template entry list and why each entry is
    one of this module's own creatures rather than a real one reused
    directly. See premium_npc_summon.lua for the actual summon/follow
    mechanic and premium_npc_access.lua for the enable/disable and
    per-account access checks applied below.

    Trigger: .premium_npc profession <key> (e.g. ".premium_npc profession
    blacksmithing") - dot-command, same mechanism as Paragon's/Prestige's
    own debug commands, fires via PLAYER_EVENT_ON_COMMAND, not a client
    slash command. Returning false once the command is recognized as ours
    suppresses the core's "unknown command" message. With no key (or an
    unrecognized one), prints the list of valid keys instead of summoning
    anything - there's no native UI a bare dot-command can show a picker
    through, unlike the Premium Menu item (premium_menu_item.lua), which
    builds its own profession submenu directly in its existing gossip
    instead of going through this command at all.

    Whatever each profession's trainer teaches is configured entirely
    through its own creature_template entry's trainer/trainer_spell rows
    (sql/db-world/02_profession_trainer_spells.sql) - this file has no
    trainer-spell logic of its own beyond the workaround below.

    Workaround: the server only ever sends a trainer's spell list once,
    when the window is first opened (core's own WorldSession::SendTrainerList,
    called from CMSG_TRAINER_LIST) - it never resends it after a successful
    teach. The client is left to recolor the remaining entries on its own
    from locally-tracked state, and on a large recipe list this is
    unreliable - other recipes can show green (available) after learning
    one, even though the actual purchase still correctly fails server-side
    (Trainer::CanTeachSpell re-checks fresh, so nothing is exploitable, it's
    a display bug only). Forcing a fresh SendTrainerList after every learn
    makes the client redraw with current, correct data instead. Applies to
    every profession's trainer here - all 14 have large recipe lists, not
    just the old single all-professions NPC.

    @module profession_trainer
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local CONFIG = PREMIUM_NPC_CONFIG.PROFESSION_TRAINER

-- key -> profession entry (table), and entry id -> true, built once.
local professionsByKey = {}
local professionEntries = {}
for _, profession in ipairs(CONFIG.PROFESSIONS) do
    professionsByKey[profession.key] = profession
    professionEntries[profession.entry] = true
end

--- Checks access and summons the given profession's trainer if allowed,
-- messaging the player either way. With no professionKey (or one that
-- doesn't match PROFESSIONS), messages the list of valid keys instead of
-- summoning anything. Shared by the .premium_npc profession command and
-- premium_menu_item.lua's item-based profession submenu.
function TryProfessionTrainer(player, professionKey)
    local allowed, reason = IsPremiumNpcAllowed(player, CONFIG)
    if not allowed then
        player:SendBroadcastMessage(reason)
        return
    end

    local profession = professionKey and professionsByKey[professionKey]
    if not profession then
        local keys = {}
        for _, p in ipairs(CONFIG.PROFESSIONS) do
            table.insert(keys, p.key)
        end
        player:SendBroadcastMessage("Usage: .premium_npc profession <name>. Available: " .. table.concat(keys, ", "))
        return
    end

    SummonPremiumNpc(player, profession.entry, CONFIG.SUMMON_DURATION_SECONDS)
end

local function OnPlayerCommand(event, player, command)
    local professionKey = command:match("^premium_npc profession%s+(%S+)$")
    if not professionKey and command ~= "premium_npc profession" then
        return
    end

    TryProfessionTrainer(player, professionKey)
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
-- profession recipe lists are large enough that leaving one open with
-- wrong colors is worse than having to reopen it. Fires for every spell
-- learn, not just ones taught here; harmless if the player's premium NPC
-- isn't actually one of our profession trainers they're currently looking
-- at, since SendTrainerList has no visible effect if that window isn't
-- open.
local function OnPlayerLearnSpell(event, player, spellId)
    local npcGuid = GetActivePremiumNpcGuid(player)
    if not npcGuid then
        return
    end

    local npc = player:GetMap():GetWorldObject(npcGuid)
    if not npc or not professionEntries[npc:GetEntry()] or not npc:IsTrainer() then
        return
    end

    player:SendTrainerList(npc)
end

RegisterPlayerEvent(44, OnPlayerLearnSpell) -- PLAYER_EVENT_ON_LEARN_SPELL
