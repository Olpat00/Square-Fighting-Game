# Resume the living-background pass

All five arenas have implemented living scenery. Runtime sources are frozen at 537 files, SHA-256 `77389F9A5CCD5FB3E595EB502E36DC768A2139166A1E916A70B70DE05CF6D12A`. The current source gate passed import and all 11 suites. Preservation has 72 passing checks, including the eight originals, curated sources, all 106 existing bitmaps and previous platform ZIP.

Final graphical capture could not start: Vulkan and D3D12 device creation failed, followed by OpenGL/ANGLE initialization failure. NVIDIA's diagnostic reported **GPU is lost**, no devices, and requested a reboot. The owning failed capture processes were stopped. No driver cause or repair is claimed. Restart Windows after saving open work; do not launch further graphics jobs while the device is lost.

The candidate EXE/PCK has been exported to `builds/windows`, bound to the frozen sources. Its README marks validation pending; the stale previous package manifest was removed only after verifying it against the preserved baseline. Do not package or call this a validated release yet. The prior validated platform ZIP remains unchanged.

The earlier 378-check/70-image temporal run is useful historical evidence, but predates the last gull geometry/height adjustment. It cannot accept the current full runtime. Current `motion_acceptance_pending.json` explicitly remains false. Do not copy acceptance flags from historical views.

After the device recovers, run one engine/graphics job at a time. Keep video capture/encoding and screenshot readbacks outside performance sampling. Runtime changes after this point require fresh source, art-preservation, visual, media, build and performance bindings.

```powershell
$taskGodot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe'
$taskPython = 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $taskGodot --path 'Game File' --script (Join-Path $PWD 'tools/validation/rebuild_stage_review.gd') --log-file (Join-Path $PWD 'evidence/background_rebuild/review_final_engine.log') -- "--output=$(Join-Path $PWD 'evidence/background_rebuild/review_final')"
& $taskGodot --path 'Game File' --script (Join-Path $PWD 'tools/validation/living_background_review.gd') --log-file (Join-Path $PWD 'evidence/background_rebuild/review_motion_engine.log') -- "--output=$(Join-Path $PWD 'evidence/background_rebuild/review_motion')"
# Inspect all 25 arena views and all 70 temporal/pause/reset captures. Bind
# exact files, harness/report hashes and frozen runtime in visualreview.json.
# Record explicit motion_reviewed=true only after actual image inspection.
& $taskPython 'evidence/background_rebuild/record_movies.py'
# Inspect the generated samples for all five movies, retaining the recorded
# decode results, then record reviewed=true and passed=true only if accepted.
& $taskGodot --path 'Game File' --script (Join-Path $PWD 'tools/validation/rebuild_match_flow.gd') -- "--evidence-root=$(Join-Path $PWD 'evidence/rebuild')"
& ./tools/validation/export_windows.ps1
& ./tools/validation/validate_windows_build.ps1
& ./tools/validation/validate_map_release.ps1
& ./tools/validation/profile_rebuild.ps1 -Arenas @('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry') -Qualities @('High','Low') -Players @(4) -Seconds 60 -Output (Join-Path $PWD 'evidence/background_rebuild/performance/final')
& $taskPython 'evidence/background_rebuild/update_delivery_notes.py' 'evidence/background_rebuild/performance/final'
& ./tools/validation/package_map_expansion.ps1 -PerformanceDirectory (Join-Path $PWD 'evidence/background_rebuild/performance/final') -ArchivePath (Join-Path $PWD 'builds/RooftopRiot-Living-Arenas-Windows.zip') -DeliveryReceiptPath (Join-Path $PWD 'evidence/background_rebuild/delivery.json')
& $taskPython 'evidence/background_rebuild/audit_delivery.py'
```

Inspect errors and native exit status after every job. All ten original profile results and any failures/outliers must remain intact; additional repeats do not replace them. The notes generator and independent final audit must pass against the exact current artifacts. The new ZIP must use the explicit destinations above to preserve both earlier release archives.

Finish with an actual all-five motion/readability audit, current validation notes and preview links. Only then mark the active background goal complete. Human/controller playtesting and weaker-PC measurements remain separate, unverified work.
