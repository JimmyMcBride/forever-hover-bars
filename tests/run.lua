-- Run from the repository root: lua5.1 tests/run.lua
local passed, failed = 0, 0
local function equal(actual, expected, message)
    assert(actual == expected, (message or "Values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function near(actual, expected)
    assert(math.abs(actual - expected) < 0.00001, "Expected " .. expected .. ", got " .. actual)
end
local function test(name, run)
    local ok, err = pcall(run)
    if ok then
        passed = passed + 1
        print("PASS " .. name)
    else
        failed = failed + 1
        print("FAIL " .. name .. ": " .. err)
    end
end

local function world(options)
    options = options or {}
    local w = { now = 0, frames = {}, fonts = {}, loaded = {}, callbacks = {}, messages = {}, mouseX = -1, mouseY = -1 }
    local env = setmetatable({}, { __index = _G })
    env._G = env
    w.env = env
    local Frame = {}
    Frame.__index = Frame
    local function noProtected(self)
        assert(not self.protected, "Attempt to mutate protected bar structure or scripts")
    end
    function Frame:SetScript(event, fn) noProtected(self); self.scripts[event] = fn end
    function Frame:RegisterEvent(event) self.events[event] = true end
    function Frame:SetAlpha(value) self.alpha = value; self.alphaWrites = self.alphaWrites + 1 end
    function Frame:GetAlpha() return self.alpha end
    function Frame:IsShown() return self.shown end
    function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function Frame:IsMouseOver()
        local r = self.rect
        return r and w.mouseX >= r[1] and w.mouseX <= r[3] and w.mouseY >= r[2] and w.mouseY <= r[4]
    end
    function Frame:Show() noProtected(self); self.shown = true end
    function Frame:Hide() noProtected(self); self.shown = false end
    function Frame:SetShown(value) noProtected(self); self.shown = value end
    function Frame:SetParent(value) noProtected(self); self.parent = value end
    function Frame:SetAttribute() noProtected(self) end
    function Frame:SetPoint() noProtected(self) end
    function Frame:SetSize(width, height) self.width, self.height = width, height end
    function Frame:SetWidth(width) self.width = width end
    function Frame:SetScrollChild(child) self.child = child end
    function Frame:SetChecked(value) self.checked = value end
    function Frame:GetChecked() return self.checked end
    function Frame:SetText(value) self.text = value end
    function Frame:SetJustifyH() end
    function Frame:SetTextColor() end
    function Frame:CreateFontString()
        local font = setmetatable({}, Frame)
        w.fonts[#w.fonts + 1] = font
        return font
    end
    function Frame:GetID() return 41 end
    function env.CreateFrame(kind, name, parent, template)
        local frame = setmetatable({ scripts = {}, events = {}, shown = true, alpha = 1,
            alphaWrites = 0, parent = parent, kind = kind, template = template }, Frame)
        w.frames[#w.frames + 1] = frame
        return frame
    end
    function env.GetTime() return w.now end
    function env.InCombatLockdown() return w.combat == true end
    function env.GetCursorInfo() return w.cursor end
    env.C_AddOns = { IsAddOnLoaded = function(name) return w.loaded[name] == true end }
    env.EditModeManagerFrame = { IsEditModeActive = function() return w.editing end }
    function env.KeybindFrames_InQuickKeybindMode() return w.binding end
    env.SpellFlyout = { IsShown = function() return w.flyoutButton ~= nil end,
        IsAttachedToButton = function(_, button) return button == w.flyoutButton end }
    env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) w.messages[#w.messages + 1] = text end }
    env.EventRegistry = { RegisterCallback = function(_, event, fn) w.callbacks[event] = fn end }
    env.GameTooltip = { SetOwner = function() end, SetText = function() end,
        AddLine = function() end, Show = function() end, Hide = function() end }
    env.Settings = {
        RegisterCanvasLayoutCategory = function(panel, name)
            w.panel, w.categoryName = panel, name
            return setmetatable({}, Frame)
        end,
        RegisterAddOnCategory = function(category) w.category = category end,
        OpenToCategory = function(id) w.openedCategory = id end,
    }
    env.SlashCmdList = {}
    env.ForeverHoverBarsDB = options.global
    env.ForeverHoverBarsCharacterDB = options.character
    w.ns = {}
    local function load(name)
        local chunk = assert(loadfile(name))
        setfenv(chunk, env)("ForeverHoverBars", w.ns)
    end
    load("Config.lua")
    for i, bar in ipairs(w.ns.bars) do
        if bar.frame ~= options.missing then
            local frame = env.CreateFrame("Frame")
            frame.protected = true
            frame.rect = { (i - 1) * 600, 0, (i - 1) * 600 + 454, 35 }
            frame.actionButtons = { {}, {} }
            env[bar.frame] = frame
        end
    end
    load("Visibility.lua")
    load("Options.lua")
    load("Core.lua")
    function w:emit(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    function w:advance(duration)
        local finish = self.now + duration
        while self.now < finish - 0.0000001 do
            local dt = math.min(0.01, finish - self.now)
            self.now = self.now + dt
            local frame = self.ns.Controller.frame
            if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, dt) end
        end
    end
    function w:hover(key)
        for _, bar in ipairs(self.ns.bars) do
            if bar.key == key then
                local r = self.env[bar.frame].rect
                self.mouseX, self.mouseY = r[1] + 45, r[2] + 15
                return
            end
        end
        self.mouseX, self.mouseY = -1, -1
    end
    w:emit("ADDON_LOADED", "ForeverHoverBars")
    return w
end

test("defaults leave all ten bars untouched and no monitor running", function()
    local w = world()
    equal(#w.ns.bars, 10)
    equal(w.env.ForeverHoverBarsCharacterDB.useCharacter, false)
    equal(w.ns.Config.GetProfile().linkedHover, false)
    equal(w.ns.Config.GetProfile().showInCombat, false)
    equal(w.ns.Controller.frame.scripts.OnUpdate, nil)
    for _, bar in ipairs(w.ns.bars) do
        equal(w.ns.Config.GetProfile().bars[bar.key], false)
        equal(w.env[bar.frame].alphaWrites, 0)
    end
end)

test("missing and invalid saved values normalize safely", function()
    local w = world({ global = { bars = { bar1 = "true", bar2 = true }, linkedHover = 1 }, character = "bad" })
    equal(w.ns.Config.GetProfile().bars.bar1, false)
    equal(w.ns.Config.GetProfile().bars.bar2, true)
    equal(w.ns.Config.GetProfile().linkedHover, false)
    equal(w.env.ForeverHoverBarsCharacterDB.useCharacter, false)
end)

test("independent hover reveals only hovered selected bar", function()
    local w = world()
    w.ns.Config.SetBar("bar2", true)
    w.ns.Config.SetBar("bar3", true)
    w:advance(0.2)
    near(w.env.MultiBarBottomLeft.alpha, 0)
    near(w.env.MultiBarBottomRight.alpha, 0)
    w:hover("bar2")
    w:advance(0.2)
    near(w.env.MultiBarBottomLeft.alpha, 1)
    near(w.env.MultiBarBottomRight.alpha, 0)
    near(w.env.MainActionBar.alpha, 1)
end)

test("linked hover reveals selected bars, not other bars", function()
    local w = world()
    w.ns.Config.SetBar("bar2", true)
    w.ns.Config.SetBar("bar3", true)
    w.ns.Config.SetOption("linkedHover", true)
    w:advance(0.2)
    w:hover("bar2")
    w:advance(0.2)
    near(w.env.MultiBarBottomLeft.alpha, 1)
    near(w.env.MultiBarBottomRight.alpha, 1)
    equal(w.env.MainActionBar.alphaWrites, 0)
end)

test("hovering unselected bar does not trigger linked group", function()
    local w = world()
    w.ns.Config.SetBar("bar2", true)
    w.ns.Config.SetOption("linkedHover", true)
    w:hover("bar1")
    w:advance(0.5)
    near(w.env.MultiBarBottomLeft.alpha, 0)
end)

test("crossing gap between linked bars cancels hiding", function()
    local w = world()
    w.ns.Config.SetBar("bar2", true)
    w.ns.Config.SetBar("bar3", true)
    w.ns.Config.SetOption("linkedHover", true)
    w:hover("bar2")
    w:advance(0.2)
    w:hover(nil)
    w:advance(0.2)
    near(w.env.MultiBarBottomLeft.alpha, 1)
    w:hover("bar3")
    w:advance(0.4)
    near(w.env.MultiBarBottomLeft.alpha, 1)
    near(w.env.MultiBarBottomRight.alpha, 1)
    w:hover(nil)
    w:advance(0.55)
    near(w.env.MultiBarBottomLeft.alpha, 0)
    near(w.env.MultiBarBottomRight.alpha, 0)
end)

test("fade duration, delay, and interrupted fade are continuous", function()
    local V = world().ns.Visibility
    local s = V.New(0)
    V.Update(s, true, 0)
    near(V.Advance(s, 0.05), 0.5)
    near(V.Advance(s, 0.1), 1)
    V.Update(s, false, 0.29)
    equal(s.target, 1)
    V.Update(s, false, 0.31)
    equal(s.target, 0)
    near(V.Advance(s, 0.385), 0.5)
    V.Update(s, true, 0.385)
    near(s.alpha, 0.5)
    near(V.Advance(s, 0.435), 0.75)
    near(V.Advance(s, 0.5), 1)
end)

test("hover stays active during combat by default", function()
    local w = world()
    w.ns.Config.SetBar("bar1", true)
    w.combat = true
    w:emit("PLAYER_REGEN_DISABLED")
    w:advance(0.3)
    near(w.env.MainActionBar.alpha, 0)
    w:hover("bar1")
    w:advance(0.2)
    near(w.env.MainActionBar.alpha, 1)
end)

test("combat option reveals selected bars then restores hover rules", function()
    local w = world()
    w.ns.Config.SetBar("bar1", true)
    w.ns.Config.SetOption("showInCombat", true)
    w:advance(0.2)
    near(w.env.MainActionBar.alpha, 0)
    w.combat = true
    w:emit("PLAYER_REGEN_DISABLED")
    w:advance(0.2)
    near(w.env.MainActionBar.alpha, 1)
    w.combat = false
    w:emit("PLAYER_REGEN_ENABLED")
    w:advance(0.55)
    near(w.env.MainActionBar.alpha, 0)
end)

for _, mode in ipairs({ "editing", "binding", "cursor" }) do
    test(mode .. " temporarily reveals selected bars", function()
        local w = world()
        w.ns.Config.SetBar("bar1", true)
        w:advance(0.2)
        w[mode] = mode == "cursor" and "spell" or true
        w:advance(0.2)
        near(w.env.MainActionBar.alpha, 1)
        w[mode] = nil
        w:advance(0.55)
        near(w.env.MainActionBar.alpha, 0)
    end)
end

test("flyout keeps owning bar and linked group visible until closed", function()
    local w = world()
    w.ns.Config.SetBar("bar2", true)
    w.ns.Config.SetBar("bar3", true)
    w.ns.Config.SetOption("linkedHover", true)
    w.flyoutButton = w.env.MultiBarBottomLeft.actionButtons[1]
    w:advance(0.3)
    near(w.env.MultiBarBottomLeft.alpha, 1)
    near(w.env.MultiBarBottomRight.alpha, 1)
    w.flyoutButton = nil
    w:advance(0.55)
    near(w.env.MultiBarBottomLeft.alpha, 0)
end)

test("Blizzard-hidden bars cannot trigger hover or become shown", function()
    local w = world()
    w.ns.Config.SetBar("pet", true)
    w.ns.Config.SetBar("bar2", true)
    w.ns.Config.SetOption("linkedHover", true)
    w.env.PetActionBar.shown = false
    w:hover("pet")
    w:advance(0.5)
    equal(w.env.PetActionBar.shown, false)
    near(w.env.MultiBarBottomLeft.alpha, 0)
    w.env.PetActionBar.shown = true
    w:advance(0.2)
    near(w.env.PetActionBar.alpha, 1)
    near(w.env.MultiBarBottomLeft.alpha, 1)
end)

test("hover checks current bar rectangle after layout changes", function()
    local w = world()
    w.ns.Config.SetBar("bar1", true)
    w.env.MainActionBar.rect = { 100, 100, 135, 554 }
    w.mouseX, w.mouseY = 120, 145 -- Between buttons; no button focus required.
    w:advance(0.2)
    near(w.env.MainActionBar.alpha, 1)
    w.env.MainActionBar.rect = { 200, 100, 235, 554 }
    w:advance(0.55)
    near(w.env.MainActionBar.alpha, 0)
end)

test("first character override snapshots global without sharing tables", function()
    local w = world()
    w.ns.Config.SetBar("bar2", true)
    w.ns.Config.SetOption("linkedHover", true)
    w.ns.Config.SetCharacter(true)
    equal(w.ns.Config.GetProfile().bars.bar2, true)
    equal(w.ns.Config.GetProfile().linkedHover, true)
    w.ns.Config.SetBar("bar2", false)
    w.ns.Config.SetOption("showInCombat", true)
    equal(w.env.ForeverHoverBarsDB.bars.bar2, true)
    equal(w.env.ForeverHoverBarsDB.showInCombat, false)
end)

test("global updates and retained independent character settings survive switching", function()
    local w = world()
    w.ns.Config.SetCharacter(true)
    w.ns.Config.SetBar("pet", true)
    w.ns.Config.SetCharacter(false)
    w.ns.Config.SetBar("bar3", true)
    equal(w.ns.Config.GetProfile().bars.pet, false)
    local other = world({ global = w.env.ForeverHoverBarsDB })
    equal(other.ns.Config.GetProfile().bars.bar3, true)
    equal(other.ns.Config.GetProfile().bars.pet, false)
    w.ns.Config.SetCharacter(true)
    equal(w.ns.Config.GetProfile().bars.pet, true)
    equal(w.ns.Config.GetProfile().bars.bar3, false)
end)

test("reload preserves selected profile and character override", function()
    local w = world()
    w.ns.Config.SetCharacter(true)
    w.ns.Config.SetBar("stance", true)
    w.ns.Config.SetOption("showInCombat", true)
    local reloaded = world({ global = w.env.ForeverHoverBarsDB, character = w.env.ForeverHoverBarsCharacterDB })
    equal(reloaded.env.ForeverHoverBarsCharacterDB.useCharacter, true)
    equal(reloaded.ns.Config.GetProfile().bars.stance, true)
    equal(reloaded.ns.Config.GetProfile().showInCombat, true)
    reloaded:advance(0.2)
    near(reloaded.env.StanceBar.alpha, 0)
end)

test("missing saved character profile initializes from global", function()
    local w = world({ global = { bars = { bar8 = true } }, character = { useCharacter = true } })
    equal(w.ns.Config.GetProfile().bars.bar8, true)
    w.ns.Config.SetBar("bar8", false)
    equal(w.env.ForeverHoverBarsDB.bars.bar8, true)
end)

test("unselecting restores opacity and removes idle update script", function()
    local w = world()
    w.env.MainActionBar.alpha = 0.8
    w.ns.Config.SetBar("bar1", true)
    w:advance(0.2)
    near(w.env.MainActionBar.alpha, 0)
    w.ns.Config.SetBar("bar1", false)
    near(w.env.MainActionBar.alpha, 0.8)
    equal(w.ns.Controller.frame.scripts.OnUpdate, nil)
end)

for _, conflict in ipairs({ "EllesmereUIActionBars", "Bartender4", "Dominos", "ElvUI" }) do
    test(conflict .. " suspends control and restores original alpha", function()
        local w = world()
        w.ns.Config.SetBar("bar1", true)
        w:advance(0.2)
        w.loaded[conflict] = true
        w:emit("ADDON_LOADED", conflict)
        near(w.env.MainActionBar.alpha, 1)
        equal(w.ns.Controller.frame.scripts.OnUpdate, nil)
        assert(w.ns.Controller.conflict)
        equal(#w.messages, 1)
        w:emit("PLAYER_ENTERING_WORLD")
        equal(#w.messages, 1)
        w.env.SlashCmdList.FOREVERHOVERBARS()
        equal(w.openedCategory, 41)
    end)
end

test("late-created Blizzard bars are found on addon load", function()
    local w = world({ missing = "MultiBar7" })
    w.ns.Config.SetBar("bar8", true)
    equal(w.ns.Controller.frame.scripts.OnUpdate, nil)
    w.env.MultiBar7 = w.env.CreateFrame("Frame")
    w.env.MultiBar7.protected = true
    w:emit("ADDON_LOADED", "Blizzard_ActionBar")
    w:advance(0.2)
    near(w.env.MultiBar7.alpha, 0)
end)

test("settings panel registers all controls and labels active editing scope", function()
    local w = world()
    equal(w.categoryName, "Forever Hover Bars")
    equal(w.env.SLASH_FOREVERHOVERBARS1, "/fhb")
    local checks = {}
    for _, frame in ipairs(w.frames) do
        if frame.kind == "CheckButton" then checks[#checks + 1] = frame end
    end
    equal(#checks, 13)
    checks[1]:SetChecked(true)
    checks[1].scripts.OnClick(checks[1])
    equal(w.env.ForeverHoverBarsCharacterDB.useCharacter, true)
    checks[3]:SetChecked(true) -- Action Bar 2.
    checks[3].scripts.OnClick(checks[3])
    equal(w.ns.Config.GetProfile().bars.bar2, true)
    equal(w.env.ForeverHoverBarsDB.bars.bar2, false)
    local found = false
    for _, font in ipairs(w.fonts) do
        if font.text == "Editing: Character settings (independent)" then found = true end
    end
    assert(found)
end)

test("stable hidden bars poll at 20Hz without per-frame alpha writes", function()
    local w = world()
    w.ns.Config.SetBar("bar1", true)
    w:advance(0.3)
    local before = w.env.MainActionBar.alphaWrites
    w:advance(1)
    local writes = w.env.MainActionBar.alphaWrites - before
    assert(writes >= 19 and writes <= 21, "Unexpected alpha write count: " .. writes)
end)

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
