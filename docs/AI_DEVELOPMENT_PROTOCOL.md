# Lyrenthos AI Engineering Protocol

## Repository source of truth

This GitHub repository is the canonical implementation of Lyrenthos.

AI agents must extend the current architecture rather than generating a parallel prototype.

## Current phase gate

### Phase 1 — Insular Genesis
The project must boot into a title screen and launch into a deterministic third-person world containing:
- chunked procedural terrain
- multiple biome identities
- water channels / lowlands
- vegetation
- landmark structures
- movement
- sprint
- jump
- Tab inventory
- day/night presentation

### Phase 2 — Living Editable World
Do not skip this architecture:
- persistent block storage
- editable terrain
- chunk streaming
- rivers/water improvements
- real inventory
- tools
- gathering
- wildlife
- first night monsters
- save/load

### Phase 3 — Survival and Combat
- health/stamina
- food
- crafting
- equipment
- hostile AI
- caves
- loot

### Phase 4 — Industry
- machines
- power
- fluids
- logistics
- signal networks
- rails

### Phase 5 — Magic and Dimensions
- magic
- portals
- multiple dimensions
- bosses

## Engineering rules

1. Do not copy Minecraft source, extracted game data, textures, sounds, models, animations or UI art.
2. Minecraft may only be used as a gameplay-behavior reference.
3. Prefer data-driven definitions.
4. Keep generation deterministic.
5. Separate generated world state from player edits.
6. Never make the rendered scene the authoritative world database.
7. Do not poll thousands of entities or machines every frame.
8. Expensive generation should move to worker threads once the system grows; commit SceneTree changes on the main thread unless the specific API is documented as thread-safe.
9. Every new system must specify save behavior.
10. Every major system must specify multiplayer authority before multiplayer implementation begins.
11. Every feature needs acceptance tests.

## Visual quality rule

Lyrenthos must look like one professionally directed game.

Keep consistent:
- scale
- silhouettes
- material response
- lighting
- UI
- VFX
- animation
- audio

Avoid generic AI-art aesthetics, inconsistent materials, excessive bloom, uncontrolled emissive surfaces and unrelated architectural styles.

## Minecraft study protocol

Allowed:
- study how players understand block interaction
- study broad resource/progression loops
- study why chunk streaming works
- study inventory/crafting ergonomics
- study redstone-like automation as a genre solution

Not allowed:
- decompile and copy proprietary code
- extract and reuse assets
- copy game data
- reuse Minecraft branding

Write Lyrenthos requirements first, then implement an original Godot system.

## Task contract

Each AI implementation task should declare:
- SYSTEM
- GOAL
- INPUT DATA
- OUTPUT DATA
- RUNTIME
- SAVE
- NETWORK
- PERFORMANCE
- TESTS
- ACCEPTANCE

## Current launcher expectation

On Windows, `run_game.bat` is configured around:
`C:\\Users\\shukl\\Downloads\\Compressed\\Godot_v4.7.2-stable_win64.exe`

The launcher must directly start the project.
