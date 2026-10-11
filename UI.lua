local ADDON, ns = ...

local Print = ns.Print
local frame, text

local GREEN, RED, YELLOW, GREY, WHITE = "|cff55ff55", "|cffff5555", "|cffffff00", "|cff999999", "|cffffffff"

local function Mins(sec)
    if not sec then return "?" end
    if sec >= 3600 then return ("%dh%02dm"):format(math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
    return ("%dm"):format(math.ceil(sec / 60))
end

local MAX_QUEST_LINES = 8

-- One line per unfinished quest: green = ready to turn in, yellow = in log, grey = pick it up.
local function QuestLine(q)
    if q.complete then
        return ("  %s+ %s - turn in|r"):format(GREEN, q.name)
    elseif q.inLog then
        local progress = (q.need and q.need > 0) and (" %d/%d"):format(q.have, q.need) or ""
        return ("  %s- %s%s|r"):format(YELLOW, q.name, progress)
    end
    return ("  %s- %s%s|r"):format(GREY, q.name, q.from and (" (" .. q.from .. ")") or "")
end

local function AddQuestLines(lines, d)
    local quests = ns.DungeonQuests and ns.DungeonQuests(d) or {}
    if #quests == 0 then return end
    table.insert(lines, ("Quests (%d left):"):format(#quests))
    for i, q in ipairs(quests) do
        if i > MAX_QUEST_LINES then
            table.insert(lines, ("  %s+%d more - /dlc quests|r"):format(GREY, #quests - MAX_QUEST_LINES))
            break
        end
        table.insert(lines, QuestLine(q))
    end
end

-- One line per prep quest: [x] done, [ ] to do (yellow = in your log, green = turn in).
local function StepLine(s)
    local step = s.step
    local part = step.part and (" (%d/%d)"):format(step.part, step.parts) or ""
    local opt = step.optional and " [optional]" or ""
    if s.status == "done" then
        return ("  %s[x] %d. %s%s|r"):format(GREEN, s.num, step.q, part)
    elseif s.status == "inlog" and s.log and s.log.complete then
        return ("  %s[ ] %d. %s%s - turn in|r"):format(GREEN, s.num, step.q, part)
    elseif s.status == "inlog" then
        local progress = (s.log and s.log.need and s.log.need > 0) and (" %d/%d"):format(s.log.have, s.log.need) or " (in log)"
        return ("  %s[ ] %d. %s%s%s|r"):format(YELLOW, s.num, step.q, part, progress)
    end
    return ("  %s[ ] %d. %s%s%s%s - %s|r"):format(GREY, s.num, step.pickup and "Pick up " or "", step.q, part, opt, step.from or "")
end

-- All prep quests for d with done/not done; the first open one also shows what to do.
-- Returns false when d has no prereqs or they're all done.
local function AddPrepLines(lines, d, title)
    local steps = ns.PrepSteps and ns.PrepSteps(d) or {}
    local open = ns.PrepOpen(d)
    if #steps == 0 or #open == 0 then return false end
    local xp, min = ns.PrepLeft(d)
    table.insert(lines, ("%s%s|r %s%d/%d done (~%dm, ~%dk XP left)|r"):format(
        YELLOW, title, GREY, #steps - #open, #steps, min, math.floor(xp / 1000 + 0.5)))
    local shownWhat = false
    for _, s in ipairs(steps) do
        table.insert(lines, StepLine(s))
        if not shownWhat and s.status ~= "done" and s.step.what then
            table.insert(lines, ("        %s%s|r"):format(GREY, s.step.what))
            shownWhat = true
        end
    end
    return true
end

-- Items to grab for later dungeons: in the recommended dungeon, or the one you're running now.
local function AddLootLines(lines, d)
    local here = { d }
    local run = ns.DB.curRun
    if run and run.instance then
        local inst = run.instance:lower()
        for _, e in ipairs(ns.ROUTE) do
            for _, m in ipairs(e.match or {}) do
                if e ~= d and inst:find(m, 1, true) then table.insert(here, e) break end
            end
        end
    end
    for _, e in ipairs(here) do
        for _, r in ipairs(ns.LootReminders(e)) do
            table.insert(lines, ("%sLoot: %s|r %s(%s) - for %s|r"):format(YELLOW, r.step.q, GREY, r.step.from or "", r["for"].name))
        end
    end
end

local function BuildText()
    local DB, S = ns.DB, ns.S
    local lines = {}
    local lvl = UnitLevel("player")
    local d, missed = ns.Recommend()

    if d then
        local done = DB.runs[d.key] or 0
        if lvl >= 60 then
            table.insert(lines, ("%sNext:|r %s %s(Spelunker)|r"):format(YELLOW, d.name, GREY))
        elseif lvl < d.start then
            table.insert(lines, ("%sSolo to %d, then:|r %s"):format(YELLOW, d.start, d.name))
        else
            local left = ns.RunsLeft(d)
            local perRun, measured = ns.XPPerRun(d)
            local tent = ns.TentPerRun(d)
            table.insert(lines, ("%sNow:|r %s%s|r  (%d-%d)"):format(YELLOW, WHITE, d.name, d.start, d.to))
            table.insert(lines, ("  ~%d more run%s to %d  |  done: %d"):format(left, left == 1 and "" or "s", d.to, done))
            table.insert(lines, ("  %s%d XP/run%s + %d tent, ~%dm/run|r"):format(GREY, math.floor(perRun + 0.5), measured and " (measured)" or "", math.floor(tent + 0.5), d.min))
            local prepXP = ns.LegPrepXP(d)
            if prepXP > 0 then
                table.insert(lines, ("  %s(counts ~%dk XP from prereq quests)|r"):format(GREY, math.floor(prepXP / 1000 + 0.5)))
            end
        end
        -- Prereqs for this dungeon if you haven't run it yet, then its quests.
        if done == 0 then AddPrepLines(lines, d, "Before your first run:") end
        AddQuestLines(lines, d)
        AddLootLines(lines, d)
        -- Prereqs for the next dungeon once the swap is close.
        local nextD = ns.ROUTE[d.index + 1]
        if lvl < 60 and lvl >= d.start and nextD and nextD.start < 60
            and (lvl >= nextD.start - 2 or ns.RunsLeft(d) <= 2) then
            if not AddPrepLines(lines, nextD, ("Prep for %s:"):format(nextD.name)) then
                table.insert(lines, ("%sNext: %s at %d - no prereqs needed|r"):format(GREY, nextD.name, nextD.start))
            end
        end
    else
        table.insert(lines, GREEN .. "Route complete!|r")
    end

    local tiers = {}
    for _, t in ipairs(ns.TIERS) do
        local done, total = ns.TierProgress(t)
        local achT = ns.DB.achTiers and ns.DB.achTiers[t]
        local color = (done == total or (achT and achT.completed)) and GREEN or WHITE
        tiers[#tiers + 1] = ("%s%s %d/%d|r"):format(color, t:sub(1, 3), done, total)
    end
    table.insert(lines, "Spelunker: " .. table.concat(tiers, "  "))

    if #missed > 0 then
        local names = {}
        for i, m in ipairs(missed) do
            if i > 3 then names[#names + 1] = ("+%d more"):format(#missed - 3) break end
            names[#names + 1] = m.name
        end
        table.insert(lines, RED .. "Not run yet: " .. table.concat(names, ", ") .. "|r")
    end

    if lvl < 60 then
        local state, left = ns.FoodStatus()
        if state == "xp" then
            table.insert(lines, ("Food: %sWell Fed (XP)|r %s"):format(GREEN, left and Mins(left) or ""))
        elseif state == "checking" then
            table.insert(lines, "Food: " .. GREY .. "Well Fed (checking tooltip...)|r")
        elseif state == "nonxp" then
            table.insert(lines, "Food: " .. YELLOW .. "Well Fed, but no XP bonus (/dlc buffs)|r")
        else
            table.insert(lines, "Food: " .. RED .. "MISSING|r")
        end
        if S.useTent then
            local onCd, cdLeft = ns.TentCooldown()
            local rested = ns.RestedFrac() * 100
            if onCd then
                table.insert(lines, ("Tent: %scooldown %s|r  |  rested %.1f%%"):format(GREY, Mins(cdLeft), rested))
            elseif rested < S.tentFrac * 100 * 0.98 then
                local inDungeon = select(2, IsInInstance()) == "party"
                local status = inDungeon and (YELLOW .. "ready - camp after this run")
                    or IsResting() and (YELLOW .. "ready - camp outside town")
                    or IsIndoors() and (YELLOW .. "ready - camp outdoors")
                    or (RED .. "READY - camp!")
                table.insert(lines, ("Tent: %s|r  |  rested %.1f%%"):format(status, rested))
            else
                table.insert(lines, ("Tent: %sready|r (rested %.1f%%, already full)"):format(GREEN, rested))
            end
        end
        local stacks, bagLeft, owned, bagCd = ns.BagStatus()
        if stacks > 0 then
            local color = stacks >= 3 and GREEN or YELLOW
            table.insert(lines, ("Bag: %sWell-Rested %d/3|r %s%s"):format(color, stacks, bagLeft and Mins(bagLeft) or "",
                bagCd > 0 and (GREY .. "  (bag cd " .. Mins(bagCd) .. ")|r") or ""))
        elseif owned and bagCd > 0 then
            table.insert(lines, ("Bag: %sno buff - bag on cooldown %s|r"):format(GREY, Mins(bagCd)))
        elseif owned then
            table.insert(lines, "Bag: " .. RED .. "MISSING - lie on your sleeping bag|r")
        elseif lvl >= 14 then
            table.insert(lines, "Bag: " .. GREY .. "no Cozy Sleeping Bag yet (chain starts in Westfall)|r")
        end
    end

    if DB.curRun then
        table.insert(lines, ("%sIn run: %s - %d trash XP so far%s|r"):format(GREY, DB.curRun.instance, DB.curRun.xp,
            DB.curRun.leftAt and " (outside - ends in 5 min)" or ""))
    end
    return table.concat(lines, "\n")
end

function ns.Refresh()
    if not frame or not frame:IsShown() then return end
    text:SetText(BuildText())
    frame:SetHeight(text:GetStringHeight() + 34)
end

function ns.CreateUI()
    local S, DB = ns.S, ns.DB
    frame = CreateFrame("Frame", "DungeonLevelingCompanionFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(290, 120)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.75)
    end
    if DB.pos then
        frame:SetPoint(DB.pos[1], UIParent, DB.pos[3], DB.pos[4], DB.pos[5])
    else
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -220)
    end
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not ns.S.locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        ns.DB.pos = { p, nil, rp, x, y }
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("DLC - Dungeon Leveling Companion")

    text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 10, -26)
    text:SetWidth(270)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")

    frame:SetShown(S.shown)
    ns.Refresh()
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function ListRoute()
    local DB = ns.DB
    local lvl = UnitLevel("player")
    Print(("%s route (runs done / est. runs left):"):format(ns.faction or ""))
    for i, d in ipairs(ns.ROUTE) do
        local done = DB.runs[d.key] or 0
        local color = ns.IsDone(d) and GREEN or (d.tier and lvl >= d.to and lvl < 60 and RED or WHITE)
        local ach = (DB.achDone and DB.achDone[d.key]) and " |cff55ff55[ach]|r" or ""
        local left = (lvl >= d.start and lvl < d.to) and ("  ~" .. ns.RunsLeft(d) .. " left") or ""
        Print(("%2d. %s%s|r [%s] %d-%d  done %d%s%s  %s%s|r"):format(
            i, color, d.name, d.key, d.start, d.to, done, ach, left, GREY, d.tier or "optional"))
    end
end

local function ShowPrep(d)
    if not d then Print("Unknown dungeon. Try /dlc route for the keys.") return end
    if not d.prep or #d.prep == 0 then Print(d.name .. ": no prerequisite quests.") return end
    local steps, open = ns.PrepSteps(d), ns.PrepOpen(d)
    local xp, min = ns.PrepLeft(d)
    Print(("%s prerequisites: %d/%d done (~%dm, ~%dk XP left):"):format(
        d.name, #steps - #open, #steps, min, math.floor(xp / 1000 + 0.5)))
    for _, s in ipairs(steps) do
        Print(StepLine(s))
        Print(("        %s%s|r"):format(GREY, s.step.what or ""))
    end
end

local function ShowQuests(d)
    if not d then Print("Unknown dungeon. Try /dlc route for the keys.") return end
    local quests = ns.DungeonQuests(d)
    Print(("%s - %d quest%s left:"):format(d.name, #quests, #quests == 1 and "" or "s"))
    for _, q in ipairs(quests) do Print(QuestLine(q)) end
    if d.note then Print("  " .. GREY .. d.note .. "|r") end
end

local function SetSetting(key, value)
    local S = ns.S
    local map = { food = "warnFood", tentwarn = "warnTent", tent = "useTent", bag = "warnBag" }
    if map[key] then
        S[map[key]] = (value == "on")
        Print(("%s %s."):format(key, S[map[key]] and "on" or "off"))
    elseif key == "calib" then
        S.calibOverride = tonumber(value)
        Print(S.calibOverride and ("Calibration forced to %.2f."):format(S.calibOverride) or "Calibration back to auto.")
    elseif key == "minlevel" and tonumber(value) then
        ns.GDB.warnMinLevel = tonumber(value)
        Print(("Alerts start at level %d on all your characters."):format(ns.GDB.warnMinLevel))
    else
        Print("Usage: /dlc set food|tentwarn|tent|bag on|off, /dlc set calib <number|auto>, /dlc set minlevel <level>")
    end
    ns.Refresh()
end

local HELP = {
    "/dlc - show/hide the window",
    "/dlc route - full route with runs done",
    "/dlc quests [dungeon] - quests for the current (or named) dungeon",
    "/dlc prep [dungeon] - prerequisite quest steps for the next (or named) dungeon",
    "/dlc qdone <quest> | qundo <quest> - mark a quest or prereq step finished (or not) by hand",
    "/dlc run <dungeon> - log a run by hand (no XP)",
    "/dlc xp <dungeon> <amount> - log a run with measured trash XP",
    "/dlc assign <dungeon> - assign the last unrecognised run",
    "/dlc undo - remove the last logged run",
    "/dlc ach - show what was read from the Spelunker achievements",
    "/dlc perf - how much time/memory the addon uses",
    "/dlc buffs - list your buffs and their tooltip text (for food/tent/bag issues)",
    "/dlc set food|tentwarn|tent|bag on|off  -  /dlc set calib <n|auto>  -  /dlc set minlevel <n>",
    "/dlc lock | unlock - lock window position",
    "/dlc faction horde|alliance|auto - pick the route (auto = your character)",
    "/dlc reset confirm - wipe this character's data",
    "Runs are logged automatically when you leave a dungeon.",
}

local function ShowHelp()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = meta and meta(ADDON, "Version") or "?"
    Print(("v%s (%s route) - commands:"):format(version, ns.faction or "?"))
    for _, l in ipairs(HELP) do Print(l) end
end

SLASH_DUNGEONLEVELINGCOMPANION1 = "/dlc"
SLASH_DUNGEONLEVELINGCOMPANION2 = "/dungeonleveling"
SlashCmdList.DUNGEONLEVELINGCOMPANION = function(input)
    local DB, S = ns.DB, ns.S
    local cmd, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" then
        S.shown = not frame:IsShown()
        frame:SetShown(S.shown)
        ns.Refresh()
    elseif cmd == "help" then
        ShowHelp()
    elseif cmd == "ach" then
        ns.PrintAchievements()
        ns.Refresh()
    elseif cmd == "route" then
        ListRoute()
    elseif cmd == "quests" then
        ShowQuests(rest ~= "" and ns.FindDungeon(rest) or (ns.Recommend()))
    elseif cmd == "prep" then
        local d = rest ~= "" and ns.FindDungeon(rest)
        if not d then
            local cur = ns.Recommend()
            d = cur and ((DB.runs[cur.key] or 0) == 0 and #ns.PrepOpen(cur) > 0 and cur or ns.ROUTE[cur.index + 1]) or nil
        end
        ShowPrep(d)
    elseif cmd == "qdone" or cmd == "qundo" then
        ns.MarkQuest(rest, cmd == "qdone")
    elseif cmd == "run" then
        local d = ns.FindDungeon(rest)
        if d then ns.RecordRun(d, 0, UnitLevel("player")) else Print("Unknown dungeon: " .. rest) end
    elseif cmd == "xp" then
        local name, amount = rest:match("^(.-)%s+(%d+)$")
        local d = ns.FindDungeon(name)
        if d and amount then ns.RecordRun(d, tonumber(amount), UnitLevel("player")) else Print("Usage: /dlc xp <dungeon> <amount>") end
    elseif cmd == "assign" then
        local d = ns.FindDungeon(rest)
        if not DB.pending then Print("No unassigned run.")
        elseif not d then Print("Unknown dungeon: " .. rest)
        else ns.RecordRun(d, DB.pending.xp, DB.pending.level) DB.pending = nil end
    elseif cmd == "undo" then
        ns.UndoLast()
    elseif cmd == "set" then
        local key, value = rest:match("^(%S+)%s*(%S*)$")
        SetSetting(key and key:lower(), value and value:lower())
    elseif cmd == "buffs" then
        -- Diagnostic: every buff/debuff on you as the addon sees it, with tooltip text.
        if InCombatLockdown() then Print("Buffs can't be read in combat - try again after.") return end
        local ok, err = pcall(function()
            for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
                for i = 1, 40 do
                    local name, expires, spellId, count = ns.GetAura(i, filter)
                    if not name then break end
                    Print(("%s%s|r (spell %s%s%s)"):format(YELLOW, name, tostring(spellId),
                        (count and count > 1) and (", x" .. count) or "",
                        filter == "HARMFUL" and ", debuff" or ""))
                    for n, text in ipairs(ns.AuraTooltipLines(i, filter)) do
                        if n > 1 then Print("    " .. GREY .. text .. "|r") end
                    end
                end
            end
        end)
        if not ok then Print("Couldn't read buffs: " .. tostring(err)) end
        local state = ns.FoodStatus()
        Print(("Food status the addon uses: %s"):format(tostring(state)))
    elseif cmd == "perf" then
        -- How expensive is one panel redraw + warning check, and how much memory we use.
        local timer = debugprofilestop
        if timer then
            local t0 = timer()
            for _ = 1, 10 do ns.Refresh() ns.CheckWarnings() end
            Print(("Panel redraw + checks: %.2f ms each (redrawn at most once a second, usually every 5s)."):format((timer() - t0) / 10))
        end
        local update = (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage) or UpdateAddOnMemoryUsage
        local mem = (C_AddOns and C_AddOns.GetAddOnMemoryUsage) or GetAddOnMemoryUsage
        if update and mem then
            update()
            Print(("Memory: %.0f KB."):format(mem(ADDON) or 0))
        end
    elseif cmd == "faction" then
        local f = rest:lower()
        S.faction = (f == "horde" and "Horde") or (f == "alliance" and "Alliance") or nil
        ns.BuildRoute(S.faction or UnitFactionGroup("player"))
        if ns.ScanAchievements then pcall(ns.ScanAchievements) end
        Print(("Using the %s route%s."):format(ns.faction, S.faction and "" or " (auto from your character)"))
        ns.Refresh()
    elseif cmd == "lock" or cmd == "unlock" then
        S.locked = (cmd == "lock")
        Print("Window " .. cmd .. "ed.")
    elseif cmd == "reset" then
        if rest == "confirm" then
            wipe(DB.runs) wipe(DB.measured) wipe(DB.log)
            DB.curRun, DB.pending = nil, nil
            Print("Data wiped for this character.")
            ns.Refresh()
        else
            Print("This wipes all logged runs for this character. Type /dlc reset confirm to do it.")
        end
    else
        ShowHelp()
    end
end
