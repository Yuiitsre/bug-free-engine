from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from rich.console import Console
from rich.progress import track

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
BIOMES = DATA / "biomes"
GENERATED = DATA / "generated"
BIOMES.mkdir(parents=True, exist_ok=True)
GENERATED.mkdir(parents=True, exist_ok=True)

console = Console()

# Phase 1 is intentionally broad enough to make the world feel like
# a real environment, but only the first eight are required by the
# current runtime classifier.

BIOME_DEFS = [
    ("meadow", "Emerald Meadow", "temperate", "#4d8a61", ["deer", "hare", "sheep"]),
    ("forest", "Silverpine Forest", "boreal", "#2f5847", ["elk", "fox", "wolf"]),
    ("wetland", "Mistfen", "wetland", "#42695d", ["frog", "heron", "otter"]),
    ("highland", "Cloudstep Highlands", "alpine", "#6d7d87", ["goat", "eagle", "marmot"]),
    ("desert", "Redglass Expanse", "arid", "#a36c49", ["fox", "vulture", "lizard"]),
    ("coast", "Bluewind Coast", "coastal", "#4c7a70", ["crab", "seal", "gull"]),
    ("arcane", "Starfall Basin", "arcane", "#526a9b", ["crystal_moth", "owl", "stag"]),
    ("frost", "Frostpine Reach", "snow", "#7f98a8", ["wolf", "hare", "mountain_goat"]),

    ("mosswood", "Mosswood", "temperate", "#436b50", ["boar", "deer", "owl"]),
    ("red_canyon", "Red Canyon", "arid", "#8e503b", ["ibex", "vulture", "lizard"]),
    ("moonlit_grove", "Moonlit Grove", "arcane", "#536b79", ["white_deer", "owl", "fox"]),
    ("storm_coast", "Storm Coast", "coastal", "#3e5d67", ["seal", "gull", "otter"]),
]

structures = [
    {"id": "village_meadow", "name": "Meadow Village", "family": "settlement", "biomes": ["meadow", "mosswood"]},
    {"id": "silverpine_watch", "name": "Silverpine Watch", "family": "outpost", "biomes": ["forest", "frost"]},
    {"id": "mistfen_mill", "name": "Mistfen Mill", "family": "industry", "biomes": ["wetland", "coast"]},
    {"id": "cloudstep_observatory", "name": "Cloudstep Observatory", "family": "landmark", "biomes": ["highland", "arcane"]},
    {"id": "redglass_waystation", "name": "Redglass Waystation", "family": "travel", "biomes": ["desert", "red_canyon"]},
    {"id": "starfall_shrine", "name": "Starfall Shrine", "family": "arcane", "biomes": ["arcane", "moonlit_grove"]},
    {"id": "frozen_camp", "name": "Frozen Expedition Camp", "family": "outpost", "biomes": ["frost", "highland"]},
    {"id": "storm_lighthouse", "name": "Storm Lighthouse Ruin", "family": "ruin", "biomes": ["coast", "storm_coast"]},
    {"id": "mosswood_bridge", "name": "Mosswood Arch Bridge", "family": "transport", "biomes": ["mosswood", "forest"]},
    {"id": "river_forge", "name": "River Forge", "family": "industry", "biomes": ["meadow", "wetland"]},
    {"id": "ancient_ring", "name": "Ancient Ring", "family": "ruin", "biomes": ["arcane", "red_canyon"]},
    {"id": "sky_survey_post", "name": "Sky Survey Post", "family": "landmark", "biomes": ["highland", "frost"]},
]

payload = []

for biome_id, name, family, color, wildlife in track(BIOME_DEFS, description="Writing biome definitions"):
    record = {
        "id": biome_id,
        "name": name,
        "family": family,
        "color": color,
        "phase": 1,
        "wildlife": wildlife,
        "active": biome_id in {b[0] for b in BIOME_DEFS[:8]},
    }
    payload.append(record)
    (BIOMES / f"{biome_id}.json").write_text(
        json.dumps(record, indent=2) + "\n",
        encoding="utf-8",
    )

(BIOMES / "biomes.json").write_text(
    json.dumps(payload[:8], indent=2) + "\n",
    encoding="utf-8",
)

(GENERATED / "structures.json").write_text(
    json.dumps(structures, indent=2) + "\n",
    encoding="utf-8",
)

# Use NumPy for deterministic Phase 1 climate-distribution diagnostics.
rng = np.random.default_rng(418231)
samples = rng.normal(loc=0.0, scale=1.0, size=(128, 128))
samples = np.clip(samples, -3.0, 3.0)

report = {
    "seed": 418231,
    "sample_resolution": [128, 128],
    "climate_mean": float(samples.mean()),
    "climate_std": float(samples.std()),
    "biome_count": len(BIOME_DEFS),
    "active_phase1_biomes": 8,
    "structure_count": len(structures),
}

(GENERATED / "phase1_generation_report.json").write_text(
    json.dumps(report, indent=2) + "\n",
    encoding="utf-8",
)

console.print("[bold cyan]Lyrenthos Phase 1 content generation complete.[/bold cyan]")
console.print(f"Biomes: {len(BIOME_DEFS)}")
console.print(f"Structures: {len(structures)}")
console.print(f"Report: {GENERATED / 'phase1_generation_report.json'}")
