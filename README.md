# Forever Hover Bars

Hide individual Blizzard action bars until you hover over them. Optionally reveal all selected bars together when any one is hovered.

**WoW Forever only.** Targets interface **16001**, client **1.60.1.70959**. Version **0.1.0** is an initial preview: automated Lua and mocked integration checks pass; live-client verification remains pending.

## Install

1. Build `ForeverHoverBars-0.1.0.zip` using the command below, or use a supplied copy of that ZIP.
2. Extract it into your Forever client's `Interface/AddOns` directory.
3. Check that the resulting path is `Interface/AddOns/ForeverHoverBars/ForeverHoverBars.toc`. Avoid an extra nested folder.
4. Restart the client if this is a new installation. Enable **Forever Hover Bars** in the AddOns list.
5. Open **Settings → AddOns → Forever Hover Bars**, or type **`/fhb`**.

All bars start with normal visibility. Select **Hide until hovered** for each bar you want to fade.

The GitHub source checkout has a different directory name. If installing source manually, copy `ForeverHoverBars.toc`, `Config.lua`, `Visibility.lua`, `Options.lua`, and `Core.lua` into a directory named **ForeverHoverBars**.

## Settings

- **Hide until hovered:** available individually for Action Bars 1–8, Pet Bar, and Stance / Form Bar. Enable the underlying bars in Blizzard's settings first.
- **Reveal all hover-hidden bars together:** hovering any selected bar reveals all selected bars. Hovering an unselected bar does not trigger the group.
- **Always show during combat:** reveals selected bars throughout combat. Off by default, so hover behavior also works in combat.
- **Use independent settings for this character:** off by default. Global settings are shared by all characters using global settings. First enabling independent settings copies the current global setup. Turning it off returns to global settings and retains the independent setup for later reuse.

The panel labels whether you are editing global or character settings.

Bars fade in over **0.1 seconds**. After leaving, they stay visible for **0.3 seconds**, then fade out over **0.15 seconds**. Entering another linked bar cancels the pending hide. Timings are fixed in this version.

Hover uses the entire bar rectangle, including gaps and empty slots. Bindings stay active while a bar is transparent. Bars remain mouse-interactive so their original region can reveal them; they are not click-through overlays.

Selected bars remain visible during Blizzard Edit Mode, quick keybinding, and cursor dragging. An open spell flyout keeps its owning bar—and the linked group when enabled—visible until closed. Ordinary tooltips retain Blizzard's behavior.

Blizzard still controls bar availability. This addon does not enable disabled bars or make absent pet, stance, vehicle, or override bars appear. Vehicle, override, extra-action, and zone-ability controls are not managed.

## Compatibility

Use Blizzard's default action bars. Hover control pauses if **EllesmereUI Action Bars**, **Bartender4**, **Dominos**, or **ElvUI** is loaded. A chat notice and the settings panel explain the conflict.

For EllesmereUI, disable **EllesmereUI Action Bars** in the AddOns list and reload. Other EllesmereUI modules can remain enabled. For other replacements, disable the conflicting addon and reload. Avoid enabling another addon's action-bar fading at the same time.

No third-party libraries are required. The addon changes opacity without replacing Blizzard scripts, modifying action attributes, moving/reparenting bars, or changing their shown state.

## Saved settings

- `ForeverHoverBarsDB`: account-wide bar selections, linked hover, and combat behavior.
- `ForeverHoverBarsCharacterDB`: independent-settings toggle and retained character profile.

The client saves these using its normal SavedVariables lifecycle. To return all bars to normal appearance, uncheck their hover settings or disable this addon and reload.

## Development and packaging

Requires **Lua 5.1** (`lua5.1`, `luac5.1`) and **Python 3.9+**:

```sh
python3 tools/check.py
python3 tools/package.py
```

The check command validates Lua syntax, runs the behavior and mocked Blizzard-integration tests, and checks local Markdown links and whitespace. GitHub Actions runs the same checks and validates package construction on pushes and pull requests.

Packaging writes `dist/ForeverHoverBars-0.1.0.zip` with exactly one top-level `ForeverHoverBars/` directory. Only runtime files and this README are included; repository metadata, tests, and development tools are excluded.

`Config.lua` owns saved profiles, `Visibility.lua` owns hover/fade decisions, `Core.lua` integrates with Blizzard frames, and `Options.lua` builds the native settings panel. One monitor samples hover at 20 Hz; opacity animates per frame only during transitions. With no bars selected, no update monitor runs.

See [in-game verification](https://github.com/JimmyMcBride/forever-hover-bars/blob/main/docs/IN_GAME_TESTING.md) for the live-client checklist. Mock tests cannot establish actual client compatibility, combat security, or visual correctness.

Reference: [Blizzard's UI source, Forever branch](https://github.com/Gethe/wow-ui-source/tree/forever).
