from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
out = ROOT / "data" / "biomes"
out.mkdir(parents=True, exist_ok=True)

biomes = [
    {"id":"emerald_meadow","name":"Emerald Meadow","family":"temperate","temperature":0.58,"humidity":0.62},
    {"id":"silverpine","name":"Silverpine","family":"boreal","temperature":0.32,"humidity":0.48},
    {"id":"red_canyon","name":"Red Canyon","family":"arid","temperature":0.72,"humidity":0.18},
    {"id":"mistfen","name":"Mistfen","family":"wetland","temperature":0.55,"humidity":0.92},
    {"id":"starfall_basin","name":"Starfall Basin","family":"arcane","temperature":0.44,"humidity":0.35},
]
for biome in biomes:
    (out / f'{biome["id"]}.json').write_text(json.dumps(biome, indent=2), encoding="utf-8")
print(f"Generated {len(biomes)} biome definitions.")
