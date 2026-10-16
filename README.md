# Hole Arcade

A Godot 4.3 hole.io-style game. Steer with a floating joystick, swallow anything that fits, and level up before the two-minute timer ends.

Play it at https://jp196400.github.io/hole-arcade/

The bottom-left corner shows the build id (the first 7 characters of the commit). The same id is drawn in the game under the timer. Both should match. The page loads `index.js`, `index.wasm`, and `index.pck` with `?v=<commit>` so Safari cannot keep an older pack. The Web preset exports with thread support off, so the build does not need `SharedArrayBuffer`. On phones the canvas stays at CSS pixels. Add `?debug=1` for FPS and draw calls, or `?speed=0.5` to scale movement.

Open the project in Godot 4.3 and run `main.tscn`. Pushes to `main` install Godot 4.3, export the Web preset, and deploy `build/web` to GitHub Pages.
