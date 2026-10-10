local _, ns = ...

-- Spelunker achievement criteria text (lowercase) -> route key.
local CRITERIA = {
    ["ragefire chasm or hall of thanes"] = { "hot", "rfc" }, -- whichever is on your route
    ["hall of thanes"] = "hot",
    ["ragefire chasm"] = "rfc",
    ["ruins of lordaeron"] = "rol",
    ["wailing caverns"] = "wc",
    ["the deadmines"] = "dm",
    ["shadowfang keep"] = "sfk",
    ["excavation site: wetlands"] = "exc",
    ["city of dalaran"] = "dal",
    ["blackfathom deeps"] = "bfd",
    ["gnomeregan"] = "gnomer",
    ["the drowned city"] = "drowned",
    ["scarlet monastery: graveyard"] = "smgy",
    ["scarlet monastery: library"] = "smlib",
    ["scarlet monastery: armory"] = "smarm",
    ["scarlet monastery: cathedral"] = "smcath",
    ["razorfen kraul"] = "rfk",
    ["krol'dok stronghold"] = "krol",
    ["razorfen downs"] = "rfd",
    ["uldaman"] = "ulda",
    ["zul'farrak"] = "zf",
    ["maraudon"] = "mara",
    ["alcaz prison"] = "alcaz",
    ["the temple of atal'hakkar"] = "st",
    ["blackrock depths"] = "brd",
    ["blackmaw hold"] = "blackmaw",
    ["lower blackrock spire"] = "lbrs",
    ["upper blackrock spire"] = "ubrs",
    ["scholomance"] = "scholo",
    ["stratholme: live"] = "stratlive",
    ["stratholme: dead"] = "stratud",
    ["stratholme: undead"] = "stratud",
    ["dire maul: east"] = "dme",
    ["dire maul: north"] = "dmn",
    ["dire maul: west"] = "dmw",
    ["the shaper's terrace"] = "shaper",
    ["shaper's terrace"] = "shaper",
}

local function Normalize(s)
    return (s or ""):lower():gsub("\226\128\153", "'"):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function Squash(s)
    return Normalize(s):gsub("^the ", ""):gsub("[^%w]", "")
end

-- Map a criteria string to a route key: exact table first, then a loose name match.
local function CriteriaKey(text)
    local n = Normalize(text)
    local mapped = CRITERIA[n]
    if type(mapped) == "table" then
        for _, key in ipairs(mapped) do
            if ns.BY_KEY[key] then return key end
        end
        return mapped[1]
    elseif mapped then
        return mapped
    end
    local sq = Squash(text)
    for _, d in ipairs(ns.ROUTE) do
        local dn = Squash(d.name)
        if sq == dn or sq:find(dn, 1, true) or dn:find(sq, 1, true) then return d.key end
    end
    return nil
end
ns.CriteriaKey = CriteriaKey

local function FindSpelunkerIDs()
    local ids = {}
    if not (GetCategoryList and GetCategoryNumAchievements and GetAchievementInfo) then return ids end
    for _, cat in ipairs(GetCategoryList() or {}) do
        local num = GetCategoryNumAchievements(cat, true) or 0
        for i = 1, num do
            local id, name = GetAchievementInfo(cat, i)
            if id and name then
                local lower = name:lower()
                if lower:find("spelunker", 1, true) then
                    for _, tier in ipairs(ns.TIERS) do
                        if lower:find(tier:lower(), 1, true) then ids[tier] = id end
                    end
                end
            end
        end
    end
    return ids
end

-- Reads the three Spelunker achievements. Stores DB.achDone[key] = true for finished
-- criteria and DB.achTiers[tier] = { id, completed, done, total }. Returns true if found.
function ns.ScanAchievements()
    local DB = ns.DB
    if not DB or not GetAchievementCriteriaInfo then return false end
    DB.achIDs = DB.achIDs or {}
    if not (DB.achIDs.Novice and DB.achIDs.Experienced and DB.achIDs.Master) then
        local found = FindSpelunkerIDs()
        for tier, id in pairs(found) do DB.achIDs[tier] = id end
    end
    local any = false
    local achDone, achTiers, unmapped = {}, {}, {}
    for _, tier in ipairs(ns.TIERS) do
        local id = DB.achIDs[tier]
        if id then
            local _, _, _, completed = GetAchievementInfo(id)
            local num = GetAchievementNumCriteria(id) or 0
            local done = 0
            for i = 1, num do
                local text, _, critDone = GetAchievementCriteriaInfo(id, i)
                if critDone then done = done + 1 end
                local key = CriteriaKey(text)
                if key then
                    if critDone or completed then achDone[key] = true end
                else
                    table.insert(unmapped, ("%s: %s"):format(tier, tostring(text)))
                end
            end
            achTiers[tier] = { id = id, completed = completed and true or false, done = completed and num or done, total = num }
            any = true
        end
    end
    if any then
        DB.achDone, DB.achTiers, ns.achUnmapped = achDone, achTiers, unmapped
    end
    return any
end

-- /dlc ach: print what the addon read from the achievements.
function ns.PrintAchievements()
    local Print, DB = ns.Print, ns.DB
    if not ns.ScanAchievements() then
        Print("Couldn't find the Spelunker achievements (achievement API missing or not loaded yet).")
        return
    end
    for _, tier in ipairs(ns.TIERS) do
        local t = DB.achTiers[tier]
        if t then
            Print(("%s Spelunker (id %d): %d/%d%s"):format(tier, t.id, t.done, t.total, t.completed and " - COMPLETE" or ""))
        else
            Print(tier .. " Spelunker: not found")
        end
    end
    for _, u in ipairs(ns.achUnmapped or {}) do
        Print("|cffff5555Unrecognised criteria|r " .. u)
    end
end

-- Rescan on login and when achievement progress changes (throttled).
local pending
local function QueueScan()
    if pending then return end
    pending = true
    C_Timer.After(3, function()
        pending = nil
        if InCombatLockdown() then QueueScan() return end -- read after combat
        local ok, found = pcall(ns.ScanAchievements)
        if ok and found and ns.RequestRefresh then ns.RequestRefresh() end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
for _, ev in ipairs({ "ACHIEVEMENT_EARNED", "CRITERIA_EARNED" }) do -- not CRITERIA_UPDATE: fires on every kill
    pcall(f.RegisterEvent, f, ev)
end
f:SetScript("OnEvent", function() if ns.DB then QueueScan() end end)
