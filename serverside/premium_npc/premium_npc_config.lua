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
}
