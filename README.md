# DLC – Dungeon Leveling Companion

**Level 14–60 through dungeons, with a plan.** DLC tells your group which dungeon to run at your level, how many more runs until you swap, which quests and prerequisite chains to grab first, and reminds you to keep your XP buffs up.

Built for **WoW Forever**'s dungeon-leveling meta: the new Forever dungeons, the Spelunker achievements, cooked-food XP, Leatherworking camp tents and the Cozy Sleeping Bag.

---

## Features

### Where to go next
- A small movable panel shows the dungeon for your level, e.g. **"Now: The Deadmines (17–19) – ~2 more runs to 19"**.
- Separate **Alliance and Horde routes**, picked automatically from your character.
- Covers every dungeon from Hall of Thanes / Ragefire Chasm to Shaper's Terrace, including the new Forever dungeons (Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, City of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, Shaper's Terrace).

### Runs left, from real XP
- Estimates XP per run for every dungeon, then **learns from your actual runs**: when you leave a dungeon, the trash XP you earned (rested bonus and quest turn-ins excluded) is logged automatically.
- One measured run **auto-calibrates every other dungeon's estimate**.
- Counts XP from unfinished dungeon quests, prerequisite chains, Well Fed food, tent rested XP and the sleeping bag. Finished quests stop counting.
- Corpse runs and repair trips don't split a run; it ends 5 minutes after you leave or when the instance resets.

### Dungeon quests and prerequisites
- Lists each dungeon's quests in the panel: **grey** = pick it up (with where), **yellow** = in your log with progress, **green** = ready to turn in. Finished quests disappear.
- **Prerequisite chains, one tracked step per quest** ([x] done / [ ] to do) — e.g. the full Defias Brotherhood chain before the Deadmines, Rethiel's quests before Excavation Site, the Forgotten Pools chain before Wailing Caverns.
- Shows the next dungeon's prerequisites as you get close to swapping, and counts their XP into when to swap.
- Uses the game's quest API to detect finished quests.

### Spelunker achievements
- Reads your **Novice / Experienced / Master Spelunker** progress straight from the achievement system.
- Warns about required dungeons you've outleveled without running.

### XP buff alerts
- **Food:** warns when your Well Fed XP buff is missing, about to expire, or from food without the XP bonus.
- **Camp tent:** warns when the Boosted Rest cooldown is over — only when you can actually camp (outdoors, outside dungeons, cities and inns) and right after you leave a dungeon.
- **Cozy Sleeping Bag:** warns when Well-Rested is gone and the bag is off cooldown.
- No alerts in combat, during cinematics, or below level 6 (configurable once for your whole account with `/dlc set minlevel`).

---

## Commands

| Command | What it does |
|---|---|
| `/dlc` | Show/hide the panel |
| `/dlc route` | Full route with runs done |
| `/dlc quests [dungeon]` | Quests for the current (or named) dungeon |
| `/dlc prep [dungeon]` | Prerequisite quest steps, with what to do |
| `/dlc qdone <quest>` / `/dlc qundo <quest>` | Mark a quest or step finished (or not) by hand |
| `/dlc run <dungeon>` / `/dlc xp <dungeon> <amount>` | Log a run by hand |
| `/dlc undo` | Remove the last logged run |
| `/dlc ach` | What was read from the Spelunker achievements |
| `/dlc set food\|tentwarn\|tent\|bag on\|off` | Turn alerts / tent estimates on or off |
| `/dlc set calib <n\|auto>` | Force an XP calibration factor |
| `/dlc set minlevel <level>` | Level the alerts start at (default 6; applies to all your characters) |
| `/dlc faction horde\|alliance\|auto` | Pick the route |
| `/dlc lock` / `/dlc unlock` | Lock the panel position |
| `/dlc perf` | How much time/memory the addon uses |
| `/dlc help` | All commands |

Dungeon keys for commands: `hot rfc dm wc rol sfk bfd stocks rfk exc gnomer smgy dal smlib drowned smarm smcath rfd ulda krol zf mara alcaz st brd blackmaw lbrs dme shaper ubrs dmw dmn stratlive stratud scholo` — or type part of the name.

---

## Notes

- **Estimates, not promises.** XP per run starts from a formula (elite counts per clear, 5-man XP share) and gets accurate once you've logged a run or two. New-dungeon numbers are guesses until then.
- **English client only** for now (buff, instance and achievement names are matched in English).
- Quest data comes from Wowhead's Classic dungeon quest guide plus Forever beta guides. If a quest never updates, tell me its exact in-game name — `/dlc qdone` hides it meanwhile.
- Progress is saved per character.
- Lightweight: the panel only redraws when something changes (plus every 5s for timers), buffs are read only when they change, and nothing is read in combat.

---

## Feedback & bug reports

Found a bug, a quest that never updates, or have measured XP numbers for a dungeon? Please open an issue on GitHub: **https://github.com/XOSexyCutie/DungeonLevelingCompanion/issues** — or leave a comment here. Include the exact quest/dungeon name and any error text.
