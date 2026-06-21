--[[
    Premium NPC Configuration

    Shared home for summonable, follow-you-around "premium" NPCs. Each NPC
    type gets its own entry ID and duration below; the actual summon
    mechanic itself lives in premium_npc_summon.lua, shared by all of them.

    Access to each NPC type is governed by three layers, checked in order
    by IsPremiumNpcAllowed in premium_npc_access.lua:
    1. ENABLED below - a global kill switch for every premium NPC.
    2. Each NPC type's own ENABLED flag.
    3. PER_ACCOUNT_ACCESS_CONTROL_ENABLED - if true, an account additionally
       needs a matching row in premium_npc_account_access for that NPC
       type's KEY, or it's denied. If false, layers 1-2 alone decide.

    @module premium_npc_config
]]

PREMIUM_NPC_CONFIG = {
    ENABLED = true,

    PER_ACCOUNT_ACCESS_CONTROL_ENABLED = true,

    PROFESSION_TRAINER = {
        KEY = "profession",
        NPC_ID = 900200,
        SUMMON_DURATION_SECONDS = 120,
        ENABLED = true,
    },

    HEIRLOOM_VENDOR = {
        KEY = "heirloom",
        NPC_ID = 900201,
        SUMMON_DURATION_SECONDS = 120,
        ENABLED = true,
    },

    CLASS_TRAINER = {
        KEY = "class",
        SUMMON_DURATION_SECONDS = 120,
        ENABLED = true,

        -- Which creature gets summoned depends on the player's own class
        -- and faction - unlike Profession Trainer, a player can only ever
        -- use their own class's spells, so there's nothing to aggregate
        -- into one NPC. These are real, existing trainer creatures
        -- (Trainer::Type::Class, each with its own dedicated gossip menu -
        -- train + unlearn talents + dual spec), reused directly rather
        -- than recreated - no new creature_template/trainer/gossip SQL
        -- needed for this NPC type at all. Death Knight has only one
        -- entry, shared by both teams (the Ebon Hold trainer isn't
        -- faction-split like the others).
        --
        -- [classId][teamId] = creature_template entry. classId matches
        -- the standard Classes (1 Warrior, 2 Paladin, 3 Hunter, 4 Rogue,
        -- 5 Priest, 6 Death Knight, 7 Shaman, 8 Mage, 9 Warlock,
        -- 11 Druid). teamId: 0 Alliance, 1 Horde.
        ENTRIES = {
            [1]  = { [0] = 5479,  [1] = 3354 },  -- Warrior
            [2]  = { [0] = 928,   [1] = 23128 }, -- Paladin
            [3]  = { [0] = 5515,  [1] = 3406 },  -- Hunter
            [4]  = { [0] = 918,   [1] = 3401 },  -- Rogue
            [5]  = { [0] = 376,   [1] = 3045 },  -- Priest
            [6]  = { [0] = 28472, [1] = 28472 }, -- Death Knight
            [7]  = { [0] = 20407, [1] = 3344 },  -- Shaman
            [8]  = { [0] = 5497,  [1] = 5883 },  -- Mage
            [9]  = { [0] = 461,   [1] = 3324 },  -- Warlock
            [11] = { [0] = 5504,  [1] = 3033 },  -- Druid
        },
    },
}
