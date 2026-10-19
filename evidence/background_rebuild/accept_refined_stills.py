"""Freeze the assistant's actual all-25 refined-still inspection as a receipt.

This file records observations authored after viewing all 25 current images.
It does not infer visual acceptance from hashes or source tests. The frozen
runtime hash intentionally prevents the observations being applied to new art.
"""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "evidence/background_rebuild"
EXPECTED = "F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    with path.open("rb") as file:
        value = hashlib.sha256()
        for block in iter(lambda: file.read(1024 * 1024), b""):
            value.update(block)
        return value.hexdigest().upper()


def record(path):
    return {"path": str(path.resolve()), "bytes": path.stat().st_size, "sha256": digest(path)}


def png(path):
    with path.open("rb") as file:
        header = file.read(24)
    assert header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR", path
    width, height = struct.unpack(">II", header[16:24])
    assert (width, height) == (1920, 1080), path
    return {**record(path), "width": width, "height": height}


source_gate_path = ROOT / "evidence/validation_all.json"
gate = read(source_gate_path)
assert gate["passed"] and gate["runtime_unchanged_during_validation"]
assert gate["runtime"]["sha256"] == EXPECTED and len(gate["runtime"]["files"]) == 537
latest_runtime_ns = 0
for entry in gate["runtime"]["files"]:
    path = ROOT / "Game File" / entry["path"]
    assert path.stat().st_size == entry["bytes"] and digest(path) == entry["sha256"], path
    latest_runtime_ns = max(latest_runtime_ns, path.stat().st_mtime_ns)
capture_provenance_path = OUT / "capture_provenance.json"
provenance = read(capture_provenance_path)
assert provenance["passed"] and provenance["unchanged_during_capture"]
assert provenance["runtime"] == gate["runtime"]

historical = read(OUT / "first_reboot_still_acceptance.json")
findings = historical["arenas"]
findings["rooftop_riot"]["observations"] = [
    "Warm terrace materials, the reflective pool, intact background guests and a correctly proportioned skyline form a coherent resort scene.",
    "The sky remains continuous at normal, overlap, recovery and near-ledge camera ranges; the earlier rectangular tonal patches and vertical seam are absent in the refined images.",
    "Players, label colors, platform surfaces and both low recovery sides remain visible in all five supplied deterministic fixtures."
]
findings["verdant_shrine"]["observations"] = [
    "Waterfalls, mist, vegetation and ruin architecture share a coherent palette with no visible image edge at the tested camera ranges.",
    "The refined cascades have irregular vertical water detail; the earlier repeating geometric chevrons are absent in normal, overlap, recovery and near-ledge views.",
    "Platform boundaries and colored player labels remain recognizable across all five supplied deterministic fixtures."
]
for arena in findings.values():
    arena["accepted"] = True
    arena["blocking_findings"] = []

stage_report_path = OUT / "review_final/stage_review.json"
stage = read(stage_report_path)
views = {"high", "low", "overlap", "recovery", "near_ledge"}
assert len(stage["captures"]) == 25 and len(findings) == 5
captures = []
seen = set()
for entry in stage["captures"]:
    path = Path(entry["file"])
    arena = entry["arena"]
    purpose = path.stem[len(arena) + 1:]
    assert arena in findings and purpose in views and entry["saved"]
    assert path.parent.resolve() == (OUT / "review_final").resolve()
    assert path.stat().st_mtime_ns >= latest_runtime_ns
    assert entry["quality"].lower() == ("low" if purpose == "low" else "high")
    assert (arena, purpose) not in seen
    seen.add((arena, purpose))
    captures.append({**png(path), "arena": arena, "quality": entry["quality"],
                     "purpose": purpose, "fixture": entry["purpose"], "reviewed": True,
                     "accepted": True, "review_method": "Assistant inspected the complete fresh screenshot through view_image."})
assert seen == {(arena, view) for arena in findings for view in views}

gulls = []
for suffix, observation in [
    ("t0120", "A pale gull with a shallow V-shaped wing silhouette is clearly visible in the upper mid-left sky."),
    ("t0300", "Two pale gull silhouettes are visible toward the upper left; their positions differ from the two-second sample."),
    ("t0600", "One pale gull is visible near the upper mid-left at a different wing/flight pose.")
]:
    path = OUT / f"review_motion/rooftop_riot_high_{suffix}.png"
    assert path.stat().st_mtime_ns >= latest_runtime_ns
    gulls.append({**png(path), "arena": "rooftop_riot", "quality": "High", "purpose": suffix,
                  "reviewed": True, "observation": observation})

motion_path = OUT / "review_motion/living_background_review.json"
motion = read(motion_path)
assert motion["passed"] and motion["failures"] == 0 and len(motion["captures"]) == 70
receipt = {
    "passed": True,
    "checked_utc": datetime.now(timezone.utc).isoformat(),
    "reviewer": "/root/background_still_review",
    "review_kind": "Assistant inspection of all25 fresh refined standard stills and three fresh Rooftop temporal gull samples.",
    "runtime": gate["runtime"],
    "runtime_files_individually_verified_against_live_checkout": True,
    "runtime_binding_method": "Current source-gate inventory, capture runner before/after inventory and individual live file hashes all agree.",
    "source_gate_file": record(source_gate_path),
    "capture_provenance_file": record(capture_provenance_path),
    "capture_report_file": record(stage_report_path),
    "harness_sha256": digest(ROOT / "tools/validation/rebuild_stage_review.gd"),
    "captures": captures,
    "arenas": findings,
    "supplementary_temporal_samples": gulls,
    "blocking_findings": [],
    "previous_findings": [
        {"arena": "rooftop_riot", "finding": "Rectangular sky tonal patches", "resolved": True},
        {"arena": "verdant_shrine", "finding": "Repeated waterfall chevrons", "resolved": True}
    ],
    "previous_review_file": record(OUT / "first_reboot_still_acceptance.json"),
    "motion_report_path": str(motion_path.resolve()),
    "motion_report_sha256": digest(motion_path),
    "motion_report_binding": "Clock/pause/reset report saved,70 captures; this still receipt does not claim visual inspection of all70 temporal images or continuous films.",
    "motion_visual_review": "pending separate root review of all maps' timed samples and current movie frames",
    "limits": [
        "These are deterministic fixture screenshots, not continuous gameplay or human playtesting.",
        "Static samples cannot prove the cadence, direction, continuity or absence of loops in background motion.",
        "This receipt does not measure performance or independently validate pause, reset, collision preservation or export behavior.",
        "The four-fighter overlap fixture intentionally places rendered fighter bodies together and partially behind upper platforms; that forced overlap is not ordinary gameplay."
    ]
}
serialized = json.dumps(receipt, indent=2) + "\n"
(OUT / "still_acceptance.json").write_text(serialized, encoding="utf-8")
(OUT / "visualreview.json").write_text(serialized, encoding="utf-8")
print("PASS: all25 fresh refined1080p standard stills reviewed; both previous visual blockers resolved. Motion footage acceptance remains separate.")
