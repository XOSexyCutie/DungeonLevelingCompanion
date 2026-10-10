local ADDON, ns = ...

local ROUTE, BY_KEY, XP = ns.ROUTE, ns.BY_KEY, ns.XP
local MAX_LEVEL = 60

local DEFAULT_SETTINGS = {
    warnFood = true,        -- warn when the Well Fed XP buff is missing
    warnTent = true,        -- warn when Boosted Rest is gone and rested XP is below the tent amount
    useTent = true,         -- count tent rested XP in estimates
    tentFrac = 0.05,        -- tent tops rested XP up to this fraction of a level
    tentPerHour = 1,        -- Boosted Rest debuff = 1 tent per hour
    foodBonus = 0.05,       -- Well Fed: +5% XP from kills
    warnBag = true,         -- warn when you own the Cozy Sleeping Bag but Well-Rested is missing
    bagBonus = 0.03,        -- Well-Rested: +1% XP per stack, 3 stacks
    bagLevel = 20,          -- level the group expects to finish the sleeping bag chain (for estimates)
    bagThrottle = 120,      -- seconds between repeated sleeping bag warnings
    groupShare = 0.28,      -- classic 5-man XP share per person
    eliteMult = 2,
    mobPerLevel = 0.05,
    questPerLevel = 125,    -- at-level quest XP ~= level x 125
    questBonus = 0.25,      -- Forever dungeon-quest bonus (guess)
    calibOverride = nil,    -- force a calibration factor; nil = auto from measured runs
    foodThrottle = 90,      -- seconds between repeated food warnings
    tentThrottle = 120,     -- seconds between repeated tent warnings
    shown = true,
    locked = false,
}

local DB, S

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DLC|r: " .. msg)
end
ns.Print = Print

local function InitDB()
    DungeonLevelingCompanionDB = DungeonLevelingCompanionDB or {}
    DB = DungeonLevelingCompanionDB
    DB.runs = DB.runs or {}          -- [key] = completed runs
    DB.measured = DB.measured or {}  -- [key] = { trash XP per run, ... } (rested bonus excluded)
    DB.log = DB.log or {}            -- { {key=, xp=, level=, t=}, ... } newest last
    DB.settings = DB.settings or {}
    for k, v in pairs(DEFAULT_SETTINGS) do
        if DB.settings[k] == nil then DB.settings[k] = v end
    end
    S = DB.settings
    ns.DB, ns.S = DB, S
    S.warnMinLevel = nil -- moved to the account-wide settings below

    -- Account-wide settings (shared by all your characters).
    DungeonLevelingCompanionGlobalDB = DungeonLevelingCompanionGlobalDB or {}
    local G = DungeonLevelingCompanionGlobalDB
    if G.warnMinLevel == nil then G.warnMinLevel = 6 end -- no alerts below this level
    ns.GDB = G
end

---------------------------------------------------------------------------
-- Auras
---------------------------------------------------------------------------
local function GetAura(index, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local a = C_UnitAuras.GetAuraDataByIndex("player", index, filter)
        if a then return a.name, a.expirationTime, a.spellId, a.applications end
        return nil
    end
    local name, _, count, _, _, expires, _, _, _, spellId = UnitAura("player", index, filter)
    return name, expires, spellId, count
end

-- Reads an aura's tooltip text. Prefers the data-only C_TooltipInfo API: a real tooltip
-- frame runs shared Blizzard tooltip code from our (addon) context, which can taint it.
-- The hidden tooltip is only a fallback for clients without C_TooltipInfo.
local scanTip

-- Text of one C_TooltipInfo line. Depending on the client version the text is either on the
-- line itself (leftText/rightText) or still packed in line.args ({ field = "leftText", stringVal = ... }).
local function TooltipLineTexts(line, out)
    for _, key in ipairs({ "leftText", "rightText" }) do
        if type(line[key]) == "string" and line[key] ~= "" then table.insert(out, line[key]) end
    end
    for _, arg in ipairs(line.args or {}) do
        if (arg.field == "leftText" or arg.field == "rightText") and type(arg.stringVal) == "string" and arg.stringVal ~= "" then
            table.insert(out, arg.stringVal)
        end
    end
end

-- All tooltip text lines of a player aura (empty table if the tooltip isn't available yet).
local function AuraTooltipLines(index, filter)
    local out = {}
    if C_TooltipInfo and C_TooltipInfo.GetUnitAura then
        local data = C_TooltipInfo.GetUnitAura("player", index, filter)
        for _, line in ipairs(data and data.lines or {}) do TooltipLineTexts(line, out) end
        return out
    end
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "DungeonLevelingCompanionScanTip", nil, "GameTooltipTemplate")
    end
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetUnitAura("player", index, filter)
    for line = 1, scanTip:NumLines() do
        local fs = _G["DungeonLevelingCompanionScanTipTextLeft" .. line]
        local text = fs and fs:GetText()
        if text and text ~= "" then table.insert(out, text) end
    end
    return out
end
ns.AuraTooltipLines, ns.GetAura = AuraTooltipLines, GetAura

local function MentionsXP(text)
    local lower = text:lower()
    return lower:find("experience", 1, true) or lower:find("%f[%a]xp%f[%A]") ~= nil
end

-- Whether a Well Fed buff gives XP: true, false, or nil when its tooltip isn't loaded yet.
-- Only a real answer is remembered (per spell), so a tooltip that wasn't ready isn't
-- cached as "no XP".
local foodXPBySpell = {}
local function FoodGivesXP(index, spellId)
    if spellId and foodXPBySpell[spellId] ~= nil then return foodXPBySpell[spellId] end
    local lines = AuraTooltipLines(index, "HELPFUL")
    -- Line 1 is the buff's name; without a description line the tooltip isn't ready.
    if #lines < 2 then return nil end
    local xp = false
    for _, text in ipairs(lines) do
        if MentionsXP(text) then xp = true break end
    end
    if spellId then foodXPBySpell[spellId] = xp end
    return xp
end

-- Auras are "secret" to addons during combat on this client, so they're only read out of
-- combat (and inside pcall). They're re-read only when UNIT_AURA says your buffs changed
-- (plus a slow 30s safety refresh). In combat, the last values read are used.
local auraCache = { food = "none", tentCd = false, bagStacks = 0 }
local auraDirty, lastScan = true, -100

function ns.MarkAurasDirty() auraDirty = true end

local function ScanAuras()
    local c = { food = "none", tentCd = false, bagStacks = 0 }
    for i = 1, 40 do
        local name, expires, spellId, count = GetAura(i, "HELPFUL")
        if not name then break end
        local lower = name:lower()
        local exp = (expires and expires > 0) and expires or nil
        if lower:find("well-rested", 1, true) or lower:find("well rested", 1, true) then
            c.bagStacks = (count and count > 0) and count or 1
            c.bagExp = exp
        elseif lower:find("boosted rest", 1, true) then
            c.tentCd, c.tentExp = true, exp
        elseif lower:find("well fed", 1, true) and c.food ~= "xp" then
            -- Only Well Fed buffs get the (slower) tooltip check for the XP bonus.
            local xp = FoodGivesXP(i, spellId)
            if xp then
                c.food, c.foodExp = "xp", exp
            elseif xp == nil then
                c.food, c.foodExp, c.retry = "checking", exp, true -- tooltip not loaded yet
            elseif c.food ~= "checking" then
                c.food, c.foodExp = "nonxp", exp
            end
        end
    end
    if not c.tentCd then
        for i = 1, 40 do
            local name, expires = GetAura(i, "HARMFUL")
            if not name then break end
            if name:lower():find("boosted rest", 1, true) then
                c.tentCd, c.tentExp = true, (expires and expires > 0) and expires or nil
                break
            end
        end
    end
    return c
end

local function RefreshAuras()
    if InCombatLockdown() then return end
    if not auraDirty and GetTime() - lastScan < 30 then return end
    local ok, c = pcall(ScanAuras)
    if ok and c then auraCache = c end
    -- A food tooltip that wasn't loaded yet gets read again on the next refresh.
    auraDirty, lastScan = (ok and c and c.retry) or false, GetTime()
end

local function Left(exp)
    return exp and math.max(0, exp - GetTime()) or nil
end

-- Returns state ("xp", "nonxp", "none") and seconds left for the food buff.
local function FoodStatus()
    RefreshAuras()
    local c = auraCache
    if c.foodExp and c.foodExp <= GetTime() then return "none" end
    return c.food, Left(c.foodExp)
end

-- Returns true and seconds left while the Boosted Rest (tent cooldown) debuff is up.
local function TentCooldown()
    RefreshAuras()
    local c = auraCache
    if not c.tentCd or (c.tentExp and c.tentExp <= GetTime()) then return false end
    return true, Left(c.tentExp)
end

local BAG_NAME = "cozy sleeping bag"
-- Where the sleeping bag is: item ID, or false if not in your bags. Re-scanned only when
-- BAG_UPDATE_DELAYED says your bags changed.
local bagItemId, bagDirty = false, true

function ns.MarkBagsDirty() bagDirty = true end

local function ScanBags()
    local numSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    local itemLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
    for bag = 0, 4 do
        for slot = 1, (numSlots(bag) or 0) do
            local link = itemLink(bag, slot)
            if link and link:lower():find(BAG_NAME, 1, true) then
                return tonumber(link:match("item:(%d+)")) or 0
            end
        end
    end
    return false
end

-- Returns found, seconds of cooldown left.
local function FindSleepingBag()
    if bagDirty then
        local ok, id = pcall(ScanBags)
        if ok then bagItemId = id end
        bagDirty = false
    end
    if not bagItemId then return false, 0 end
    local itemCd = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    local start, duration = 0, 0
    if bagItemId > 0 and itemCd then start, duration = itemCd(bagItemId) end
    local left = (start and start > 0 and duration and duration > 0) and (start + duration - GetTime()) or 0
    return true, math.max(0, left)
end

-- Returns stacks of Well-Rested (0 if missing), seconds left, owns bag, bag cooldown left.
local function BagStatus()
    RefreshAuras()
    local c = auraCache
    local stacks = c.bagStacks
    if c.bagExp and c.bagExp <= GetTime() then stacks = 0 end
    local ok, owned, cd = pcall(FindSleepingBag)
    if not ok then owned, cd = false, 0 end
    return stacks, stacks > 0 and Left(c.bagExp) or nil, owned, cd
end

local function RestedFrac()
    local max = UnitXPMax("player")
    if not max or max == 0 then return 0 end
    return (GetXPExhaustion() or 0) / max
end

ns.FoodStatus, ns.TentCooldown, ns.RestedFrac, ns.BagStatus = FoodStatus, TentCooldown, RestedFrac, BagStatus

---------------------------------------------------------------------------
-- Estimates (same math as the Google Sheet)
---------------------------------------------------------------------------
local function Avg(t)
    if not t or #t == 0 then return nil end
    local s = 0
    for _, v in ipairs(t) do s = s + v end
    return s / #t
end

local function RawTrash(d)
    local L = (d.start + d.to) / 2
    return d.elites * (5 * L + 45) * (1 + S.mobPerLevel * d.off) * S.eliteMult * S.groupShare
end

-- Sleeping bag bonus for a leg: assumed active once the group reaches bagLevel.
local function BagBonus(d)
    return ((d.start + d.to) / 2 >= S.bagLevel) and S.bagBonus or 0
end

-- Kill XP multiplier for a leg: food + sleeping bag.
local function KillBonus(d)
    return 1 + S.foodBonus + BagBonus(d)
end

function ns.Calibration()
    if S.calibOverride then return S.calibOverride end
    local measured, formula = 0, 0
    for _, d in ipairs(ROUTE) do
        local avg = Avg(DB.measured[d.key])
        if avg then
            measured = measured + avg
            formula = formula + RawTrash(d) * KillBonus(d)
        end
    end
    if formula > 0 then return measured / formula end
    return 1
end

function ns.XPPerRun(d)
    return Avg(DB.measured[d.key]) or RawTrash(d) * ns.Calibration() * KillBonus(d), Avg(DB.measured[d.key]) ~= nil
end

function ns.TentPerRun(d)
    if not S.useTent then return 0 end
    local lvl = math.floor((d.start + d.to) / 2)
    local need = XP[lvl] or 0
    return math.min(ns.XPPerRun(d), S.tentFrac * need * S.tentPerHour * d.min / 60)
end

-- XP from d's dungeon quests you haven't finished yet (finished ones aren't counted).
function ns.QuestXP(d)
    local left = ns.QuestsLeft and ns.QuestsLeft(d) or d.quests
    return left * d.to * S.questPerLevel * (1 + S.questBonus) * (1 + BagBonus(d))
end

-- XP still needed to reach `toLevel` from the player's current level/XP.
local function XPRemaining(toLevel)
    local lvl = UnitLevel("player")
    if lvl >= toLevel then return 0 end
    local remaining = (XP[lvl] or 0) - UnitXP("player")
    for l = lvl + 1, toLevel - 1 do remaining = remaining + (XP[l] or 0) end
    return remaining
end

-- XP that prerequisite quests will give during d's leg: d's own unfinished prep (if you
-- haven't run it yet) plus the next dungeon's prep, which you do before swapping.
function ns.LegPrepXP(d)
    if not ns.PrepLeft then return 0 end
    local xp = 0
    if (DB.runs[d.key] or 0) == 0 then xp = xp + ns.PrepLeft(d) end
    local nextD = ROUTE[d.index + 1]
    if nextD and nextD.start < MAX_LEVEL then xp = xp + ns.PrepLeft(nextD) end
    return xp
end

-- Runs left on dungeon d to hit its "run until" level (at least 1 if never run),
-- counting the XP you'll get from prerequisite quests along the way.
function ns.RunsLeft(d)
    local done = DB.runs[d.key] or 0
    local remaining = XPRemaining(d.to) - ns.LegPrepXP(d)
    local perRun = ns.XPPerRun(d) + ns.TentPerRun(d)
    if perRun <= 0 then return done == 0 and 1 or 0 end
    -- Unfinished quests are turned in on the next run, whether it's your first or not.
    local questXP = ns.QuestXP(d)
    if done == 0 or questXP > 0 then
        local next = perRun + questXP
        return 1 + math.max(0, math.ceil((remaining - next) / perRun))
    end
    return math.max(0, math.ceil(remaining / perRun))
end

-- The dungeon you should be running now, plus Spelunker dungeons you've outleveled.
function ns.Recommend()
    local lvl = UnitLevel("player")
    local current, missed = nil, {}
    if lvl < MAX_LEVEL then
        for _, d in ipairs(ROUTE) do
            if lvl >= d.start and lvl < d.to then current = d break end
        end
        if not current and lvl < ROUTE[1].start then current = ROUTE[1] end
    else
        for _, d in ipairs(ROUTE) do
            if d.tier and not ns.IsDone(d) then current = d break end
        end
    end
    for _, d in ipairs(ROUTE) do
        if d.tier and d ~= current and not ns.IsDone(d) and lvl >= d.to and lvl < MAX_LEVEL then
            table.insert(missed, d)
        end
    end
    return current, missed
end

-- A dungeon counts as done if we logged a run or the Spelunker achievement says so.
function ns.IsDone(d)
    return (DB.runs[d.key] or 0) > 0 or (DB.achDone and DB.achDone[d.key]) or false
end

function ns.TierProgress(tier)
    local total, done = 0, 0
    for _, d in ipairs(ROUTE) do
        if d.tier == tier then
            total = total + 1
            if ns.IsDone(d) then done = done + 1 end
        end
    end
    return done, total
end

---------------------------------------------------------------------------
-- Dungeon lookup
---------------------------------------------------------------------------
function ns.FindDungeon(text)
    if not text or text == "" then return nil end
    text = text:lower()
    if BY_KEY[text] then return BY_KEY[text] end
    for _, d in ipairs(ROUTE) do
        if d.name:lower() == text then return d end
    end
    for _, d in ipairs(ROUTE) do
        if d.name:lower():find(text, 1, true) then return d end
    end
    return nil
end

-- Work out which route entry an instance run belongs to.
local function ResolveRun(run)
    local inst = (run.instance or ""):lower()
    local candidates = {}
    for _, d in ipairs(ROUTE) do
        for _, m in ipairs(d.match) do
            if inst:find(m, 1, true) then table.insert(candidates, d) break end
        end
    end
    if #candidates <= 1 then return candidates[1] end
    -- Several wings share the instance name: use the subzones we saw.
    local best, bestHits = nil, 0
    for _, d in ipairs(candidates) do
        local hits = 0
        for _, sz in ipairs(d.subzones or {}) do
            if run.subzones[sz] then hits = hits + 1 end
        end
        if hits > bestHits then best, bestHits = d, hits end
    end
    if best then return best end
    -- No subzone evidence: default to the wing without a subzone list (e.g. LBRS), else unknown.
    for _, d in ipairs(candidates) do
        if not d.subzones then return d end
    end
    return nil
end

---------------------------------------------------------------------------
-- Recording runs
---------------------------------------------------------------------------
function ns.RecordRun(d, xp, level)
    DB.runs[d.key] = (DB.runs[d.key] or 0) + 1
    if xp and xp > 0 and (level or 0) < MAX_LEVEL then
        DB.measured[d.key] = DB.measured[d.key] or {}
        table.insert(DB.measured[d.key], xp)
        while #DB.measured[d.key] > 10 do table.remove(DB.measured[d.key], 1) end
    end
    table.insert(DB.log, { key = d.key, xp = xp or 0, level = level, t = time() })
    while #DB.log > 200 do table.remove(DB.log, 1) end
    local msg = ("Logged %s run #%d"):format(d.name, DB.runs[d.key])
    if xp and xp > 0 then msg = msg .. (" (%d trash XP, rested bonus excluded)"):format(xp) end
    Print(msg .. ".")
    if d.tier and DB.runs[d.key] == 1 then
        local done, total = ns.TierProgress(d.tier)
        Print(("%s Spelunker: %d/%d dungeons done."):format(d.tier, done, total))
    end
    if ns.Refresh then ns.Refresh() end
end

function ns.UndoLast()
    local last = table.remove(DB.log)
    if not last then Print("Nothing to undo.") return end
    local d = BY_KEY[last.key]
    DB.runs[last.key] = math.max(0, (DB.runs[last.key] or 1) - 1)
    local m = DB.measured[last.key]
    if m and last.xp and last.xp > 0 then
        for i = #m, 1, -1 do
            if m[i] == last.xp then table.remove(m, i) break end
        end
    end
    Print(("Removed the last %s run."):format(d and d.name or last.key))
    if ns.Refresh then ns.Refresh() end
end

local function InPartyInstance()
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "party" then
        return GetInstanceInfo()
    end
    return nil
end

local function NoteSubzone()
    local run = DB.curRun
    if not run then return end
    for _, z in ipairs({ GetSubZoneText(), GetMinimapZoneText() }) do
        if z and z ~= "" then run.subzones[z:lower()] = true end
    end
end

local function FinishRun()
    local run = DB.curRun
    DB.curRun = nil
    if not run then return end
    local duration = (run.leftAt or time()) - run.start
    if run.xp <= 0 and duration < 600 then return end -- too short to count (zoned in and out)
    local d = ResolveRun(run)
    if d then
        ns.RecordRun(d, run.xp, run.level)
    else
        DB.pending = run
        Print(("Finished a run in %s but couldn't tell which wing. Type |cffffff00/dlc assign <dungeon>|r (e.g. /dlc assign smlib)."):format(run.instance))
    end
end

local function CheckInstance()
    local name = InPartyInstance()
    local run = DB.curRun
    if name then
        if run and run.instance ~= name then FinishRun() run = nil end
        if run then
            run.leftAt = nil -- back inside within the grace period: same run
        else
            DB.curRun = { instance = name, start = time(), xp = 0, level = UnitLevel("player"), subzones = {} }
        end
        NoteSubzone()
    elseif run and not run.leftAt then
        run.leftAt = time() -- don't end yet: corpse runs and repair trips continue the run
    end
end

-- A run ends after being outside for RUN_GRACE seconds, or when the instance is reset.
local RUN_GRACE = 300
local function CheckRunTimeout()
    local run = DB and DB.curRun
    if run and run.leftAt and time() - run.leftAt >= RUN_GRACE then FinishRun() end
end

local function OnSystemMessage(msg)
    local run = DB.curRun
    if run and run.leftAt and msg and msg:lower():find("has been reset", 1, true) then FinishRun() end
end

-- Run XP comes from the XP bar, not combat chat (which can be secret in combat):
-- XP gained, minus rested XP spent (the rested bonus), minus quest XP turned in.
local xpSnap

-- Total XP earned since level 1, so level-ups need no special casing.
local function TotalXP()
    local lvl = UnitLevel("player")
    local total = UnitXP("player")
    for l = 1, lvl - 1 do total = total + (XP[l] or 0) end
    return total
end

local function SnapshotXP()
    xpSnap = { total = TotalXP(), rested = GetXPExhaustion() or 0 }
end

local function OnXPUpdate()
    local prev = xpSnap
    local cur = { total = TotalXP(), rested = GetXPExhaustion() or 0 }
    -- Level and XP can update a moment apart on level-up; wait for them to agree.
    if prev and cur.total < prev.total then return end
    xpSnap = cur
    local run = DB.curRun
    if not prev or not run or run.leftAt then return end
    local gained = cur.total - prev.total
    if gained <= 0 then return end
    local restedSpent = math.max(0, prev.rested - cur.rested)
    run.xp = run.xp + math.max(0, gained - restedSpent)
end

local function OnQuestTurnedIn(xpReward)
    local run = DB.curRun
    if run and not run.leftAt and tonumber(xpReward) then
        run.questXP = (run.questXP or 0) + tonumber(xpReward)
        run.xp = math.max(0, run.xp - tonumber(xpReward))
    end
end

---------------------------------------------------------------------------
-- Warnings
---------------------------------------------------------------------------
local lastFoodWarn, lastTentWarn, lastBagWarn, foodExpireWarned, hadBoostedRest, wasInDungeon = 0, 0, 0, nil, nil, false
local tentPending = false

-- Our own big on-screen alert text. We deliberately don't use Blizzard's RaidWarningFrame:
-- calling Blizzard UI code from an addon taints it, and that taint spread into Blizzard's
-- health code ("secret number" errors).
local alertFrame, alertText
local function ShowAlert(msg)
    if not alertFrame then
        alertFrame = CreateFrame("Frame", "DungeonLevelingCompanionAlert", UIParent)
        alertFrame:SetSize(800, 40)
        alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -180)
        alertFrame:SetFrameStrata("HIGH")
        alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        alertText:SetAllPoints()
        alertText:SetTextColor(1, 0.35, 0.35)
        alertFrame:SetScript("OnUpdate", function(self)
            local left = (self.hideAt or 0) - GetTime()
            if left <= 0 then self:Hide() return end
            self:SetAlpha(math.min(1, left)) -- fade out over the last second
        end)
    end
    alertText:SetText(msg)
    alertFrame.hideAt = GetTime() + 5
    alertFrame:SetAlpha(1)
    alertFrame:Show()
end

local function Warn(msg)
    ShowAlert(msg)
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING) end
    Print("|cffff5555" .. msg .. "|r")
    if ns.alertLog then table.insert(ns.alertLog, msg) end -- for the test suite
end

local function CheckWarnings()
    if not S then return end
    local lvl = UnitLevel("player")
    if lvl >= MAX_LEVEL or lvl < (ns.GDB and ns.GDB.warnMinLevel or 6) then return end
    if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then return end
    -- Not during cinematics or with the UI hidden.
    if (InCinematic and InCinematic()) or (IsInCinematicScene and IsInCinematicScene())
        or (UIParent and not UIParent:IsVisible()) then return end
    local now = GetTime()
    local inCombat = InCombatLockdown()

    if S.warnFood then
        local state, left = FoodStatus()
        if state ~= "xp" and state ~= "checking" then
            foodExpireWarned = nil
            if not inCombat and now - lastFoodWarn >= S.foodThrottle then
                lastFoodWarn = now
                Warn(state == "nonxp" and "Your food buff gives no bonus XP - eat XP food!" or "Missing Well Fed XP buff - eat!")
            end
        elseif left and left <= 60 and not foodExpireWarned then
            foodExpireWarned = true
            Warn("Well Fed XP buff runs out in under a minute!")
        end
    end

    -- Tents can only go up outdoors, outside dungeons and rest areas. Leaving a dungeon or the
    -- cooldown ending while you can't camp queues an alert for the moment you can.
    local inDungeon = InPartyInstance() ~= nil
    if wasInDungeon and not inDungeon then tentPending = true end
    wasInDungeon = inDungeon

    if S.warnTent and S.useTent then
        local onCd = TentCooldown()
        if hadBoostedRest and not onCd then tentPending = true end -- debuff just dropped
        hadBoostedRest = onCd
        -- No camping in dungeons, indoors, or rest areas (cities and inns).
        local canCamp = not inDungeon and not IsIndoors() and not IsResting() and not inCombat
        if onCd or RestedFrac() >= S.tentFrac * 0.98 then
            tentPending = false
        elseif canCamp and (tentPending or now - lastTentWarn >= S.tentThrottle) then
            tentPending = false
            lastTentWarn = now
            Warn("Tent cooldown is off - put up the LW tent for rested XP!")
        end
    end

    if S.warnBag then
        local stacks, _, owned, cd = BagStatus()
        if owned and stacks == 0 and cd <= 0 and not inCombat and now - lastBagWarn >= S.bagThrottle then
            lastBagWarn = now
            Warn("Well-Rested is gone - lie on your sleeping bag for 3 minutes!")
        end
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- Panel redraws are batched: events just mark it dirty, the 1s ticker redraws once.
local refreshDirty, lastRefresh = true, -100
function ns.RequestRefresh() refreshDirty = true end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("ZONE_CHANGED")
ev:RegisterEvent("ZONE_CHANGED_INDOORS")
ev:RegisterEvent("PLAYER_XP_UPDATE")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:RegisterEvent("UPDATE_EXHAUSTION")
ev:RegisterEvent("QUEST_TURNED_IN")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("CHAT_MSG_SYSTEM")
ev:RegisterEvent("UNIT_AURA")
ev:RegisterEvent("BAG_UPDATE_DELAYED")

ev:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            InitDB()
            -- Horde or Alliance route (S.faction overrides, set with /dlc faction).
            ns.BuildRoute(S.faction or UnitFactionGroup("player"))
            SnapshotXP()
            if ns.CreateUI then ns.CreateUI() end
            C_Timer.NewTicker(5, function() CheckRunTimeout() CheckWarnings() end)
            -- Panel redraw: right after something changed, else every 5s for the timers.
            C_Timer.NewTicker(1, function()
                if ns.Refresh and (refreshDirty or GetTime() - lastRefresh >= 5) then
                    refreshDirty, lastRefresh = false, GetTime()
                    ns.Refresh()
                end
            end)
        end
        return
    end
    if not DB then return end
    if event == "UNIT_AURA" then
        if arg1 == "player" then ns.MarkAurasDirty() ns.RequestRefresh() end
        return
    elseif event == "BAG_UPDATE_DELAYED" then
        ns.MarkBagsDirty()
        ns.RequestRefresh()
        return
    elseif event == "CHAT_MSG_SYSTEM" then
        -- Only matters right after leaving a dungeon (instance reset ends the run).
        if DB.curRun and DB.curRun.leftAt then pcall(OnSystemMessage, arg1) end -- text can be secret
        return
    end
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        CheckInstance()
        C_Timer.After(2, CheckWarnings) -- just zoned (e.g. out of a dungeon): check right away
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        NoteSubzone()
        CheckWarnings() -- may have just stepped outdoors
    elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        OnXPUpdate()
    elseif event == "UPDATE_EXHAUSTION" then
        -- Rested went UP on its own (tent, inn): re-baseline. Drops are the rested bonus
        -- being spent on a kill, which OnXPUpdate needs to see.
        if xpSnap and TotalXP() == xpSnap.total and (GetXPExhaustion() or 0) > xpSnap.rested then SnapshotXP() end
    elseif event == "QUEST_TURNED_IN" then
        OnQuestTurnedIn(arg2)
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.MarkAurasDirty() -- buffs may have changed during the fight
        CheckWarnings()
    end
    ns.RequestRefresh()
end)

ns.ResolveRun, ns.OnXPUpdate, ns.CheckInstance, ns.CheckWarnings, ns.InitDB = ResolveRun, OnXPUpdate, CheckInstance, CheckWarnings, InitDB
