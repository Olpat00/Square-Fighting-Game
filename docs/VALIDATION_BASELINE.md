# Validation record

Current source, graphical review, profiles, media and exported-package evidence are recorded below. **The input fallback, final source aggregate and current package pass; the full native-loop acceptance report remains open.** Automated passes do not certify human feel, listening quality or every animation transition. See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) and [COMPLETION_AUDIT.md](COMPLETION_AUDIT.md).

The active goal is the massive graphics upgrade to the existing game, preserving gameplay and sounds. This record retains the broader original-game evidence and limitations; unperformed physical-controller testing does not block this graphics goal. Final native checks verify the existing loop and packaged presentation, not a new gameplay or audio redesign.

## Executed checks

| Check | Recorded result | Evidence and scope |
| --- | --- | --- |
| Aggregate | Import plus seven suites passed; zero errors/warnings | `evidence/validation_all.json`, September 28, 18:27:07–18:28:09 UTC. All eight processes exit 0, including the current input fallback and wall-clock instrumentation; accepted mapping, original/model hashes and executed commands are recorded. |
| Input | **2,440 checks, zero failures** | `docs/moves/input-validation.json`: provider isolation/remapping/CPU behavior plus 18 regressions from observed Windows key events. Covers malformed physical Pause fallback, genuine Pause, ordinary physical layout precedence and release/remap behavior. Physical hardware remains separate. |
| Content | 1,114 checks, zero failures | `docs/moves/content-validation.json`: five definitions, 125 moves, animation/timing/cancel contracts, distinct mechanics and temporary unshipped sixth-ID registration. |
| Combat | **95 checks, zero failures** | `evidence/combat_scenarios.json`: real fixed-step attacks/movement/defense/stocks, both ledges, jump/dodge exhaustion and refresh, bounded actual-hit influence, KO contributors/expiry/reset, and actual Party warning-to-damage interval of 72 ticks. |
| Abilities | **193 checks, zero failures** | `evidence/ability_scenarios.json`: all five kits, passives, counters, projectiles/reflection, traps, ultimate bounds/captures, recovery limits, taunt props and effect cleanup. |
| Presentation state | **88 checks, zero failures** | `evidence/presentation_state.json`: main/UI/stage lifecycle, breakup/reset, synthetic disconnect/pause, citations, launch dispatch, results, all five actual 1K texture loads with identical animations, and High restoration. Headless. |
| Settings | Four conditions passed | `evidence/settings_scenarios.json`: sanitization, persistence round trip, preserved user settings and corrupt defaults. |
| Pairings/rematches | 15 pairs, valid four-CPU finish, 20 rematches; **80 → 80 nodes** | `evidence/pairing_soak.json`. Includes mirrors. Bounded cleanup/smoke evidence, not exhaustive balance or leak proof. |
| Render-rate independence | Fresh 1,200-tick comparison passed at 30/144 | `evidence/render_rate_comparison.json`, September 28, 18:04 UTC. Seed-matched authoritative positions/states/damage/stocks/contacts/KO history on one machine, not cross-platform determinism. |
| Graphical UI | 56 checks, 22 captures, zero failures | `evidence/visual_overhaul/ui_final/ui_flow.json`: normal menu loop, all five selections, remapped cues and reachable 1.25-scale controls. |
| Graphical presentation | 66 captures, 137 triggers; zero failures | `evidence/visual_overhaul/presentation_final/presentation_scenarios.json`: all five fighters, 20 specials/five ultimates, ordinary action/launches and settings effects. Later focused contour/contact review supersedes its identified defects. |
| Final ability/contact refinement | 58 contour captures/151 triggers; 2 jab captures/8 triggers; no failures | `evidence/visual_overhaul/ability_contour_final/`, `jab_contact_review/` and `FINAL_VISUAL_REVIEW.md`. Six contour reports were read; 16 selected originals were visually inspected, plus both corrected jab frames. |
| Low texture tier | Five 1K derivatives and separate graphical run passed | `evidence/characters/texture_tiers.json`, `evidence/visual_overhaul/low_textures/presentation_scenarios.json` and runtime state tests. Geometry/skin/animation buffers preserved. It is distinct from Mobile renderer. |
| Characters | Five canonical fighters; 388 nonconstant clips | `evidence/characters/export_validation.json`, material/timing comparisons and engine/gait reports. Original/runtime hashes independently rechecked; editable rigs exist. Selected deformation review is bounded. |
| Stage/props/audio files | Exports valid; 23 non-silent stereo WAVs | Stage/prop reports and `evidence/stage/audio_validation.json`; original PCM samples do not clip. Actual mixed recording is separately measured below. |
| Current Windows export | EXE/PCK and all 154 source records match manifest | `builds/windows/build_manifest.json`, built September 28, **18:23:04.9952962 UTC**, includes the input fallback. Source inventory and file hashes were stable across the latest package attempt. Final two-stage package validation passed at 20:46:44 UTC. |
| Exported-PCK UI | **56 checks/22 fresh captures**, exit 0; zero errors/warnings | `evidence/windows_release_flow/validation.json`, final run 20:46:06–20:46:44 UTC. Matching editor engine loads the explicit PCK and external UI script. This does not execute through the release EXE. |
| Actual release EXE | **600 ticks, four fighters, 24 contacts, 1920×1080 capture**, exit 0; zero errors/warnings | Same report, `release_executable_smoke`, plus `release_smoke/smoke_runtime.json`. Release binary starts its default main scene with adjacent PCK and supported smoke user arguments; no external-script override. Screenshot readback/concurrent work make this a functional check, not a profile. |
| Native-window flow | **Input fixed; full loop report pending** | Observed Windows injected letters carried malformed Pause physical codes. Shared fallback passes regression; native light/special/pause and training rematch/menu now respond. Final full normal-window flow/exit report is still required. |

## Current performance measurements

`evidence/performance_forward.json` and `performance_mobile.json` were freshly measured sequentially without competing GPU jobs, with four CPU fighters in Party, High graphics, 3,600 fixed ticks, and a 1920×1080 window/readback on an RTX 4080 SUPER.

| Renderer | Samples | Mean / P95 / P99 | Worst | Above 16.667 ms | Peak draws / primitives / video memory |
| --- | ---: | --- | ---: | ---: | --- |
| Forward+ | 48,496 | 1.223 / 1.663 / 2.012 ms | 13.729 ms | 0 | 233 / 398,076 / 879,944,976 bytes |
| Mobile | 93,591 | 0.634 / 0.929 / 1.447 ms | 13.621 ms | 0 | 153 / 397,782 / 614,989,392 bytes |

The clock is `Time.get_ticks_usec` between process callbacks: raw monotonic wall intervals, not Godot's adjusted simulation delta, GPU timestamps or display-present latency. The first two seconds are excluded; sample sums match sample-window durations. Runs last about 61.3 seconds. Logical layout is 1600×900; actual output/readback is 1920×1080, with the engine reporting a 2304×1296 render texture. These are bounded measurements on this desktop, not minimum-spec certification. Both runs use High; neither is a Low-tier benchmark. Prior `*_engine_delta.json` and `*_midcapture.json` reports are superseded diagnostic history.

## Visual and media review

`evidence/visual_overhaul/FINAL_VISUAL_REVIEW.md` records the final independent review. The rebuilt architecture, pool, materials, portraits and compact HUD are visibly improved. Follow-up contours resolve broad opaque energy shapes and below-deck effects; Fine Print's warning remains readable at normal camera size, and the jab burst was corrected without changing collision/timing. Selected Forward+/Mobile and flash-on/off frames were inspected. The generated distant image is an in-scene background asset, not a fabricated gameplay screenshot.

`evidence/integration/gameplay.mp4` is actual 600-tick/10.03-second four-CPU Party gameplay. Measured encoded output is **1600×900 at 60 fps**, despite the game window being 1920×1080 after startup. `evidence/gameplay_capture.json` and `gameplay_media.log` record full decoding, original mixed audio at **−29.5 dBFS mean / −11.3 dBFS peak**, file hash and scope. Offline recording is not performance evidence.

`evidence/gameplay_review/REVIEW.md` surveys 20 ordered 2 Hz samples and inspects ten at original size. No glaring missing asset, broken skeleton or main-combat framing defect was found. A respawn label partly clips at the top and close-contact player labels overlap in some samples. The body/HUD remain visible. This was sampled-still review, not continuous playback, subjective listening or exhaustive animation-transition review.

## Preserved shutdown observations

The first final aggregate completed all presentation/pairing assertions but those two Godot processes exited with Windows access violation `0xc0000005` (`-1073741819`) at the same engine offset `0x547f2c`. There were no preceding script errors/warnings. Evidence is retained in `validation_all_shutdown_failure.json`, `presentation_state_shutdown_failure.log`, `pairing_soak_shutdown_failure.log` and `headless_shutdown_windows_events.json`. An isolated presentation rerun and the complete final aggregate then exited cleanly. The intermittent engine-shutdown cause is unresolved; it is not presented as a fixed gameplay defect or erased by the successful rerun.

## Package runner correction

The first runner attempted `--path/--main-pack/--script` on the release template, which rejected unsupported path overrides. The original report/logs remain as `evidence/windows_release_flow/historical_unsupported_override*`. The repaired runner separates editor-engine PCK UI execution from actual release EXE default-scene smoke. It also preserves the manifest's UTC timestamp instead of reparsing a deserialized DateTime as local time. The failed historical report's shifted timestamp is not authoritative.

A later attempt against the final PCK exited 0 before its last UI capture/report, and the runner correctly failed freshness/completeness checks. It occurred during an interrupted session; the cause is unproven. Its report/log remain in `historical_incomplete_ui.json` and `.log`. The clean final rerun generated all 22 captures and the 56-check report; no stale outputs were accepted.

Current exported EXE SHA-256: `D34D36F3BE1A6C49C56525AE86469B92E4F417DDF0B43CF00DD80C385C4B0562`.
Current exported PCK SHA-256: `C2C725C0D52894A70218B703EFF47F5900A5A027A474D6AB7B84B624CBD2F81E`. The final validation report verifies 154 source hashes and stable EXE/PCK/manifest before and after both passing stages.

## Reproduction and remaining gates

Use the verified Godot 4.7.2 toolchain from [TOOLCHAIN.md](TOOLCHAIN.md). Source runners: `validate_all.ps1`, `compare_render_rates.ps1`; graphical harnesses: `ui_flow.gd`, `presentation_scenarios.gd`; measurements: `profile_windows.ps1`; media: `capture_gameplay.ps1` then `inspect_gameplay_media.ps1`; packaging: `export_windows.ps1` then `validate_windows_build.ps1`. All are under `tools/validation/`. Run profiles without competing graphical processes and retain old reports separately when comparing revisions.

Close native-window keyboard match/pause/rematch/menu/exit from its full report, then save the final handoff checkpoint. Physical controllers, human competitive feel and subjective audio listening remain explicit limits; successful import, script execution, still images and numerical audio measurements do not certify those.
