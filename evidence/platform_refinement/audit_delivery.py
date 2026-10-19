"""Independent read-only release audit. Run after profiling and packaging finish.

Only final_audit.json is written; no receipt, runtime, build or documentation is
modified. Standard-library-only, with streamed hashing and ZIP decompression.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "Game File"
BUILD = ROOT / "builds/windows"
RUNTIME_SHA = "5D87C1AAB5E7C45183D0AFD7AD941C8BC2456A96F0A1326730F16A60C202B7B0"
OLD_ZIP_SHA = "7DF9A8AA9BCF41CA60A8A4C6244BF31AE07297FAD68E9D6ADACC8D0B0D60C9B3"
OLD_ZIP = ROOT / "builds/RooftopRiot-Five-Arenas-Windows.zip"
NEW_ZIP = ROOT / "builds/RooftopRiot-Platform-Upgrade-Windows.zip"
ARENAS = {"rooftop_riot", "lunar_reach", "verdant_shrine", "abyssal_observatory", "ember_foundry"}
NEW_ARENAS = ARENAS - {"rooftop_riot", "lunar_reach"}
VIEWS = {"high", "low", "overlap", "recovery", "near_ledge"}
EXTENSIONS = {".gd", ".gdshader", ".godot", ".tscn", ".tres", ".glb", ".png", ".jpg", ".jpeg", ".svg", ".wav", ".ogg", ".json", ".import", ".uid", ".cfg"}
TRACKED: dict[Path, str] = {}
CHECKS: list[str] = []


def require(condition, message):
    if not condition:
        raise ValueError(message)


def path(value, base=ROOT):
    result = Path(value)
    return (result if result.is_absolute() else base / result).resolve()


def stream_hash(stream):
    digest = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(chunk)
    return digest.hexdigest().upper()


def file_hash(value):
    with path(value).open("rb") as stream:
        return stream_hash(stream)


def check_hash(value, expected, size=None):
    file = path(value)
    require(re.fullmatch(r"[0-9A-Fa-f]{64}", str(expected)) is not None, f"Invalid SHA-256: {file}")
    actual = file_hash(file)
    require(actual == expected.upper(), f"SHA-256 differs: {file}")
    require(size is None or file.stat().st_size == size, f"Size differs: {file}")
    TRACKED[file] = actual
    return file


def read_json(value):
    file = path(value)
    TRACKED[file] = file_hash(file)
    return json.loads(file.read_text(encoding="utf-8-sig"))


def check_record(record, base=ROOT):
    return check_hash(path(record["path"], base), record["sha256"], record.get("bytes"))


def check_png(record, base=ROOT):
    file = check_record(record, base)
    with file.open("rb") as stream:
        header = stream.read(24)
    require(header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR", f"Invalid PNG: {file}")
    require(struct.unpack(">II", header[16:24]) == (1920, 1080), f"PNG dimensions differ: {file}")
    require((record["width"], record["height"]) == (1920, 1080), f"PNG receipt dimensions differ: {file}")


def inventory_hash(records):
    # Receipt order is the canonical PowerShell Sort-Object path order. Python
    # ordinal sorting would order punctuation differently on this Windows host.
    normalized = [{"path": r["path"].replace("\\", "/"), "bytes": int(r["bytes"]), "sha256": r["sha256"].upper()} for r in records]
    return hashlib.sha256(json.dumps(normalized, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest().upper()


def check_inventory(inventory):
    records = inventory["files"]
    require(len(records) == 525 and len({r["path"] for r in records}) == 525, "Runtime inventory must contain 525 unique files.")
    require(inventory["sha256"].upper() == RUNTIME_SHA and inventory_hash(records) == RUNTIME_SHA, "Runtime inventory is not the frozen platform source.")


def audit_repeats(primary_provenance):
    """Keep optional repeat evidence separate; frame outliers never fail this gate."""
    repeats = []
    for folder_name, expected_case in [("repeat_observatory", "abyssal_observatory_high_4p"), ("repeat_foundry", "ember_foundry_low_4p")]:
        folder = ROOT / "evidence/platform_refinement/performance" / folder_name
        if not folder.exists():
            continue
        provenance_path = folder / "profile_provenance.json"
        provenance = read_json(provenance_path)
        require(provenance["passed"] is True and provenance["unchanged_during_profiling"] is True and len(provenance["cases"]) == 1, f"Repeat profiling is incomplete: {folder_name}")
        check_inventory(provenance["runtime"])
        require(provenance["harness_sha256"].upper() == primary_provenance["harness_sha256"].upper(), f"Repeat measurement harness differs: {folder_name}")
        check_hash("tools/validation/rebuild_performance.gd", provenance["harness_sha256"])
        require(provenance["art"]["present"] is True and provenance["art"]["sha256"].upper() == primary_provenance["art"]["sha256"].upper(), f"Repeat fighter art differs: {folder_name}")
        check_record(provenance["art"])
        case = provenance["cases"][0]
        require(case["case"] == expected_case and case["file"] == expected_case + ".json" and case["players"] == 4 and case["requested_seconds"] >= 60, f"Repeat case differs: {folder_name}")
        report = read_json(check_hash(folder / case["file"], case["sha256"]))
        require(report["arena"] == case["arena"] and report["quality"].lower() == case["quality"].lower() and report["players"] == 4 and expected_case == f"{report['arena']}_{report['quality'].lower()}_4p", f"Repeat report identity differs: {folder_name}")
        require(report["duration_seconds"] >= 59 and report["simulation_ticks_in_sample_window"] >= 3300 and report["frame_intervals"]["count"] >= 100 and report["readback_inside_sample_window"] is False and report["captured_pixels"] == "(1920, 1080)" and report["viewport_render_cpu"]["available"] is True and report["viewport_render_gpu"]["available"] is True, f"Repeat measurement incomplete: {folder_name}")
        outputs = []
        for file in sorted(folder.iterdir()):
            if file.is_file() and file.suffix.lower() in {".json", ".log", ".png"}:
                digest = file_hash(file)
                check_hash(file, digest)
                outputs.append({"file": file.name, "bytes": file.stat().st_size, "sha256": digest})
        repeats.append({"directory": str(folder), "case": expected_case, "runtime_source_sha256": RUNTIME_SHA, "provenance_sha256": TRACKED[path(provenance_path)], "report_sha256": case["sha256"], "duration_seconds": report["duration_seconds"], "simulation_ticks": report["simulation_ticks_in_sample_window"], "frame_intervals": report["frame_intervals"], "viewport_render_cpu": report["viewport_render_cpu"], "viewport_render_gpu": report["viewport_render_gpu"], "outputs": outputs})
    if repeats:
        CHECKS.append("Separate optional repeat reports, unchanged runtime/art/harness and output hashes; frame outliers retained")
    return repeats


def audit(delivery_path):
    delivery = read_json(delivery_path)
    require(delivery["passed"] is True and delivery["runtime_source_sha256"].upper() == RUNTIME_SHA, "Delivery receipt is not the accepted platform build.")
    require(path(delivery["archive"]) == NEW_ZIP and NEW_ZIP != OLD_ZIP, "Delivery must use the dedicated platform ZIP.")
    check_hash(OLD_ZIP, OLD_ZIP_SHA)
    check_hash(NEW_ZIP, delivery["archive_sha256"], delivery["archive_bytes"])
    CHECKS.append("Dedicated platform archive and unchanged prior five-arena ZIP")

    gate = read_json("evidence/validation_all.json")
    require(gate["passed"] is True and gate["runtime_unchanged_during_validation"] is True and gate["failed_suites"] == 0, "Source gate failed.")
    require(gate["completed_suites"] == gate["expected_suites"] == len(gate["suites"]) == 12, "Source suites incomplete.")
    check_inventory(gate["runtime"])
    expected = {r["path"] for r in gate["runtime"]["files"]}
    actual = {p.relative_to(PROJECT).as_posix() for p in PROJECT.rglob("*") if p.is_file() and ".godot" not in p.relative_to(PROJECT).parts and p.suffix.lower() in EXTENSIONS and not p.name.lower().startswith("source_") and p.name.lower() not in {"validate_input.gd", "engine.png"}}
    require(actual == expected, "Current runtime file set differs from the frozen 525-file inventory.")
    for record in gate["runtime"]["files"]:
        check_record(record, PROJECT)
    for suite in gate["suites"]:
        require(suite["passed"] is True and suite["exit_code"] == 0 and not suite["problems"] and not suite["unexpected_error_lines"] and not suite["unexpected_warning_lines"], f"Source suite failed: {suite['name']}")
        if suite.get("script_sha256"):
            match = re.search(r'--script\s+"([^"]+)"', suite["command"])
            require(match is not None, f"Missing suite harness: {suite['name']}")
            check_hash(match.group(1), suite["script_sha256"])
    require(gate["roster_preflight"]["originals_preserved"] is True, "Original preservation gate failed.")
    originals = gate["roster_preflight"]["original_sources"]
    require(len(originals) == 8, "Eight supplied originals are required.")
    for original in originals:
        require(original["preserved"] is True and original["actual_sha256"] == original["expected_sha256"], "Original preservation receipt differs.")
        check_hash(original["path"], original["expected_sha256"])
    CHECKS.append("Current 525-file source, canonical SHA-256 and all twelve source suites")

    visual = read_json("evidence/platform_refinement/visualreview.json")
    require(visual["passed"] is True, "Visual review has not passed.")
    check_inventory(visual["runtime"])
    check_hash("tools/validation/rebuild_stage_review.gd", visual["harness_sha256"])
    stage_report = read_json(check_hash(visual["report_path"], visual["report_sha256"]))
    captures = visual["captures"]
    require(len(captures) == 25 and {(c["arena"], c["purpose"]) for c in captures} == {(a, v) for a in ARENAS for v in VIEWS}, "Visual views incomplete or duplicated.")
    require(len(stage_report["captures"]) == 25 and all(c["saved"] is True for c in stage_report["captures"]), "Stage capture report incomplete.")
    require({path(c["path"]) for c in captures} == {path(c["file"]) for c in stage_report["captures"]}, "Review and capture report name different images.")
    for capture in captures:
        require(capture["reviewed"] is True and capture["quality"] == ("Low" if capture["purpose"] == "low" else "High"), "Unreviewed capture or incorrect quality.")
        check_png(capture)
    CHECKS.append("Twenty-five exact reviewed PNG hashes, 1080p headers and current review harness")

    manifest_path = ROOT / "builds/windows/build_manifest.json"
    manifest = read_json(manifest_path)
    require(inventory_hash(manifest["runtime_source_files"]) == RUNTIME_SHA and len(manifest["runtime_source_files"]) == 525, "Exported inventory differs.")
    current_build = {"executable": check_hash(BUILD / "RooftopRiot.exe", manifest["exe_sha256"]), "pck": check_hash(BUILD / "RooftopRiot.pck", manifest["pck_sha256"]), "manifest": manifest_path}
    windows = read_json("evidence/windows_release_flow/validation.json")
    require(windows["passed"] is True and windows["build_unchanged_during_validation"] is True and not windows["problems"] and windows["runtime_source_hashes_verified_before"] == windows["runtime_source_hashes_verified_after"] == 525, "Windows gate failed or is stale.")
    for key, field in [("executable", "executable_sha256"), ("pck", "pck_sha256"), ("manifest", "build_manifest_sha256")]:
        check_hash(current_build[key], windows[field])
    ui = windows["pck_ui_harness"]
    require(ui["passed"] is True and ui["exit_code"] == 0 and not ui["timed_out"] and not ui["errors"] and not ui["warnings"] and ui["checks"] == ui["expected_checks"] == 108 and len(ui["captured_images"]) == 40, "Exported-PCK UI coverage incomplete.")
    check_hash(ui["harness"], ui["harness_sha256"])
    for capture in ui["captured_images"]:
        check_png(capture, ROOT / "evidence/windows_release_flow")
    smoke = windows["release_executable_smoke"]
    require(smoke["passed"] is True and smoke["exit_code"] == 0 and smoke["ticks"] == 600 and smoke["fighters"] == 4 and smoke["contacts"] > 0 and not smoke["errors"] and not smoke["warnings"], "Actual Windows smoke failed.")
    check_png(smoke["capture"], ROOT / "evidence/windows_release_flow")
    release = read_json("evidence/map_expansion/release_validation.json")
    require(release["passed"] is True and release["build_unchanged_during_validation"] is True and not release["problems"] and len(release["cases"]) == 3, "Three-arena EXE gate incomplete.")
    check_hash(release["harness"], release["harness_sha256"])
    for moment in ["before", "after"]:
        require(release["runtime_inventory_" + moment]["sha256"].upper() == RUNTIME_SHA and release["runtime_inventory_" + moment]["files"] == 525, "EXE runtime binding differs.")
        for record in release["build_hashes_" + moment].values():
            check_record(record)
    require({c["requested_arena"] for c in release["cases"]} == NEW_ARENAS, "EXE arenas differ.")
    for case in release["cases"]:
        require(case["passed"] is True and case["exit_code"] == 0 and not case["timed_out"] and case["ticks"] == 600 and case["contacts"] > 0 and not case["errors"] and not case["warnings"] and not case["problems"], "An actual arena EXE case failed.")
        require(case["reported_arena"] == case["requested_arena"] and case["reported_input_providers"] == ["res://input/cpu_input_provider.gd"] * 4, "EXE arena/CPU identity differs.")
        check_png(case["capture"])
        check_record(case["runtime_report_file"])
        for record in case["log_files"].values():
            check_record(record)
    flow = read_json("evidence/rebuild/match_flow.json")
    require(flow["checks"] == 35 and flow["failures"] == 0 and flow["graphical"] is True and len(flow["results"]) == 35 and all(r["passed"] is True for r in flow["results"]), "Match lifecycle gate failed.")
    reasons = {"LAST ONE STANDING", "TIME · STOCKS THEN DAMAGE", "SUDDEN DEATH DECISION", "EXACT TIE · DRAW", "SIMULTANEOUS FINAL KO · DRAW"}
    require(len(flow["matches"]) == 5 and {m["arena"] for m in flow["matches"]} == ARENAS and all(m["contacts"] > 0 and m["kos"] > 0 and "winner" in m["result"] and m["result"]["reason"] in reasons for m in flow["matches"]), "Five natural full matches incomplete.")
    latest_runtime_write = max((PROJECT / r["path"]).stat().st_mtime_ns for r in gate["runtime"]["files"])
    require(path("evidence/rebuild/match_flow.json").stat().st_mtime_ns >= max(latest_runtime_write, path("tools/validation/rebuild_match_flow.gd").stat().st_mtime_ns), "Full matches predate current source or lifecycle harness.")
    CHECKS.append("Current exported build, 108 UI checks, actual EXE smokes and five full matches")

    profile_record = delivery["evidence"]["profile_provenance"]
    profile_path = check_record(profile_record)
    provenance = read_json(profile_path)
    require(provenance["passed"] is True and provenance["unchanged_during_profiling"] is True and len(provenance["cases"]) == 10, "Profile provenance incomplete.")
    check_inventory(provenance["runtime"])
    check_hash("tools/validation/rebuild_performance.gd", provenance["harness_sha256"])
    require(provenance["art"]["present"] is True, "Profile art binding absent.")
    check_record(provenance["art"])
    cases = {c["case"]: c for c in provenance["cases"]}
    expected_cases = {f"{a}_{q}_4p" for a in ARENAS for q in ["high", "low"]}
    require(set(cases) == expected_cases and len(delivery["performance"]) == 10 and {c["case"] for c in delivery["performance"]} == expected_cases, "Ten High/Low four-player profiles incomplete.")
    profiles = []
    for case_name, case in cases.items():
        file = check_hash(profile_path.parent / case["file"], case["sha256"])
        report = read_json(file)
        require(report["arena"] == case["arena"] and report["quality"].lower() == case["quality"].lower() and report["players"] == case["players"] == 4 and case["requested_seconds"] >= 60, f"Profile case identity differs: {case_name}")
        require(report["duration_seconds"] >= 59 and report["simulation_ticks_in_sample_window"] >= 3300 and report["frame_intervals"]["count"] >= 100 and report["readback_inside_sample_window"] is False and report["captured_pixels"] == "(1920, 1080)" and report["viewport_render_cpu"]["available"] is True and report["viewport_render_gpu"]["available"] is True, f"Profile measurement incomplete: {case_name}")
        delivery_case = next(c for c in delivery["performance"] if c["case"] == case_name)
        require(path(delivery_case["file"]) == file and delivery_case["sha256"].upper() == case["sha256"].upper(), "Delivery profile binding differs.")
        profiles.append({"case": case_name, "sha256": case["sha256"], "frame_p99_ms": report["frame_intervals"]["p99_ms"], "over_16_667": report["frame_intervals"]["over_16_667"]})
    CHECKS.append("Ten current 60-second CPU/GPU profiles, runtime/art/harness and delivery hash bindings")
    repeat_profiles = audit_repeats(provenance)

    for record in delivery["evidence"].values():
        check_record(record)
    with zipfile.ZipFile(NEW_ZIP) as archive:
        names = archive.namelist()
        receipt_files = {r["file"]: r for r in delivery["files"]}
        require(len(names) == len(set(names)) == len(receipt_files) == 22 and set(names) == set(receipt_files), "ZIP exact entry set differs.")
        package_bytes = archive.read("package_manifest.json")
        require(hashlib.sha256(package_bytes).hexdigest().upper() == delivery["package_manifest_sha256"].upper(), "Decoded package manifest differs.")
        package = json.loads(package_bytes.decode("utf-8-sig"))
        require(package["runtime_source_sha256"].upper() == RUNTIME_SHA and set(package["expected_archive_entries"]) == set(names) and len(package["files"]) == 21, "Packaged inventory differs.")
        require(package["evidence"] == delivery["evidence"], "Packaged evidence differs from external receipt.")
        package_files = {r["file"]: r for r in package["files"]}
        require(set(package_files) == set(names) - {"package_manifest.json"}, "Package manifest payload set differs.")
        for name in names:
            record = receipt_files[name]
            with archive.open(name) as stream:
                decoded_sha = stream_hash(stream)
            require(decoded_sha == record["sha256"].upper() and archive.getinfo(name).file_size == record["bytes"], f"Decoded ZIP payload differs: {name}")
            check_hash(BUILD / name, record["sha256"], record["bytes"])
            if name != "package_manifest.json":
                require(package_files[name] == record, f"Package and delivery payload records differ: {name}")
            if name.endswith(".md"):
                source = ROOT / "docs" / name
                if name == "README.md": source = ROOT / "docs/WINDOWS_BUILD_README.md"
                elif name == "MOTION_CREDITS.md": source = ROOT / "source_art/motion/README.md"
                elif name == "LUNAR_ASSET_CREDITS.md": source = PROJECT / "assets/lunar_reach/CREDITS.md"
                elif name.startswith("maps/") and name.endswith("_CREDITS.md"): source = PROJECT / "assets/arenas" / name.removeprefix("maps/").removesuffix("_CREDITS.md") / "CREDITS.md"
                check_hash(source, record["sha256"], record["bytes"])
        require(file_hash(manifest_path) == delivery["build_manifest_sha256"].upper() == package["build_manifest_sha256"].upper(), "Build manifest binding differs.")
    CHECKS.append("All 22 ZIP entries decoded; package, receipt, build copies and current documentation match")
    for file, expected_hash in TRACKED.items():
        require(file_hash(file) == expected_hash, f"File changed during independent audit: {file}")
    CHECKS.append("All audited files remained unchanged through the audit")
    return {"archive": str(NEW_ZIP), "archive_sha256": delivery["archive_sha256"], "runtime_source_sha256": RUNTIME_SHA, "runtime_files": 525, "reviewed_captures": 25, "zip_entries": 22, "profiles": profiles, "repeat_profiles": repeat_profiles, "old_five_arenas_zip_sha256": OLD_ZIP_SHA}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--delivery", default="evidence/platform_refinement/delivery.json")
    args = parser.parse_args()
    report = {"generated_at_utc": datetime.now(timezone.utc).isoformat(), "passed": False, "checks": CHECKS, "problems": [], "scope": "Independent hashes, archive decoding and existing receipt checks; no engine execution or human playtesting."}
    try:
        report.update(audit(path(args.delivery)))
        report["passed"] = True
    except Exception as error:
        report["problems"].append(f"{type(error).__name__}: {error}")
    report["audit_script_sha256"] = file_hash(__file__)
    output = ROOT / "evidence/platform_refinement/final_audit.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"PLATFORM DELIVERY AUDIT {'PASS' if report['passed'] else 'FAIL'}: {output}")
    for problem in report["problems"]:
        print(problem, file=sys.stderr)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
