# Premium-NPC

A standalone AzerothCore ALE/Lua module providing summonable, follow-you-around "premium" NPCs. Each NPC type is summoned via a dot-command, follows the player around for a fixed duration, then despawns on its own.

## Requirements

- [ALE](https://github.com/azerothcore/mod-ale) ("AzerothCore Lua Engine") installed and running.

## Setup

1. Symlink (or copy) `serverside/premium_npc/` into ALE's configured script path (`lua_scripts/premium_npc` by default - see `ALE.ScriptPath` in `mod_ale.conf`).
2. Apply the SQL in `sql/` against `acore_world`.
3. New `creature_template` rows are only picked up by a full worldserver restart (not `.reload ale`, and not `.reload creature_template`, which only refreshes existing entries) - restart once after applying new SQL here.
4. `.reload ale` to load the Lua.

## Current NPCs

### Profession Trainer

- Trigger: `.premium_npc profession`
- Model/`unit_class` borrowed from the real Gelman Stonehand (Mining Trainer, entry 5513) - his own row is never modified.
- `creature_template` entry 900200.
- Summons next to the player, follows for `PREMIUM_NPC_CONFIG.PROFESSION_TRAINER.SUMMON_DURATION_SECONDS` (120s by default), then despawns. Re-summoning while one is still out reports the remaining cooldown instead of spawning a second one.
- Does not yet teach anything - its `npc_trainer` list is empty. See Roadmap below.

## Architecture

- `premium_npc_summon.lua` - the shared summon/follow/cooldown mechanic, used by every NPC type. Spawns a `TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT` copy of the given creature entry, makes it follow the player, and matches its faction to the player's.
- `premium_npc_config.lua` - per-NPC-type settings (entry ID, summon duration).
- One file per NPC type (e.g. `profession_trainer.lua`) - owns only that NPC's summon trigger (the dot-command). Whatever that NPC actually *does* once summoned (trainer spells, vendor items, gossip, etc.) is configured entirely through standard AzerothCore data (`npc_trainer`, `npc_vendor`, gossip tables) against its own `creature_template` entry, not custom Lua logic.

## Roadmap

- Populate Profession Trainer's `npc_trainer` list with every profession's full rank-up chain (Apprentice through Grand Master) and recipe list, combined into one window. Ordered low-to-high rank per profession, since the native Trainer window shows whatever order the data is in and doesn't dynamically sort by what's currently trainable.
- Add a Heirloom Vendor NPC here, using the same summon mechanic. (A heirloom vendor currently exists in a separate `mod-roguelite` module with its own compiled C++ summon implementation; the plan is to reimplement it here instead, since `mod-roguelite` is expected to be retired.)
