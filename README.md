# AS-Addons

Addons for [Azeroth Survivors](https://wow.aethus.pl/), a survivors-style game built on a rewritten WoW 1.12 client: survive waves, level up, pick talents, loot gear, move on to harder maps.

The game loads regular WoW 1.12 addons (Lua 5.0, `## Interface: 11200`). These addons are written for its game mode, where spells cast on their own and most of the stock interface is noise.

![SurvivorsUI and SurvivorsGuardians in a run](docs/gameplay.jpg)

## Addons

All addons share one window: the gold `S` button on the minimap, `/survivors`, or a key set under Key Bindings > Survivors. Each addon adds its own tab.

### AS Companion and SurvivorsBuilds

The build planner lives in **AS Companion** (`AS-Companion` folder), a Windows app (`ASCompanion.exe`, from the releases): talent trees, spell priorities and weights, banned spells, target and fallback jewelry including the legendary amulet of each spell, reroll, skip and banish rules, text sharing, and a **Launch game** button. See [AS-Companion/README.md](AS-Companion/README.md).

The level-up cards are drawn by the game engine and never reach addons. The companion starts the game, reads the cards from its console output, shows the best pick in a banner and can pick it for you (keys 1, 2, 3 and R; skip and banish stay manual). It weighs spells you already own, the legendary amulet you wear and your luck.

**SurvivorsBuilds** is the in-game side. It receives the active build of each class when the companion launches the game, then shows it in the Builds tab and in a small panel while you pick a card, and writes every spell you take or rank up to the chat.

### SurvivorsUI

A compact replacement for the stock interface.

- Bottom center block: target bar (name, health, percent), player health, resource, spell icons with cooldown sweep, experience bar.
- Stock player frame, target frame and action bars are hidden.
- Trimmed chat, square minimap with mouse wheel zoom.
- Micro buttons and backpack fade out until hovered.
- Settings in the Interface tab of the shared window, or `/sui`.
  - Resize every block.
  - `Unlock frames` shows a grid: drag to move, mouse wheel to resize. Frames snap to each other, to the screen edges and center, and to the grid. Hold Shift to disable snapping.
  - Max camera zoom out, from 15 to 90 yards.

![Settings panel with frames unlocked](docs/settings.jpg)

### SurvivorsGuardians

A tracker for the map guardians (mini bosses) and bosses.

- One row per guardian: compass dot (north is up), level, health once damaged.
- Dead guardians are greyed out, struck through and marked `DEAD`, with a respawn countdown once the delay has been measured.
- Colored pins on the minimap edge point to each living guardian.
- Bosses get their own row when they appear, and the header shows a countdown to the next one.
- Click a row to target that guardian or boss.
- Guardians are remembered per map, so the full list shows from the start of your next run there.
- `/guardians` resets the panel position, `/guardians peek` toggles the automatic level and health readout.

SurvivorsGuardians works on its own. With SurvivorsUI installed, its panel is moved and resized from the same settings.

## Install

Download `AS-Addons.zip` and `ASCompanion.exe` from the [latest release](https://github.com/ZKYXYKZ/AS-Addons/releases/latest).

1. In game, open Options, go to the AddOns tab and click `Open AddOns Folder`.
2. Extract `AS-Addons.zip` into it.
3. Enable them in the AddOns list. They load at your next run.
4. Put `ASCompanion.exe` next to `AzerothSurvivors.exe` and start the game from it.

## Known limits

- The run timer, the kill and gold counters, the damage meter and the native spell icon row are drawn by the game engine. Addons cannot move or hide them.
- The game only reveals a guardian on the map once you get close, so the first run on a map fills the list as you explore.
- The boss countdown is estimated from combat activity, since the game timer is not readable from Lua. Expect a few seconds of drift until the first boss appears.
- To read the level and health of distant guardians, the tracker targets each one for a fraction of a second, at most every 30 seconds, then restores your target.

## Notes for developers

`NOTES.md` (in French) documents what the game exposes to addons, how to run an isolated test instance, and how each addon works internally.

## Disclaimer

Unofficial fan project, not affiliated with Azeroth Survivors or with Blizzard Entertainment.
