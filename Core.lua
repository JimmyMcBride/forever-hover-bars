local addonName, addon = ...
local Config, Visibility = addon.Config, addon.Visibility
local Controller = { entries = {}, interval = 0.05 }
addon.Controller = Controller

local replacements = {
    { "EllesmereUIActionBars", "EllesmereUI Action Bars" },
    { "Bartender4", "Bartender4" },
    { "Dominos", "Dominos" },
    { "ElvUI", "ElvUI" },
}

local function FindConflict()
    for _, candidate in ipairs(replacements) do
        if C_AddOns.IsAddOnLoaded(candidate[1]) then
            return candidate[2]
        end
    end
end

local function ForceVisible(profile)
    return (profile.showInCombat and InCombatLockdown())
        or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive())
        or (KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode())
        or GetCursorInfo() ~= nil
end

local function HasFlyout(bar)
    if not SpellFlyout or not SpellFlyout:IsShown() or not SpellFlyout.IsAttachedToButton then
        return false
    end
    for _, button in ipairs(bar.actionButtons or {}) do
        if SpellFlyout:IsAttachedToButton(button) then
            return true
        end
    end
    return false
end

local function Restore(entry)
    entry.frame:SetAlpha(entry.originalAlpha)
end

function Controller:Poll(now)
    local profile = Config.GetProfile()
    local hovered = {}
    for key, entry in pairs(self.entries) do
        local bar = entry.frame
        -- IsVisible follows Blizzard's shown/parent state, including at alpha zero.
        hovered[key] = bar:IsVisible() and (bar:IsMouseOver() or HasFlyout(bar))
    end
    local active = Visibility.Resolve(profile, hovered, ForceVisible(profile))
    for key, entry in pairs(self.entries) do
        Visibility.Update(entry.state, active[key], now)
        -- Reassert at the bounded poll rate if Blizzard's own fades changed alpha.
        entry.frame:SetAlpha(entry.state.alpha)
    end
end

function Controller:OnUpdate(elapsed)
    local now = GetTime()
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= self.interval then
        self.elapsed = self.elapsed % self.interval
        self:Poll(now)
    end
    for _, entry in pairs(self.entries) do
        if entry.state.started then
            entry.frame:SetAlpha(Visibility.Advance(entry.state, now))
        end
    end
end

function Controller:Refresh()
    if not self.ready then return end
    self.conflict = FindConflict()
    local profile = Config.GetProfile()
    for key, entry in pairs(self.entries) do
        if self.conflict or not profile.bars[key] then
            Restore(entry)
            self.entries[key] = nil
        end
    end
    if not self.conflict then
        for _, bar in ipairs(addon.bars) do
            local frame = _G[bar.frame]
            if profile.bars[bar.key] and frame and not self.entries[bar.key] then
                local alpha = frame:GetAlpha()
                if issecretvalue and issecretvalue(alpha) then alpha = 1 end
                self.entries[bar.key] = {
                    frame = frame, originalAlpha = alpha, state = Visibility.New(alpha),
                }
            end
        end
    end
    if next(self.entries) then
        self.elapsed = 0
        self.frame:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)
        self:Poll(GetTime())
    else
        self.frame:SetScript("OnUpdate", nil)
    end
    if self.conflict and self.warned ~= self.conflict then
        self.warned = self.conflict
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Forever Hover Bars:|r Hover control paused because "
            .. self.conflict .. " is loaded. Type /fhb for details.")
    end
    if addon.Options.Refresh then addon.Options.Refresh() end
end

Controller.frame = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "CURSOR_CHANGED",
    "ACTIONBAR_SHOWGRID", "ACTIONBAR_HIDEGRID", "UPDATE_BINDINGS" }) do
    Controller.frame:RegisterEvent(event)
end
Controller.frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        Config.Initialize()
        addon.Options.Create()
        Controller.ready = true
        addon.SettingsChanged = function() Controller:Refresh() end
        EventRegistry:RegisterCallback("EditMode.Enter", function() Controller:Refresh() end, Controller)
        EventRegistry:RegisterCallback("EditMode.Exit", function() Controller:Refresh() end, Controller)
        EventRegistry:RegisterCallback("QuickKeybindFrame.QuickKeybindModeEnabled", function() Controller:Refresh() end, Controller)
        EventRegistry:RegisterCallback("QuickKeybindFrame.QuickKeybindModeDisabled", function() Controller:Refresh() end, Controller)
    end
    Controller:Refresh()
end)
