# DLC – Dungeon Leveling Companion Changelog

## 1.1.0

- Group sync: party members running DLC share level, route dungeon, quests and prerequisites still needed, and XP food status (never sent in combat).
- Options window (`/dlc config`, or right-click the panel/minimap button): panel scale, opacity, section toggles, alerts, sync, minimap and route choice.
- Draggable minimap button, plus a LibDataBroker launcher when available.
- Click-through toggle for the panel (options or `/dlc clickthrough`).
- Secret bosses: Viktor the Vile (Ruins of Lordaeron) and Lyn the Ignored (Dalaran); the Tome of Dalaran is tracked as optional Dalaran prep.
- Tent estimate uses measured start-to-start run time per dungeon once known (`~Nm/run (measured)`).
- Hall of Thanes starts at 4461 XP per run; XP per run follows the group's latest 3 runs, so it drops as you outlevel a dungeon.

## 1.0.0 – First release

- Alliance and Horde dungeon leveling routes, 14–60, including the new WoW Forever dungeons.
- Panel: current dungeon, runs left to the swap level, XP per run, quests, prerequisites, Spelunker progress, buff status.
- Automatic run logging from the XP bar (rested bonus and quest XP excluded), with auto-calibration of all estimates.
- Dungeon quest tracker using the quest log and quest API; finished quests drop out of the XP estimate.
- Prerequisite quest chains tracked one quest at a time, counted into when to swap dungeons.
- Spelunker achievement progress read from the achievement system.
- Alerts for Well Fed (XP food), Leatherworking camp tent cooldown (outdoors only, not in cities/inns/dungeons) and the Cozy Sleeping Bag.
- Combat-safe: no buff reads in combat, no alerts in combat or cinematics.
- Food XP check handles every tooltip format, retries if the tooltip isn't loaded yet, and `/dlc buffs` shows exactly what the addon reads.
- Alerts use their own on-screen text (no Blizzard raid-warning frame, avoids UI taint) and start at level 6 by default; `/dlc set minlevel` sets it account-wide.
