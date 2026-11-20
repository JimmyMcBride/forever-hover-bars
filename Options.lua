local _, addon = ...
local Options = {}
addon.Options = Options

function Options.Create()
    local panel = CreateFrame("Frame")
    panel.name = addon.title
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -30, 8)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(560, 660)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(math.max(280, width))
    end)

    local function Text(text, y, font)
        local label = content:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
        label:SetPoint("TOPLEFT", 12, y)
        label:SetPoint("RIGHT", content, "RIGHT", -12, 0)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        return label
    end

    Text(addon.title, -12, "GameFontNormalLarge")
    Text("Choose bars to hide until hovered. Enable bars in Blizzard's settings first.", -42)
    local controls = {}
    local function Checkbox(label, y, read, write, tooltip)
        local check = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        check:SetSize(26, 26)
        check:SetPoint("TOPLEFT", 10, y)
        local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", check, "RIGHT", 4, 0)
        text:SetText(label)
        check:SetScript("OnClick", function(self)
            write(self:GetChecked())
            Options.Refresh()
        end)
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", function() GameTooltip:Hide() end)
        controls[#controls + 1] = { check = check, read = read }
    end

    Checkbox("Use independent settings for this character", -76,
        function() return ForeverHoverBarsCharacterDB.useCharacter end,
        addon.Config.SetCharacter,
        "First use copies global settings. Turning this off returns to global settings and retains your character setup.")
    local scope = Text("", -110, "GameFontNormal")
    Text("Hide until hovered", -156, "GameFontNormal")
    for index, bar in ipairs(addon.bars) do
        local key = bar.key
        Checkbox(bar.label, -178 - (index - 1) * 28,
            function() return addon.Config.GetProfile().bars[key] end,
            function(value) addon.Config.SetBar(key, value) end,
            "Fade this bar while idle. Its original region still detects hover, including gaps between buttons. Keybindings remain active.")
    end
    Checkbox("Reveal all hover-hidden bars together", -474,
        function() return addon.Config.GetProfile().linkedHover end,
        function(value) addon.Config.SetOption("linkedHover", value) end,
        "Hover any selected bar to reveal all selected bars. Unselected bars retain Blizzard's normal behavior.")
    Checkbox("Always show during combat", -508,
        function() return addon.Config.GetProfile().showInCombat end,
        function(value) addon.Config.SetOption("showInCombat", value) end,
        "Reveal selected bars during combat. When disabled, hover behavior also applies in combat.")
    local status = Text("", -552)
    status:SetTextColor(1, 0.75, 0.3)
    Text("Fade in: 0.1s. Hide delay: 0.3s. Fade out: 0.15s.\nBars remain visible while editing, binding keys, or dragging actions.", -610)

    function Options.Refresh()
        for _, control in ipairs(controls) do
            control.check:SetChecked(control.read())
        end
        scope:SetText(ForeverHoverBarsCharacterDB.useCharacter
            and "Editing: Character settings (independent)"
            or "Editing: Global settings (shared by characters using global settings)")
        status:SetText(addon.Controller.conflict
            and ("Hover control paused: " .. addon.Controller.conflict .. " is loaded. Disable its action-bar module and reload to use Blizzard bars.")
            or "Hover control ready. Blizzard still decides which bars are available.")
    end
    panel:SetScript("OnShow", Options.Refresh)
    Options.category = Settings.RegisterCanvasLayoutCategory(panel, addon.title)
    Settings.RegisterAddOnCategory(Options.category)
    SLASH_FOREVERHOVERBARS1 = "/fhb"
    SlashCmdList.FOREVERHOVERBARS = function()
        Settings.OpenToCategory(Options.category:GetID())
    end
end
