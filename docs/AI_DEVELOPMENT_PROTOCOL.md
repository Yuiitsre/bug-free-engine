# Lyrenthos AI Development Protocol

## Purpose
This repository is the implementation source for Lyrenthos. Future coding agents must extend the existing architecture instead of replacing it with disconnected prototypes.

## Non-negotiable rules
1. Do not copy Minecraft source, assets, extracted data, sounds, models, animations or UI.
2. Study Minecraft only for high-level gameplay behavior and player expectations.
3. Prefer data-driven definitions over hard-coded gameplay constants.
4. Keep world generation deterministic: same seed + same generator version = same unmodified world.
5. Keep player edits separate from generated terrain.
6. Never use the rendered scene as the authoritative world database.
7. All major systems need save/load behavior and deterministic tests before being expanded.
8. Avoid per-frame iteration over large entity or machine collections.
9. Use asynchronous generation for expensive world work, but commit scene-tree changes on the main thread unless a specific API is documented thread-safe.
10. Every new feature must state its performance budget.

## Phase gates

### Phase 1 — Genesis
- procedural world foundation
- five prototype biome identities
- landmark structures
- movement/input
- inventory shell
- deterministic seed

### Phase 2 — Living World
- real chunk mesh
- water and rivers
- vegetation
- animals
- day/night
- weather
- persistence

### Phase 3 — Survival
- blocks
- tools
- gathering
- inventory grid
- crafting
- food
- health/stamina
- first hostile mobs

### Phase 4 — Industry
- machines
- power
- fluid networks
- item logistics
- automation signals
- rail transport

### Phase 5 — Magic and Dimensions
- arcane system
- portals
- multiple dimensions
- dimension-specific resources
- bosses

### Phase 6 — World Simulation
- settlements
- NPC schedules
- economy
- seasons
- migration
- world events

### Phase 7 — Multiplayer
- authoritative server
- replication
- persistence
- anti-cheat validation

## Task contract
Every AI task should have:
- SYSTEM
- GOAL
- INPUT DATA
- RUNTIME DATA
- SAVE DATA
- NETWORK AUTHORITY
- PERFORMANCE BUDGET
- TESTS
- ACCEPTANCE CRITERIA

## Visual quality
Lyrenthos should use a consistent premium fantasy-sandbox style:
- strong silhouettes
- material readability
- restrained emissive effects
- varied but coherent roughness
- atmospheric depth
- handcrafted hero landmarks
- original prop language
- no generic AI-looking collage aesthetics

## Current Phase 1 acceptance
A fresh clone with Godot 4.x available should open the project and expose:
- procedural terrain
- biome variation
- three visible structures
- third-person movement
- sprint
- jump
- Tab inventory
- reproducible seed

The prototype is intentionally temporary. Phase 2 replaces the column renderer with a production chunk mesh and introduces proper world streaming.
