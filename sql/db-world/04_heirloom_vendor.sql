-- "Heirloom Vendor" - summonable, follows the player. Model, faction, and
-- unit_flags copied from the real "Enchanter Isian" heirloom vendor (entry
-- 35507, CreatureDisplayID 29830, faction 2027) - a separate entry, her
-- own row/model/vendor list are never touched.
--
-- unit_flags 770 = UNIT_FLAG_NON_ATTACKABLE (0x2) | UNIT_FLAG_IMMUNE_TO_PC
-- (0x100) | UNIT_FLAG_IMMUNE_TO_NPC (0x200): this NPC follows the player
-- through potentially hostile areas and needs the fuller set - without
-- it, a following summon gets pulled into combat by nearby hostile
-- creatures and abandons the player to run back to its spawn point.
--
-- npcflag 4224 = UNIT_NPC_FLAG_VENDOR (0x80) | UNIT_NPC_FLAG_REPAIR
-- (0x1000): also repairs equipped gear, at the normal gold cost the
-- engine computes per item's own durability loss - no extra data needed.
DELETE FROM `creature_template` WHERE `entry` = 900201;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `RegenHealth`) VALUES
(900201, 'Heirloom Vendor', 'Premium', 80, 80, 2027, 4224, 8, 770, 1);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 900201;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(900201, 0, 29830, 1, 1);

-- Sells every heirloom-quality (Quality = 7) weapon/armor item that
-- exists in item_template, at whatever its existing BuyPrice already is -
-- no ExtendedCost, no per-item catalog, no gating, just a plain vendor.
-- Excluded: 44090 ("Test Mail Shoulder 2", a Blizzard test/debug leftover)
-- and 38691 ("Ancestral Claymore", has no stats and isn't actually sold by
-- any real heirloom vendor in the base game data - not a real heirloom).
-- maxcount = 0: unlimited stock, never depletes.
DELETE FROM `npc_vendor` WHERE `entry` = 900201;
INSERT INTO `npc_vendor` (`entry`, `item`, `slot`, `maxcount`, `incrtime`, `ExtendedCost`)
    SELECT 900201, `entry`, ROW_NUMBER() OVER (ORDER BY `entry`) - 1, 0, 0, 0
    FROM `item_template` WHERE `Quality` = 7 AND `class` IN (2, 4) AND `entry` NOT IN (44090, 38691);
