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

    GLYPH_VENDOR = {
        KEY = "glyph",
        SUMMON_DURATION_SECONDS = 120,
        ENABLED = true,

        -- One creature_template entry per class rather than one shared
        -- entry for all ten - VendorItemData::GetItemCount() (core's
        -- CreatureData.h) returns uint8, so a single creature's *stored*
        -- npc_vendor list silently truncates at 255 total rows, before
        -- any per-player filtering runs. All ten classes' glyphs
        -- combined (353) blow past that. Same per-class ENTRIES pattern
        -- Class Trainer uses below, just keyed by class only - glyphs
        -- aren't faction-specific. classId matches the standard Classes
        -- (1 Warrior, 2 Paladin, 3 Hunter, 4 Rogue, 5 Priest,
        -- 6 Death Knight, 7 Shaman, 8 Mage, 9 Warlock, 11 Druid).
        ENTRIES = {
            [1]  = 900203, -- Warrior
            [2]  = 900204, -- Paladin
            [3]  = 900205, -- Hunter
            [4]  = 900206, -- Rogue
            [5]  = 900207, -- Priest
            [6]  = 900208, -- Death Knight
            [7]  = 900209, -- Shaman
            [8]  = 900210, -- Mage
            [9]  = 900211, -- Warlock
            [11] = 900212, -- Druid
        },
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

    TELEPORTER = {
        KEY = "teleporter",
        NPC_ID = 900202,
        SUMMON_DURATION_SECONDS = 120,
        ENABLED = true,

        -- Major-city destinations only (no zones/dungeons/raids), shown
        -- faction-gated - an account only ever sees its own faction's
        -- four cities. Coordinates verified against this server's own
        -- game_graveyard table and real in-city creature positions, not
        -- taken on faith from any reference source. Exodar and
        -- Silvermoon City genuinely use map 530 (the same map ID as
        -- Outland) - a real, confirmed quirk of how their Burning
        -- Crusade-era zones were added, not a typo.
        --
        -- [teamId] = ordered list of {name, map, x, y, z, o}. teamId:
        -- 0 Alliance, 1 Horde.
        DESTINATIONS = {
            [0] = {
                { name = "Stormwind",  map = 0,   x = -8842.09, y = 626.358,  z = 94.0867,  o = 3.61363 },
                { name = "Ironforge",  map = 0,   x = -4900.47, y = -962.585, z = 501.455,  o = 5.40538 },
                { name = "Darnassus",  map = 1,   x = 9869.91,  y = 2493.58,  z = 1315.88,  o = 2.78897 },
                { name = "Exodar",     map = 530, x = -3864.92, y = -11643.7, z = -137.644, o = 5.50862 },
            },
            [1] = {
                { name = "Orgrimmar",       map = 1,   x = 1601.08,  y = -4378.69, z = 9.9846,   o = 2.14362 },
                { name = "Thunder Bluff",   map = 1,   x = -1274.45, y = 71.8601,  z = 128.159,  o = 2.80623 },
                { name = "Undercity",       map = 0,   x = 1633.75,  y = 240.167,  z = -43.1034, o = 6.26128 },
                { name = "Silvermoon City", map = 530, x = 9738.28,  y = -7454.19, z = 13.5605,  o = 0.043914 },
            },
        },
    },
}
