# Lyrenthos

Lyrenthos is a Godot 4.x fantasy survival-sandbox prototype being built as an original game.

## Run on Windows

### Normal

Double-click:

`run_game.bat`

The launcher automatically:

1. finds the actual `project.godot` even when the repository was extracted as `bug-free-engine-main`;
2. finds your Godot 4.7.2 installation;
3. creates a local Python `.venv`;
4. installs required Python modules automatically;
5. generates Phase 1 content;
6. validates the project;
7. starts the game directly.

### Debug

Double-click:

`run_debug.bat`

This uses the Godot console executable so GDScript/runtime errors remain visible in the terminal.

## Your current Godot location

`C:\Users\shukl\Downloads\Compressed\Godot_v4.7.2-stable_win64.exe`

If Godot is moved, edit `GODOT_DIR` in the launcher files.

## Controls

- WASD — move
- Mouse — camera
- Shift — sprint
- Space — jump
- Tab — inventory
- Esc — close overlay / release mouse
- E — interaction hook

## Python toolchain

The repository uses Python for offline development/content tooling, not real-time gameplay.

Required modules are in `requirements.txt` and are installed automatically into:

`.venv`

Current tooling modules:
- NumPy — deterministic procedural data analysis
- Rich — readable generation/validation output

The toolchain generates:
- `data/biomes/*.json`
- `data/generated/structures.json`
- `data/generated/phase1_generation_report.json`

## Phase 1 systems

- deterministic procedural terrain
- chunked ArrayMesh terrain
- terrain collision
- eight active biome identities
- water channels / lowlands
- vegetation MultiMesh
- original landmark structures
- title screen
- HUD
- inventory shell
- settings
- day/night presentation

## Original-game rule

Lyrenthos must remain an original implementation. Minecraft may be studied for broad gameplay behavior only. Do not copy source code, extracted game data, textures, models, sounds, animations, UI art or branding.
