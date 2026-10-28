# Azeroth Survivors Companion

**English** · [Français](README.fr.md)

A companion app and three addons for [Azeroth Survivors](https://wow.aethus.pl/), the survivors-style game built on a rewritten WoW 1.12 client.

Plan your build once, launch the game from the companion, and let it pick the right level-up cards for you while you play.

<a href="https://www.buymeacoffee.com/zkyxykz"><img src="AS-Companion/web/img/buymeacoffee.png" alt="Buy me a coffee" height="36"></a>

![SurvivorsUI and SurvivorsGuardians in a run](docs/gameplay.jpg)

## Get started

1. Download **[ASCompanion.exe](https://github.com/ZKYXYKZ/Azeroth-Survivor-Companion/releases/latest/download/ASCompanion.exe)**.
2. Put it in the game folder, next to `AzerothSurvivors.exe`, and run it. It installs the addons in the right folder by itself. Anywhere else works too: it then looks for the game, and asks where `AzerothSurvivors.exe` is if it can't find it.
3. Create a build for your class, then click **Launch game**.

That's all. Windows 10 or 11, nothing else to install. The companion keeps itself and the addons up to date.

> Windows may show a SmartScreen warning the first time, because the app is not code-signed: click **More info**, then **Run anyway**. Every release is built from this repository by GitHub Actions, and `SHA256SUMS.txt` lets you check the files.

## What it does

### Plan your builds

![Builds page: talent trees of a Fury warrior](docs/companion-builds.jpg)


- **Talents**: the three trees of your class, as in the game.
- **Spells**: your priority order, a weight from 1 to 5 for each, and the spells you never want. A run holds 6 spells: the first 6 are your targets, the rest are fallbacks.
- **Jewelry**: the rings, trinkets and amulets you want, legendary amulets included, each with a weight from 1 to 5. Hover any piece to see its effects.
- **Rules**: how much rarity counts, how many rerolls to keep, when to accept fallback jewelry, and more.
- **Suggested builds**: a ready-made build for each of the 28 specs, with a recommended race, added in one click.
- **Apply in game**: open the Armory on the spec you want, click **Apply in game** and don't move the mouse (about twenty seconds): the companion clicks Reset and places the build's talent points. It never changes your class or spec, and works at any resolution, 4K included.
- **Share**: export a build as one line of text, import a friend's build in one click.

### Pick the cards for you

Always start the game with **Launch game**: that's how the companion sees the level-up cards.

- A banner over the game shows the best card.
- Turn on **Auto-pick** in Options and the companion chooses and rerolls for you.
- Its choices follow the run: spells you already have and their rank, how much damage each spell really does, the amulet you wear, your luck, and the jewelry slots still free. Rings and trinkets can't be swapped once taken, so it is careful with them.
- It follows your build, nothing else: when no card belongs to it, it rerolls while you have rerolls, then suggests a skip, and otherwise leaves the choice to you.
- It recognizes your spec from the spell or pet your last talent gives at the start of a run, and switches to your build for that spec. The arrows of the in-game panel switch the companion's build too.
- Replaying from the end-of-run screen keeps your class and build.
- Skip and Banish have no key in the game yet, so they stay manual.

### Track your runs

![Statistics page](docs/companion-stats.png)

The **Statistics** page has two tabs:

- **Solo** records every run launched from the companion, endless and heroic modes included: time survived, level, kills, DPS, bosses and guardians, with charts by run, by class, by spec and by race, and the damage share of each spell.
- **Community** shows the runs shared by all companion players, also on [as-stats.zkysolutions.com](https://as-stats.zkysolutions.com): best runs per zone and difficulty, win rate per class, spec and race, the most played builds (added to yours in one click) and the spells that deal the most damage.

### Simulate a build

The **Simulator** page plays a build against the game's own data (spells, enemies, zones and bosses read from the game files) to compare builds before trying them. It is calibrated with real runs, and gets more accurate as shared runs come in.

### Manage the addons

The **Addons** page shows each addon with what it does, its version, and buttons to install, update, enable, disable or uninstall it. Auto-update can be turned off for all addons or for each one, and an addon is only reinstalled when it actually changed.

![Addons page](docs/companion-addons.png)

## The addons

### SurvivorsBuilds

<img src="docs/build-panel.png" alt="Build panel in a run" align="right" width="260">

Shows your build on screen during the run: the 6 target spells with their rank, the jewelry you wear in its quality color, what's still missing, and the fallback jewelry with the level it's accepted from. While you pick a card, it reminds you what to banish and how many rerolls are left. It follows your spec like the companion, and the arrows next to its title switch to another of your builds, in the companion too. Specs without a build of yours get the suggested one.

It also records each run (health, enemies, bosses, stats, spell ranks and damage meter, pets and procs included) for the statistics and the simulator. The companion needs it: it warns you and offers to install or enable it if it's missing.

<br clear="right">

### SurvivorsUI

A compact interface for this game mode: target, health, resource and spell bars in one block at the bottom, a cleaner chat, a square minimap, and a farther camera zoom. Every block can be moved and resized on a grid.

![Settings panel with frames unlocked](docs/settings.jpg)

### SurvivorsGuardians

<img src="docs/guardians.png" alt="Guardians panel with a boss" align="right" width="260">

Tracks the four guardian lairs and the bosses: guardian health, alive or fighting, dead with the countdown until it comes back, and the next boss. Click a row to target it.

<br clear="right">

All three share one window: the gold **S** button on the minimap, or `/survivors`. Their panels can be dragged with the mouse.

## Good to know

- Builds, statistics and settings are kept in `%APPDATA%\AS-Companion`, so updates never touch them.
- Closing the companion window quits it, unless a game it launched is still running.
- The companion needs Microsoft WebView2, built into Windows 10 and 11. If it's missing, the companion offers to install it.
- Something wrong? **Options → Bug report** zips the companion log, your latest runs and your settings: send that file with a description.
- Prefer a manual install? Each release also has `AzerothSurvivors-Addons.zip`: extract it into the game folder.

## Is it safe?

- The whole source is in this repository. Every release is built by GitHub Actions from that source, not on someone's PC, and `SHA256SUMS.txt` lists the fingerprint of each file.
- The companion only talks to GitHub (to check for updates), to the community site [as-stats.zkysolutions.com](https://as-stats.zkysolutions.com), and, if it is missing, to Microsoft for WebView2. No account. Your builds stay on your PC. At the end of each run, an anonymous summary goes to the community site to improve the suggested builds and the simulator: no player name, path or address, only a random ID tied to the install, and IP addresses are not stored. **Share my runs**, on by default, can be turned off in the options.
- The exe is not signed yet, so Windows SmartScreen may warn on first launch: **More info → Run anyway**.
- Auto-pick is off by default. The addons only read the game through its official addon API.

## For developers

- Build the companion: `node tools/build-companion.js` (uses the C# compiler shipped with Windows, output in `dist\`).
- Publish a version: push a tag `vX.Y.Z`. GitHub Actions builds the companion, packages the addons and publishes the release.
- `NOTES.md` (in French) explains what the game exposes and how every part works.

## Disclaimer

Unofficial fan project, not affiliated with Azeroth Survivors or with Blizzard Entertainment.

Made by [ZKYXYKZ](https://x.com/zkyxykz).
