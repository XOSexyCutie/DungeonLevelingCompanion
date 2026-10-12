local _, ns = ...

-- Quest tracking for route dungeons and their prerequisite steps.
-- A quest's ID comes from Data.lua ("[id]") when known, otherwise it's learned from your
-- quest log by name. With an ID, C_QuestLog.IsQuestFlaggedCompleted says if it's finished.

local function Key(s)
    local k = (s or ""):lower():gsub("[^%w]", "")
    return k
end
ns.QuestKey = Key

local function Trim(s)
    local t = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return t
end

-- Turn Data.lua's "Quest Name (giver/where) [id]" strings into { name, from, key, id, class }.
-- Placeholders (TBD etc.) are skipped. Runs again whenever the route is rebuilt for a faction.
function ns.PrepareQuests()
    for _, d in ipairs(ns.ROUTE) do
        d.questInfo = {}
        d.questPlaceholder = false
        for _, entry in ipairs(d.questList or {}) do
            local id = tonumber(entry:match("%[(%d+)%]%s*$"))
            local text = Trim((entry:gsub("%s*%[%d+%]%s*$", "")))
            local name, from = text:match("^(.-)%s*%((.-)%)$")
            name = name or text
            local placeholder = name:find("TBD", 1, true) or name:find("^Classic") or name:find("^%d+ quests")
            if placeholder then
                d.questPlaceholder = true
            else
                local class = from and from:lower():find("paladin", 1, true) and "PALADIN" or nil
                table.insert(d.questInfo, { name = name, from = from, key = Key(name), id = id, class = class })
            end
        end
        for _, step in ipairs(d.prep or {}) do
            step.key = Key(step.q)
        end
    end
    -- Names shared by every part of a prereq chain (e.g. Hidden Enemies) -> number of parts.
    ns.multipart = {}
    for _, d in ipairs(ns.ROUTE) do
        for _, step in ipairs(d.prep or {}) do
            if step.parts and not step.id then ns.multipart[step.key] = step.parts end
        end
    end
end
ns.PrepareQuests()

---------------------------------------------------------------------------
-- Quest log
---------------------------------------------------------------------------
local logCache, logById = {}, {} -- [key] / [id] = { id, complete, have, need }

local function ReadLog()
    local log = {}
    if C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetNumQuestLogEntries then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.title then
                local complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID)
                table.insert(log, { key = Key(info.title), id = info.questID, complete = complete and true or false })
            end
        end
    else
        for i = 1, (GetNumQuestLogEntries() or 0) do
            local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
            if title and not isHeader then
                table.insert(log, { key = Key(title), id = questID, complete = (isComplete == 1 or isComplete == true) })
            end
        end
    end
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        for _, q in ipairs(log) do
            local objs = q.id and C_QuestLog.GetQuestObjectives(q.id)
            if objs and #objs > 0 then
                local have, need = 0, 0
                for _, o in ipairs(objs) do
                    have = have + math.min(o.numFulfilled or 0, o.numRequired or 0)
                    need = need + (o.numRequired or 0)
                end
                q.have, q.need = have, need
            end
        end
    end
    return log
end

local function ScanLog()
    local DB = ns.DB
    if not DB then return end
    local ok, log = pcall(ReadLog)
    if not ok or not log then return end
    DB.questIDs = DB.questIDs or {}
    DB.idKey = DB.idKey or {}
    local byKey, byId = {}, {}
    for _, q in ipairs(log) do
        byKey[q.key] = q
        if q.id and q.id > 0 then
            byId[q.id] = q
            DB.questIDs[q.key] = q.id
            DB.idKey[q.id] = q.key
        end
    end
    logCache, logById = byKey, byId
end

local function IsFlaggedCompleted(id)
    local fn = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
    if not id or not fn then return false end
    local ok, done = pcall(fn, id)
    return ok and done and true or false
end

-- Log entry for a quest: by ID when known (names repeat across chain parts), else by name.
local function InLog(key, id)
    if id then return logById[id] end
    return logCache[key]
end

-- True once the quest has been turned in.
function ns.QuestFinished(key, id)
    local DB = ns.DB
    DB.questDone = DB.questDone or {}
    if InLog(key, id) then return false end -- in your log right now
    if id then return IsFlaggedCompleted(id) or DB.questDone[key] == "manual" end
    if DB.questDone[key] == "manual" then return true end
    -- Same name as a multi-part prerequisite chain: finished only after all those parts
    -- plus this one have been turned in.
    local parts = ns.multipart and ns.multipart[key]
    if parts then return ns.TurnedInCount(key) > parts end
    if DB.questDone[key] then return true end
    local learned = DB.questIDs and DB.questIDs[key]
    if learned and IsFlaggedCompleted(learned) then
        DB.questDone[key] = true
        return true
    end
    return false
end

-- Unfinished quests for dungeon d with their status:
-- { name, from, inLog, complete, have, need }
function ns.DungeonQuests(d)
    local out = {}
    local _, class = UnitClass("player")
    for _, q in ipairs(d.questInfo or {}) do
        if (not q.class or q.class == class) and not ns.QuestFinished(q.key, q.id) then
            local l = InLog(q.key, q.id)
            -- Same name as a prereq chain: the log entry is a prereq part until those are done.
            local parts = not q.id and ns.multipart and ns.multipart[q.key]
            if parts and ns.TurnedInCount(q.key) < parts then l = nil end
            table.insert(out, {
                name = q.name, from = q.from, key = q.key,
                inLog = l ~= nil, complete = l and l.complete, have = l and l.have, need = l and l.need,
            })
        end
    end
    return out
end

-- How many of d's quests still give XP. Finished quests (tracked or /dlc qdone) don't count.
-- Dungeons whose quests aren't known yet (TBD) count their estimate until the first run.
function ns.QuestsLeft(d)
    if d.questPlaceholder and #(d.questInfo or {}) == 0 then
        return ((ns.DB.runs[d.key] or 0) == 0) and (d.quests or 0) or 0
    end
    return #ns.DungeonQuests(d)
end

---------------------------------------------------------------------------
-- Prerequisite steps
---------------------------------------------------------------------------
-- A follow-up quest being in your log or finished means the step is done.
local function Unlocked(step)
    for _, u in ipairs(step.unlocks or {}) do
        if type(u) == "number" then
            if logById[u] or IsFlaggedCompleted(u) then return true end
        else
            local k = Key(u)
            if logCache[k] or ns.QuestFinished(k) then return true end
        end
    end
    return false
end

-- How many different quests with this name you've turned in (for same-name chains).
function ns.TurnedInCount(key)
    local n = 0
    for _ in pairs((ns.DB.turnedIn or {})[key] or {}) do n = n + 1 end
    return n
end

-- Items in your bags or bank. Each item seen is remembered, so a step stays done after the
-- item is used up (e.g. the Tome of Dalaran once Lyn is summoned).
local function HaveItem(id)
    local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not fn then return false end
    local ok, n = pcall(fn, id, true)
    if ok and n and n > 0 then
        ns.DB.itemsSeen = ns.DB.itemsSeen or {}
        ns.DB.itemsSeen[id] = true
    end
    return ns.DB.itemsSeen and ns.DB.itemsSeen[id] or false
end

-- Status of one quest step: "done", "inlog" or "todo", plus its quest log entry.
local function StepStatus(step)
    if ns.DB.questDone and ns.DB.questDone[step.key] == "manual" then return "done" end
    if step.bag and ns.HasSleepingBag and ns.HasSleepingBag() then return "done" end
    if step.item then
        for _, id in ipairs(step.items or {}) do
            if HaveItem(id) then return "done" end
        end
        return HaveItem(step.item) and "done" or "todo"
    end
    if Unlocked(step) then return "done" end
    if step.id then
        -- Exact: this part's quest ID.
        if logById[step.id] then return "inlog", logById[step.id] end
        if IsFlaggedCompleted(step.id) then return "done" end
        return "todo"
    elseif step.part then
        -- Same-name chain without IDs: count distinct turn-ins of that name.
        local turned = ns.TurnedInCount(step.key)
        if step.part <= turned then return "done" end
        if step.part == turned + 1 and logCache[step.key] then return "inlog", logCache[step.key] end
        return "todo"
    end
    local l = logCache[step.key]
    if l then return step.pickup and "done" or "inlog", l end
    if ns.QuestFinished(step.key) then return "done" end
    return "todo"
end

-- Every prep step for dungeon d with its status: { step, num, status, log }.
function ns.PrepSteps(d)
    local out = {}
    for i, step in ipairs(d.prep or {}) do
        local status, log = StepStatus(step)
        table.insert(out, { step = step, num = i, status = status, log = log })
    end
    return out
end

-- Item steps for later dungeons that drop in dungeon d and aren't done yet: { step, for = dungeon }.
function ns.LootReminders(d)
    local out = {}
    for _, other in ipairs(ns.ROUTE) do
        for _, step in ipairs(other.prep or {}) do
            if step.lootIn == d.key and StepStatus(step) ~= "done" then
                table.insert(out, { step = step, ["for"] = other })
            end
        end
    end
    return out
end

-- Steps still to do (not done) for dungeon d.
function ns.PrepOpen(d)
    local out = {}
    for _, s in ipairs(ns.PrepSteps(d)) do
        if s.status ~= "done" then table.insert(out, s) end
    end
    return out
end

-- XP and minutes still to come from d's required (non-optional) prep steps.
function ns.PrepLeft(d)
    local xp, min = 0, 0
    for _, s in ipairs(ns.PrepOpen(d)) do
        if not s.step.optional then
            if not s.step.pickup then xp = xp + (s.step.xp or (s.step.lvl or 0) * 75) end
            min = min + (s.step.min or 0)
        end
    end
    return xp, min
end

-- /dlc qdone <quest> and /dlc qundo <quest>: mark a quest or prep step finished by hand.
function ns.MarkQuest(text, done)
    local DB = ns.DB
    DB.questDone = DB.questDone or {}
    local want = Key(text)
    if want == "" then ns.Print("Usage: /dlc qdone <part of quest name>") return end
    local function mark(key, name)
        DB.questDone[key] = done and "manual" or nil
        ns.Print(("%s marked %s."):format(name, done and "finished" or "not finished"))
        if ns.Refresh then ns.Refresh() end
    end
    for _, d in ipairs(ns.ROUTE) do
        for _, step in ipairs(d.prep or {}) do
            if step.key:find(want, 1, true) then return mark(step.key, step.q) end
        end
        for _, q in ipairs(d.questInfo or {}) do
            if q.key:find(want, 1, true) then return mark(q.key, q.name) end
        end
    end
    ns.Print("No route quest matches: " .. tostring(text))
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local pending
local function QueueScan()
    if pending then return end
    pending = true
    C_Timer.After(1, function() -- QUEST_LOG_UPDATE fires on every kill; batch it
        pending = nil
        ScanLog()
        if ns.RequestRefresh then ns.RequestRefresh() end
    end)
end

local f = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN" }) do
    pcall(f.RegisterEvent, f, ev)
end
f:SetScript("OnEvent", function(_, event, questID)
    if not ns.DB then return end
    if event == "QUEST_TURNED_IN" and questID then
        local DB = ns.DB
        DB.questDone = DB.questDone or {}
        local key = DB.idKey and DB.idKey[questID]
        if key then
            if not DB.questDone[key] then DB.questDone[key] = true end
            -- Remember each distinct quest ID turned in under this name (same-name chains).
            DB.turnedIn = DB.turnedIn or {}
            DB.turnedIn[key] = DB.turnedIn[key] or {}
            DB.turnedIn[key][questID] = true
        end
    end
    QueueScan()
end)
