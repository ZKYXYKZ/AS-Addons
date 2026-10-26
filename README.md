# AS-Addons

**English** · [Français](README.fr.md)

Tools for [Azeroth Survivors](https://wow.aethus.pl/), a survivors-style game built on a rewritten WoW 1.12 client: survive waves, level up, pick spells and jewelry, beat the bosses, move on to harder maps.

- **AS Companion**: a Windows app to plan your builds, launch the game, pick the level-up cards for you and keep your run statistics.
- **SurvivorsUI**, **SurvivorsBuilds**, **SurvivorsGuardians**: in-game addons, written for this game mode.

![SurvivorsUI and SurvivorsGuardians in a run](docs/gameplay.jpg)

[![Buy me a coffee](AS-Companion/web/img/buymeacoffee.png)](https://www.buymeacoffee.com/zkyxykz)

## Quick start

1. Download `AzerothSurvivors-Addons.zip` from the [latest release](https://github.com/ZKYXYKZ/AS-Addons/releases/latest).
2. Extract it into the game folder, the one that holds `AzerothSurvivors.exe`. It adds `ASCompanion.exe` there and the three addons to `benilla-config\AddOns`, the folder the game loads addons from.
3. Start `ASCompanion.exe`, create a build for your class, then click **Launch game**.

The companion updates itself and the addons from the GitHub releases. Windows 10 or 11, nothing else to install.

## AS Companion

The companion opens in its own window, rendered by Microsoft WebView2 (built into Windows 10 and 11). If WebView2 is missing, the companion offers to download and install it in the background, and meanwhile opens its interface in your browser. A tray icon reopens the window. Closing the window quits the companion, unless a game it launched is still running.

### Builds

- **Talents**: the three trees of the class with the game's background art, 51 points, milestones and capstone.
- **Spells**: priority order with a weight from 1 to 5, and banned spells. A run holds 6 spells: the first 6 are targets, the rest fallbacks.
- **Jewelry**: target and fallback rings, trinkets and amulets, including the legendary amulet of each spell, each with a weight from 1 to 5. Every piece shows its effects, decoded from the game.
- **Rules**: rarity weight, rerolls kept in reserve, banishes, reroll before skipping, level from which fallback rings and trinkets are accepted, legendary bonus, adapt to the run.
- **Sharing**: Export and Import a whole build as one line of text.

### In a run

Click **Launch game**. The game must be started from the companion: that is how it reads the level-up cards, from the game's console output.

- A banner over the game shows the best card, without taking the focus.
- **Auto-pick** (Options) presses 1, 2, 3, 4 or R for you, and presses again if the game missed it. Skip and Banish have no key in the game yet, so they stay manual.
- The advice adapts to the run: spells already taken, their rank, their real share of your damage (read from the game's combat log), the amulet you wear and its upgrades, your luck, and the free jewelry slots. Rings and trinkets can't be swapped once taken, so fallbacks are only accepted from the level set in the Rules.
- Luck comes from the game itself: the SurvivorsBuilds addon records it at the start of each run, and the companion adds the luck jewelry taken during the run.

### Statistics

Every run launched from the companion is recorded when it ends, endless mode included (after the final boss the game can go on, with a boss every 5 minutes, until you die):

- filters by class, zone and result;
- key figures: runs, victories, time played, best survival, max level and kills, average and max DPS, bosses and guardians killed, best endless;
- survival time and DPS per run, average survival by class, damage share by spell;
- tables by spec and by race, and the latest runs.

### Addons

Lists the game addons with their description, installed version and latest version. Install, update, enable, disable or uninstall them (uninstalled folders go to the Recycle Bin). Close the game first. Installed addons also update themselves at startup and every 30 minutes outside a run (option in Options).

### Options

Game path (with a Browse button), language, auto-pick, advice banner, version and update check.

### Updates

At startup the companion checks the latest GitHub release. When a newer one exists, an **Update** button shows in the status bar: it downloads the release, checks its SHA-256, updates the installed addons and the companion, then restarts. Builds, statistics and settings are kept in `%APPDATA%\AS-Companion`.

### Windows warning

`ASCompanion.exe` is not code-signed, so SmartScreen may warn on first launch: **More info**, then **Run anyway**. It is built from this repository by GitHub Actions, and `SHA256SUMS.txt` in each release lets you check every file.

## Addons

All three share one window: the gold `S` button on the minimap, `/survivors`, or a key set under Key Bindings > Survivors.

### SurvivorsBuilds

The bridge with AS Companion.

- A panel that stays on screen during the run: the 6 target spells with their icon and rank, the jewelry you wear in its quality color (target or fallback), and the target jewelry still missing.
- While you pick a card: spells to banish, rerolls left, and the build rule.
- Every spell you take or rank up is written to the chat with its priority.
- Records your luck for the companion and turns on the combat log it reads.

### SurvivorsUI

A compact replacement for the stock interface.

- Bottom center block: target bar, player health, resource, spell icons with cooldown sweep, experience bar.
- Stock player frame, target frame and action bars are hidden. Trimmed chat, square minimap with mouse wheel zoom, micro buttons that fade until hovered.
- Settings in the Interface tab of the shared window, or `/sui`: resize every block, unlock frames to move them on a grid with snapping (hold Shift to disable it), camera zoom out from 15 to 90 yards.

![Settings panel with frames unlocked](docs/settings.jpg)

### SurvivorsGuardians

A tracker for the four guardian lairs and the bosses, fed by the game's own addon API.

- One row per lair: guardian name, health, asleep or fighting.
- An empty lair shows the countdown until a new guardian claims it.
- Bosses get their own row with their health. The header counts the held lairs and shows the next boss with its countdown.
- Click a row to target that guardian or boss.

The Build and Guardians panels can be dragged directly with the mouse.

## Known limits

- Skip and Banish can't be automated until the game adds keybinds for them.
- The run timer, the kill and gold counters, the damage meter and the native spell icon row are drawn by the game engine: addons can't move or hide them.
- Addons can't send anything to the companion while the game runs. The companion reads the game's console output and combat log instead.

## For developers

- Build the companion: `node tools/build-companion.js` (uses the C# compiler shipped with Windows, output in `dist\`).
- Release: push a tag `vX.Y.Z`. GitHub Actions builds the companion, packages the addons with that version and publishes `ASCompanion.exe`, `AzerothSurvivors-Addons.zip`, one zip per addon, `addons.json` and `SHA256SUMS.txt`.
- `NOTES.md` (in French) documents what the game exposes, how the data is decoded from the game files, and how each part works.

## Disclaimer

Unofficial fan project, not affiliated with Azeroth Survivors or with Blizzard Entertainment.

Made by [ZKYXYKZ](https://x.com/zkyxykz).
