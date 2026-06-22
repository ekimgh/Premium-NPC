--[[
    Premium Menu Item

    A usable item ("Premium Menu", entry 9017 - repurposed from a
    confirmed-orphaned item ("Codex of Holy Protection III", zero
    references in any loot/vendor/quest-reward table) rather than a new
    item_template row, see sql/db-world/06_premium_menu_item.sql) that
    opens a gossip menu listing every premium NPC type the player's
    account currently has access to, as a convenience alternative to
    typing each .premium_npc <type> command directly.

    This entry's *original* client-side Item.dbc record already has
    InventoryType 0 (non-equippable) and the book/tome icon used below -
    client and server data already agree, so no binary Item.dbc patch is
    needed (unlike an earlier attempt with a different entry that really
    was a two-handed sword client-side, which left a stale sword icon).

    The menu is filtered at build time: a type only appears if
    IsPremiumNpcAllowed (premium_npc_access.lua) currently allows it for
    that player, so there's nothing to select that would just be denied
    afterward. Selecting an option runs the exact same
    access-check-then-summon logic as its own dot-command, by calling
    that NPC type's own shared Try<Name>(player) function (defined in its
    own file - profession_trainer.lua, heirloom_vendor.lua,
    glyph_vendor.lua, class_trainer.lua, teleporter.lua) - not a separate
    copy of that logic.

    Both gossip hooks return false, which (confirmed via
    WorldSession::HandleUseItemOpcode in core source) suppresses the
    item's attached spell (5407, "Segra Darkthorn Effect" - an unused,
    harmless leftover, only attached because the client requires some
    on-use spell to offer "Use" at all) from ever actually casting.

    Granted via .premium_npc menu (gives one copy if the player has
    access to at least one premium NPC type, reusing the same per-type
    access checks above, denies otherwise) or automatically on a new
    character's first ever login, if premium is enabled for that account
    at that moment.

    @module premium_menu_item
]]

dofile("lua_scripts/premium_npc/premium_npc_config.lua")

local ITEM_ENTRY = 9017

-- Ordered list of {label, config, run}. run(player) is each NPC type's
-- own shared Try<Name>(player) function, reused here rather than
-- duplicating the access-check-then-summon logic a second time.
-- icon: GossipOptionIcon value (GossipDef.h) - 1 vendor bag, 2 taxi
-- (paper airplane), 3 trainer book, 9 crossed swords (battle).
-- Refer to: https://www.azerothcore.org/wiki/gossip_menu_option
local OPTIONS = {
    { label = "Profession Trainer", icon = 3, config = PREMIUM_NPC_CONFIG.PROFESSION_TRAINER, run = function(player) TryProfessionTrainer(player) end },
    { label = "Heirloom Vendor", icon = 1, config = PREMIUM_NPC_CONFIG.HEIRLOOM_VENDOR, run = function(player) TryHeirloomVendor(player) end },
    { label = "Glyph Vendor", icon = 4, config = PREMIUM_NPC_CONFIG.GLYPH_VENDOR, run = function(player) TryGlyphVendor(player) end },
    { label = "Class Trainer", icon = 9, config = PREMIUM_NPC_CONFIG.CLASS_TRAINER, run = function(player) TryClassTrainer(player) end },
    { label = "Teleporter", icon = 2, config = PREMIUM_NPC_CONFIG.TELEPORTER, run = function(player) TryTeleporter(player) end },
}

-- [playerGuidLow] = the ordered list of options actually shown to that
-- player on their last OnGossipHello, so OnGossipSelect can map their
-- chosen intid back to the right one. Keyed per-player, not global -
-- two different players using this item around the same time must not
-- clobber each other's shown list.
local shownOptionsByPlayer = {}

local function OnGossipHello(event, player, item)
    local shown = {}
    for _, option in ipairs(OPTIONS) do
        if IsPremiumNpcAllowed(player, option.config) then
            table.insert(shown, option)
            player:GossipMenuAddItem(option.icon, option.label, 0, #shown)
        end
    end

    if #shown > 0 then
        shownOptionsByPlayer[player:GetGUIDLow()] = shown
        player:GossipSendMenu(900203, item) -- sql/db-world/06_premium_menu_item.sql
    else
        player:SendBroadcastMessage("You don't have access to any premium NPCs.")
        player:GossipComplete()
    end

    return false
end

local function OnGossipSelect(event, player, item, sender, intid)
    player:GossipComplete()

    local shown = shownOptionsByPlayer[player:GetGUIDLow()]
    local option = shown and shown[intid]
    if option then
        option.run(player)
    end

    return false
end

RegisterItemGossipEvent(ITEM_ENTRY, 1, OnGossipHello) -- GOSSIP_EVENT_ON_HELLO
RegisterItemGossipEvent(ITEM_ENTRY, 2, OnGossipSelect) -- GOSSIP_EVENT_ON_SELECT

local function GrantPremiumMenuItem(player)
    if player:AddItem(ITEM_ENTRY, 1) then
        player:SendBroadcastMessage("You received a Premium Menu item.")
    else
        player:SendBroadcastMessage("Could not give you a Premium Menu item - you may already have one, or your inventory is full.")
    end
end

local function OnPlayerCommand(event, player, command)
    if command ~= "premium_npc menu" then
        return
    end

    if IsPremiumEnabled(player) then
        GrantPremiumMenuItem(player)
    else
        player:SendBroadcastMessage("You don't have access to any premium NPCs.")
    end

    return false
end

RegisterPlayerEvent(42, OnPlayerCommand) -- PLAYER_EVENT_ON_COMMAND

local function OnFirstLogin(event, player)
    if IsPremiumEnabled(player) then
        GrantPremiumMenuItem(player)
    end
end

RegisterPlayerEvent(30, OnFirstLogin) -- PLAYER_EVENT_ON_FIRST_LOGIN
