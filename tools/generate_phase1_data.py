from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "biomes"
OUT.mkdir(parents=True, exist_ok=True)

BIOMES = [
    ("meadow", "Emerald Meadow", "temperate", "#4d8a61"),
    ("forest", "Silverpine Forest", "boreal", "#2f5847"),
    ("wetland", "Mistfen", "wetland", "#42695d"),
    ("highland", "Cloudstep Highlands", "alpine", "#6d7d87"),
    ("desert", "Redglass Expanse", "arid", "#a36c49"),
    ("coast", "Bluewind Coast", "coastal", "#4c7a70"),
    ("arcane", "Starfall Basin", "arcane", "#526a9b"),
    ("frost", "Frostpine Reach", "snow", "#7f98a8"),
]

payload = []
for biome_id, name, family, color in BIOMES:
    record = {
        "id": biome_id,
        "name": name,
        "family": family,
        "color": color,
        "phase": 1,
        "status": "prototype_data",
    }
    payload.append(record)
    (OUT / f"{biome_id}.json").write_text(
        json.dumps(record, indent=2) + "\n",
        encoding="utf-8",
    )

(OUT / "biomes.json").write_text(
    json.dumps(payload, indent=2) + "\n",
    encoding="utf-8",
)

print(f"Generated {len(payload)} Lyrenthos biome definitions.")
