# MonkeySpeed Standalone

A lightweight speedometer addon for World of Warcraft 3.3.5a. Shows your current movement speed as a percentage of the zone's normal run speed, along with a colored bar that changes color as you move faster.

This is a **standalone** build — it has no dependency on `MonkeyLibrary` or `MonkeyBuddy`. 

**Original Author**: Trentin (trentin@toctastic.net), Website: http://toctastic.net/

![Interface: 30300 (WotLK 3.3.5a)](https://img.shields.io/badge/Interface-30300-orange)

---

## Contents

- [Installation](#installation)
- [Using the addon](#using-the-addon)
  - [The speedometer display](#the-speedometer-display)
  - [Mouse controls](#mouse-controls)
  - [Slash commands](#slash-commands)
  - [Calibration](#calibration)
  - [Stability filter](#stability-filter)
- [Titan Panel integration](#titan-panel-integration)
  - [Enabling](#enabling)
  - [Right-click menu](#right-click-menu)
- [Saved settings](#saved-settings)

---

## Installation

1. Close World of Warcraft completely.
2. Copy the `MonkeySpeed-SA` folder into your AddOns directory:

   ```
   <WoW install>\Interface\AddOns\MonkeySpeed-SA\
   ```

   After copying, the structure should look like:

   ```
   Interface\AddOns\MonkeySpeed-SA\
       MonkeySpeed-SA.toc
       MonkeySpeed-SA.xml
       MonkeySpeed.lua
       MonkeySpeedInit.lua
       MonkeySpeedSlash.lua
       MonkeySpeedTitan.lua
       localization.lua
       Fonts\myriapsc.ttf
       Textures\bar.tga
   ```

3. Launch WoW. At the character-selection screen click **AddOns** (bottom-left), make sure **MonkeySpeed Standalone** is enabled, and enter the world.

You should see a small boxed speedometer in the center of the screen showing a percentage (e.g. `100%`) and a colored bar underneath. Drag it wherever you like (see [Mouse controls](#mouse-controls)).

---

## Using the addon

### The speedometer display

- **Percent text** — your current speed expressed as a percentage of the zone's base run speed. `100%` is normal run speed, `160%` is a typical mount, etc.
- **Colored bar** — color-coded speed indicator:

  | Speed       | Bar color |
  |-------------|-----------|
  | 0%          | Red       |
  | 1–99%       | Orange    |
  | 100%        | Deep orange |
  | 101–139%    | Green     |
  | 140–199%    | Magenta   |
  | 200–549%    | Purple    |
  | 550%+       | Blue      |

  A black bar with `???%` means the zone hasn't been calibrated yet — see [Calibration](#calibration) below.

### Mouse controls

| Action | Effect |
|--------|--------|
| **Hover** | Shows a tooltip with the addon title and description. |
| **Left-click + drag** | Moves the speedometer frame anywhere on screen. Only works when the frame is unlocked (see `/mslock`). |
| **Right-click** | Calibrates the current zone assuming you are moving at 100% foot run speed. Equivalent to `/mscalibrate`. Should be used while running forward on foot with no speed buffs. |

### Slash commands

Every command has a long form (`/monkeyspeed…`) and a short form (`/ms…`). Toggles flip the setting each time they are run.

| Command | Short form | What it does |
|---|---|---|
| `/monkeyspeed` | `/mspeed` | Print the full help listing in chat. |
| `/monkeyspeeddisplay` | `/msdisplay` | Toggle the entire speedometer on/off (both bar and text). |
| `/monkeyspeedpercent` | `/mspercent` | Toggle just the percent text. |
| `/monkeyspeedbar` | `/msbar` | Toggle just the colored bar. |
| `/monkeyspeedlock` | `/mslock` | Lock or unlock the frame. When locked, left-click + drag does nothing. |
| `/monkeyspeeddebug` | `/msdebug` | Toggle debug mode. Prints raw zone-rate data to the chat frame as you move — might be useful when tuning calibration. |
| `/monkeyspeedcalibrate [N]` | `/mscalibrate [N]` | Recalibrate the current zone's base run speed by collecting `N` samples (0.1 s each, default 10) while you run on foot. See [Calibration](#calibration). |
| `/monkeyspeedsensitivity [N]` | `/mssensitivity [N]` | Set the size of the mode-filter sliding window (1–30, default 5). See [Stability filter](#stability-filter). |
| `/monkeyspeedreset` | `/msreset` | Reset all MonkeySpeed settings to defaults. Shows a confirmation dialog before applying. |

### Calibration

MonkeySpeed stores a per-zone baseline rate for what "100% run speed" looks like. New zones auto-populate on first visit, but the initial guess can be rough — if your readout looks incorrect, calibrate it:

1. Start running forward **on foot with no speed buffs** in a straight line at a constant speed.
2. Either:
   - **Right-click the speedometer** — quickest way, or
   - Type `/mscalibrate` (no argument = default 10 samples, ~1 second).

To collect more samples for a steadier baseline, pass `N` — the number of 0.1 s samples to take. For example `/mscalibrate 20` runs for ~2 seconds, `/mscalibrate 50` for ~5 seconds. Valid range is 2–100.

The addon prints when calibration starts (with how long to keep running) and again when it finishes. It commits the **most-frequent measured rate** over the sample window as the baseline; if every sample ends up unique it falls back to the arithmetic mean. Two warnings may follow:

- **Jittery readings** — if the most-frequent value won less than 40 % of the samples, the addon suggests re-running calibration with a larger `N`.
- **Zero samples** — if any tick recorded zero movement, the addon reminds you to keep moving forward on foot for the whole calibration window.

Calibration is saved per zone and shared across all characters on the account.

### Stability filter

The underlying measurement comes from `GetPlayerMapPosition`, whose coordinate precision is limited enough that consecutive 0.1 s samples can drift by ±10–15 %. To keep the displayed number from jittering, the addon feeds each 0.1 s reading into a small sliding window and displays the **most-frequent value** in that window (with the mean used as a fallback when every sample is unique).

Tune the window size with `/mssensitivity N`:

- `1` — no filtering, raw per-tick readings (very jittery).
- `5` — default. Settles in ~0.5 s, tolerates the usual noise.
- `10`–`30` — steadier but slower to react to real speed changes (mount up, speed buff, etc.).

Running `/mssensitivity` with no argument prints the current value. The chosen value is saved across sessions.

---

## Titan Panel integration

If **Titan Panel** is installed and enabled, MonkeySpeed automatically registers a plugin that displays your current speed on the Titan bar. The integration is purely additive — if Titan is not present, nothing extra happens and the rest of MonkeySpeed works exactly the same.

### Enabling

After logging in with both addons loaded:

1. Right-click any empty area of the Titan bar (or use `/titanpanel`).
2. Find **MonkeySpeed** under the **Information** category and enable it.

The widget shows `MonkeySpeed: NN%` and reads the same speed value as the in-world bar (post-calibration, post-sliding-window). The percentage text uses the same color scheme as the on-screen bar, with the purple and blue shades brightened slightly for readability against Titan's dark background.

### Right-click menu

| Option | Effect |
|---|---|
| **Calibrate** | Same as `/mscalibrate` — recalibrates the current zone with the default 10-sample window. |
| **Show MonkeySpeed Bar** | Toggle the in-world MonkeySpeed frame on/off without affecting the Titan widget. State persists across reloads (same `MonkeySpeedConfig.m_bDisplay` flag as `/msdisplay`). |
| **Show Label Text** | Standard Titan toggle — hides the `MonkeySpeed:` label, leaving just the colored percentage. |
| **Hide** | Removes the plugin from the Titan bar. Re-enable it via `/titanpanel`. |

---

## Saved settings

Settings are persisted **per account** (shared across every character on the account) in the `MonkeySpeedConfig` SavedVariable. WoW writes this to:

```
WTF\Account\<ACCOUNT>\SavedVariables\MonkeySpeed-SA.lua
```

Stored values include:

- Frame width and lock state
- Whether percent text / bar / the whole frame are shown
- Debug mode flag
- Per-zone baseline rates
- `/mssensitivity` value (sliding-window size)

To reset MonkeySpeed back to defaults, run `/msreset` (or `/monkeyspeedreset`) in game and confirm the dialog. If you'd rather wipe everything from disk, close WoW and delete the `MonkeySpeed-SA.lua` file at the path above.