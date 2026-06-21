--[[
    Premium NPC Access

    Checks whether a player's account is allowed to use a given premium NPC
    type, applying the three layers documented in premium_npc_config.lua in
    order: the global kill switch, that NPC type's own enabled flag, and
    (only if turned on) the per-account whitelist.

    @module premium_npc_access
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

--- @param player Player
--- @param npcConfig table One of PREMIUM_NPC_CONFIG's per-NPC-type tables (needs .KEY and .ENABLED)
--- @return boolean allowed
--- @return string|nil reason Message to show the player if not allowed
function IsPremiumNpcAllowed(player, npcConfig)
    if not PREMIUM_NPC_CONFIG.ENABLED then
        return false, "Premium NPCs are currently disabled on this server."
    end

    if not npcConfig.ENABLED then
        return false, "This premium NPC is currently disabled."
    end

    if not PREMIUM_NPC_CONFIG.PER_ACCOUNT_ACCESS_CONTROL_ENABLED then
        return true
    end

    local accountId = player:GetAccountId()
    local result = CharDBQuery(string.format(
        "SELECT 1 FROM premium_npc_account_access WHERE account_id = %d AND npc_key = '%s'",
        accountId, npcConfig.KEY
    ))

    if not result then
        return false, "Your account does not have access to this premium NPC."
    end

    return true
end

--- Cheap check for whether ANY premium NPC type could possibly be
-- allowed for this player right now - for callers that don't care which
-- specific type, just whether there's at least one (e.g. deciding
-- whether to grant the premium menu item at all). Runs at most one query
-- regardless of how many NPC types exist, instead of calling
-- IsPremiumNpcAllowed (one query each, when per-account control is on)
-- once per type just to answer that.
--- @param player Player
--- @return boolean enabled
function IsPremiumEnabled(player)
    if not PREMIUM_NPC_CONFIG.ENABLED then
        return false
    end

    local anyTypeEnabled = false
    for _, npcConfig in pairs(PREMIUM_NPC_CONFIG) do
        if type(npcConfig) == "table" and npcConfig.ENABLED then
            anyTypeEnabled = true
            break
        end
    end
    if not anyTypeEnabled then
        return false
    end

    if not PREMIUM_NPC_CONFIG.PER_ACCOUNT_ACCESS_CONTROL_ENABLED then
        return true
    end

    local accountId = player:GetAccountId()
    local result = CharDBQuery(string.format(
        "SELECT 1 FROM premium_npc_account_access WHERE account_id = %d LIMIT 1",
        accountId
    ))

    return result ~= nil
end
