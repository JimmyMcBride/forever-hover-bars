local _, addon = ...

addon.title = "Forever Hover Bars"
addon.bars = {
    { key = "bar1", frame = "MainActionBar", label = "Action Bar 1" },
    { key = "bar2", frame = "MultiBarBottomLeft", label = "Action Bar 2" },
    { key = "bar3", frame = "MultiBarBottomRight", label = "Action Bar 3" },
    { key = "bar4", frame = "MultiBarRight", label = "Action Bar 4" },
    { key = "bar5", frame = "MultiBarLeft", label = "Action Bar 5" },
    { key = "bar6", frame = "MultiBar5", label = "Action Bar 6" },
    { key = "bar7", frame = "MultiBar6", label = "Action Bar 7" },
    { key = "bar8", frame = "MultiBar7", label = "Action Bar 8" },
    { key = "pet", frame = "PetActionBar", label = "Pet Bar" },
    { key = "stance", frame = "StanceBar", label = "Stance / Form Bar" },
}

local Config = {}
addon.Config = Config

local function Normalize(profile)
    profile = type(profile) == "table" and profile or {}
    profile.bars = type(profile.bars) == "table" and profile.bars or {}
    for _, bar in ipairs(addon.bars) do
        profile.bars[bar.key] = profile.bars[bar.key] == true
    end
    profile.linkedHover = profile.linkedHover == true
    profile.showInCombat = profile.showInCombat == true
    return profile
end

function Config.Initialize()
    ForeverHoverBarsDB = Normalize(ForeverHoverBarsDB)
    local character = ForeverHoverBarsCharacterDB
    character = type(character) == "table" and character or {}
    character.useCharacter = character.useCharacter == true
    if type(character.profile) == "table" then
        character.profile = Normalize(character.profile)
    end
    ForeverHoverBarsCharacterDB = character
    if character.useCharacter and not character.profile then
        Config.SetCharacter(true)
    end
end

function Config.GetProfile()
    if ForeverHoverBarsCharacterDB.useCharacter then
        return ForeverHoverBarsCharacterDB.profile
    end
    return ForeverHoverBarsDB
end

function Config.Changed()
    if addon.SettingsChanged then
        addon.SettingsChanged()
    end
end

function Config.SetCharacter(enabled)
    local character = ForeverHoverBarsCharacterDB
    if enabled and not character.profile then
        local source = ForeverHoverBarsDB
        local copy = { bars = {}, linkedHover = source.linkedHover, showInCombat = source.showInCombat }
        for _, bar in ipairs(addon.bars) do
            copy.bars[bar.key] = source.bars[bar.key]
        end
        character.profile = copy
    end
    character.useCharacter = enabled == true
    Config.Changed()
end

function Config.SetOption(key, enabled)
    if key == "linkedHover" or key == "showInCombat" then
        Config.GetProfile()[key] = enabled == true
        Config.Changed()
    end
end

function Config.SetBar(key, enabled)
    for _, bar in ipairs(addon.bars) do
        if bar.key == key then
            Config.GetProfile().bars[key] = enabled == true
            Config.Changed()
            return
        end
    end
end
