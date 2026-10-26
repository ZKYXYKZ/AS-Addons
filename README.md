# AS-Addons

Addons for [Azeroth Survivors](https://wow.aethus.pl/), a survivors-style game built on a rewritten WoW 1.12 client: survive waves, level up, pick talents, loot gear, move on to harder maps.

The game loads regular WoW 1.12 addons (Lua 5.0, `## Interface: 11200`). These addons are written for its game mode, where spells cast on their own and most of the stock interface is noise.

![SurvivorsUI and SurvivorsGuardians in a run](docs/gameplay.jpg)

## Addons

All addons share one window: the gold `S` button on the minimap, `/survivors`, or a key set under Key Bindings > Survivors. Each addon adds its own tab.

### SurvivorsBuilds

A build planner for every class, with the game's real talent trees, spells and jewelry, in English or French.

- **Talents**: the three trees of the class with the in-game layout, a row opening every 5 points, milestones at 10, 20 and 30 points, 51 points in total. Left click adds a point, right click removes one. The spec is detected from the tree with the most points.
- **Spells**: priority order with a weight from 1 to 5, and banned spells. A run holds 6 spells, so the first 6 are targets and the rest are fallbacks.
- **Jewelry**: wishlists for 2 rings, 2 trinkets and 1 amulet, with fallbacks and banned pieces.
- **Rules**: how much a card's rarity weighs against your priority, rerolls kept in reserve, reroll before skipping, and the game's Store Level-Ups option.
- **Sharing**: Export gives a line of text with the whole build, Import turns that text back into a build.
- **In a run**: while you pick a card, a small panel lists your priorities with their current rank, the spells to banish and the rerolls left. Every spell you take or rank up is written to the chat, with its priority.

The level-up cards are drawn by the game engine and never reach addons, so the planner guides your picks but does not make them.

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

1. In game, open Options, go to the AddOns tab and click `Open AddOns Folder`.
2. Copy the `SurvivorsBuilds`, `SurvivorsUI` and `SurvivorsGuardians` folders into it.
3. Enable them in the AddOns list. They load at your next run.

## Known limits

- The run timer, the kill and gold counters, the damage meter and the native spell icon row are drawn by the game engine. Addons cannot move or hide them.
- The game only reveals a guardian on the map once you get close, so the first run on a map fills the list as you explore.
- The boss countdown is estimated from combat activity, since the game timer is not readable from Lua. Expect a few seconds of drift until the first boss appears.
- To read the level and health of distant guardians, the tracker targets each one for a fraction of a second, at most every 30 seconds, then restores your target.

## Notes for developers

`NOTES.md` (in French) documents what the game exposes to addons, how to run an isolated test instance, and how each addon works internally.

## Disclaimer

Unofficial fan project, not affiliated with Azeroth Survivors or with Blizzard Entertainment.
