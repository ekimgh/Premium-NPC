# Premium-NPC

A standalone AzerothCore ALE/Lua module providing summonable, follow-you-around "premium" NPCs. Each NPC type is summoned via a dot-command, follows the player around for a fixed duration, then despawns on its own. Only one premium NPC (of any type) can be active per player at a time - summoning a new one despawns whichever one that player already has out.

## Requirements

- [ALE](https://github.com/azerothcore/mod-ale) ("AzerothCore Lua Engine") installed and running.

## Setup

1. Symlink (or copy) `serverside/premium_npc/` into ALE's configured script path (`lua_scripts/premium_npc` by default - see `ALE.ScriptPath` in `mod_ale.conf`).
2. Apply the SQL in `sql/db-world/` against `acore_world` and `sql/db-characters/` against `acore_characters`.
3. New `creature_template` rows are only picked up by a full worldserver restart (not `.reload ale`, and not `.reload creature_template`, which only refreshes existing entries) - restart once after applying new SQL here. Changes to an *existing* entry's fields (e.g. `gossip_menu_id`) just need `.reload creature_template <entry>`. `trainer`/`trainer_spell` changes need `.reload trainer`. `gossip_menu_option` changes need `.reload gossip_menu_option`. None of these targeted reloads need a restart.
4. `.reload ale` to load the Lua.

## Access control

Three layers, checked in this order (`premium_npc_access.lua`, `IsPremiumNpcAllowed`):

1. `PREMIUM_NPC_CONFIG.ENABLED` - global kill switch for every premium NPC.
2. Each NPC type's own `ENABLED` flag (e.g. `PREMIUM_NPC_CONFIG.PROFESSION_TRAINER.ENABLED`).
3. `PREMIUM_NPC_CONFIG.PER_ACCOUNT_ACCESS_CONTROL_ENABLED` - if `true`, an account additionally needs a row in `premium_npc_account_access` (`account_id`, `npc_key`) matching that NPC type's `KEY` (e.g. `"profession"`), or it's denied. If `false` (the default), layers 1-2 alone decide, and every account has access to every enabled NPC type.

## Architecture

- `premium_npc_summon.lua` - the shared summon/follow mechanic, used by every NPC type. Spawns a `TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT` copy of the given creature entry, makes it follow the player, matches its faction to the player's, and despawns any premium NPC that player already has active first.
- `premium_npc_config.lua` - per-NPC-type settings (entry ID, summon duration, enabled flag, access-control key) plus the two global toggles described above.
- `premium_npc_access.lua` - `IsPremiumNpcAllowed(player, npcConfig)`, the three-layer access check described above.
- One file per NPC type (e.g. `profession_trainer.lua`) - owns only that NPC's summon trigger (the dot-command) and the access check before summoning. Whatever that NPC actually *does* once summoned (trainer spells, vendor items, gossip, etc.) is configured entirely through standard AzerothCore data (`npc_trainer`, `npc_vendor`, gossip tables) against its own `creature_template` entry, not custom Lua logic.\

## Current NPCs

### Profession Trainer

- Trigger: `.premium_npc profession`
- Model/`unit_class` borrowed from the real Gelman Stonehand (Mining Trainer, entry 5513) - his own row is never modified.
- `creature_template` entry 900200.
- Summons next to the player, follows for `PREMIUM_NPC_CONFIG.PROFESSION_TRAINER.SUMMON_DURATION_SECONDS` (120s by default), then despawns (or despawns early if a different premium NPC is summoned first).
- Teaches every profession's full rank-up chain and recipe list from one trainer window (`sql/db-world/02_profession_trainer_spells.sql`) - aggregated from every real profession trainer in the game (base + Master + Grand Master + specialization trainers), deduplicated by spell, ordered low-to-high skill rank within each profession. The native Trainer window shows whatever's not yet trainable as greyed/red rather than hiding it.

### Heirloom Vendor

- Trigger: `.premium_npc heirloom`
- Model/faction borrowed from the real Enchanter Isian (Heirloom Vendor, entry 35507) - her own row is never modified.
- `creature_template` entry 900201.
- Summons next to the player, follows for `PREMIUM_NPC_CONFIG.HEIRLOOM_VENDOR.SUMMON_DURATION_SECONDS` (120s by default), then despawns (or despawns early if a different premium NPC is summoned first).
- Sells every heirloom-quality (`Quality = 7`) weapon/armor item in `item_template` at its existing `BuyPrice`, with no extra currency, catalog, or unlock gating - a plain `npc_vendor` list (`sql/db-world/04_heirloom_vendor.sql`), no custom purchase logic. Excludes two known non-heirloom anomalies in the base game data (entries 44090, 38691).
