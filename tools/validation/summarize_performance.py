"""Summarize measured reports without hiding readback spikes or inferring mobile speed."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
evidence = ROOT / "evidence"
hardware = json.loads((evidence / "preflight/performance_hardware.json").read_text(encoding="utf-8-sig"))
rows, notes, reports = [], [], []
for name, label in [("forward", "Forward+"), ("mobile", "Mobile")]:
    report = json.loads((evidence / f"performance_{name}.json").read_text(encoding="utf-8-sig"))
    expected = "forward_plus" if name == "forward" else "mobile"
    assert report["renderer"] == expected and report["ticks"] == 3600 and report["profile_mode"]
    assert report["captured_pixel_size"] == "(1920, 1080)"
    assert report["sample_clock"].startswith("Time.get_ticks_usec")
    reports.append(report)
    spikes = report.get("frame_spikes", [])
    capture_spikes = [s for s in spikes if s["capture_on_previous_frame"]]
    noncapture_count = report["frames_over_16_667ms"] - len(capture_spikes)
    rows.append(f'| {label} | {report["sample_count"]:,} | {report["mean_frame_ms"]:.3f} | {report["p95_frame_ms"]:.3f} | {report["p99_frame_ms"]:.3f} | {report["worst_frame_ms"]:.3f} | {report["frames_over_16_667ms"]} / {noncapture_count} | {int(report["peak_draw_calls"])} | {int(report["peak_primitives"]):,} | {report["peak_video_memory_bytes"] / 2**20:.1f} |')
    notes.append(f'- {label}: {report["wall_seconds"]:.3f}s wall time, {report["render_frames"]:,} total rendered frames, {report["contacts"]} resolved contacts and {len(report["kos"])} KOs. ' + (f'{len(capture_spikes)} over-budget sample(s) immediately followed synchronous screenshot readback/PNG encoding. ' if capture_spikes else '') + f'{noncapture_count} over-budget sample(s) were unrelated to screenshot capture. See `evidence/performance_{name}.json`.')

budget_summary = ("No sampled frame exceeded the 16.667 ms target in either run." if all(r["frames_over_16_667ms"] == 0 for r in reports) else "Both renderers have a measured P99 below the 16.667 ms target, with over-budget frames disclosed above." if all(r["p99_frame_ms"] < 16.667 for r in reports) else "At least one renderer exceeds the 16.667 ms target at P99; stable 60 FPS is not established for that configuration.")
text = f'''# Measured Windows performance

Measured {reports[0]['measured_started_utc'][:10]}. Hardware: {hardware['cpu']['Name'].strip()}, {hardware['memory_gib']} GiB system RAM, NVIDIA GeForce RTX 4080 SUPER; {hardware['os']['Caption']} {hardware['os']['Version']}. Godot 4.7.2, Vulkan 1.4.341. Hardware evidence: `evidence/preflight/performance_hardware.json`.

Each run advances 3,600 authoritative ticks at 60 Hz with four seeded Normal CPUs (Clutch, Sunstruck, Heavy Duty, Deadfall), Party lift/pyro, damage effects, blood, High graphics and normal game audio. V-sync and the render cap are disabled to measure headroom. Other game/Blender processes are stopped. Frame samples cover the run after a two-second wall-clock warmup; they are unsmoothed monotonic microsecond intervals between process callbacks, not engine-adjusted simulation deltas or GPU-only timestamps. Fine Print's separate ability/rendered cases are in the full-five visual review.

Both the window and captured image measure **1920×1080**; the logical UI viewport is 1600×900. Godot's texture-size query reports 2304×1296 while the actual retrieved image is 1920×1080. Both raw values are retained. This API discrepancy is not silently treated as proof of an internal GPU allocation size.

| Renderer | Samples | Mean ms | P95 ms | P99 ms | Raw max ms | >16.667 ms: all / excluding capture | Peak draws | Peak primitives | Peak reported VRAM MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
{chr(10).join(rows)}

{chr(10).join(notes)}

Readback is validation overhead, not a player feature. The summary includes every measured frame; capture-tagged spikes are disclosed rather than silently dropped. Sample sums agree with their monotonic sampling-window durations to within 0.1 ms. {budget_summary} These runs do not establish performance on weaker PCs, iOS devices, every possible match, or cold driver-cache conditions. The Mobile run is a Windows renderer compatibility/performance check, not phone validation.

Historical pre-overhaul runs with a mid-match screenshot are retained as `performance_*_midcapture.json`; superseded engine-delta measurements are `performance_*_engine_delta.json`. An early pre-overhaul Mobile attempt exited without a complete report and was rejected by the runner. Use the current wall-time reports above for the revised arena, lighting, shaders, portraits and effects.

Reproduce with `tools/validation/profile_windows.ps1` (optional `-Profiles forward` or `-Profiles mobile`), then run this Python script. The runner rejects logged errors/warnings, stale output, wrong renderer/resolution and too few samples. It requests an early screenshot; the report tags its cost if loading delays place it outside warmup. `Launch-Mobile.cmd` selects Mobile in a new game process. No renderer switch is promised inside a running match.
'''
(ROOT / "docs/PERFORMANCE.md").write_text(text, encoding="utf-8")
print("Wrote docs/PERFORMANCE.md from both fresh renderer reports.")
