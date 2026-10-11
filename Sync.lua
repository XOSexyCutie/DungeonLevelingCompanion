local _, ns = ...

-- Group sync: party members running DLC share where they are on the route, which route quests
-- they still need, open prereqs and whether they have XP food. Small addon messages, sent only
-- when something changed (plus a heartbeat), never in combat.
--
-- Message: "S;<proto>;<faction A/H>;<level>;<cur key>;<runs left>;<food 1/0>;<key>=<codes>,<prep>;..."
--   codes: one digit per quest in that dungeon's questList: 0 done/not needed, 1 needs to pick
--   up, 2 in log, 3 ready to turn in. Both sides use the same Data.lua list (same faction).
-- "R" asks everyone in the group to send theirs.

local PREFIX = "DLCSYNC"
local PROTO = 1
local HEARTBEAT = 60   -- resend unchanged status this often (seconds)
local MIN_GAP = 3      -- never send more often than this
local STALE = 300      -- forget members not heard from for this long

ns.party = {} -- [name] = { name, level, cur, runsLeft, food, faction, quests = { [key] = codes }, prep = { [key] = n }, seen }

local lastMsg, lastSent, sendQueued = nil, -100, false

local function Enabled() return ns.GDB and ns.GDB.sync ~= false and ns.DB end

local function Channel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
        and not IsInGroup(LE_PARTY_CATEGORY_HOME) then return "INSTANCE_CHAT" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

local function Send(msg)
    local channel = Channel()
    local send = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if not channel or not send then return false end
    return pcall(send, PREFIX, msg, channel)
end

-- One digit per quest of d: see the codes above.
local function QuestCodes(d)
    local open = {}
    for _, q in ipairs(ns.DungeonQuests(d)) do open[q.key] = q end
    local codes = {}
    for i, q in ipairs(d.questInfo or {}) do
        local o = open[q.key]
        codes[i] = not o and "0" or o.complete and "3" or o.inLog and "2" or "1"
    end
    return table.concat(codes)
end

local function OpenPrep(d)
    local n = 0
    for _, s in ipairs(ns.PrepOpen(d)) do
        if not s.step.optional then n = n + 1 end
    end
    return n
end

local function BuildStatus()
    local d = ns.Recommend()
    local parts = {
        "S", PROTO, (ns.faction == "Horde") and "H" or "A", UnitLevel("player"),
        d and d.key or "-", d and ns.RunsLeft(d) or 0, (ns.FoodStatus() == "xp") and 1 or 0,
    }
    if d then
        for _, e in ipairs({ d, ns.ROUTE[d.index + 1] }) do
            table.insert(parts, ("%s=%s,%d"):format(e.key, QuestCodes(e), OpenPrep(e)))
        end
    end
    return table.concat(parts, ";")
end

-- Send our status if it changed (or the heartbeat is due). Waits out combat and MIN_GAP.
local function MaybeSend(force)
    if not Enabled() or not Channel() then return end
    if InCombatLockdown() then sendQueued = true return end
    local now = GetTime()
    if now - lastSent < MIN_GAP then
        if not sendQueued then
            sendQueued = true
            C_Timer.After(MIN_GAP, function() sendQueued = false MaybeSend(force) end)
        end
        return
    end
    local ok, msg = pcall(BuildStatus)
    if not ok then return end
    if not force and msg == lastMsg and now - lastSent < HEARTBEAT then return end
    if Send(msg) then lastMsg, lastSent, sendQueued = msg, now, false end
end
function ns.SyncNow() MaybeSend(true) end

local function Parse(sender, msg)
    local f = {}
    for field in (msg .. ";"):gmatch("([^;]*);") do f[#f + 1] = field end
    if f[1] ~= "S" or tonumber(f[2]) ~= PROTO then return end
    local m = { name = sender, faction = f[3], level = tonumber(f[4]), cur = f[5] ~= "-" and f[5] or nil,
                runsLeft = tonumber(f[6]), food = f[7] == "1", quests = {}, prep = {}, seen = GetTime() }
    for i = 8, #f do
        local key, codes, prep = f[i]:match("^(%w+)=(%d*),(%d+)$")
        if key then m.quests[key], m.prep[key] = codes, tonumber(prep) end
    end
    ns.party[sender] = m
end

local function InGroupNow(name)
    return (UnitInParty and UnitInParty(name)) or (UnitInRaid and UnitInRaid(name)) or false
end

local function Prune()
    local now = GetTime()
    for name, m in pairs(ns.party) do
        if now - m.seen > STALE or not InGroupNow(name) then ns.party[name] = nil end
    end
end

-- Party members with DLC, sorted by name.
function ns.PartyMembers()
    local out = {}
    if not Enabled() then return out end
    for _, m in pairs(ns.party) do table.insert(out, m) end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- [quest key] = { names } of party members (same faction route) who still need d's quests.
function ns.PartyNeeds(d)
    local out = {}
    if not d then return out end
    local mine = (ns.faction == "Horde") and "H" or "A"
    for _, m in ipairs(ns.PartyMembers()) do
        local codes = m.faction == mine and m.quests[d.key]
        if codes then
            for i, q in ipairs(d.questInfo or {}) do
                local c = codes:sub(i, i)
                if c ~= "" and c ~= "0" then
                    out[q.key] = out[q.key] or {}
                    table.insert(out[q.key], m.name)
                end
            end
        end
    end
    return out
end

-- /dlc group
local STATUS = { ["1"] = "needs to pick up", ["2"] = "in log", ["3"] = "ready to turn in" }
function ns.PrintGroup()
    local Print = ns.Print
    if not Enabled() then Print("Group sync is off - /dlc sync on") return end
    local members = ns.PartyMembers()
    if #members == 0 then
        Print(Channel() and "Nobody else in your group is running DLC (or they haven't synced yet)." or "You're not in a group.")
        return
    end
    for _, m in ipairs(members) do
        local d = m.cur and ns.BY_KEY[m.cur]
        Print(("%s (%d) - %s%s%s"):format(m.name, m.level or 0, d and d.name or "?",
            m.runsLeft and (", ~%d runs left"):format(m.runsLeft) or "", m.food and "" or ", |cffff5555no XP food|r"))
        for key, codes in pairs(m.quests) do
            local e = ns.BY_KEY[key]
            if e then
                local open = {}
                for i, q in ipairs(e.questInfo or {}) do
                    local s = STATUS[codes:sub(i, i)]
                    if s then table.insert(open, ("%s (%s)"):format(q.name, s)) end
                end
                if #open > 0 then Print(("  %s: %s"):format(e.name, table.concat(open, ", "))) end
                if (m.prep[key] or 0) > 0 then Print(("  %s: %d prereq quest%s left"):format(e.name, m.prep[key], m.prep[key] == 1 and "" or "s")) end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local f = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "CHAT_MSG_ADDON", "PLAYER_REGEN_ENABLED" }) do
    pcall(f.RegisterEvent, f, ev)
end
local registered, groupSize = false, 0
f:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
    if not ns.DB then return end
    if not registered then
        local reg = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
        registered = reg and pcall(reg, PREFIX) or false
        -- Status changes (quests, level, food) show up within 5s; unchanged status only resends on the heartbeat.
        C_Timer.NewTicker(5, function() MaybeSend(false) end)
    end
    if event == "CHAT_MSG_ADDON" then
        if prefix ~= PREFIX or not Enabled() then return end
        local ok = pcall(function()
            local name = Ambiguate and Ambiguate(sender, "none") or sender
            if name == UnitName("player") then return end
            if msg == "R" then
                lastMsg = nil -- someone new: send ours even if unchanged
                C_Timer.After(1 + math.random() * 2, function() MaybeSend(true) end)
            else
                Parse(name, msg)
                if ns.RequestRefresh then ns.RequestRefresh() end
            end
        end)
        return ok
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        Prune()
        local size = (GetNumGroupMembers and GetNumGroupMembers()) or 0
        if size > groupSize and Enabled() and Channel() and not InCombatLockdown() then
            Send("R") -- someone joined (or we did): ask everyone for their status
            MaybeSend(true)
        end
        groupSize = size
        if ns.RequestRefresh then ns.RequestRefresh() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if sendQueued then sendQueued = false MaybeSend(false) end
    end
end)
