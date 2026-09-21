# odin-engine

A 3D game engine foundation in Odin. It uses `vendor:raylib` for the window, input, and drawing.

## Requirements

* Windows 10 64-bit or newer
* Odin compiler on `PATH`
* MSVC compiler plus Windows SDK
* GPU driver with OpenGL support

## Run the demo

1. Open PowerShell in this folder.
2. If the build fails, install the requirements above first.
3. Run `odin run .` to open the demo window.
4. Press ENTER to leave the menu and play.
5. Close the window to stop the program.

## Controls

* `WASD` or arrow keys move the player.
* `SPACE` jumps. The jump plays a short beep.
* `P` or `ESC` pauses and resumes.

## Stress test

1. Run `odin run . -- --stress=5000` for a scene with 5000 objects.
2. Add `--seed=7` to repeat the same scene.
3. Add `--no-cull` to compare results without frustum culling.
4. Add `--no-instancing` to compare results without instancing.
5. When the window closes, the program writes frame data to `perf.csv`.

## Reference scene

1. Run `odin run . -- --ref=ref_scene.json --stress=10000` to write a fixed scene file.
2. This command writes the file and stops. It opens no window.
3. Load the file in tests to repeat the same scene after each change.

## Tests

1. Run `odin test <package>/` for one package, for example `odin test physics/`.
2. Run each package in the list below to test the full project.
3. If a test fails, it prints the file, the line, and the failed condition.

Tested packages: `app`, `object`, `scene`, `input`, `physics`, `assets`, `audio`, `persist`, `editor`, `render`, `gltf`, `material`, `stress`, `perf`, `cull`, `lod`, `stream`.

## Debug in VSCode

1. Install the extensions that VSCode suggests for this folder.
2. Press F5 and select `Debug game.exe`.
3. The launch task builds `game.exe` before the debugger starts.

## Layout

* `app` runs the window and the fixed-step game loop.
* `game` holds game state, the camera, and the draw code.
* `scene` stores game objects and parent links.
* `object` defines game objects, transforms, and components.
* `stress` builds seeded test scenes.
* `perf` records frame times and writes CSV files.
* `cull` skips objects outside the camera view.
* `render` groups boxes into instanced draw batches.
* `lod` selects full or reduced detail by camera distance.
* `stream` queues asset loads under a memory budget.
* `physics` integrates bodies and finds AABB overlap pairs.
* `assets` loads files from disk behind handles.
* `material` loads the lit shader pair.
* `gltf` reads glTF files through `vendor:cgltf`.
* `audio` holds master, music, and effects gains.
* `persist` saves and loads scenes as JSON.
* `editor` holds the orbit camera and the scene inspector.
* `input` maps keys to game actions.

## Flags

* `--stress=N` spawns N test objects.
* `--seed=N` sets the scene generator seed.
* `--ref=PATH` writes a reference scene file and stops.
* `--no-cull` disables frustum culling.
* `--no-instancing` disables instanced drawing.
