# Hole Arcade

A Godot 4.3 hole.io-style prototype. Drag the hole to swallow anything smaller than you and grow before the 90-second timer runs out. Tap after the round to play again.

Play it at https://jp196400.github.io/hole-arcade/

The Web preset exports with thread support off, so the build does not need `SharedArrayBuffer` or cross-origin isolation headers. That is what keeps it running on GitHub Pages and on phone browsers. The hole eases toward your finger instead of jumping to each touch sample. On phones the canvas stays at CSS pixels (not the full device pixel ratio), which is what keeps WebGL from filling a 3x iPhone framebuffer. Add `?debug=1` to the page URL to show FPS, frame time, physics time, draw calls, and active bodies.

Open the project in Godot 4.3 and run `main.tscn`. Pushes to `main` install Godot 4.3 headless plus the matching export templates, export the Web preset, and deploy `build/web` to GitHub Pages.
