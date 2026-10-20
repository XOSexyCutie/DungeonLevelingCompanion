# DLC – Dungeon Leveling Companion Changelog

## 1.3.0

- City of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold and Shaper's Terrace are marked as live at the November 4 launch (the old "if not live" fallback notes are gone).
- Cozy Sleeping Bag chain on the Horde route: note picked up in the Barrens (WC prep), turned in in Westfall (DM trip), Stonetalon before RFK, Loch Modan dam + Thoradin's Wall before the Excavation Site.
- The sleeping bag XP bonus in estimates starts at the dungeon whose prereqs finish the chain (Alliance: Ruins of Lordaeron, Horde: Excavation Site) instead of a fixed level 20.
- City of Dalaran quests from Wowhead's guide, 4 per faction. Horde: the Dalaran Sewer Key chain from Tarren Mill is tracked as prep before the first run.
- City of Dalaran (Alliance): An Alarming Request (Emissary Jacques, Southshore, level 30) is tracked as prep - it leads to Heart of Disruption and the Dalaran Sewer Key.
- Shaper's Terrace: gathering Un'Goro power crystals (used at consoles inside) is a prep step for both factions.
- Blackmaw Hold estimates assume a BRD-sized run (elites, quests and minutes) until real data is in.

## 1.2.0

- Cozy Sleeping Bag chain tracked as prereq steps along the route: pick up the note in Westfall (Deadmines prep), Barrens tower + Stonetalon camp on the way to Wailing Caverns, Loch Modan dam + Thoradin's Wall on the walk to Ruins of Lordaeron. Its 15,265 quest XP counts toward when to swap dungeons.
- Owning the sleeping bag marks the chain done and adds its +3% to the estimates for the legs still ahead.
- When the next dungeon's prereq XP covers the rest of a leg, the panel says to stop running and go do the prereqs.
- Crest of Lordaeron is listed for Alliance too (it isn't Horde only).

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
