"""Write the record of assistant inspections performed through view_image.

This is an observation receipt, not a visual-quality classifier. Findings below
were authored after viewing every named current screenshot in this review turn.
"""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "evidence/background_rebuild"


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


expected = "77389F9A5CCD5FB3E595EB502E36DC768A2139166A1E916A70B70DE05CF6D12A"
capture_provenance_path = OUT / "capture_provenance_first_reboot.json"
if not capture_provenance_path.exists():
    capture_provenance_path = OUT / "capture_provenance.json"
capture_provenance = json.loads(capture_provenance_path.read_text(encoding="utf-8-sig"))
assert capture_provenance["passed"] and capture_provenance["unchanged_during_capture"]
gate = capture_provenance
assert gate["runtime"]["sha256"] == expected and len(gate["runtime"]["files"]) == 537
changed_since_capture = []
for entry in gate["runtime"]["files"]:
    path = ROOT / "Game File" / entry["path"]
    if path.stat().st_size != entry["bytes"] or digest(path) != entry["sha256"]:
        changed_since_capture.append(entry["path"])

stage_folder = OUT / "review_final_first_reboot"
if not stage_folder.exists():
    stage_folder = OUT / "review_final"
stage_report = stage_folder / "stage_review.json"
report = json.loads(stage_report.read_text(encoding="utf-8-sig"))
views = {"high", "low", "overlap", "recovery", "near_ledge"}
arenas = {"rooftop_riot", "lunar_reach", "verdant_shrine", "abyssal_observatory", "ember_foundry"}
assert len(report["captures"]) == 25
findings = {
    "rooftop_riot": {
        "accepted": False,
        "observations": [
            "Warm terrace materials, reflective pool, skyline and intact guest silhouettes form a cohesive resort scene.",
            "Players, label colors, platform surfaces and both recovery sides remain visible in the supplied deterministic fixtures.",
            "Hard-edged rectangular tonal patches are visibly superimposed on the sky, particularly in overlap, recovery and near-ledge views; these undermine the intended natural backdrop."
        ],
        "blocking_findings": ["Rectangular sky tonal patches and a large vertical seam require correction and fresh capture review."]
    },
    "lunar_reach": {
        "accepted": True,
        "observations": [
            "The muted relay dish sits to the left of combat rather than competing with the center platform.",
            "The rover and small orbital satellite read as scenery, and the Earth remains distinct against the black sky.",
            "The lower-contrast terrain, pale platform trims, player rings and recovery positions are readable in all five fixtures."
        ],
        "blocking_findings": []
    },
    "verdant_shrine": {
        "accepted": False,
        "observations": [
            "Waterfalls, mist, vegetation and ruin architecture share a coherent palette with no visible image edge at the tested camera ranges.",
            "Platform boundaries and colored player labels remain recognizable across the five fixtures.",
            "Large regular zigzag or chevron bands repeat across the lower waterfall overlays, especially the left cascade; they read as a geometric shader pattern rather than falling water."
        ],
        "blocking_findings": ["Repeated waterfall chevrons require irregular downstream streaks and fresh capture review."]
    },
    "abyssal_observatory": {
        "accepted": True,
        "observations": [
            "Clearly visible fish shoals, jellyfish bells and trailing filaments occupy separate background depth planes around the gold observatory frame.",
            "The center water remains relatively quiet behind fighters; bright fish shapes stay behind the gameplay geometry.",
            "Platform rims, player rings and low recoveries are visible in High and Low fixtures and at the wider camera ranges."
        ],
        "blocking_findings": []
    },
    "ember_foundry": {
        "accepted": True,
        "observations": [
            "Orange side spillways, copper collection vessels, flywheels, chains and smoke fit the molten industrial background.",
            "The brighter molten scenery is concentrated toward the sides, leaving the central combat space quieter.",
            "Dark platform faces retain their pale trims and readable boundaries; four fighters and both low recovery paths remain visible."
        ],
        "blocking_findings": []
    }
}
captures = []
seen = set()
for entry in report["captures"]:
    path = stage_folder / Path(entry["file"]).name
    arena = entry["arena"]
    purpose = path.stem[len(arena) + 1:]
    assert entry["saved"] and arena in arenas and purpose in views
    assert (arena, purpose) not in seen
    seen.add((arena, purpose))
    captures.append({**png(path), "arena": arena, "quality": entry["quality"],
                     "purpose": purpose, "fixture": entry["purpose"], "reviewed": True,
                     "accepted": findings[arena]["accepted"],
                     "review_method": "Assistant inspected the complete screenshot through view_image."})
assert seen == {(arena, view) for arena in arenas for view in views}

gulls = []
temporal_folder = OUT / "review_motion_first_reboot"
if not temporal_folder.exists():
    temporal_folder = OUT / "review_motion"
for suffix, observation in [
    ("t0120", "One pale gull with a shallow V-shaped wing silhouette is visible in the upper mid-left sky."),
    ("t0300", "Two pale gull silhouettes are visible toward the upper left; their positions differ from the two-second sample."),
    ("t0600", "One pale gull appears again near the upper mid-left at a different wing/flight pose.")
]:
    path = temporal_folder / f"rooftop_riot_high_{suffix}.png"
    gulls.append({**png(path), "arena": "rooftop_riot", "quality": "High", "purpose": suffix,
                  "reviewed": True, "observation": observation})

receipt = {
    "passed": False,
    "checked_utc": datetime.now(timezone.utc).isoformat(),
    "reviewer": "/root/background_still_review",
    "review_kind": "Assistant inspection of all 25 fresh standard stills and three Rooftop temporal gull samples.",
    "runtime": gate["runtime"],
    "runtime_files_individually_verified_against_live_checkout": not changed_since_capture,
    "runtime_binding_method": "Capture runner measured the runtime inventory before and after all25 standard and70 temporal captures and recorded an unchanged matching source-gate hash.",
    "runtime_changes_since_capture": changed_since_capture,
    "capture_provenance_file": record(capture_provenance_path),
    "capture_report_file": record(stage_report),
    "harness_sha256": digest(ROOT / "tools/validation/rebuild_stage_review.gd"),
    "captures": captures,
    "arenas": findings,
    "supplementary_temporal_samples": gulls,
    "blocking_findings": [
        {"arena": arena, "finding": issue}
        for arena, data in findings.items() for issue in data["blocking_findings"]
    ],
    "limits": [
        "These are deterministic fixture screenshots, not continuous gameplay or human playtesting.",
        "Static samples cannot prove the cadence, direction, continuity or absence of loops in background motion.",
        "This receipt does not measure performance or validate pause, reset, collision preservation or export behavior.",
        "The four-fighter overlap fixture intentionally places rendered fighter bodies together and partially behind upper platforms; the background review does not treat that forced overlap as ordinary gameplay.",
        "Rooftop and Shrine require fixes and a new runtime binding before overall still acceptance."
    ]
}
(OUT / "first_reboot_still_acceptance.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
print("Reviewed 25 fresh standard stills; overall acceptance FAIL: Rooftop sky patches and Shrine waterfall chevrons.")
