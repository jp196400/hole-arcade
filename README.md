# Hole Arcade

A Godot 4.3 hole.io-style game. Steer with a floating joystick, swallow what fits when the hole is under it, and clear 10 themed maps. Coins, upgrades, and 15 hole skins are saved on the device. The game opens on the live level. Tap or drag to start. Ads and Remove Ads are test placeholders, with no ad account and no charge.

Play it at https://jp196400.github.io/hole-arcade/

The bottom-left corner shows the build id (the first 7 characters of the commit). The same id is under the timer. The page loads `index.js`, `index.wasm`, and `index.pck` with `?v=<commit>` so a refresh cannot keep an older pack. The Web preset exports with thread support off. On phones the canvas stays at CSS pixels (`devicePixelRatio` 1). The 3D view renders at full viewport scale with 2x MSAA. Add `?debug=1` for FPS and draw calls, `?speed=0.5` to scale movement, or `?unlockall=1` to open every level and skin.

Only Downtown is open at first. Clearing a level unlocks the next one and can award 1–3 stars. The maps are Downtown, Suburbs, Park, Boardwalk, Farm, Harbor, Campus, Fairground, Industrial, and Skyline, each with its own layout and sky. Cyan is the only skin that starts unlocked. The next skins are spaced across rounds played, objects eaten, levels cleared, stars, and escalating coin prices. A locked skin can be tried for one round after a rewarded ad. A save from an older build keeps skins it already had. Add `?unlockall=1` to open every level and skin.

`FIRST_AD_SECONDS` is 120: the first interstitial waits until two minutes of cumulative play, then pauses the round. Placeholder interstitials show Skip after `SKIP_AFTER_SECONDS` (5). A later AdMob build would let the ad network time that skip. After the first round, a skippable interstitial can appear between rounds on a 2-then-3 round cadence, and never sooner than 90 seconds after any ad. Rewarded placeholders must finish to pay out; the X forfeits. Those offers are: watch an ad for 2x coins, watch an ad to keep going once per round after being eaten, try a locked skin, and double the daily reward. There is no banner during play. Remove Ads is a stub priced with `REMOVE_ADS_PRICE` at $2.99. It turns off interstitials only.

Buildings, roads, cars, people, and trees are [Kenney](https://kenney.nl) CC0 models (City Kit roads, commercial, and suburban, Car Kit, Mini Characters, Nature Kit). Smaller props are original low-poly meshes. See `assets/kenney/LICENSE.txt`. The music loop is "Level 1" from Juhani Junkala's Retro Game Music Pack, CC0, via [OpenGameArt](https://opengameart.org/content/5-chiptunes-action) (`assets/music/LICENSE.txt`). Sound effects are original. The HUD uses [Fredoka](https://fonts.google.com/specimen/Fredoka) under the SIL Open Font License (`assets/fonts/OFL.txt`).

Open the project in Godot 4.3 and run `main.tscn`. Pushes to `main` export the Web preset and deploy `build/web` to GitHub Pages.
