# AS Companion

Build planner and launcher for Azeroth Survivors. It edits your builds, starts the game, reads the level-up cards and advises or picks the best one.

## Start

1. Put the `AS-Companion` folder next to `AzerothSurvivors.exe`.
2. Run `Start-Companion.cmd`. The builder opens in your browser at http://localhost:47821/.
3. Create a build for your class: talents, spell priorities, jewelry, rules.
4. Click **Launch game**.

## Builder

- **Talents**: the three trees of the class, 51 points, milestones and capstone.
- **Spells**: priority order with a weight, banned spells. The first 6 are targets, the rest fallbacks.
- **Jewelry**: target and fallback rings, trinkets and amulets, including the legendary amulet of each spell.
- **Rules**: rarity weight, rerolls kept in reserve, banishes, reroll before skipping, level from which fallback rings and trinkets are accepted, legendary boost, adapt to the run.
- **Options**: game path, language, card auto-pick, overlay.
- **Sharing**: Export and Import a build as one line of text.

## In game

The companion reads the cards the game prints on its console, so the game must be started with **Launch game**. A topmost banner shows the advice. With auto-pick on, the keys 1, 2, 3 and R are sent to the game window. Skip and banish have no key and stay manual.

At launch the companion also writes the active builds into the SurvivorsBuilds addon saved variables: the in-game Builds tab and the guide panel show them during the run.

Builds are stored in `state.json`, the log in `companion.log`.
