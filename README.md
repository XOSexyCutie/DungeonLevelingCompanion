# DLC – Dungeon Leveling Companion

**Know which dungeon opens next, and quest for it on the way.** DLC shows the dungeons open at your level, when the next one opens, and the quests and prerequisite chains to pick up before you get there. It also reminds you to keep your XP buffs up.

Built for **WoW Forever** alts leveling with pugs: the new Forever dungeons, the Spelunker achievements, cooked-food XP, Leatherworking camp tents and the Cozy Sleeping Bag.

---

## Features

### Now, Next, Also open
- **Now:** the first dungeon in your level range that still has something to do, with its prerequisites and quests.
- **Next:** the next dungeon to open, its min level and how far you are from it, e.g. **"Next: The Drowned City at 35 (2 levels, ~48k XP)"**. Its prequests and dungeon quests are listed underneath so you can grab them while questing. When several dungeons open at the same level (e.g. SM Graveyard and City of Dalaran at 28), all of them are shown.
- **Also open:** the other dungeons you could join a group for right now.
- Dungeon level ranges follow Wowhead's WoW Forever dungeon chart. `/dlc route` lists every dungeon by min level.
- Separate **Alliance and Horde quest lists**, picked automatically from your character.
- Covers every dungeon from Hall of Thanes / Ragefire Chasm to Shaper's Terrace, including the new Forever dungeons (Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, City of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, Shaper's Terrace).

### Dungeon quests and prequests
- Lists each dungeon's quests: **grey** = pick it up (with where), **yellow** = in your log with progress, **green** = ready to turn in. Finished quests disappear.
- **Prerequisite chains, one tracked step per quest** ([x] done / [ ] to do), e.g. the Defias Brotherhood chain before the Deadmines, the Dalaran Sewer Key, Rethiel's quests before Excavation Site, A Small Favor before Krol'dok's Tome of Twilight.
- Shows how long the open prequests take and how much XP they give.
- Uses the game's quest API to detect finished quests. `/dlc qdone` marks one by hand.
- Loot reminders for items you need later (e.g. the Black Tome in Shadowfang Keep for Dalaran's secret boss).

### Spelunker achievements
- Reads your **Novice / Experienced / Master Spelunker** progress straight from the achievement system. Runs are also logged automatically when you leave a dungeon.
- Warns about required dungeons you've outleveled without running.

### XP buff alerts
- **Food:** warns when your Well Fed XP buff is missing, about to expire, or from food without the XP bonus.
- **Camp tent:** warns when the Boosted Rest cooldown is over, but only when you can actually camp (outdoors, outside dungeons, cities and inns).
- **Cozy Sleeping Bag:** warns when Well-Rested is gone and the bag is off cooldown. The bag's quest chain is tracked as prequests along the way.
- No alerts in combat, during cinematics, or below level 6 (configurable once for your whole account with `/dlc set minlevel`).

### Group sync
- Party members running DLC see each other's level, focus dungeon, quests still needed and XP food status.

---

## Commands

| Command | What it does |
|---|---|
| `/dlc` | Show/hide the panel |
| `/dlc route` | Every dungeon by min level, with runs done |
| `/dlc quests [dungeon]` | Quests for the current/next (or named) dungeon |
| `/dlc prep [dungeon]` | Prerequisite quest steps, with what to do |
| `/dlc qdone <quest>` / `/dlc qundo <quest>` | Mark a quest or step finished (or not) by hand |
| `/dlc run <dungeon>` | Log a run by hand |
| `/dlc undo` | Remove the last logged run |
| `/dlc ach` | What was read from the Spelunker achievements |
| `/dlc set food\|tentwarn\|tent\|bag on\|off` | Turn alerts / tent status on or off |
| `/dlc set minlevel <level>` | Level the alerts start at (default 6; applies to all your characters) |
| `/dlc config` | Options window (also: right-click the panel or minimap button) |
| `/dlc faction horde\|alliance\|auto` | Pick the quest lists |
| `/dlc lock` / `/dlc unlock` | Lock the panel position |
| `/dlc help` | All commands |

Dungeon keys for commands: `hot rfc dm wc rol sfk bfd stocks rfk exc gnomer smgy dal smlib drowned smarm smcath rfd ulda krol zf mara alcaz st brd blackmaw lbrs dme shaper ubrs dmw dmn stratlive stratud scholo`, or type part of the name.

---

## Notes

- **English client only** for now (buff, instance and achievement names are matched in English).
- Quest data comes from Wowhead's Classic dungeon quest guide and its live WoW Forever data. Shaper's Terrace and Alcaz Prison (Horde) quests aren't on Wowhead yet. If a quest never updates, tell me its exact in-game name; `/dlc qdone` hides it meanwhile.
- Progress is saved per character.
- Lightweight: the panel only redraws when something changes (plus every 5s for timers), buffs are read only when they change, and nothing is read in combat.

---

## Feedback & bug reports

Found a bug, a quest that never updates, or a quest Wowhead doesn't list yet? Please open an issue on GitHub: **https://github.com/XOSexyCutie/DungeonLevelingCompanion/issues**, or leave a comment here. Include the exact quest/dungeon name and any error text.
