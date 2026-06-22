-- "Glyph Vendor" - summonable, follows the player. Model/faction copied
-- from the real "Librarian Ingram" Inscription Supplies vendor (entry
-- 27143, CreatureDisplayID 24346, faction 2006) - a separate entry, her
-- own row/model/vendor list are never touched.
--
-- unit_flags 770 = UNIT_FLAG_NON_ATTACKABLE (0x2) | UNIT_FLAG_IMMUNE_TO_PC
-- (0x100) | UNIT_FLAG_IMMUNE_TO_NPC (0x200): this NPC follows the player
-- through potentially hostile areas and needs the fuller set - without
-- it, a following summon gets pulled into combat by nearby hostile
-- creatures and abandons the player to run back to its spawn point.
--
-- npcflag 128 = UNIT_NPC_FLAG_VENDOR only - no repair (unlike the
-- Heirloom Vendor), since repair isn't thematically relevant here.
--
-- One creature_template entry per class (900203-900212) rather than one
-- shared entry for all ten, even though every player only ever sees
-- their own class's ~33-47 glyphs (well under the 150-item
-- SMSG_LIST_INVENTORY display cap). The reason isn't the display cap -
-- it's that VendorItemData::GetItemCount() (CreatureData.h) returns
-- uint8, so a single creature's *stored* npc_vendor list silently
-- truncates at 255 total rows, before any per-player filtering ever
-- runs. All ten classes' glyphs combined (353) blow past that, which
-- was confirmed live: a single shared entry filtered by a `conditions`
-- CONDITION_CLASS row per item (an earlier version of this file) showed
-- an empty vendor window for some classes, because 353 truncates to 97
-- and only the 97 numerically-lowest glyph entries (irrespective of
-- class) were ever even considered. Same per-class `ENTRIES` pattern
-- Class Trainer already uses (premium_npc_config.lua), just keyed by
-- class only (glyphs aren't faction-specific, unlike class trainers).
DELETE FROM `creature_template` WHERE `entry` BETWEEN 900203 AND 900212;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `RegenHealth`) VALUES
(900203, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Warrior
(900204, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Paladin
(900205, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Hunter
(900206, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Rogue
(900207, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Priest
(900208, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Death Knight
(900209, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Shaman
(900210, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Mage
(900211, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1), -- Warlock
(900212, 'Glyph Vendor', 'Premium', 80, 80, 2006, 128, 8, 770, 1); -- Druid

DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 900203 AND 900212;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(900203, 0, 24346, 1, 1),
(900204, 0, 24346, 1, 1),
(900205, 0, 24346, 1, 1),
(900206, 0, 24346, 1, 1),
(900207, 0, 24346, 1, 1),
(900208, 0, 24346, 1, 1),
(900209, 0, 24346, 1, 1),
(900210, 0, 24346, 1, 1),
(900211, 0, 24346, 1, 1),
(900212, 0, 24346, 1, 1);

-- Each entry's own npc_vendor list holds only that one class's real
-- glyphs (class = 16), at whatever BuyPrice already is - no
-- ExtendedCost, no per-item catalog. AllowableClass is used both to pick
-- which entry an item belongs to (real glyphs already carry the correct
-- per-class bitmask there - confirmed against ItemTemplate.h's
-- ITEM_SUBCLASS_GLYPH_* order and SharedDefines.h's Classes enum) and to
-- exclude 11 known junk rows under class 16 in the base game data
-- (AllowableClass = -1: Blizzard "NPC Equip" placeholders and one
-- "Deprecated Test Glyph") that are not real, sellable glyphs - same
-- kind of known-anomaly exclusion the Heirloom Vendor's own catalog
-- already does (entries 44090/38691). maxcount = 0: unlimited stock,
-- never depletes.
DELETE FROM `npc_vendor` WHERE `entry` BETWEEN 900203 AND 900212;
INSERT INTO `npc_vendor` (`entry`, `item`, `slot`, `maxcount`, `incrtime`, `ExtendedCost`)
    SELECT m.vendor_entry, it.entry, ROW_NUMBER() OVER (PARTITION BY m.vendor_entry ORDER BY it.entry) - 1, 0, 0, 0
    FROM `item_template` it
    JOIN (
        SELECT 900203 AS vendor_entry, 1 AS class_mask -- Warrior
        UNION ALL SELECT 900204, 2                     -- Paladin
        UNION ALL SELECT 900205, 4                     -- Hunter
        UNION ALL SELECT 900206, 8                     -- Rogue
        UNION ALL SELECT 900207, 16                    -- Priest
        UNION ALL SELECT 900208, 32                    -- Death Knight
        UNION ALL SELECT 900209, 64                    -- Shaman
        UNION ALL SELECT 900210, 128                   -- Mage
        UNION ALL SELECT 900211, 256                   -- Warlock
        UNION ALL SELECT 900212, 1024                  -- Druid
    ) AS m
    ON it.AllowableClass = m.class_mask
    WHERE it.class = 16 AND it.AllowableClass > 0;

-- No `conditions` rows needed - each entry above only ever contains its
-- own class's glyphs, so there's nothing left to filter per-player.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 23 AND `SourceGroup` BETWEEN 900203 AND 900212;
