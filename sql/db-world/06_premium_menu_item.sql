-- Repurposes item_template entry 38691 ("Ancestral Claymore") into the
-- premium menu item - a usable item that opens a gossip menu listing
-- every premium NPC type the player's account has access to. Chosen
-- instead of a new item_template row because this entry is a confirmed
-- Blizzard debug/test leftover: it has no stats and isn't sold, looted,
-- or quest-rewarded anywhere in the base game data (the same reason it
-- was excluded from the Heirloom Vendor's catalog - see
-- sql/db-world/04_heirloom_vendor.sql) - completely orphaned, so
-- repurposing it carries no risk of affecting any real player or vendor.
--
-- class/subclass changed from Weapon/Two-Hand Sword to Miscellaneous/
-- Junk, and InventoryType to 0 (non-equippable) - this is what actually
-- makes "Use" available instead of "Equip" on right-click. Quality stays
-- 7 (heirloom) deliberately - Quality only controls the tooltip
-- color/glow, it's independent of InventoryType/equippability, so there's
-- no conflict keeping the heirloom-flashy look on a non-equippable item.
-- DisplayID 1143 is a plain book/tome icon (same one mod-premium's own
-- equivalent item uses), not the original claymore model.
--
-- spellid_1/spelltrigger_1 attach Hearthstone's own real spell (8690) as
-- a placeholder, purely because the client only offers "Use" at all for
-- an item with a real on-use spell attached - premium_menu_item.lua's
-- gossip hooks return false on every interaction, which suppresses this
-- spell from ever actually casting (confirmed via
-- WorldSession::HandleUseItemOpcode in core source); it only matters as
-- a safe fallback if that script somehow failed to load.
UPDATE `item_template` SET
    `name` = 'Premium Menu',
    `class` = 15,
    `subclass` = 0,
    `InventoryType` = 0,
    `DisplayID` = 1143,
    `spellid_1` = 8690,
    `spelltrigger_1` = 0,
    `spellcharges_1` = 0,
    `maxcount` = 1,
    `description` = 'Use to access your premium services.'
WHERE `entry` = 38691;

-- Gossip header text shown above the menu (premium_menu_item.lua's
-- OnGossipHello). A new row scoped to our own use, not a reused real one.
DELETE FROM `npc_text` WHERE `ID` = 900203;
INSERT INTO `npc_text` (`ID`, `text0_0`) VALUES
(900203, 'What would you like to do?');
