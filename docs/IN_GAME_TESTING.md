# In-game verification

Status: **pending**. Target client: **1.60.1.70959**, interface **16001**. Automated tests use mocked frames; they do not replace these checks.

For a test pass, record the date, actual `GetBuildInfo()` result, enabled UI addons, character class, each result, and any Lua errors or blocked-action/taint warnings. Do not commit account names or personal game data.

## Setup and visibility

- [ ] Install into `Interface/AddOns/ForeverHoverBars`, restart, and confirm the addon loads without errors.
- [ ] With EllesmereUI Action Bars enabled, confirm hover control pauses, a single chat notice appears, and `/fhb` explains the conflict. Disable that module and reload for the remaining checks.
- [ ] Confirm `/fhb` and Settings → AddOns open the panel and all thirteen checkboxes are usable, including in smaller settings windows.
- [ ] On a fresh profile, confirm no bar changes until selected.
- [ ] Individually select Action Bars 1–8. Each fades while idle and reveals over buttons, empty slots, and gaps. Unselected bars remain unchanged.
- [ ] Repeat with vertical, multi-row, resized, scaled, and moved layouts. Check both default bar art and buttons for residual icons/glows while transparent.
- [ ] Disable a bar in Blizzard settings. Hovering its old location must not show it or trigger a linked group.
- [ ] Test Pet Bar with a pet present and absent, including summon/dismiss. Test Stance / Form Bar across available forms/stances and a character without those controls.

## Linked hover and transitions

- [ ] With linking off, hovering one selected bar reveals only that bar.
- [ ] With linking on, hovering any selected bar reveals every available selected bar. Hovering an unselected bar does not reveal the group.
- [ ] Move between selected bars within the 0.3-second delay. The group stays visible without flicker.
- [ ] Leave all selected bars. Check 0.3-second delay followed by 0.15-second fade; re-enter during fading and check smooth 0.1-second reveal.
- [ ] Open a spell flyout and move into it. Its owning bar/group remains visible until the flyout closes; selecting spells and tooltips work normally.

## Combat and Blizzard interaction

- [ ] With combat override off, hover and linked hover work during combat. Test keyboard bindings while bars are transparent and mouse clicks after reveal.
- [ ] With combat override on, entering combat reveals selected bars; leaving combat restores hover rules.
- [ ] Change hover, link, combat, and character-profile settings during combat. Check for Lua errors and blocked-action/taint warnings.
- [ ] Verify main-bar paging and form changes preserve their normal actions, bindings, and button state.
- [ ] Enter/exit Blizzard Edit Mode and quick keybinding. Selected bars remain visible during editing and resume hover behavior afterward.
- [ ] Drag actions, spells, macros, and items onto bars. Selected bars stay visible during dragging; placements work normally.
- [ ] Enter/exit vehicle, possess, override, and special-action states. Blizzard's normal controls must remain available; suppressed regular bars must not be forced shown.
- [ ] Unselect a faded bar, then disable the addon and reload. Normal Blizzard appearance and interactions return.

## Profiles and persistence

- [ ] Edit global settings, reload, and log into another character using global settings. Selections and toggles match.
- [ ] Enable independent character settings. Initial values copy global values. Character edits do not change global settings.
- [ ] Return to global settings and change them. Re-enable independent settings; previous character choices return unchanged.
- [ ] Reload and relog with independent settings enabled. Bar choices and behavior persist.

Do not mark a client build verified until the applicable checks pass. Mark unavailable class-specific or vehicle scenarios as pending rather than passing them without observation.
