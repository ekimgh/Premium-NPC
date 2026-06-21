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

`IsPremiumEnabled(player)` (same file) answers the cheaper question "does this player have access to *any* premium NPC type at all" in at most one query, for callers that don't care which specific type (e.g. deciding whether to grant the premium menu item below) - it doesn't replace `IsPremiumNpcAllowed` for an actual per-type decision.

Note: access is only checked when summoning - once an NPC is out, anyone nearby (not just the summoning player) can interact with it. This is a known, deliberate gap, not a bug - see the Premium-NPC access scope decision in this project's notes if revisiting it.

## Architecture

- `premium_npc_summon.lua` - the shared summon/follow mechanic, used by every NPC type. Spawns a `TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT` copy of the given creature entry, makes it follow the player, matches its faction to the player's, and despawns any premium NPC that player already has active first.
- `premium_npc_config.lua` - per-NPC-type settings (entry ID, summon duration, enabled flag, access-control key) plus the two global toggles described above.
- `premium_npc_access.lua` - `IsPremiumNpcAllowed(player, npcConfig)` and `IsPremiumEnabled(player)`, described above.
- One file per NPC type (e.g. `profession_trainer.lua`) - owns that NPC's summon trigger (the dot-command) and exposes a shared `Try<Name>(player)` function (e.g. `TryProfessionTrainer`) that does the actual access-check-then-summon work. The dot-command handler and `premium_menu_item.lua`'s item menu both just call that same function, rather than duplicating the check-then-summon logic in each caller. Whatever the NPC actually *does* once summoned (trainer spells, vendor items, gossip, etc.) is configured entirely through standard AzerothCore data (`npc_trainer`, `npc_vendor`, gossip tables) against its own `creature_template` entry, not custom Lua logic.
- `premium_menu_item.lua` - the premium menu item described below.

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
- Also repairs equipped gear (`UNIT_NPC_FLAG_REPAIR`), at the normal gold cost the engine computes per item's own durability loss.

### Class Trainer

- Trigger: `.premium_npc class`
- Unlike the other two NPCs, this one needs no new SQL at all: a player can only ever use their own class's spells, so there's nothing to aggregate the way Profession Trainer aggregates every profession into one NPC. Instead, `PREMIUM_NPC_CONFIG.CLASS_TRAINER.ENTRIES` maps the player's class and faction directly to a real, existing class trainer creature (e.g. Warrior Alliance -> entry 5479) and summons a temporary copy of it - same mechanic as the other two, just pointed at real data instead of a custom entry. Death Knight uses a single entry for both factions (the Ebon Hold trainer isn't faction-split like the others).
- Summons next to the player, follows for `PREMIUM_NPC_CONFIG.CLASS_TRAINER.SUMMON_DURATION_SECONDS` (120s by default), then despawns (or despawns early if a different premium NPC is summoned first).
- Offers training plus "unlearn talents" and "Dual Talent Specialization" - real class trainers' own dedicated gossip menus include both, unlike profession trainers (confirmed by inspecting several real trainers' `gossip_menu_option` rows directly).

### Teleporter

- Trigger: `.premium_npc teleporter`
- Model borrowed from the real Archmage Xylem (the Dalaran-sewers city teleporter NPC, entry 8379) - his own row is never modified. Unlike that model choice, his actual teleport behavior isn't reusable data (his `gossip_menu_id` is just the generic shared pool), so this NPC's destination menu is built entirely in Lua (`teleporter.lua`'s `OnGossipHello`/`OnGossipSelect`, registered via `RegisterCreatureGossipEvent`) rather than native trainer/vendor tables.
- `creature_template` entry 900202.
- Summons next to the player, follows for `PREMIUM_NPC_CONFIG.TELEPORTER.SUMMON_DURATION_SECONDS` (120s by default), then despawns (or despawns early if a different premium NPC is summoned first).
- Lists only the player's own faction's four major cities (no zones/dungeons/raids) - `PREMIUM_NPC_CONFIG.TELEPORTER.DESTINATIONS`. Coordinates were verified against this server's own `game_graveyard` table and real in-city creature positions rather than taken on faith from any reference source.

## Premium Menu item

- Granted via `.premium_npc menu` (one copy, `maxcount` 1, if the player has access to at least one premium NPC type, denies otherwise) or automatically on a new character's first ever login if premium is enabled for that account at that moment.
- Item entry 9017, repurposed from a confirmed-orphaned item ("Codex of Holy Protection III" - no references in any loot/vendor/quest-reward table) rather than a new `item_template` row - see `sql/db-world/06_premium_menu_item.sql`. Quality stays 7 (heirloom-flashy) deliberately; only `InventoryType`, class/subclass, and the icon changed, which is what makes it usable instead of equippable.
- Right-click ("Use") opens a gossip menu pre-filtered to only the NPC types the player's account currently has access to (so there's nothing to select that would just be denied afterward), each with its own thematic icon. Selecting one calls that NPC type's own shared `Try<Name>(player)` function - the exact same access-check-then-summon logic its dot-command uses, not a separate copy.
- The item's attached placeholder spell (5407, "Segra Darkthorn Effect" - required only because the client won't offer "Use" at all without *some* on-use spell attached) never actually casts - both gossip hooks return `false`, which suppresses it.
