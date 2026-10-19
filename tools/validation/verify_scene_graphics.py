"""Verify revision 3 scope and file integrity without running a match."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
BASE = "0ffe149"
PROJECT = ROOT / "Game File"
OUT = ROOT / "evidence/visual_overhaul/scene_revision3"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--release", action="store_true", help="Also verify the exported manifest")
args = parser.parse_args()
checks = []


def check(name, ok, detail=None):
    checks.append({"name": name, "passed": bool(ok), "detail": detail})


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT).decode("utf-8")


def read(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")


def sha(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest().upper()


def functions(text):
    return {m.group(1): m.group(0).strip() for m in re.finditer(
        r"^func (\w+).*?(?=^func |\Z)", text, re.M | re.S)}


changed = set(git("diff", "--name-only", "-z", BASE, "--", "Game File").strip("\0").split("\0"))
changed.update(git("ls-files", "--others", "--exclude-standard", "-z", "--", "Game File").strip("\0").split("\0"))
changed.discard("")
allowed_code = {"Game File/characters/fighter_visual.gd", "Game File/stages/rooftop_riot/stage_controller.gd"}
shader_names = {"pool_water", "hotel_windows", "pyro_flame", "pyro_warning", "terrace_foliage"}
for name in shader_names:
    allowed_code.add(f"Game File/stages/rooftop_riot/{name}.gdshader")
    allowed_code.add(f"Game File/stages/rooftop_riot/{name}.gdshader.uid")
unexpected = sorted(p for p in changed if p not in allowed_code and not p.startswith("Game File/assets/stage/"))
check("Runtime changes confined to scene graphics and fighter lighting", not unexpected, unexpected)

stage_path = "Game File/stages/rooftop_riot/stage_controller.gd"
before = git("show", f"{BASE}:{stage_path}")
after = read(stage_path)
old_functions, new_functions = functions(before), functions(after)
for name in old_functions:
    if name not in {"_ready", "_build_environment", "_prepare_scenery", "step"}:
        check(f"Stage function unchanged: {name}", old_functions[name] == new_functions.get(name))
check("Authoritative platforms and seed unchanged", old_functions["_ready"].split("\t_build_environment()")[0] == new_functions["_ready"].split("\t_build_environment()")[0])
check("Lift, hazard clock, random schedule and phase unchanged", old_functions["step"].split("\tfor i in hazard_warnings.size():")[0] == new_functions["step"].split("\tfor i in hazard_warnings.size():")[0])
check("Stage state defaults unchanged", before.split("func _ready")[0] == after.split("func _ready")[0].replace("var hazard_flames: Array[MeshInstance3D] = []\n", ""))
fighter_path = "Game File/characters/fighter_visual.gd"
old_fighter = functions(git("show", f"{BASE}:{fighter_path}"))
new_fighter = functions(read(fighter_path))
for name, body in old_fighter.items():
    candidate = new_fighter.get(name, "").replace("\t\t_light_character(model)\n", "")
    check(f"Fighter presentation function preserved: {name}", body == candidate)
old_contract = json.loads(git("show", f"{BASE}:evidence/stage/stage_manifest.json"))["coordinate_contract"]
new_contract = json.loads(read("evidence/stage/stage_manifest.json"))["coordinate_contract"]
check("Exported platform coordinate contract unchanged", old_contract == new_contract)
for item in json.loads(read("evidence/preflight/source_hashes.json")):
    check(f"Supplied original preserved: {Path(item['Path']).parent.name}", sha(item["Path"]) == item["Hash"].upper())
art = json.loads(read("source_art/stage/stage_generation.json"))
check("Stage provenance is revision 3", art["revision"] == 3)
for item in art["files"]:
    p = ROOT / item["path"]
    check(f"Art provenance: {item['path']}", p.stat().st_size == item["bytes"] and sha(p) == item["sha256"].upper())
for name in ["gameplay_angle", "pyro_detail", "architecture_detail"]:
    path = OUT / "final" / f"{name}.png"
    size = struct.unpack(">II", path.read_bytes()[16:24])
    check(f"Source preview dimensions: {name}", size == (1920, 1080), size)
for name in ["revision3_final_import.log", "revision3_final_preview.log"]:
    text = read(f"evidence/stage/{name}")
    errors = re.findall(r"^.*(?:SCRIPT ERROR|Parse Error|ERROR:|WARNING:).*$", text, re.M)
    check(f"Clean engine log: {name}", not errors, errors)

package = None
if args.release:
    package = json.loads(read("builds/windows/build_manifest.json"))
    for name in ["exe", "pck"]:
        check(f"Release {name.upper()} hash", sha(ROOT / f"builds/windows/RooftopRiot.{name}") == package[f"{name}_sha256"])
    extensions = {".gd", ".gdshader", ".godot", ".tscn", ".tres", ".glb", ".png", ".wav", ".json"}
    actual = {p.relative_to(PROJECT).as_posix() for p in PROJECT.rglob("*") if p.is_file() and ".godot" not in p.relative_to(PROJECT).parts and p.suffix in extensions and not p.name.startswith("source_") and p.name not in {"validate_input.gd", "engine.png"}}
    recorded = {p["path"] for p in package["runtime_source_files"]}
    check("Export manifest covers current runtime source inventory", actual == recorded, sorted(actual ^ recorded))
    for item in package["runtime_source_files"]:
        path = PROJECT / item["path"]
        check(f"Packaged source: {item['path']}", path.stat().st_size == item["bytes"] and sha(path) == item["sha256"])

result = {"checked_utc": datetime.now(timezone.utc).isoformat(), "baseline_commit": BASE, "scene_revision": 3,
          "scope": "Static preservation and artifact integrity; no match simulated; visual judgement recorded separately",
          "passed": all(c["passed"] for c in checks), "check_count": len(checks), "runtime_changed_paths": sorted(changed),
          "package_timestamp_utc": package["build_timestamp_utc"] if package else None, "checks": checks}
(OUT / ("release_integrity.json" if args.release else "source_integrity.json")).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"passed": result["passed"], "checks": len(checks), "failures": [c for c in checks if not c["passed"]]}))
raise SystemExit(0 if result["passed"] else 1)
