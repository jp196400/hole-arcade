# Hole Arcade

A Godot 4.3 hole.io-style game. Steer with a floating joystick, swallow what fits when the hole is under it, and clear 10 city maps. Coins, upgrades, and 15 hole skins are saved on the device. Ads and Remove Ads are placeholders.

Play it at https://jp196400.github.io/hole-arcade/

The bottom-left corner shows the build id (the first 7 characters of the commit). The same id is under the timer. The page loads `index.js`, `index.wasm`, and `index.pck` with `?v=<commit>` so a refresh cannot keep an older pack. The Web preset exports with thread support off. On phones the canvas stays at CSS pixels (`devicePixelRatio` 1). The 3D view renders at full viewport scale with 2x MSAA. Add `?debug=1` for FPS and draw calls, `?speed=0.5` to scale movement, or `?unlockall=1` to open every level and skin.

Only Downtown is open at first. Clearing a level unlocks the next one. Cyan is the only skin that starts unlocked. The others unlock by clearing levels, eating objects, reaching a size, or spending coins. A save from an older build keeps skins it already had.

Buildings, roads, cars, people, and trees are [Kenney](https://kenney.nl) CC0 models (City Kit roads, commercial, and suburban, Car Kit, Mini Characters, Nature Kit). Those packs have no benches; construction barriers and planters are the street furniture. See `assets/kenney/LICENSE.txt`. The HUD uses [Fredoka](https://fonts.google.com/specimen/Fredoka) under the SIL Open Font License (`assets/fonts/OFL.txt`).

Open the project in Godot 4.3 and run `main.tscn`. Pushes to `main` export the Web preset and deploy `build/web` to GitHub Pages.
