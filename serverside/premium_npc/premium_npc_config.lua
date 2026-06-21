--[[
    Premium NPC Configuration

    Shared home for summonable, follow-you-around "premium" NPCs (Profession
    Trainer today, with more planned - e.g. eventually migrating
    mod-roguelite's Heirloom Vendor here too). Each NPC type gets its own
    entry ID and duration below; the actual summon mechanic itself lives in
    premium_npc_summon.lua, shared by all of them.

    @module premium_npc_config
]]

PREMIUM_NPC_CONFIG = {
    PROFESSION_TRAINER = {
        NPC_ID = 900200,
        SUMMON_DURATION_SECONDS = 120,
    },
}
