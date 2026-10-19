"""Re-evaluate living-background preservation against the retained baseline.

No engine is launched. Canonical inventories come from release_provenance.ps1;
all source blocks, assets, and archive bytes are independently read again here.
"""
from pathlib import Path
import datetime as dt
import hashlib
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "evidence/background_rebuild"
PROJECT = ROOT / "Game File"
BASE_PROJECT = OUT / "baseline/Game File"


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def sha(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def block_sha(block):
    return hashlib.sha256(block).hexdigest().upper()


def function(raw, name):
    match = re.search(rb"^func " + name.encode() + rb"\(.*?(?=^func |\Z)", raw, re.M | re.S)
    if not match:
        raise ValueError(f"Missing function {name}")
    return match.group(0).rstrip(b"\r\n")


def collision(raw):
    match = re.search(rb"\bplatforms = \[.*?\]", function(raw, "_ready"), re.S)
    if not match:
        raise ValueError("Missing authoritative platforms dictionary")
    return match.group(0)


def inventory(project):
    # Dot-source the repository's canonical inventory/hash implementation, rather
    # than approximate PowerShell's path sorting and compact JSON serialization.
    def quote(value):
        return "'" + str(value).replace("'", "''") + "'"
    script = ". " + quote(ROOT / "tools/validation/release_provenance.ps1")
    script += "; Get-ReleaseRuntimeInventory " + quote(project)
    script += " | ConvertTo-Json -Depth 8 -Compress"
    powershell = shutil.which("pwsh")
    if powershell is None:
        raise RuntimeError("PowerShell 7 is required to match the source gate's canonical inventory")
    process = subprocess.run([powershell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script],
                             check=True, capture_output=True, encoding="utf-8-sig")
    return json.loads(process.stdout)


def shader_code(path):
    code = path.read_text(encoding="utf-8-sig")
    code = re.sub(r"/\*.*?\*/", "", code, flags=re.S)
    return re.sub(r"//[^\n]*", "", code)


def main():
    previous = OUT / "preservation.json"
    archived = OUT / "preservation_first_reboot.json"
    if previous.exists() and not archived.exists():
        shutil.copy2(previous, archived)
    old = read_json(archived)
    baseline = read_json(OUT / "baseline.json")
    gate = read_json(ROOT / "evidence/validation_all.json")
    runtime = inventory(PROJECT)
    baseline_runtime = inventory(BASE_PROJECT)
    runtime_matches_gate = runtime == gate["runtime"]
    if not (runtime_matches_gate and gate["passed"] and gate["runtime_unchanged_during_validation"]):
        raise ValueError("Current canonical source inventory is not covered by the fresh passing gate")

    checks = []
    def check(name, passed, detail=None):
        checks.append({"name": name, "passed": bool(passed), "detail": detail})

    arenas = []
    for previous_arena in old["arenas"]:
        relative = previous_arena["path"]
        before = (BASE_PROJECT / relative).read_bytes()
        after = (PROJECT / relative).read_bytes()
        same_collision = collision(before) == collision(after)
        check(previous_arena["arena"] + " collision dictionary unchanged", same_collision,
              {"baseline_sha256": block_sha(collision(before)), "current_sha256": block_sha(collision(after)),
               "comparison": "Exact source bytes of complete platforms assignment"})
        builders = []
        for previous_builder in previous_arena["visual_platform_and_hazard_builders"]:
            name = previous_builder["function"]
            first = function(before, name)
            current = function(after, name)
            same = first == current
            record = {"function": name, "unchanged": same, "baseline_sha256": block_sha(first),
                      "current_sha256": block_sha(current)}
            builders.append(record)
            check(previous_arena["arena"] + " " + name + " preserved", same, record)
        arenas.append({"arena": previous_arena["arena"], "path": relative,
                       "baseline_file_sha256": sha(BASE_PROJECT / relative),
                       "current_file_sha256": sha(PROJECT / relative),
                       "collision_dictionary_unchanged": same_collision,
                       "visual_platform_and_hazard_builders": builders})

    inherited = "stages/rooftop_riot/stage_controller.gd"
    before = (BASE_PROJECT / inherited).read_bytes()
    after = (PROJECT / inherited).read_bytes()
    for name in ["main_bounds", "support", "solve_motion", "hazard_contacts", "is_hazard_warning_at", "react",
                 "reset_cosmetics", "break_nearby_decoration", "break_nearby_sign"]:
        first = function(before, name)
        current = function(after, name)
        check("Inherited authoritative stage " + name + " unchanged", first == current,
              {"baseline_sha256": block_sha(first), "current_sha256": block_sha(current),
               "comparison": "Exact function bytes, excluding separator newlines"})

    original_step = function(before, "step")
    current_step = function(after, "step")
    prefix_end = b'\treaction = move_toward(reaction, 0.0, 0.025)'
    prefix = lambda text: text[:text.index(prefix_end) + len(prefix_end)]
    check("Inherited tick, sunset and reaction clock unchanged", prefix(original_step) == prefix(current_step),
          {"comparison": "Exact step prefix through authoritative reaction decay"})
    start = b"\tfor entry in reactive_materials:"
    schedule = lambda text: text[text.index(start):]
    check("Inherited lift position, random hazard scheduling, warning and active phases unchanged",
          schedule(original_step) == schedule(current_step),
          {"baseline_sha256": block_sha(schedule(original_step)), "current_sha256": block_sha(schedule(current_step))})
    first_reset = function(before, "reset_match")
    current_reset = function(after, "reset_match")
    extra = b"\n\t_animate_rooftop()"
    check("Inherited match reset unchanged except added presentation clock refresh",
          current_reset.endswith(extra) and current_reset[:-len(extra)] == first_reset,
          {"permitted_added_statement": "_animate_rooftop()"})
    for name in ["preset", "seed_value", "tick", "hazard_side", "hazard_phase", "hazard_cycle", "event_rng"]:
        declaration = lambda text: re.search(rb"^var " + name.encode() + rb"(?:\s|:).*?$", text, re.M).group(0)
        check("Inherited state default " + name + " unchanged", declaration(before) == declaration(after),
              {"declaration": declaration(after).decode("utf-8")})

    normalize = lambda records: sorted([{"path": r["path"].replace("\\", "/"), "bytes": r["bytes"],
                                        "sha256": r["sha256"].upper()} for r in records], key=lambda r: r["path"].casefold())
    baseline_matches = (baseline_runtime["sha256"] == baseline["runtime"]["sha256"] and
                        normalize(baseline_runtime["files"]) == normalize(baseline["runtime"]["files"]))
    check("Baseline runtime copy matches its recorded inventory", baseline_matches,
          {"actual_sha256": baseline_runtime["sha256"], "expected_sha256": baseline["runtime"]["sha256"]})
    originals = {r["path"]: r for r in baseline_runtime["files"]}
    current = {r["path"]: r for r in runtime["files"]}
    missing = sorted(set(originals) - set(current))
    changed = [{"path": path, "baseline_sha256": originals[path]["sha256"],
                "current_sha256": record["sha256"], "bytes": record["bytes"]}
               for path, record in current.items() if path in originals and record != originals[path]]
    new = [record for path, record in current.items() if path not in originals]
    check("No preserved runtime files deleted", not missing, missing)
    check("Existing runtime modifications confined to stages presentation",
          all(r["path"].startswith("stages/") and Path(r["path"]).suffix in [".gd", ".gdshader"] for r in changed),
          [r["path"] for r in changed])
    check("New runtime content confined to stage presentation",
          all(r["path"].startswith("stages/") and Path(r["path"]).suffix in [".gd", ".gdshader", ".uid"] for r in new),
          [r["path"] for r in new])

    supplied = []
    manifest = read_json(OUT / "baseline/docs/asset_manifest.json")
    source_entries = {}
    for entry in manifest:
        key = entry["source_path"]
        if key in source_entries and entry["source_sha256"].upper() != source_entries[key]["source_sha256"].upper():
            raise ValueError("Baseline source manifest contains conflicting source hashes")
        source_entries[key] = entry
    for entry in sorted(source_entries.values(), key=lambda row: row["source_path"]):
        relative = entry["source_path"].replace("\\", "/")
        actual = sha(ROOT / relative)
        expected = entry["source_sha256"].upper()
        record = {"path": relative, "expected_sha256": expected, "actual_sha256": actual, "preserved": expected == actual}
        supplied.append(record)
        check("Supplied original preserved " + relative, expected == actual, record)

    curated = []
    character_release = read_json(ROOT / "evidence/characters/hero_rebuild/release_assets.json")
    historical_curated = {row["fighter"]: row for row in old["curated_character_sources"]}
    for entry in character_release["fighters"]:
        relative = "source_art/characters/" + entry["fighter"] + "/curated.blend"
        actual = sha(ROOT / relative)
        expected = entry["curated_sha256"].upper()
        historical_expected = historical_curated[entry["fighter"]]["expected_sha256"].upper()
        preserved = expected == actual == historical_expected
        record = {"fighter": entry["fighter"], "path": relative, "expected_sha256": expected,
                  "actual_sha256": actual, "historical_expected_sha256": historical_expected, "preserved": preserved}
        curated.append(record)
        check("Curated editable character art preserved " + entry["fighter"], preserved, record)
    archive = Path(baseline["previous_archive"])
    archive_sha = sha(archive)
    archive_bytes = archive.stat().st_size
    archive_preserved = archive_sha == baseline["previous_archive_sha256"] and archive_bytes == baseline["previous_archive_bytes"]
    prior_archive = {"path": str(archive), "bytes": archive_bytes, "sha256": archive_sha, "preserved": archive_preserved}
    check("Previously delivered Windows archive preserved", archive_preserved, prior_archive)

    shrine = (PROJECT / "stages/verdant_shrine/verdant_shrine_stage.gd").read_bytes()
    backdrop = shader_code(PROJECT / "stages/verdant_shrine/shrine_backdrop.gdshader")
    shared = shader_code(PROJECT / "stages/arena_backdrop.gd")
    ribbons = []
    for values in re.findall(r"cascade\(uv,vec2\(([\d.]+),([\d.]+)\),vec2\(([\d.]+),([\d.]+)\),([\d.]+),([\d.]+)\)", backdrop):
        x0, y0, x1, y1, width0, width1 = map(float, values)
        ribbons.append({"start": [x0, y0], "end": [x1, y1], "width_top": width0, "width_bottom": width1})
    check("Shrine flow clock comes from stage tick / 60",
          b"_animate_scene(tick/60.0)" in function(shrine, "step") and
          b'material.set_shader_parameter("scene_time",seconds)' in function(shrine, "_animate_scene"))
    check("Shrine reset explicitly restores time zero", b"_animate_scene(0.0)" in function(shrine, "reset_match"))
    localization = ("vec2 uv = UV+parallax_offset;" in backdrop and "texture(panorama,uv)" in backdrop and
                    "cascade(uv," in backdrop and "vec2 coordinates = uv;" in backdrop and
                    "falls *= water_color;" in backdrop and "flow_coordinates = uv*vec2(610.0,46.0)-vec2(0.0,scene_time*4.4);" in backdrop and
                    len(ribbons) == 4 and all(r["end"][1] > r["start"][1] and r["width_top"] > 0 and r["width_bottom"] > 0 for r in ribbons))
    check("Shrine artwork uses identical parallax coordinates for sampling and cascade masks", localization,
          {"shader_sha256": sha(PROJECT / "stages/verdant_shrine/shrine_backdrop.gdshader"),
           "downstream": "Features of falling_water(p) advance toward increasing UV.y because p.y=46*uv.y-4.4*scene_time. Irregular long ribbons avoid the old repeated horizontal carrier.",
           "localized": "Four positive-downstream cascade ribbons gated by original white/blue water color; displacement multiplied by falls. Foliage/lagoon have separate local masks."})
    check("Shared backdrop writes parallax only when shader declares uniform",
          'if framed_shader != material_override.shader:' in shared and 'parallax_available = false' in shared and
          'if uniform.name == "parallax_offset": parallax_available = true' in shared and
          'if parallax_available:' in shared and 'set_shader_parameter("parallax_offset"' in shared)
    low_flow = ("float flow = falling_water(flow_coordinates);" in backdrop and
                "float fine_flow = low_quality ? flow : falling_water(" in backdrop and
                "color *= 1.0+(mix(flow,fine_flow,0.35)-0.5)*0.20*falls;" in backdrop and
                b'_animate_scene(tick/60.0)' in function(shrine, "apply_quality") and
                b'(graphics_quality != "Low" or i < 3)' in function(shrine, "_animate_scene"))
    check("Essential Shrine flow survives Low", low_flow,
          {"flow": "Base advected ribbons computed on both tiers; Low skips only extra fine field, retains water refraction/highlights, lagoon ripples, spray/mist, reduced foliage sway and three birds."})
    checked_shaders = ["stages/verdant_shrine/shrine_backdrop.gdshader", "stages/verdant_shrine/jungle_leaf.gdshader",
                       "stages/verdant_shrine/atmosphere.gdshader", "stages/verdant_shrine/valley_bird.gdshader",
                       "stages/lunar_reach/earth.gdshader"]
    no_time = all(not re.search(r"\bTIME\b", shader_code(PROJECT / path)) for path in checked_shaders)
    check("New Shrine and lunar ambience does not use free-running shader TIME", no_time,
          {"files": [{"path": path, "sha256": sha(PROJECT / path)} for path in checked_shaders],
           "comparison": "Shader code with line/block comments removed"})

    bitmaps = []
    for relative, entry in originals.items():
        if Path(relative).suffix.lower() not in [".png", ".jpg", ".jpeg"]:
            continue
        actual = sha(PROJECT / relative)
        size = (PROJECT / relative).stat().st_size
        bitmaps.append({"path": relative, "bytes": size, "sha256": actual,
                        "preserved": size == entry["bytes"] and actual == entry["sha256"]})
    bitmap_preserved = len(bitmaps) == 106 and all(row["preserved"] for row in bitmaps)
    if len(checks) != 72 or {row["name"] for row in checks} != {row["name"] for row in old["checks"]}:
        missing_checks = sorted({row["name"] for row in old["checks"]} - {row["name"] for row in checks})
        extra_checks = sorted({row["name"] for row in checks} - {row["name"] for row in old["checks"]})
        raise ValueError(f"Expected exact original 72 invariants; actual={len(checks)} missing={missing_checks} extra={extra_checks}")
    flow_metadata = dict(old["shrine_flow_metadata"])
    flow_metadata["cascade_ribbons"] = ribbons
    flow_metadata["downstream_flow"] = {"coordinates": "uv * vec2(610.0,46.0) - vec2(0.0,scene_time*4.4)",
                                        "direction": "Increasing UV.y, matching all cascade end.y > start.y",
                                        "field": "Continuous irregular long ribbons and spray; no repeated horizontal carrier",
                                        "shader_sha256": sha(PROJECT / "stages/verdant_shrine/shrine_backdrop.gdshader")}
    result = {"audited_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
              "passed": all(row["passed"] for row in checks) and bitmap_preserved and runtime_matches_gate,
              "scope": old["scope"], "baseline_path": str(OUT / "baseline.json"),
              "baseline_sha256": sha(OUT / "baseline.json"), "baseline_runtime_sha256": baseline_runtime["sha256"],
              "arenas": arenas, "runtime": runtime, "supplied_originals": supplied,
              "curated_character_sources": curated, "prior_archive": prior_archive,
              "shrine_flow_metadata": flow_metadata, "checks": checks, "limitations": old["limitations"],
              "runtime_diff": {"baseline_file_count": len(originals), "unchanged_file_count": len(originals)-len(changed)-len(missing),
                               "changed_files": changed, "new_files": new, "missing_files": missing},
              "preserved_existing_bitmaps": bitmaps,
              "existing_bitmap_preservation_passed": bitmap_preserved,
              "current_source_gate": {"path": str(ROOT / "evidence/validation_all.json"),
                                      "sha256": sha(ROOT / "evidence/validation_all.json"),
                                      "passed": gate["passed"], "runtime_matches_exactly": runtime_matches_gate,
                                      "finished_utc": gate["finished_utc"]},
              "audit_tool_sha256": sha(Path(__file__)), "previous_receipt": {"path": str(archived), "sha256": sha(archived)}}
    previous.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": result["passed"], "checks": len(checks), "bitmaps": len(bitmaps),
                      "runtime_files": len(runtime["files"]), "runtime_sha256": runtime["sha256"],
                      "failures": [row["name"] for row in checks if not row["passed"]]}))
    if not result["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
