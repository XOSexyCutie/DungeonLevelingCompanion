# DLC – Dungeon Leveling Companion Changelog

## 1.0.0 – First release

- Alliance and Horde dungeon leveling routes, 14–60, including the new WoW Forever dungeons.
- Panel: current dungeon, runs left to the swap level, XP per run, quests, prerequisites, Spelunker progress, buff status.
- Automatic run logging from the XP bar (rested bonus and quest XP excluded), with auto-calibration of all estimates.
- Dungeon quest tracker using the quest log and quest API; finished quests drop out of the XP estimate.
- Prerequisite quest chains tracked one quest at a time, counted into when to swap dungeons.
- Spelunker achievement progress read from the achievement system.
- Alerts for Well Fed (XP food), Leatherworking camp tent cooldown (outdoors only, not in cities/inns/dungeons) and the Cozy Sleeping Bag.
- Combat-safe: no buff reads in combat, no alerts in combat or cinematics.
- Alerts use their own on-screen text (no Blizzard raid-warning frame, avoids UI taint) and start at level 6 by default; `/dlc set minlevel` sets it account-wide.
