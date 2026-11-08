"""DLC (Dungeon Leveling Companion) test suite: runs the addon in Lua 5.1 against a fake WoW API (secret auras in combat, quest log, achievements).

Run from the addon folder:  python tests/test_dlc.py   (needs: pip install lupa)
"""
import sys, pathlib
from lupa.lua51 import LuaRuntime

ADDON_DIR = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parent.parent
lua = LuaRuntime(unpack_returned_tuples=True)

lua.execute(r'''
XPT = { 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
        25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400 }
state = { level = 18, xp = 1000, rested = 0, now = 1000, t = 100000, inInstance = false, instName = nil, subzone = "",
          auras = { HELPFUL = {}, HARMFUL = {} }, combat = false, indoors = false, resting = false,
          warnings = {}, chat = {}, errors = {}, frames = {}, bag = nil, bagCdStart = 0 }
local function secretCheck() if state.combat then error("GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'DungeonLevelingCompanion'") end end
function GetTime() return state.now end
function time() return state.t end
function UnitLevel() return state.level end
function UnitXP() return state.xp end
function UnitXPMax() return XPT[state.level] or 0 end
function GetXPExhaustion() return state.rested > 0 and state.rested or nil end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function InCombatLockdown() return state.combat end
function IsIndoors() return state.indoors end
function IsResting() return state.resting end
function IsInInstance() return state.inInstance, state.inInstance and "party" or "none" end
function GetInstanceInfo() return state.instName, "party" end
function GetSubZoneText() return state.subzone end
function GetMinimapZoneText() return state.subzone end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
state.questLog = {}; state.flagged = {}; state.class = "HUNTER"; state.faction = "Alliance"
function UnitFactionGroup() return state.faction, state.faction end
function debugprofilestop() return os.clock() * 1000 end
state.unitAuraCount = 0
function UnitClass() return state.class, state.class end
C_QuestLog = { GetNumQuestLogEntries = function() return #state.questLog end,
  GetInfo = function(i) local q = state.questLog[i] if q then return { title = q.title, questID = q.id, isHeader = false } end end,
  IsComplete = function(id) for _, q in ipairs(state.questLog) do if q.id == id then return q.complete end end return false end,
  GetQuestObjectives = function(id) for _, q in ipairs(state.questLog) do if q.id == id and q.need then return { { numFulfilled = q.have, numRequired = q.need } } end end return {} end,
  IsQuestFlaggedCompleted = function(id) return state.flagged[id] or false end }
C_UnitAuras = { GetAuraDataByIndex = function(unit, i, filter)
    secretCheck()
    local a = state.auras[filter][i]
    if a then return { name = a.name, expirationTime = a.exp, spellId = 1, applications = a.count or 0 } end
end }
C_Container = { GetContainerNumSlots = function(b) return b == 0 and 16 or 0 end,
  GetContainerItemLink = function(b, s) if b == 0 and s == 3 and state.bag then return "|cffffffff|Hitem:211527::::|h[Cozy Sleeping Bag]|h|r" end end,
  GetItemCooldown = function(id) return state.bagCdStart, 3600, 1 end }
ACH = {
  { id = 9001, name = "Novice Spelunker", crit = { {"Ragefire Chasm or Hall of Thanes", true}, {"Ruins of Lordaeron", true}, {"Wailing Caverns", true}, {"The Deadmines", true}, {"Shadowfang Keep", true}, {"Excavation Site: Wetlands", true} } },
  { id = 9002, name = "Experienced Spelunker", crit = { {"City of Dalaran", true}, {"Blackfathom Deeps", true}, {"Gnomeregan", false} } },
  { id = 9003, name = "Master Spelunker", crit = { {"Razorfen Downs", false} } } }
local byId = {} for _, a in ipairs(ACH) do byId[a.id] = a end
function GetCategoryList() return { 96 } end
function GetCategoryNumAchievements() return #ACH end
function GetAchievementInfo(a, b) local x = b and ACH[b] or byId[a] if not x then return nil end local all = true for _, c in ipairs(x.crit) do all = all and c[2] end return x.id, x.name, 10, all end
function GetAchievementNumCriteria(id) return #byId[id].crit end
function GetAchievementCriteriaInfo(id, i) local c = byId[id].crit[i] return c[1], 0, c[2] end

local function newFrame(name)
  local f = { shown = true, scripts = {}, events = {} }
  local fs_meta = { __index = function(t, k) return function(self, ...)
      if k == "SetText" then self._text = ...; state.lastText = ... elseif k == "GetText" then return self._text elseif k == "GetStringHeight" then return 100 end
    end end }
  setmetatable(f, { __index = function(t, k)
    if k == "SetScript" then return function(self, ev, fn) self.scripts[ev] = fn end end
    if k == "RegisterEvent" then return function(self, ev) self.events[ev] = true end end
    if k == "IsShown" then return function(self) return self.shown end end
    if k == "SetShown" then return function(self, v) self.shown = v end end
    if k == "CreateFontString" then return function() return setmetatable({}, fs_meta) end end
    if k == "NumLines" then return function(self) return self._lines or 0 end end
    if k == "SetUnitAura" then return function(self, unit, i, filter)
        secretCheck()
        local a = state.auras[filter][i]
        self._lines = 0
        if a then self._lines = 2
          _G[name .. "TextLeft1"] = { GetText = function() return a.name end }
          _G[name .. "TextLeft2"] = { GetText = function() return a.tip or "" end }
        end
      end end
    if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 0, 0 end end
    return function() end
  end })
  if name then _G[name] = f end
  return f
end
function CreateFrame(kind, name) local f = newFrame(name) table.insert(state.frames, f) return f end
UIParent = { IsVisible = function() return state.uiVisible ~= false end }
WorldFrame = {}
function InCinematic() return state.cinematic == true end
DEFAULT_CHAT_FRAME = { AddMessage = function(self, m) table.insert(state.chat, m) end }
RaidWarningFrame = {}
ChatTypeInfo = { RAID_WARNING = {} }
function RaidNotice_AddMessage(f, msg) table.insert(state.warnings, msg) end
SOUNDKIT = { RAID_WARNING = 8959 }
function PlaySound() end
tickers, afters = {}, {}
C_Timer = { NewTicker = function(sec, fn) table.insert(tickers, fn) end, After = function(sec, fn) table.insert(afters, fn) end }
SlashCmdList = {}
local function safe(fn, ...) local ok, err = pcall(fn, ...) if not ok then table.insert(state.errors, tostring(err)) end end
function fire(event, ...)
  for _, f in ipairs(state.frames) do
    if f.events[event] and f.scripts.OnEvent then safe(f.scripts.OnEvent, f, event, ...) end
  end
end
function tick()
  fire("UNIT_AURA", "player"); fire("BAG_UPDATE_DELAYED")
  local a = afters; afters = {}
  for _, fn in ipairs(a) do safe(fn) end
  for _, fn in ipairs(tickers) do safe(fn) end
end
-- Simulate a kill: base XP, of which `bonus` comes from rested.
function kill(base, bonus)
  bonus = math.min(bonus or 0, state.rested)
  state.rested = state.rested - bonus
  if bonus > 0 then fire("UPDATE_EXHAUSTION") end
  state.xp = state.xp + base + bonus
  while XPT[state.level] and state.xp >= XPT[state.level] do state.xp = state.xp - XPT[state.level]; state.level = state.level + 1 end
  fire("PLAYER_XP_UPDATE", "player")
end
function quest(xp)
  state.xp = state.xp + xp
  while XPT[state.level] and state.xp >= XPT[state.level] do state.xp = state.xp - XPT[state.level]; state.level = state.level + 1 end
  fire("PLAYER_XP_UPDATE", "player"); fire("QUEST_TURNED_IN", 123, xp, 100)
end
''')

ns = lua.table()
for fname in ["Data.lua", "Core.lua", "UI.lua", "Achievements.lua", "Quests.lua", "Sync.lua", "Options.lua"]:
    code = (ADDON_DIR / fname).read_text(encoding="utf-8")
    lua.eval(f"function(code) return assert(loadstring(code, '@{fname}')) end")(code)("DungeonLevelingCompanion", ns)

G = lua.globals()
ns.alertLog = lua.table()
run = lua.execute
run('fire("ADDON_LOADED", "DungeonLevelingCompanion"); fire("PLAYER_ENTERING_WORLD"); tick()')

def take(key):
    if key == "warnings":
        out = list(ns.alertLog.values()); ns.alertLog = lua.table(); return out
    out = list(G.state[key].values()); run(f"state.{key} = {{}}"); return out
fails = 0
def check(label, cond, extra=""):
    global fails
    print(("PASS " if cond else "FAIL ") + label + (f"  -> {extra}" if extra else ""))
    if not cond: fails += 1

take("warnings"); take("chat")

# --- 1. Combat must not touch auras (the in-game error) ---
run('state.auras.HELPFUL = { { name = "Well Fed", exp = state.now + 900, tip = "Increases experience gained from kills by 5%." },'
    ' { name = "Well-Rested", exp = state.now + 3600, count = 3, tip = "Experience gained increased by 3%." } };'
    ' state.auras.HARMFUL = { { name = "Boosted Rest", exp = state.now + 1800 } }; state.now = state.now + 5; tick()')
run('state.combat = true')
for _ in range(10):
    run('state.now = state.now + 1; tick()'); ns.Refresh()
errs = take("errors")
check("no Lua errors while in combat (auras secret)", not errs, errs[:1])
food = ns.FoodStatus()
check("in combat: food still shows Well Fed (cached)", food[0] == "xp", food)
tent = ns.TentCooldown()
check("in combat: tent cooldown still shown (cached)", tent[0] is True and 1700 < tent[1] < 1800, tent)
bag = ns.BagStatus()
check("in combat: bag stacks cached", bag[0] == 3, bag)
check("in combat: no warnings fired", not take("warnings"))
run('state.combat = false; fire("PLAYER_REGEN_ENABLED"); tick()')
check("after combat: no errors", not take("errors"))

# cached food expiring during a long fight
run('state.auras.HELPFUL[1].exp = state.now + 20; state.now = state.now + 1; tick(); state.combat = true; state.now = state.now + 30; tick()')
fs = ns.FoodStatus(); fs = fs if isinstance(fs, str) else fs[0]
check("in combat: cached food expires on its own timer", fs == "none", fs)
run('state.combat = false; state.auras.HELPFUL[1].exp = state.now + 900; state.now = state.now + 1; tick()')
take("warnings"); take("chat")

# --- 2. Run XP from the XP bar ---
run('state.level = 18; state.xp = 1000; state.rested = 500; fire("PLAYER_XP_UPDATE", "player")')
run('state.inInstance = true; state.instName = "The Deadmines"; fire("ZONE_CHANGED_NEW_AREA"); tick()')
run('kill(150, 150)')            # rested doubles: +150 base, +150 rested -> trash 150
run('state.combat = true; kill(100, 0); kill(200, 200); state.combat = false')   # in combat -> +300 trash
run('state.rested = state.rested + 900; fire("UPDATE_EXHAUSTION")')               # (tent-like rested gain) must not count
run('kill(120, 120)')            # +120
run('quest(1500)')               # quest XP inside -> excluded
print("   run xp so far:", G.DungeonLevelingCompanionDB.curRun.xp)
check("run XP = kill XP minus rested minus quest", G.DungeonLevelingCompanionDB.curRun.xp == 570, G.DungeonLevelingCompanionDB.curRun.xp)

# level-up in the middle of the run
run('state.xp = XPT[state.level] - 100; fire("PLAYER_XP_UPDATE", "player")')   # simulate time passing outside tracking? no: counts
before = G.DungeonLevelingCompanionDB.curRun.xp
run('kill(400, 0)')
lvl = G.state.level
check("level-up mid-run counted correctly (+400)", G.DungeonLevelingCompanionDB.curRun.xp - before == 400 and lvl == 19, (G.DungeonLevelingCompanionDB.curRun.xp - before, lvl))
# level/XP updating out of order on level-up
before = G.DungeonLevelingCompanionDB.curRun.xp
run('state.xp = state.xp + 50; local oldlvl = state.level; fire("PLAYER_XP_UPDATE", "player")')
run('state.xp = XPT[state.level] + 10 - 0')  # bogus intermediate not fired
check("normal +50", G.DungeonLevelingCompanionDB.curRun.xp - before == 50, G.DungeonLevelingCompanionDB.curRun.xp - before)

# leave + finish run -> logged
run('state.xp = 100; fire("PLAYER_XP_UPDATE", "player")')
take("chat")
run('state.t = state.t + 2400; state.inInstance = false; state.instName = nil; fire("ZONE_CHANGED_NEW_AREA"); state.t = state.t + 400; tick()')
logged = take("chat")
check("run logged on leaving", any("Logged The Deadmines run" in m for m in logged), logged[:1])

# --- 3. Warnings: outdoors / rest area / dungeon ---
run('state.level = 22; state.xp = 0; state.rested = 0; state.auras.HARMFUL = {}; state.now = state.now + 500; state.resting = true; tick()')
take("warnings")
run('state.now = state.now + 300; tick()')
check("no tent alert in Stormwind", not take("warnings"))
run('state.resting = false; fire("ZONE_CHANGED"); tick()')
check("tent alert when leaving Stormwind", any("Tent" in w for w in take("warnings")))
run('state.combat = true; state.auras.HELPFUL = {}; state.now = state.now + 500; tick()')
check("no warnings in combat", not take("warnings"))
run('state.combat = false; fire("PLAYER_REGEN_ENABLED"); tick()')
w = take("warnings")
check("food warning after combat once auras readable", any("Well Fed" in x for x in w), w)

# --- 4. Achievements ---
run('DungeonLevelingCompanionDB.achIDs = nil'); ok = ns.ScanAchievements()
check("achievements read", ok and ns.TierProgress("Novice")[0] == 6, ns.TierProgress("Novice"))
run('state.combat = true; fire("CRITERIA_UPDATE"); tick(); tick()')
check("achievement rescan deferred in combat, no errors", not take("errors"))
run('state.combat = false; tick()')

# --- 5. Panel renders in and out of combat ---
for c in ("false", "true", "false"):
    run(f"state.combat = {c}"); ns.Refresh()
check("panel renders without errors", not take("errors"))
print(G.state.lastText)
print("\nFAILURES:", fails)

# --- 6. Quest tracker ---
def panel_quests(name="The Deadmines"):
    # The quest block under the Now:/Next: line for that dungeon.
    ns.Refresh()
    lines = G.state.lastText.split("\n")
    h = next((k for k, l in enumerate(lines) if ("Now:" in l or "Next:" in l) and name in l), None)
    if h is None: return []
    i = None
    for k in range(h + 1, len(lines)):
        if "Now:" in lines[k] or "Next:" in lines[k]: break
        if (lines[k].startswith("Quests") or lines[k].startswith("Dungeon quests")) and (" - " not in lines[k].split("(")[0] or name in lines[k]): i = k; break
    if i is None: return []
    out = [lines[i]]
    for l in lines[i+1:]:
        if not l.startswith("  "): break
        out.append(l)
    return out
def qlog():
    run('fire("QUEST_LOG_UPDATE"); tick()')
run('state.level = 17; state.xp = 0; state.inInstance = false')
qlog()
q = panel_quests(); print("\n".join(q))
check("17 -> Next: Deadmines at 18 with its 6 quests, all 'not picked up'", any("Next:" in l and "The Deadmines" in l and "at 18" in l for l in G.state.lastText.split("\n"))
      and q and q[0].startswith("Dungeon quests (6 left)") and all("cff999999" in l for l in q[1:]), q[:1])
run('state.questLog = { { title = "Red Silk Bandanas", id = 214, complete = false, have = 3, need = 10 },'
    ' { title = "Oh Brother. . .", id = 167, complete = true },'
    ' { title = "The Defias Brotherhood", id = 155, complete = false } }')
qlog(); q = panel_quests(); print("\n".join(q))
check("in-log quest shows progress 3/10", any("Red Silk Bandanas 3/10" in l for l in q))
check("complete quest shows 'turn in'", any("Oh Brother. . . - turn in" in l for l in q), [l for l in q if "Brother" in l])
# turn in Oh Brother
run('table.remove(state.questLog, 2); state.flagged[167] = true; fire("QUEST_TURNED_IN", 167, 1200, 0); qlog_dummy = 1')
qlog(); q = panel_quests()
check("turned-in quest disappears", not any("Oh Brother" in l for l in q) and "(5 left)" in q[0], q[:1])
# Defias chain: turn in part (155), then next part with same name (156)
run('table.remove(state.questLog, 2); state.flagged[155] = true; fire("QUEST_TURNED_IN", 155, 500, 0)'); qlog()
print("   (Defias dungeon quest stays listed until its final part, id 166, is done)")
check("prereq chain part turned in -> dungeon quest still listed (final part not done)", any("Defias Brotherhood" in l and "cff999999" in l for l in panel_quests()))
run('table.insert(state.questLog, { title = "The Defias Brotherhood", id = 166, complete = false })'); qlog()
check("final part (166) picked up -> shown yellow (in log)", any("Defias Brotherhood" in l and "cffffff00" in l for l in panel_quests()))
# quest finished before install: learned ID + flagged -> hidden on its own
run('DungeonLevelingCompanionDB.questIDs["collectingmemories"] = 168; state.flagged[168] = true'); qlog()
check("flagged-completed (learned id) hidden", not any("Collecting Memories" in l for l in panel_quests()))
# manual qdone
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("qdone underground")'); take("chat")
check("/fr qdone hides quest", not any("Underground Assault" in l for l in panel_quests()))
# paladin-only quest
run('state.level = 21'); 
check("SFK paladin quest hidden for hunter", not panel_quests("Shadowfang Keep"))
run('state.class = "PALADIN"')
check("SFK paladin quest shown for paladin", any("Test of Righteousness" in l for l in panel_quests("Shadowfang Keep")))
run('state.class = "HUNTER"')
# combat safety
run('state.combat = true; fire("QUEST_LOG_UPDATE"); tick()'); ns.Refresh(); run('state.combat = false')
check("no errors from quest tracking", not take("errors"))
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("quests dm")'); print("\n".join(take("chat")))
print("\nFAILURES:", fails)

# --- 7. Prerequisite steps + swap timing ---
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("reset confirm"); state.questLog = {}; state.flagged = {}; DungeonLevelingCompanionDB.questDone = {}; DungeonLevelingCompanionDB.questIDs = {}')
run('DungeonLevelingCompanionDB.achDone = {}'); take("chat")
run('state.level = 15; state.xp = 0'); qlog()
def panel(): ns.Refresh(); return G.state.lastText.split("\n")
p = panel()
check("15 -> Now: Hall of Thanes, 'Before you go' shows Nip 'Em in the Bud", any("Now:" in l and "Hall of Thanes" in l for l in p)
      and any("Before you go" in l for l in p) and any("Nip 'Em in the Bud" in l for l in p), p[:4])
run('state.flagged[0] = false')
# picking up Old Ironforge Incursion (unlocked) -> Nip step done
run('state.questLog = { { title = "Old Ironforge Incursion", id = 9100, complete = false } }'); qlog()
check("unlock in log -> Nip 'Em step done", not any("Nip 'Em in the Bud" in l for l in panel()))
# level 16: Deadmines (min 18) is next - its prequests show already
run('state.level = 16; state.xp = 0; DungeonLevelingCompanionDB.runs.hot = 2'); qlog()
p = panel(); print("\n".join(p[:12]))
i_next = next((k for k, l in enumerate(p) if "Next:" in l and "The Deadmines" in l), None)
check("Next: Deadmines at 18 with 'Prequests:' under it", i_next is not None and p[i_next + 1].startswith("|cffffff00Prequests:"), p[:12])
check("XP to go shown for the next dungeon", i_next is not None and "2 levels" in p[i_next], p[i_next] if i_next is not None else None)
xp_prep, _ = ns.PrepLeft(ns.BY_KEY.dm)
check("DM prep XP = real chain XP 6100", xp_prep == 6100, xp_prep)
# chain progress: parts 65,132 done, 135 in log 2/5
run('state.flagged[65] = true; state.flagged[132] = true; state.questLog = { { title = "The Defias Brotherhood", id = 135, complete = false, have = 2, need = 5 } }'); qlog()
p = panel()
check("parts 1-2 [x], part 3 in log with progress", any("[x] 2. The Defias Brotherhood (1/6)" in l for l in p) and any("[x] 3. The Defias Brotherhood (2/6)" in l for l in p) and any("[ ] 4. The Defias Brotherhood (3/6) 2/5" in l for l in p), [l for l in p if "Defias" in l])
xp_prep2, _ = ns.PrepLeft(ns.BY_KEY.dm)
check("prep XP drops as parts finish (680+340+1350+1700)", xp_prep2 == 4070, xp_prep2)
# chain done (155 flagged) -> prequests gone
run('for _, id in ipairs({135,141,142,155}) do state.flagged[id] = true end; state.questLog = {}'); qlog()
p = panel()
check("chain done -> Defias steps gone from DM prequests", all("Defias" not in s.step.q for s in ns.PrepOpen(ns.BY_KEY.dm).values()), [s.step.q for s in ns.PrepOpen(ns.BY_KEY.dm).values()])
# Excavation: unlock by Horrors in the Highland in log completes 3 Rethiel steps
run('state.level = 26; state.xp = 0; DungeonLevelingCompanionDB.runs.rfk = 1; state.questLog = { { title = "Horrors in the Highland", id = 9200, complete = false } }'); qlog()
steps = [s.step.q for s in ns.PrepOpen(ns.BY_KEY.exc).values()]
check("Excavation: Rethiel prereqs done when Horrors in the Highland is in log", steps == ["Young Crocolisk Skins"], steps)
# manual qdone of a prep step
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("qdone young croc")'); take("chat")
check("/fr qdone marks a prep step done", len(list(ns.PrepOpen(ns.BY_KEY.exc).values())) == 0)
# /fr prep output
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("prep st")'); out = take("chat"); print("\n".join(out[:4]))
check("/fr prep lists steps", any("Sunken Temple prerequisites" in l for l in out))
# optional steps excluded from XP
xp_st, _ = ns.PrepLeft(ns.BY_KEY.st); xp_zf, _ = ns.PrepLeft(ns.BY_KEY.zf)
check("optional ZF steps excluded from prep XP", xp_zf == 40 * 75, xp_zf)
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 8. Now / Next / Also open ---
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("reset confirm"); state.questLog = {}; state.flagged = {}; DungeonLevelingCompanionDB.questDone = {}; DungeonLevelingCompanionDB.questIDs = {}'); take("chat")
run('DungeonLevelingCompanionDB.achDone = {}; state.level = 25; state.xp = 0'); qlog()
now, nxt, missed, _ = ns.Recommend()
nowk = [d.key for d in now.values()]
check("25: open = WC, SFK, Stockade, BFD, Excavation", nowk == ["wc", "sfk", "stocks", "bfd", "exc"], nowk)
nextall = [d.key for d in ns.Recommend()[3].values()]
check("25: next = SM Graveyard + Dalaran, both at 28", nxt.minLvl == 28 and nextall == ["smgy", "dal"], nextall)
check("25: outleveled Spelunker dungeons are 'missed'", [d.key for d in missed.values()] == ["hot", "rol", "dm"], [d.key for d in missed.values()])
p = panel()
check("panel: Now WC, Next Dalaran, Also open lists the rest", any("Now:" in l and "Wailing Caverns" in l for l in p)
      and any("Next:" in l and "SM Graveyard + City of Dalaran" in l and "at 28" in l for l in p)
      and any("Also open:" in l and "Shadowfang Keep" in l and "Excavation Site" in l for l in p), p)
check("Dalaran prequests (An Alarming Request) shown before 28, labelled", any("Prequests - City of Dalaran" in l for l in p) and any("An Alarming Request" in l for l in p), p)
# a dungeon with all quests done and a run logged drops out of 'open'
run('DungeonLevelingCompanionDB.runs.wc = 1')
for q in ns.BY_KEY.wc.questInfo.values(): G.DungeonLevelingCompanionDB.questDone[q.key] = "manual"
qlog(); now, nxt, missed, _ = ns.Recommend()
check("WC run + quests done -> no longer open", "wc" not in [d.key for d in now.values()] and now[1].key == "sfk", [d.key for d in now.values()])
run('DungeonLevelingCompanionDB.questDone["deviatehides"] = nil'); qlog()
check("run logged but a quest left -> still open", "wc" in [d.key for d in ns.Recommend()[0].values()])
run('DungeonLevelingCompanionDB.runs.wc = nil')
# level 60: Spelunker leftovers, no next
run('state.level = 60'); now, nxt, missed, _ = ns.Recommend()
check("60: open = Spelunker dungeons not run, no next", nxt is None and len(now) > 0 and all(d.tier for d in now.values()), (nxt, len(now)))
check("no errors", not take("errors"))

# --- 9. Horde route ---
run('state.faction = "Horde"; SlashCmdList.DUNGEONLEVELINGCOMPANION("faction auto")'); out = take("chat")
check("faction auto -> Horde route", any("Horde route" in l for l in out), out)
keys = [d.key for d in ns.ROUTE.values()]
check("Horde route starts RFC, Ruins, WC; no HoT/Stockade", keys[:3] == ["rfc", "rol", "wc"] and "hot" not in keys and "stocks" not in keys, keys[:6])
run('state.level = 15; state.xp = 0'); d = ns.Focus()
check("Horde at 15 -> Ragefire Chasm", d.key == "rfc", d.key)
run('state.level = 19'); d = ns.Focus()
check("Horde at 19 (past RFC) -> Ruins of Lordaeron", d.key == "rol", d.key)
qlog(); p = panel()
check("Horde Ruins quests shown (Light's Justice)", any("Light's Justice" in l for l in p))
steps = [s.step.q for s in ns.PrepOpen(ns.BY_KEY.wc).values()]
check("Horde WC prereqs include The Forgotten Pools chain", "The Forgotten Pools" in steps, steps)
run('state.questLog = { { title = "Leaders of the Fang", id = 1, complete = false } }'); qlog()
steps = [s.step.q for s in ns.PrepOpen(ns.BY_KEY.wc).values()]
check("Leaders of the Fang in log -> Forgotten Pools chain done", steps == ["Raptor Horns", "...and that note you found"], steps)
run('DungeonLevelingCompanionDB.achIDs = nil'); ns.ScanAchievements()
check("achievement 'RFC or Hall of Thanes' maps to rfc for Horde", G.DungeonLevelingCompanionDB.achDone.rfc == True, list(G.DungeonLevelingCompanionDB.achDone.keys()))
check("Horde Novice 6/6 from achievement", ns.TierProgress("Novice")[0] == 6, ns.TierProgress("Novice"))
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("route")'); out = take("chat"); print("\n".join(out[:5]))
run('state.faction = "Alliance"; SlashCmdList.DUNGEONLEVELINGCOMPANION("faction auto")'); take("chat")
check("back to Alliance route", ns.ROUTE[1].key == "hot")
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 10. Same-name chain without IDs (Horde Hidden Enemies) ---
run('state.faction = "Horde"; SlashCmdList.DUNGEONLEVELINGCOMPANION("faction auto"); SlashCmdList.DUNGEONLEVELINGCOMPANION("reset confirm")'); take("chat")
run('state.questLog = {}; state.flagged = {}; DungeonLevelingCompanionDB.questDone = {}; DungeonLevelingCompanionDB.turnedIn = {}; DungeonLevelingCompanionDB.idKey = {}; DungeonLevelingCompanionDB.achDone = {}')
run('state.level = 13; state.xp = 0'); qlog()
def rfc_steps(): return [(s.step.part, s.status) for s in ns.PrepSteps(ns.BY_KEY.rfc).values()]
check("Hidden Enemies: both parts to do", rfc_steps() == [(1, "todo"), (2, "todo")], rfc_steps())
run('state.questLog = { { title = "Hidden Enemies", id = 5726, complete = false } }'); qlog()
check("part 1 in log", rfc_steps() == [(1, "inlog"), (2, "todo")], rfc_steps())
run('state.questLog = {}; fire("QUEST_TURNED_IN", 5726, 500, 0)'); qlog()
check("part 1 turned in -> [x], part 2 to do", rfc_steps() == [(1, "done"), (2, "todo")], rfc_steps())
run('state.questLog = { { title = "Hidden Enemies", id = 5727, complete = true } }'); qlog()
check("part 2 in log", rfc_steps() == [(1, "done"), (2, "inlog")], rfc_steps())
p = panel(); print("\n".join(l for l in p if "Hidden" in l or "Before" in l))
check("RFC dungeon quest not finished and NOT shown in log while a prereq part is", any(q.name == "Hidden Enemies" and not q.inLog for q in ns.DungeonQuests(ns.BY_KEY.rfc).values()))
run('state.questLog = {}; fire("QUEST_TURNED_IN", 5727, 500, 0)'); qlog()
check("both parts [x]", rfc_steps() == [(1, "done"), (2, "done")], rfc_steps())
run('state.questLog = { { title = "Hidden Enemies", id = 5728, complete = false } }'); qlog()
check("RFC part in log shown as dungeon quest (yellow)", any(q.name == "Hidden Enemies" and q.inLog for q in ns.DungeonQuests(ns.BY_KEY.rfc).values()))
run('state.questLog = {}; fire("QUEST_TURNED_IN", 5728, 900, 0)'); qlog()
check("after the RFC part, dungeon quest finished", not any(q.name == "Hidden Enemies" for q in ns.DungeonQuests(ns.BY_KEY.rfc).values()))
run('state.faction = "Alliance"; SlashCmdList.DUNGEONLEVELINGCOMPANION("faction auto")'); take("chat")
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 11. Performance: no work on unrelated events, batched redraws ---
run('state.scans = 0; local orig = C_UnitAuras.GetAuraDataByIndex; C_UnitAuras.GetAuraDataByIndex = function(...) state.scans = state.scans + 1; return orig(...) end')
run('state.tipScans = 0')
run('state.auras.HELPFUL = { { name = "Arcane Intellect", exp = state.now + 900, tip = "Increases Intellect" }, { name = "Mark of the Wild", exp = state.now + 900, tip = "x" }, { name = "Well Fed", exp = state.now + 900, tip = "Increases experience gained from kills by 5%." } }')
run('fire("UNIT_AURA", "player"); state.now = state.now + 1'); ns.Refresh()
run('state.scans = 0')
for _ in range(20):
    run('fire("CHAT_MSG_SYSTEM", "Bob has invited you to join a group."); fire("UNIT_AURA", "party1"); state.now = state.now + 0.2')
    ns.Refresh()
check("party UNIT_AURA + system chat spam -> no aura rescans", G.state.scans == 0, G.state.scans)
run('fire("UNIT_AURA", "player"); state.now = state.now + 0.5'); ns.Refresh()
check("player UNIT_AURA -> one rescan", G.state.scans > 0)
fs = ns.FoodStatus(); fs = fs if isinstance(fs, str) else fs[0]
check("food still detected (only Well Fed tooltip read)", fs == "xp", fs)
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("perf")'); out = take("chat"); print("\n".join(out))
check("/fr perf reports", any("ms each" in l for l in out))
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 12. Taint safety: no Blizzard raid-warning frame, no alerts at low level / in cinematics ---
run('state.raidNoticeCalls = 0; RaidNotice_AddMessage = function() state.raidNoticeCalls = state.raidNoticeCalls + 1 end')
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("set food on"); SlashCmdList.DUNGEONLEVELINGCOMPANION("set tentwarn on")'); take("chat")
run('state.auras.HELPFUL = {}; state.auras.HARMFUL = {}; state.rested = 0; state.indoors = false; state.resting = false; state.combat = false')
run('state.level = 1; state.xp = 0; state.now = state.now + 1000; tick()')
check("level 1: no alerts", not take("warnings"))
run('state.level = 20; state.cinematic = true; state.now = state.now + 1000; tick()')
check("in a cinematic: no alerts", not take("warnings"))
run('state.cinematic = false; state.uiVisible = false; state.now = state.now + 1000; tick()')
check("UI hidden: no alerts", not take("warnings"))
run('state.uiVisible = true; state.now = state.now + 1000; tick()')
w = take("warnings")
check("level 20, normal UI: alerts fire", any("Well Fed" in x for x in w), w)
check("Blizzard RaidNotice_AddMessage never called", G.state.raidNoticeCalls == 0, G.state.raidNoticeCalls)
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("set minlevel 25")'); take("chat")
run('state.now = state.now + 1000; tick()')
check("/fr set minlevel 25 -> no alerts at 20", not take("warnings"))
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("set minlevel 10")'); take("chat")
# data-only tooltip API path
run('state.tipFrames = 0; local cf = CreateFrame; CreateFrame = function(kind, ...) if kind == "GameTooltip" then state.tipFrames = state.tipFrames + 1 end return cf(kind, ...) end')
run('C_TooltipInfo = { GetUnitAura = function(unit, i, filter) local a = state.auras[filter][i] return a and { lines = { { leftText = a.name }, { leftText = a.tip } } } end }')
run('state.auras.HELPFUL = { { name = "Well Fed", exp = state.now + 900, tip = "Increases experience gained from kills by 5%.", spell = 99 } }; fire("UNIT_AURA", "player"); state.now = state.now + 1')
fs = ns.FoodStatus(); fs = fs if isinstance(fs, str) else fs[0]
check("food XP read via C_TooltipInfo", fs == "xp", fs)
check("no hidden tooltip frame created when C_TooltipInfo exists", G.state.tipFrames == 0, G.state.tipFrames)
run('C_TooltipInfo = nil')
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 13. Account-wide alert start level (default 4) ---
run('DungeonLevelingCompanionGlobalDB = nil; ns_init = 1'); ns.InitDB(); take("chat")
check("default alert start level is 6", G.DungeonLevelingCompanionGlobalDB.warnMinLevel == 6, G.DungeonLevelingCompanionGlobalDB.warnMinLevel)
run('state.auras.HELPFUL = {}; state.auras.HARMFUL = {}; state.combat = false; state.level = 5; state.now = state.now + 1000; tick()')
check("level 5: no alerts", not take("warnings"))
run('state.level = 6; state.now = state.now + 1000; tick()')
check("level 6: alerts start", len(take("warnings")) > 0)
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("set minlevel 8")'); out = take("chat")
check("/fr set minlevel says all characters", any("all your characters" in l for l in out), out)
# "log in" a different character: per-character data is new, account-wide setting stays
run('DungeonLevelingCompanionDB = nil'); ns.InitDB()
check("new character keeps account-wide minlevel 8", G.DungeonLevelingCompanionGlobalDB.warnMinLevel == 8 and G.DungeonLevelingCompanionDB.runs is not None and len(list(G.DungeonLevelingCompanionDB.runs.keys())) == 0)
check("per-character settings don't carry warnMinLevel", G.DungeonLevelingCompanionDB.settings.warnMinLevel is None)
run('state.level = 6; state.now = state.now + 1000; tick()')
check("level 6 with minlevel 8: no alerts", not take("warnings"))
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 14. Food XP detection robustness ---
def food():
    fs = ns.FoodStatus(); return fs if isinstance(fs, str) else fs[0]
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("set food on")'); take("chat")
run('state.level = 20; state.combat = false; state.auras.HARMFUL = {}')
# a) C_TooltipInfo where text only exists in line.args (older client format)
run('C_TooltipInfo = { GetUnitAura = function(u, i, f) local a = state.auras[f][i] if not a then return nil end '
    'return { lines = { { args = { { field = "leftText", stringVal = a.name } } }, { args = { { field = "leftText", stringVal = a.tip } } } } } end }')
run('state.auras.HELPFUL = { { name = "Well Fed", exp = state.now + 900, tip = "Increases experience gained from kills by 5%.", spell = 1 } }')
run('local o = C_UnitAuras.GetAuraDataByIndex; C_UnitAuras.GetAuraDataByIndex = function(u, i, f) local d = o(u, i, f) local a = state.auras[f][i] if d and a then d.spellId = a.spell end return d end')
run('fire("UNIT_AURA", "player"); state.now = state.now + 1')
check("tooltip text packed in line.args -> XP food detected", food() == "xp", food())
# b) tooltip not loaded yet (only the name line) -> 'checking', no alert, not cached as 'no XP'
run('state.tipReady = false; local real = C_TooltipInfo.GetUnitAura; C_TooltipInfo.GetUnitAura = function(u, i, f) local d = real(u, i, f) if d and not state.tipReady then d.lines = { d.lines[1] } end return d end')
run('state.auras.HELPFUL = { { name = "Well Fed", exp = state.now + 900, tip = "Increases experience gained from kills by 5%.", spell = 2 } }; fire("UNIT_AURA", "player"); state.now = state.now + 1')
check("tooltip not ready -> 'checking'", food() == "checking", food())
take("warnings"); run('state.now = state.now + 500; tick()')
check("no 'no XP' alert while checking", not any("no bonus XP" in w or "Missing" in w for w in take("warnings")))
run('state.tipReady = true; state.now = state.now + 2'); ns.Refresh()
check("tooltip loads -> XP detected on retry", food() == "xp", food())
# c) wording with 'XP' instead of 'experience'
run('state.auras.HELPFUL = { { name = "Well Fed", exp = state.now + 900, tip = "Increases XP from kills by 5%.", spell = 3 } }; fire("UNIT_AURA", "player"); state.now = state.now + 1')
check("'XP' wording detected", food() == "xp", food())
# d) genuinely non-XP food
run('state.auras.HELPFUL = { { name = "Well Fed", exp = state.now + 900, tip = "Increases Stamina and Spirit by 2.", spell = 4 } }; fire("UNIT_AURA", "player"); state.now = state.now + 1')
check("stat-only food: first read -> still checking", food() == "checking", food())
for _ in range(6):
    run("state.now = state.now + 3"); ns.Refresh()
check("stat-only food: after 5 spaced reads -> nonxp", food() == "nonxp", food())
# e) /dlc buffs diagnostic
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("buffs")'); out = take("chat"); print("\n".join(out))
check("/dlc buffs lists the buff, its spell and tooltip", any("Well Fed" in l and "spell 4" in l for l in out) and any("Stamina" in l for l in out))
run('C_TooltipInfo = nil')
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 15. Real tooltip from the game: description arrives after the time-left line ---
run('C_TooltipInfo = { GetUnitAura = function(u, i, f) local a = state.auras[f][i] if not a then return nil end '
    'local lines = { { leftText = a.name } } '
    'if state.descReady then table.insert(lines, { leftText = a.tip }) end '
    'table.insert(lines, { leftText = "59 min remaining" }) return { lines = lines } end }')
run('state.descReady = false; state.auras.HELPFUL = { { name = "Well Fed", exp = state.now + 3600, '
    'tip = "Your Strength is increased by 1. Experience gained from kills increased by 5%.", spell = 1248422 } }; '
    'fire("UNIT_AURA", "player"); state.now = state.now + 1')
check("name + time-left only -> 'checking' (not cached as no XP)", food() == "checking", food())
for _ in range(10):  # lots of refreshes within one second must not 'confirm' no-XP
    ns.Refresh(); ns.CheckWarnings()
check("rapid refreshes don't confirm 'no XP'", food() == "checking", food())
run('state.descReady = true; state.now = state.now + 3'); ns.Refresh()
check("Roasted Boar Meat tooltip -> XP food", food() == "xp", food())
check("no 'no bonus XP' alert during all this", not any("no bonus XP" in w for w in take("warnings")))
run('C_TooltipInfo = nil')
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 16. Dalaran secret boss: Black Tome (SFK) -> Tome of Dalaran (item steps) ---
run('state.items = {}; GetItemCount = function(id) return state.items[id] or 0 end; SlashCmdList.DUNGEONLEVELINGCOMPANION("reset confirm")'); take("chat")
def dal_prep(): return [(s.step.q, s.status) for s in ns.PrepSteps(ns.BY_KEY.dal).values()]
def tome(): return [(q, st) for q, st in dal_prep() if q != "An Alarming Request"]
check("Alliance Dalaran prep = Sewer Key quest, then both tome steps", dal_prep() == [("An Alarming Request", "todo"), ("Black Tome", "todo"), ("Tome of Dalaran", "todo")], dal_prep())
xp_dal, min_dal = ns.PrepLeft(ns.BY_KEY.dal)
check("tome steps are optional (only the key quest counts: 660 XP, 20m)", xp_dal == 660 and min_dal == 20, (xp_dal, min_dal))
run('state.level = 21; state.xp = 0'); lines = panel()
check("SFK panel reminds to loot the Black Tome", any("Loot: Black Tome" in l and "City of Dalaran" in l for l in lines), [l for l in lines if "Loot" in l])
run('state.items[276561] = 1'); lines = panel()
check("Black Tome in bags -> step done, reminder gone", tome()[0][1] == "done" and not any("Loot: Black Tome" in l for l in lines), tome())
run('state.items[276561] = 0; state.items[275989] = 1')
check("Tome of Dalaran in bags -> both done", tome() == [("Black Tome", "done"), ("Tome of Dalaran", "done")], tome())
run('state.items[275989] = 0')
check("tome used up -> still done (remembered)", tome() == [("Black Tome", "done"), ("Tome of Dalaran", "done")], tome())

# Shaper's Terrace: any Un'Goro power crystal counts the prep step as done.
def crystals(): return [(s.step.q, s.status) for s in ns.PrepSteps(ns.BY_KEY.shaper).values()]
check("Shaper's Terrace prep = power crystals, to do", crystals() == [("Un'Goro Power Crystals", "todo")], crystals())
run('state.items[11186] = 3')
check("a Red Power Crystal -> crystal step done", crystals() == [("Un'Goro Power Crystals", "done")], crystals())
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 17. Group sync, options window, minimap button, panel sections ---
run('''
state.sent = {}; state.inGroup = false; state.party = {}
function IsInGroup() return state.inGroup end
function IsInRaid() return false end
function GetNumGroupMembers() return state.inGroup and 2 or 0 end
function UnitName() return "Me" end
function Ambiguate(s) return s end
function UnitInParty(n) return state.party[n] or false end
C_ChatInfo = { RegisterAddonMessagePrefix = function() return true end,
               SendAddonMessage = function(p, m, ch) table.insert(state.sent, { p, m, ch }) end }
GameTooltip = setmetatable({}, { __index = function() return function() end end })
Minimap = CreateFrame("Frame", "Minimap"); Minimap.GetWidth = function() return 140 end; Minimap.GetCenter = function() return 100, 100 end
''')
run('state.level = 21; state.xp = 0; state.now = state.now + 100; state.inGroup = true; state.party.Bob = true; fire("GROUP_ROSTER_UPDATE")')
sent = [(m[1], m[2], m[3]) for m in G.state.sent.values()]
check("joining a group asks for status and sends ours", any(s[1] == "R" for s in sent) and any(s[1].startswith("S;1;A;21;") for s in sent), sent)
check("sent to PARTY with the DLCSYNC prefix", all(s[0] == "DLCSYNC" and s[2] == "PARTY" for s in sent), sent)
d = ns.Focus()
n = len(list(d.questInfo.values()))
run(f'fire("CHAT_MSG_ADDON", "DLCSYNC", "S;1;A;22;{d.key};2;0;{d.key}={"1" * n},1", "PARTY", "Bob")')
lines = panel()
check("panel: group line with Bob, level, no XP food, prereqs", any("Bob 22" in l and "no XP food" in l for l in lines), [l for l in lines if "Bob" in l])
check("panel: quests show who else needs them", n == 0 or any("Bob" in l and ("+Bob" in l or "Group needs" in l) for l in lines), [l for l in lines if "Bob" in l])
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("group")'); out = take("chat")
check("/dlc group lists Bob", any("Bob (22)" in l for l in out), out[:3])
run('state.sent = {}; state.combat = true; state.now = state.now + 120'); run('for _, fn in ipairs(tickers) do fn() end')
check("nothing sent in combat", len(list(G.state.sent.values())) == 0, list(G.state.sent.values()))
run('state.combat = false; fire("PLAYER_REGEN_ENABLED")')
check("queued status sent after combat", len(list(G.state.sent.values())) > 0)
run('state.party.Bob = nil; fire("GROUP_ROSTER_UPDATE")'); lines = panel()
check("Bob leaves -> dropped from the panel", not any("Bob" in l for l in lines))
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("sync off")'); take("chat"); run('state.sent = {}; state.now = state.now + 120; for _, fn in ipairs(tickers) do fn() end')
check("sync off -> nothing sent", len(list(G.state.sent.values())) == 0)
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("sync on")'); take("chat")
# options + minimap
run('ns_opts_ok = pcall(SlashCmdList.DUNGEONLEVELINGCOMPANION, "config")')
check("/dlc config builds the options window", G.ns_opts_ok and G.DungeonLevelingCompanionOptions is not None)
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("minimap")'); out = take("chat")
check("/dlc minimap toggles the button", any("hidden" in l for l in out) and G.DungeonLevelingCompanionGlobalDB.minimapHide, out)
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("minimap")'); take("chat")
# section toggles + secret boss
G.DungeonLevelingCompanionDB.settings.showSpelunker = False; lines = panel()
check("Spelunker section can be hidden", not any("Spelunker:" in l for l in lines))
G.DungeonLevelingCompanionDB.settings.showSpelunker = True
run('state.level = 20'); lines = panel()
rec = ns.Focus().key
check("Ruins of Lordaeron shows its secret boss", rec != "rol" or any("Secret boss:" in l and "Viktor" in l for l in lines), (rec, [l for l in lines if "Secret" in l]))
check("no errors", not take("errors"), take("errors"))
print("\nFAILURES:", fails)

# --- 19. Click-through toggle ---
run('DungeonLevelingCompanionFrame.EnableMouse = function(self, v) self.mouse = v end')
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("clickthrough")'); out = take("chat")
check("/dlc clickthrough -> panel ignores the mouse", G.DungeonLevelingCompanionFrame.mouse is False and G.DungeonLevelingCompanionDB.settings.clickThrough, out)
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("clickthrough")'); take("chat")
check("toggle again -> mouse back on", G.DungeonLevelingCompanionFrame.mouse is True)
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 22. Cozy Sleeping Bag chain: Westfall pickup (DM prep), Barrens/Stonetalon (WC), Loch Modan/Hillsbrad (RoL) ---
run('SlashCmdList.DUNGEONLEVELINGCOMPANION("reset confirm"); state.questLog = {}; state.flagged = {}; state.bag = false; '
    'DungeonLevelingCompanionDB.questDone = {}; DungeonLevelingCompanionDB.questIDs = {}; DungeonLevelingCompanionDB.turnedIn = {}; '
    'DungeonLevelingCompanionDB.achDone = {}'); take("chat")
run('state.level = 16; state.xp = 0; DungeonLevelingCompanionDB.runs.hot = 2'); qlog(); ns.MarkBagsDirty()
def steps(k): return [(s.step.q, s.status) for s in ns.PrepSteps(ns.BY_KEY[k]).values()]
check("DM prep starts with the note pickup", steps("dm")[0] == ("...and that note you found", "todo"), steps("dm")[:2])
check("DM prep XP unchanged by the pickup (6100)", ns.PrepLeft(ns.BY_KEY.dm)[0] == 6100, ns.PrepLeft(ns.BY_KEY.dm))
wc_xp = ns.PrepLeft(ns.BY_KEY.wc)[0]
check("WC prep = Raptor Horns 1275 + 3150 + 3150 + 315", wc_xp == 1275 + 6615, wc_xp)
check("RoL prep = 3150 + 3150 + 2350", ns.PrepLeft(ns.BY_KEY.rol)[0] == 8650, ns.PrepLeft(ns.BY_KEY.rol))
# note picked up in Westfall: DM step done, WC step 'in log'
run('state.questLog = { { title = "...and that note you found", id = 96500, complete = false } }'); qlog()
check("note in log -> DM pickup done", steps("dm")[0][1] == "done", steps("dm")[0])
check("note in log -> WC turn-in step in log", steps("wc")[1] == ("...and that note you found", "inlog"), steps("wc"))
# Wet Job in log -> everything before it done, RoL Wet Job in log
run('state.questLog = { { title = "Wet Job", id = 96503, complete = false } }'); qlog()
wc = [s for s in steps("wc") if s[0] != "Raptor Horns" and s[0] != "Rekindle"]
check("Wet Job in log -> Barrens/Stonetalon steps done", all(st == "done" for _, st in wc), wc)
check("Wet Job in log -> RoL first step in log", steps("rol")[0] == ("Wet Job", "inlog"), steps("rol"))
check("RoL prep XP still counts Wet Job until turned in (8650)", ns.PrepLeft(ns.BY_KEY.rol)[0] == 8650, ns.PrepLeft(ns.BY_KEY.rol))
# owning the bag (finished before install) -> every bag step done
run('state.questLog = {}; state.bag = true'); qlog(); ns.MarkBagsDirty()
check("bag owned -> RoL prep empty", len(list(ns.PrepOpen(ns.BY_KEY.rol).values())) == 0)
check("bag owned -> WC only Raptor Horns left", [s.step.q for s in ns.PrepOpen(ns.BY_KEY.wc).values()] == ["Raptor Horns"])
check("no errors", not take("errors"))
print("\nFAILURES:", fails)

# --- 23. Cozy Sleeping Bag chain, Horde: Barrens pickup (WC), Westfall (DM), Stonetalon (RFK), dam + wall (Excavation Site) ---
run('state.faction = "Horde"; SlashCmdList.DUNGEONLEVELINGCOMPANION("faction auto"); SlashCmdList.DUNGEONLEVELINGCOMPANION("reset confirm"); '
    'state.questLog = {}; state.flagged = {}; state.bag = false; DungeonLevelingCompanionDB.questDone = {}; '
    'DungeonLevelingCompanionDB.questIDs = {}; DungeonLevelingCompanionDB.turnedIn = {}; DungeonLevelingCompanionDB.achDone = {}'); take("chat")
run('state.level = 19; state.xp = 0'); qlog(); ns.MarkBagsDirty()
bagq = {"...and that note you found", "Stepping Stones", "Rekindle", "Scramble", "Wet Job", "Eagle's Fist", "This Must Be The Place"}
def bagsteps(k): return [s for s in steps(k) if s[0] in bagq]
check("Horde WC prep ends with the note pickup", steps("wc")[-1] == ("...and that note you found", "todo"), steps("wc")[-2:])
check("Horde DM prep = Westfall turn-in (3150)", bagsteps("dm") == [("...and that note you found", "todo")] and ns.PrepLeft(ns.BY_KEY.dm)[0] == 3150, steps("dm"))
check("Horde RFK prep = Stonetalon (3150 + 315)", [q for q, _ in bagsteps("rfk")] == ["Stepping Stones", "Rekindle", "Scramble"] and ns.PrepLeft(ns.BY_KEY.rfk)[0] == 3465, steps("rfk"))
check("Horde Excavation prep = Dragonmaw Rumors then dam + wall", [q for q, _ in steps("exc")] == ["Dragonmaw Rumors", "Wet Job", "Eagle's Fist", "This Must Be The Place"], steps("exc"))
check("no bag steps on Horde Ruins of Lordaeron", bagsteps("rol") == [], steps("rol"))
# note in log: WC pickup done, DM turn-in in log
run('state.questLog = { { title = "...and that note you found", id = 79007, complete = false } }'); qlog()
check("Horde note in log -> WC pickup done, DM turn-in in log", steps("wc")[-1][1] == "done" and steps("dm")[0] == ("...and that note you found", "inlog"), (steps("wc")[-1], steps("dm")))
check("no errors", not take("errors"))

# --- Back-to-back runs ---
run('state.faction = "Alliance"; SlashCmdList.DUNGEONLEVELINGCOMPANION("faction auto")'); take("chat")
def sfk(): return G.DungeonLevelingCompanionDB.runs.sfk or 0
def enter(): run('state.inInstance = true; state.instName = "Shadowfang Keep"; fire("ZONE_CHANGED_NEW_AREA"); tick()')
def leave(): run('state.t = state.t + 60; state.inInstance = false; state.instName = nil; fire("ZONE_CHANGED_NEW_AREA"); tick()')
run('DungeonLevelingCompanionDB.runs.sfk = nil; DungeonLevelingCompanionDB.curRun = nil;'
    'state.level = 23; state.xp = 0; state.rested = 0; fire("PLAYER_XP_UPDATE", "player")')
# run 1, someone else resets while we're outside, run 2 starts within the grace period
enter(); run('kill(3000); fire("ENCOUNTER_END", 1, "Rethilgore", 1, 5, 1); kill(2000); fire("ENCOUNTER_END", 9, "Arugal", 1, 5, 1)')
leave(); run('state.t = state.t + 120'); enter()
run('kill(4000)'); take("chat")
run('fire("ENCOUNTER_END", 1, "Rethilgore", 1, 5, 1)')
check("same boss twice -> first run logged", sfk() == 1, sfk())
run('kill(1000)'); leave(); run('state.t = state.t + 400; tick()')
check("second run logged too", sfk() == 2, sfk())
# a wipe re-pull of the same boss without leaving doesn't split
enter(); run('kill(500); fire("ENCOUNTER_END", 1, "Rethilgore", 1, 5, 0); fire("ENCOUNTER_END", 1, "Rethilgore", 1, 5, 1); kill(500)')
check("failed + successful pull is still one run", G.DungeonLevelingCompanionDB.curRun.xp == 1000 and sfk() == 2, G.DungeonLevelingCompanionDB.curRun.xp)
# group member resets -> run ends right away via sync
leave(); take("chat")
run('state.inGroup = true; state.party.Bob = true; fire("CHAT_MSG_ADDON", "DLCSYNC", "X", "PARTY", "Bob")')
check("reset from a group member ends the run", G.DungeonLevelingCompanionDB.curRun is None and any("Logged Shadowfang" in m for m in take("chat")))
# we reset -> group is told
enter(); run('kill(800)'); leave(); run('state.sent = {}; fire("CHAT_MSG_SYSTEM", "Shadowfang Keep has been reset.")')
sent = [G.state.sent[i][2] for i in range(1, len(G.state.sent) + 1)]
check("our reset is sent to the group", "X" in sent and G.DungeonLevelingCompanionDB.curRun is None, sent)
# old XP-estimate data and settings are cleared on load
run('DungeonLevelingCompanionDB.measured = { sfk = { 19869 } }; DungeonLevelingCompanionDB.cycle = {}; DungeonLevelingCompanionDB.settings.groupShare = 0.28'); ns.InitDB()
check("pre-1.5.0 estimate data cleared", G.DungeonLevelingCompanionDB.measured is None and G.DungeonLevelingCompanionDB.cycle is None
      and G.DungeonLevelingCompanionDB.settings.groupShare is None)
check("no errors", not take("errors"))
# Wowhead quest lists for the new dungeons
qn = lambda k: [q.name for q in ns.BY_KEY[k].questInfo.values()]
check("Drowned City Alliance quests from Wowhead", len(qn("drowned")) == 5 and "Magics of the Drowned City" in qn("drowned"), qn("drowned"))
check("Krol'dok Alliance quests + A Small Favor prep", len(qn("krol")) == 8 and ns.BY_KEY.krol.prep[1].id == 94907, qn("krol"))
run('state.faction = "Horde"; SlashCmdList.DUNGEONLEVELINGCOMPANION("faction auto")'); take("chat")
check("Drowned City Horde quests from Wowhead", "The Drowned City" in qn("drowned") and len(qn("drowned")) == 5, qn("drowned"))
check("Shaper's Terrace still TBD", ns.BY_KEY.shaper.questPlaceholder and len(qn("shaper")) == 0)
check("no errors", not take("errors"))
print("\nFAILURES:", fails)
