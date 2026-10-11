local ADDON, ns = ...

-- Options window, minimap button, and an entry in Blizzard's AddOns settings that opens it.
-- Everything here is our own frames: no Blizzard option templates (they differ between
-- clients) and no calls into Blizzard UI code beyond the tooltip.

local GREY, YELLOW = "|cff999999", "|cffffff00"
local options

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------
local function Label(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
    return fs
end

-- Checkbox bound to get()/set(value).
local function Check(parent, text, get, set, tip)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local label = Label(cb, text)
    label:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    cb:SetScript("OnShow", function(self) self:SetChecked(get() and true or false) end)
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        if ns.Refresh then ns.Refresh() end
    end)
    if tip then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, 1, 1, 1)
            GameTooltip:AddLine(tip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

-- Horizontal slider bound to get()/set(value), drawn with the classic slider textures.
local function Slider(parent, text, minV, maxV, step, fmt, get, set)
    local s = CreateFrame("Slider", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(180, 17)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    if s.SetBackdrop then
        s:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-SliderBar-Background", edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
                        tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 6, bottom = 6 } })
    end
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local label = Label(s, text, "GameFontNormalSmall")
    label:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2)
    local value = Label(s, "", "GameFontHighlightSmall")
    value:SetPoint("LEFT", s, "RIGHT", 8, 0)
    local quiet = false
    s:SetScript("OnShow", function(self)
        quiet = true
        self:SetValue(get())
        value:SetText(fmt:format(get()))
        quiet = false
    end)
    s:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / step + 0.5) * step
        value:SetText(fmt:format(v))
        if not quiet then set(v) end
    end)
    return s
end

local function Button(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

---------------------------------------------------------------------------
-- Options window
---------------------------------------------------------------------------
local function RouteText()
    local S = ns.S
    return S.faction and ("Route: " .. S.faction) or ("Route: auto (" .. (ns.faction or "?") .. ")")
end

local function BuildOptions()
    local S, G = ns.S, ns.GDB
    local f = CreateFrame("Frame", "DungeonLevelingCompanionOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(460, 494)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                        tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    end
    f:Hide()
    -- Escape closes it.
    if UISpecialFrames then table.insert(UISpecialFrames, "DungeonLevelingCompanionOptions") end

    local title = Label(f, "DLC - Dungeon Leveling Companion", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local function Header(text, x, y)
        local h = Label(f, text, "GameFontNormal")
        h:SetPoint("TOPLEFT", x, y)
        return h
    end
    local function Row(widget, x, y) widget:SetPoint("TOPLEFT", x, y) return widget end
    local function Setting(key) return function() return S[key] end, function(v) S[key] = v end end

    -- Left column: panel and sections.
    local L, R = 22, 240
    Header("Panel", L, -50)
    Row(Check(f, "Show panel", function() return S.shown end, ns.SetPanelShown), L, -68)
    Row(Check(f, "Lock position", Setting("locked")), L, -92)
    Row(Check(f, "Click-through", function() return S.clickThrough end, function(v) S.clickThrough = v ns.ApplyLook() end,
        "Mouse clicks go through the panel to the game world. While on, the panel can't be dragged or right-clicked - use the minimap button or /dlc config to turn it off."), L, -116)
    Row(Slider(f, "Scale", 0.6, 1.5, 0.05, "%.2f", function() return S.scale end,
        function(v) S.scale = v ns.ApplyLook() end), L + 4, -160)
    Row(Slider(f, "Background opacity", 0, 1, 0.05, "%.2f", function() return S.bgAlpha end,
        function(v) S.bgAlpha = v ns.ApplyLook() end), L + 4, -204)

    Header("Show on the panel", L, -236)
    local sections = {
        { "showPrep", "Prerequisite quests" },
        { "showQuests", "Dungeon quests" },
        { "showSecrets", "Secret bosses & loot reminders" },
        { "showGroup", "Group (party members with DLC)" },
        { "showSpelunker", "Spelunker progress" },
        { "showBuffs", "Food / tent / sleeping bag" },
    }
    for i, s in ipairs(sections) do
        local get, set = Setting(s[1])
        Row(Check(f, s[2], get, set), L, -254 - (i - 1) * 24)
    end

    -- Right column: alerts, group, minimap, route.
    Header("Alerts", R, -50)
    Row(Check(f, "Missing XP food", Setting("warnFood")), R, -68)
    Row(Check(f, "Tent ready", Setting("warnTent")), R, -92)
    Row(Check(f, "Sleeping bag buff gone", Setting("warnBag")), R, -116)
    Row(Check(f, "Count tent XP in estimates", Setting("useTent")), R, -140)
    Row(Slider(f, "Alerts start at level (all characters)", 1, 60, 1, "%d", function() return G.warnMinLevel end,
        function(v) G.warnMinLevel = v end), R + 4, -184)

    Header("Group", R, -212)
    Row(Check(f, "Share progress with my party", function() return G.sync end, function(v)
        G.sync = v
        if v and ns.SyncNow then ns.SyncNow() end
    end, "Party members running DLC see your level, dungeon, which route quests you still need and whether you have XP food - and you see theirs."), R, -230)

    Header("Other", R, -266)
    Row(Check(f, "Minimap button", function() return not G.minimapHide end, function(v)
        G.minimapHide = not v
        ns.UpdateMinimapButton()
    end), R, -284)
    local route
    route = Row(Button(f, RouteText(), 180, function()
        -- auto -> Alliance -> Horde -> auto
        S.faction = (S.faction == nil and "Alliance") or (S.faction == "Alliance" and "Horde") or nil
        ns.BuildRoute(S.faction or UnitFactionGroup("player"))
        if ns.ScanAchievements then pcall(ns.ScanAchievements) end
        route:SetText(RouteText())
        ns.Refresh()
    end), R + 4, -316)
    route:SetScript("OnShow", function(self) self:SetText(RouteText()) end)

    local hint = Label(f, GREY .. "Right-click the panel or minimap button to open this. /dlc help lists all commands.|r", "GameFontNormalSmall")
    hint:SetPoint("BOTTOM", 0, 18)
    hint:SetWidth(420)
    return f
end

function ns.ToggleOptions()
    options = options or BuildOptions()
    options:SetShown(not options:IsShown())
end

-- Entry under Blizzard's Options > AddOns with a button that opens our window.
function ns.RegisterOptions()
    local name = "DLC - Dungeon Leveling Companion"
    local canvas = CreateFrame("Frame")
    canvas.name = name
    local t = Label(canvas, name, "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16)
    local b = Button(canvas, "Open DLC options", 180, function() ns.ToggleOptions() end)
    b:SetPoint("TOPLEFT", 16, -50)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(canvas, name))
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(canvas)
    end
end

---------------------------------------------------------------------------
-- Minimap button (draggable around the minimap)
---------------------------------------------------------------------------
local mm

local function PlaceButton()
    local angle = math.rad(ns.GDB.minimapAngle or 220)
    local r = (Minimap:GetWidth() / 2) + 5
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function Tooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText("DLC - Dungeon Leveling Companion", 1, 1, 1)
    local d = ns.Recommend()
    if d then
        local lvl = UnitLevel("player")
        if lvl >= d.start and lvl < 60 then
            GameTooltip:AddLine(("Now: %s - ~%d runs left"):format(d.name, ns.RunsLeft(d)), 1, 0.82, 0)
        else
            GameTooltip:AddLine("Next: " .. d.name, 1, 0.82, 0)
        end
    end
    local members = ns.PartyMembers and ns.PartyMembers() or {}
    if #members > 0 then GameTooltip:AddLine(("%d party member%s with DLC"):format(#members, #members == 1 and "" or "s"), 0.6, 0.6, 0.6) end
    GameTooltip:AddLine(YELLOW .. "Left-click|r show/hide panel")
    GameTooltip:AddLine(YELLOW .. "Right-click|r options")
    GameTooltip:AddLine(YELLOW .. "Drag|r move button")
    GameTooltip:Show()
end

local function OnClick(button)
    if button == "RightButton" then ns.ToggleOptions() else ns.TogglePanel() end
end

function ns.CreateMinimapButton()
    -- Data broker launcher too, for Titan Panel / ElvUI / Bazooka users (if a broker is loaded).
    local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
    if ldb then
        pcall(ldb.NewDataObject, ldb, "DungeonLevelingCompanion", {
            type = "launcher", text = "DLC", icon = "Interface\\Icons\\INV_Misc_Map_01",
            OnClick = function(_, button) OnClick(button) end,
            OnTooltipShow = function(tt) tt:AddLine("DLC - Dungeon Leveling Companion") end,
        })
    end
    if not Minimap then return end
    mm = CreateFrame("Button", "DungeonLevelingCompanionMinimapButton", Minimap)
    mm:SetSize(31, 31)
    mm:SetFrameStrata("MEDIUM")
    mm:SetFrameLevel(8)
    mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mm:RegisterForDrag("LeftButton")
    mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local bg = mm:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    local icon = mm:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    local border = mm:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    mm:SetScript("OnClick", function(_, button) OnClick(button) end)
    mm:SetScript("OnEnter", Tooltip)
    mm:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mm:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            ns.GDB.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            PlaceButton()
        end)
    end)
    mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    ns.UpdateMinimapButton()
end

function ns.UpdateMinimapButton()
    if not mm then return end
    if ns.GDB.minimapHide then mm:Hide() else PlaceButton() mm:Show() end
end
