-- Per-account whitelist of which premium NPC types an account may use.
-- Only consulted at all when PREMIUM_NPC_CONFIG.PER_ACCOUNT_ACCESS_CONTROL_ENABLED
-- is true (see premium_npc_config.lua) - an account with no row here for a
-- given npc_key is denied that NPC type whenever that mode is on. When
-- that mode is off, this table isn't read at all and every account has
-- access to every NPC type that's otherwise enabled.
--
-- npc_key matches each NPC type's own `KEY` value in premium_npc_config.lua
-- (e.g. "profession" for the Profession Trainer).
CREATE TABLE IF NOT EXISTS `premium_npc_account_access` (
    `account_id` INT UNSIGNED NOT NULL,
    `npc_key` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`account_id`, `npc_key`)
) ENGINE=InnoDB;
