# Hole Arcade

A Godot 4.3 hole.io-style prototype. Drag the hole to swallow anything smaller than you and grow before the 90-second timer runs out. Tap after the round to play again.

Play it at https://jp196400.github.io/hole-arcade/

The Web preset exports with thread support off, so the build does not need `SharedArrayBuffer` or cross-origin isolation headers. That is what keeps it running on GitHub Pages and on phone browsers. The hole eases toward your finger instead of jumping to each touch sample, and the web build renders with the Compatibility renderer at a reduced 3D resolution so phones stay smoother.

Open the project in Godot 4.3 and run `main.tscn`. Pushes to `main` install Godot 4.3 headless plus the matching export templates, export the Web preset, and deploy `build/web` to GitHub Pages.
