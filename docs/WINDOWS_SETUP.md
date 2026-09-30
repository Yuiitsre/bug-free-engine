# Windows setup

## Normal launch

Double-click:

`run_game.bat`

The launcher:

1. finds `project.godot` recursively, so GitHub ZIP folder names do not matter;
2. locates Godot 4.7.2 from `C:\Users\shukl\Downloads\Compressed`;
3. finds Python 3;
4. creates `.venv`;
5. installs `requirements.txt` automatically;
6. generates Phase 1 data;
7. validates the project;
8. launches Godot using the actual project directory.

## If Python is not installed

Install Python 3.10+ from python.org and enable **Add Python to PATH**.

## If Godot is moved

Edit `GODOT_DIR` at the top of `run_game.bat`.

## Generated files

The Python pipeline creates:

- `data/biomes/*.json`
- `data/generated/structures.json`
- `data/generated/phase1_generation_report.json`

The generated files are deterministic from the Phase 1 world seed.

## Runtime architecture

Python is an offline development/content toolchain. Godot/GDScript remains responsible for real-time gameplay, rendering, physics and input. This keeps the game portable and avoids a Python interpreter inside the shipping runtime.
