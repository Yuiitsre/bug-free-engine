from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import venv
from pathlib import Path

REQUIRED = [
    "project.godot",
    "scenes/main.tscn",
    "scripts/main.gd",
    "data/biomes/biomes.json",
]

ROOT = Path(__file__).resolve().parents[1]
REQUIREMENTS = ROOT / "requirements.txt"
VENV = ROOT / ".venv"


def run(command: list[str], cwd: Path | None = None) -> None:
    print("\n>", " ".join(map(str, command)))
    subprocess.check_call(command, cwd=str(cwd or ROOT))


def venv_python() -> Path:
    if os.name == "nt":
        return VENV / "Scripts" / "python.exe"
    return VENV / "bin" / "python"


def setup_venv() -> None:
    py = venv_python()
    if not py.exists():
        print("[LYRENTHOS] Creating local Python environment...")
        venv.EnvBuilder(with_pip=True, clear=False, upgrade_deps=True).create(VENV)

    print("[LYRENTHOS] Installing/repairing Python modules...")
    run([str(py), "-m", "pip", "install", "--upgrade", "pip"])
    run([str(py), "-m", "pip", "install", "--prefer-binary", "-r", str(REQUIREMENTS)])

    print("[LYRENTHOS] Python environment ready:")
    print(py)


def validate_project() -> None:
    missing = [p for p in REQUIRED if not (ROOT / p).exists()]
    if missing:
        print("[ERROR] Missing required project files:")
        for item in missing:
            print("  -", item)
        raise SystemExit(2)

    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    if 'run/main_scene="res://scenes/main.tscn"' not in project_text:
        print("[ERROR] project.godot does not point at scenes/main.tscn")
        raise SystemExit(3)

    print("[LYRENTHOS] Project structure validated.")


def build_phase1_data() -> None:
    py = venv_python()
    generator = ROOT / "tools" / "generate_phase1_content.py"
    if not generator.exists():
        raise SystemExit("[ERROR] tools/generate_phase1_content.py is missing.")

    run([str(py), str(generator)], cwd=ROOT)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=ROOT)
    parser.add_argument("--setup", action="store_true")
    parser.add_argument("--build", action="store_true")
    args = parser.parse_args()

    os.chdir(args.project_root.resolve())

    if args.setup:
        setup_venv()

    if args.build:
        validate_project()
        setup_venv()
        build_phase1_data()

        from rich.console import Console
        from rich.panel import Panel

        console = Console()
        console.print(Panel.fit(
            "LYRENTHOS Phase 1\n"
            "World data generated and project validated.\n"
            "Godot can now launch the project.",
            title="READY",
            border_style="cyan",
        ))


if __name__ == "__main__":
    main()
