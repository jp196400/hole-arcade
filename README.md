# Hole Arcade

A Godot 4.3 hole.io-style game. Steer with a floating joystick, swallow anything that fits, and level up before the two-minute timer ends.

Play it at https://jp196400.github.io/hole-arcade/

The bottom-left corner shows the build id (the first 7 characters of the commit). The same id is under the timer. The page loads `index.js`, `index.wasm`, and `index.pck` with `?v=<commit>` so a refresh cannot keep an older pack. The Web preset exports with thread support off. On phones the canvas stays at CSS pixels. Add `?debug=1` for FPS and draw calls, or `?speed=0.5` to scale movement.

Buildings, roads, cars, people, and trees are [Kenney](https://kenney.nl) CC0 models (City Kit roads, commercial, and suburban, Car Kit, Mini Characters, Nature Kit). Those packs have no benches; construction barriers and planters are the street furniture. See `assets/kenney/LICENSE.txt`.

Open the project in Godot 4.3 and run `main.tscn`. Pushes to `main` export the Web preset and deploy `build/web` to GitHub Pages.
