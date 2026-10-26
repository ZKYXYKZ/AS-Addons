# AS Companion

Build planner and launcher for Azeroth Survivors. It edits your builds, starts the game, reads the level-up cards and advises or picks the best one.

## Install

1. Download `AzerothSurvivors-Addons.zip` (exe and addons) or `ASCompanion.exe` alone from the [latest release](https://github.com/ZKYXYKZ/AS-Addons/releases/latest).
2. Put the exe next to `AzerothSurvivors.exe` (or anywhere, then set the game path in Options with Browse).
3. Run it. The builder opens in its own window. A tray icon reopens it.

Windows 10 or 11 only, nothing to install: it runs on the .NET Framework shipped with Windows and shows its window with Microsoft Edge. The exe is not code-signed, so SmartScreen may warn on first launch: More info, Run anyway. It is built from this repository by GitHub Actions, and `SHA256SUMS.txt` in each release lets you check the file.

## Builder

- **Build**: on one page, the three talent trees of the class (51 points, milestones and capstone), the spell priorities with a weight and banned spells (the first 6 are targets, the rest fallbacks), and the target and fallback rings, trinkets and amulets, including the legendary amulet of each spell, each with a weight from 1 to 5. Every piece of jewelry shows its effects, decoded from the game.
- **Rules**: rarity weight, rerolls kept in reserve, banishes, reroll before skipping, level from which fallback rings and trinkets are accepted, legendary boost, adapt to the run.
- **Options**: game path (with a Browse button), language, card auto-pick, overlay.
- **Sharing**: Export and Import a build as one line of text.

## In game

Click **Launch game**. The companion reads the cards the game prints on its console, so the game must be started from it. A banner shows the advice without taking the focus. With auto-pick on, the keys 1, 2, 3 and R are sent to the game window, and sent again if the game did not take them. Skip and banish have no key and stay manual; a banish also refreshes the cards, so it is advised when a banned card shows up.

Luck makes rarer cards. The SurvivorsBuilds addon records your luck from the character stats at the start of each run, and the companion reads it at the next launch, then adds the luck jewelry taken in the run. It rerolls an average card more readily when luck is high.

At launch the companion writes the active builds into the SurvivorsBuilds addon saved variables: the in-game Builds tab and the guide panel show them during the run.

Builds and the log are in `%APPDATA%\AS-Companion`.

## Build from source

```
node tools/build-companion.js
```

Compiles `AS-Companion/src/Companion.cs` with the C# compiler of the .NET Framework (`csc.exe`, part of Windows) and embeds `AS-Companion/web` into `dist/ASCompanion.exe`.
