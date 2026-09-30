# Lyrenthos — Phase 1 Updated: Insular Genesis

Phase 1 is now the first actual playable vertical slice.

## What is in this version

### Boot / launcher
- `run_game.bat` uses the exact Godot 4.7.2 Windows path shown for this machine:
  `C:\\Users\\shukl\\Downloads\\Compressed\\Godot_v4.7.2-stable_win64.exe`
- falls back to the console build or a Godot executable on PATH
- launches the game directly, not the editor

### World
- deterministic seed: `418231`
- 25 initial chunks around the player
- one ArrayMesh terrain surface per chunk
- generated triangle collision per chunk
- multi-scale elevation
- climate and moisture fields
- procedural river channels and lowlands
- water surface generation
- eight biome identities
- deterministic foliage distribution
- MultiMesh forest dressing
- four landmark families

### Biomes
1. Emerald Meadow
2. Silverpine Forest
3. Mistfen
4. Cloudstep Highlands
5. Redglass Expanse
6. Bluewind Coast
7. Starfall Basin
8. Frostpine Reach

### Landmarks
- meadow village
- circular observatory
- river mill
- ancient ruin

### Player
- third-person controller
- mouse camera
- spring-arm camera collision
- WASD movement
- Shift sprint
- Space jump
- Tab inventory
- Esc overlay close / mouse release

### UI
- title screen
- Enter Lyrenthos
- Settings
- Quit
- gameplay HUD
- biome display
- coordinates
- day/time state
- inventory shell with 36 slots

### Simulation
- 24-minute default day
- day/night state
- moving sun
- dynamic lighting energy

## Visual direction

Lyrenthos is a **3D fantasy survival sandbox / exploration game** with a premium stylized-realistic presentation.

The important distinction from Minecraft is architectural and visual:

- Lyrenthos terrain is represented by continuous chunk meshes rather than thousands of visible cube nodes.
- Biomes are driven by environmental fields rather than a list of disconnected random themes.
- Structures are landmark silhouettes with authored composition.
- Materials are procedural and restrained.
- Emissive accents are used as navigation/readability elements rather than covering every asset.
- The camera, UI and world framing are designed as one product.

No Minecraft source code or extracted Minecraft assets are used.

## Phase 1 architecture

`world generation -> chunk mesh -> collision -> scenery -> player -> camera -> UI`

World generation remains deterministic. Rendering is not the source of truth.

The next phases must preserve:
- stable world seed
- stable generator version
- data-driven content
- separate persistent player edits
- bounded runtime work

## Phase 2 target

The next implementation step is not to add hundreds of random features. It is to make the world editable and persistent:

1. true voxel/block storage
2. chunk streaming as the player moves
3. break/place interaction
4. item definitions
5. tools
6. inventory stack/count logic
7. water behavior
8. real vegetation assets
9. wildlife
10. first night hostile set
11. save/load modified chunks

After that foundation is stable, machines, magic and dimensions can be layered on top.
