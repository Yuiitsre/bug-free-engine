# Lyrenthos

## Phase 1 — Insular Genesis

This repository now contains the first real playable Lyrenthos world slice.

### Launch

Run:

`run_game.bat`

The launcher checks the Godot installation shown in the current development environment:

`C:\\Users\\shukl\\Downloads\\Compressed`

Expected executable:

`Godot_v4.7.2-stable_win64.exe`

### Controls

- WASD — move
- Mouse — camera
- Shift — sprint
- Space — jump
- Tab — inventory
- Esc — close overlays / release mouse
- E — interaction hook

### Phase 1 systems

- deterministic procedural world
- chunked ArrayMesh terrain
- terrain collision
- eight biomes
- water channels
- vegetation MultiMesh
- landmark structures
- title screen
- inventory shell
- settings panel
- day/night clock
- HUD

### Python tooling

`tools/generate_phase1_data.py` generates the biome data files in `data/biomes/`.

### Important

Lyrenthos is an original project. Minecraft may be used only as a high-level gameplay reference. Do not copy proprietary Minecraft code, textures, models, sounds, animations, UI art, extracted data or branding.
