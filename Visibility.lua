local _, addon = ...
local Visibility = { fadeIn = 0.1, hideDelay = 0.3, fadeOut = 0.15 }
addon.Visibility = Visibility

function Visibility.New(alpha)
    return { alpha = alpha, target = alpha }
end

function Visibility.Advance(state, now)
    if state.started then
        local progress = math.min(1, math.max(0, (now - state.started) / state.duration))
        state.alpha = state.from + (state.target - state.from) * progress
        if progress >= 1 then
            state.started = nil
        end
    end
    return state.alpha
end

function Visibility.Update(state, active, now)
    Visibility.Advance(state, now)
    if active then
        state.lastActive = now
    end
    local visible = active or (state.lastActive and now - state.lastActive < Visibility.hideDelay)
    local target = visible and 1 or 0
    if target ~= state.target then
        state.from = state.alpha
        state.target = target
        state.started = now
        state.duration = target == 1 and Visibility.fadeIn or Visibility.fadeOut
    end
    return state.alpha
end

function Visibility.Resolve(profile, hovered, forceVisible)
    local anyHovered = false
    if profile.linkedHover then
        for key, selected in pairs(profile.bars) do
            if selected and hovered[key] then
                anyHovered = true
                break
            end
        end
    end
    local active = {}
    for key, selected in pairs(profile.bars) do
        if selected then
            active[key] = not not (forceVisible or anyHovered or hovered[key])
        end
    end
    return active
end
