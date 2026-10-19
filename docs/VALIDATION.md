# Validation record

<!-- LIVING_ARENAS_CURRENT_BEGIN -->
## Living arenas — current acceptance

Exported **2026-10-04T19:39:14.0345852Z** with Godot 4.7.2; **537 runtime files** match the current source, build, still-review, motion-media and performance inventories (`F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825`).

| Check | Current result | Evidence |
|---|---|---|
| Source and preservation | Import plus all 11 suites pass; 5,097 assertions; eight supplied originals and 106 existing bitmaps preserved | `evidence/validation_all.json`, `evidence/background_rebuild/preservation.json` |
| Stage/presentation/motion regression | 120 stage, 181 presentation and 86 animation assertions | Source gate suite records |
| Arena review | 25 exact, reviewed 1080p stills: High, Low, overlap, recovery and near-ledge on every arena | `evidence/background_rebuild/visualreview.json` |
| Scenery clocks and restoration | 378 assertions across ten arena/tier cases; 0/2/5/10-second samples, pause through render frames and requested world steps, quality roundtrip and reset | `evidence/background_rebuild/review_motion/living_background_review.json` |
| Current ambient clips | Five High/60FPS, 12-second stationary-player fixtures at measured 1600×900; exact media/harness reports hashed, full decode and assistant sample-frame review recorded | `evidence/background_rebuild/motion/movie_receipt.json` |
| Full lifecycle | Five natural CPU matches through results and rematch; 35 checks | `evidence/rebuild/match_flow.json` |
| Exported UI | 108 checks and 40 current 1080p images; matching editor loads the explicit exported PCK | `evidence/windows_release_flow/validation.json` |
| Actual executable | Default 600-tick/four-CPU run plus each added arena at 600 ticks with explicit CPU providers and contacts; clean exits | Windows receipt and `evidence/map_expansion/release_validation.json` |
| Performance | Ten current source/art/harness-bound 60-second High/Low cases, five arenas, four CPU fighters, 1080p; a 120 FPS render cap, with VSync disabled | `evidence/background_rebuild/performance/final_capped120/profile_provenance.json` |

Current stills establish assistant visual review of those exact images, including background composition, player visibility and landing-edge readability. The scenery harness proves clock ownership and deterministic pause/reset/restoration; state changes alone do not prove attractive or visible motion. Current ambient clips are fully decoded and their 0/2/5/10-second samples inspected for five stationary-player fixtures. Actual video dimensions (1600×900) are measured separately from the 1080p stills and profile window, with no upscaling. These samples do not establish continuous human acceptance or every combat/recovery sequence. Earlier map movies and before/after fighter comparisons remain historical. Screenshot readback and movie capture are excluded from the profile window.

The ten cases recorded 41 intervals above 16.667 ms out of 71,983 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers. The full matrix uses a 120 FPS render cap, with VSync disabled. It measures this explicitly controlled workload and its headroom against a 16.667 ms frame budget; it is not an uncapped stress result or a device/driver fix.

The earlier uncapped matrix stopped during Lunar Reach High after Vulkan lost-device breadcrumbs and a native signal 11 crash; an unclean Windows restart was observed. Only the two Rooftop cases completed. The failed native log and process-failure receipt became entirely NUL bytes and cannot establish exit status. The intact engine log, partial reports and corrupt files are preserved in `evidence/background_rebuild/performance/aborted_uncapped_20261004/`, with `failure.json` recording these limitations. The root cause remains unknown. The capped matrix does not conceal, supersede or resolve that failure.

The dedicated ZIP target is `builds/RooftopRiot-Living-Arenas-Windows.zip`. Packaging separately verifies source/build/UI/EXE/lifecycle/profile receipts and every archive entry, writing `evidence/background_rebuild/delivery.json`. Human playtesting, physical multi-controller testing, continuous human motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant visual review of scenery fixtures and automated CPU matches do not establish competitive balance, sound-mix quality or zero clipping in every combat pose.
<!-- LIVING_ARENAS_CURRENT_END -->

<!-- LIVING_ARENAS_HISTORY_BEGIN -->
## Historical records before the living-background upgrade

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current living-background acceptance is above. Any earlier heading or text calling a result current applies only to its recorded snapshot. The preceding platform runtime, docs, tools and Windows build are preserved under `evidence/background_rebuild/baseline/`. Earlier failure histories remain retained.
<!-- LIVING_ARENAS_HISTORY_END -->

<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->
## Platform refinement — current acceptance

Exported **2026-10-04T17:42:41.6458493Z** with Godot 4.7.2; **525 runtime files** match the current source, build, visual-review and performance inventories (`5D87C1AAB5E7C45183D0AFD7AD941C8BC2456A96F0A1326730F16A60C202B7B0`).

| Check | Current result | Evidence |
|---|---|---|
| Source and preservation | Import plus all 11 suites pass; 5,097 assertions; eight supplied originals preserved | `evidence/validation_all.json` |
| Stage/presentation/motion regression | 120 stage, 181 presentation and 86 animation assertions | Source gate suite records |
| Platform review | 25 exact, reviewed 1080p stills: High, Low, overlap, recovery and near-ledge on every arena | `evidence/platform_refinement/visualreview.json` |
| Full lifecycle | Five natural CPU matches through results and rematch; 35 checks | `evidence/rebuild/match_flow.json` |
| Exported UI | 108 checks and 40 current 1080p images; matching editor loads the explicit exported PCK | `evidence/windows_release_flow/validation.json` |
| Actual executable | Default 600-tick/four-CPU run plus each added arena at 600 ticks with explicit CPU providers and contacts; clean exits | Windows receipt and `evidence/map_expansion/release_validation.json` |
| Performance | Ten current source/art/harness-bound 60-second High/Low cases, five arenas, four CPU fighters, 1080p | `evidence/platform_refinement/performance/final/profile_provenance.json` |

Current platform stills establish assistant visual review of those exact images, including face shading and landing-edge readability. They do not establish temporal shimmer, continuous motion or human acceptance. Earlier map movies and before/after fighter comparisons remain historical. Screenshot readback is excluded from the profile window.

The ten cases recorded 1,650 intervals above 16.667 ms out of 564,786 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers.

The dedicated ZIP target is `builds/RooftopRiot-Platform-Upgrade-Windows.zip`. Packaging separately verifies source/build/UI/EXE/lifecycle/profile receipts and every archive entry, writing `evidence/platform_refinement/delivery.json`. Human playtesting, physical multi-controller testing, continuous motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant still review and automated CPU matches do not establish competitive balance or zero clipping in every pose.
<!-- PLATFORM_REFINEMENT_CURRENT_END -->

<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->
## Historical records before the platform refinement

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current platform acceptance is above. The pre-platform runtime, docs, tools, Windows build and map evidence are preserved under `evidence/platform_refinement/baseline/`. Earlier failure histories remain retained.
<!-- PLATFORM_REFINEMENT_HISTORY_END -->

<!-- MAP_EXPANSION_HISTORICAL_BEGIN -->
## Historical five-arena expansion before platform refinement: recorded acceptance

The three new arenas are Verdant Shrine, Abyssal Observatory and Ember Foundry. The Last Resort and Lunar Reach remain available. The current build was exported at **2026-10-03T22:40:09.3475549Z** with Godot 4.7.2, and its **515 runtime files** match the validated source inventory.

| Check | Result | Evidence |
|---|---|---|
| Source and preservation | Import + all 11 suites pass; 5,097 assertions, four settings scenarios, 36 pairings and 20 rematches. All eight supplied originals preserved. | `evidence/validation_all.json` |
| New arena behavior | 120 stage checks; 181 presentation checks; 86 animation checks, including complete lift cycles. Low reductions/restoration and paused clocks are covered on all five maps. | Stage, presentation and animation reports referenced by the source gate |
| Full match lifecycle | Five complete CPU matches; 35 checks; results, stock losses and clean rematches. | `evidence/rebuild/match_flow.json` |
| Graphical review | 15 current High/Low, overlap, wide recovery and near-ledge captures reviewed; no blocking still-image findings. | `evidence/map_expansion/visual_review.json` |
| Continuous footage | Three 900-tick CPU movies; 29 / 43 / 41 contacts for Shrine / Observatory / Foundry. Normal and half-speed MP4s fully decode. Native movies are 1600×900; PNGs are 1920×1080. | `evidence/map_expansion/brawl/<arena>/capture_validation.json` |
| Exported package UI | 108 checks and 40 fresh captures using the matching engine on the exported PCK; clean exit. | `evidence/windows_release_flow/validation.json` |
| Actual Windows EXE | Each new arena completes 600 ticks with four explicit CPU providers and combat contacts; clean exit, fresh 1080p capture, source/build hashes unchanged. | `evidence/map_expansion/release_validation.json` |
| Performance | Ten source-bound, isolated 60-second cases, all five arenas at High/Low with four CPU fighters. | [Measured results](PERFORMANCE.md) |

The full source gate initially exposed an outdated mock stage interface and a six-second lift test that did not cover the slower ocean lift. The mock now implements the arena-bounds interface and the animation test samples each complete cycle, including ascent/descent and foot anchors. These fixture repairs did not change gameplay rules. The initial failed report is retained in `evidence/map_expansion/initial_source_gate_failure.json`.

The first three-map EXE validator rejected the texture-size metadata even though the window, actual image readback and saved PNG were all 1920×1080. The same metadata discrepancy exists in the prior accepted build. The runner now checks window, image and PNG dimensions and retains texture metadata separately; all three fresh reruns pass. This validation-only correction changes no runtime files. The failed receipt is retained in `evidence/map_expansion/release_size_metadata_failure.json`, with original case outputs under `release/history/`.

Human playtesting, physical controllers, subjective audio/continuous-motion acceptance and weaker-PC performance remain unverified. Automated matches and assistant still review do not establish competitive balance. Current delivery is `builds/RooftopRiot-Five-Arenas-Windows.zip`; its final receipt is `evidence/map_expansion/delivery.json`.
<!-- MAP_EXPANSION_HISTORICAL_END -->

## Prior eight-fighter rebuild: historical acceptance before map expansion

Final source, asset, graphical lifecycle, Windows build and isolated performance checks pass. Current checks use Godot 4.7.2 on Windows and the protected October 2 baseline. `Fighting Game Backup 20261002-103700` preserves the prior source, exported build, originals and uncommitted work. All eight supplied original model hashes remain unchanged.

| Check | Current result | Evidence |
|---|---|---|
| Art pipeline | Eight 60-bone runtime rigs and 619 changing clips pass after the final torso repairs; High/Low geometry, skin and animation parity. All eight re-exports produce identical GLB bytes and leave curated sources unchanged. Final High/Low/source/portrait hashes recorded at 20:31:59 UTC. | `evidence/characters/hero_rebuild/release_assets.json`, `asset_validation.json`, `reproducibility.json`, `active_control_export_test.json`; `evidence/characters/texture_tiers.json` |
| Input and engine exit | 2,442 input checks; 15 predetermined animation runs each passed 76 checks and exited 0 after the static-state workaround. | `docs/moves/input-validation.json`, `evidence/rebuild/native_exit_fixed.json` |
| Presentation | 130 checks, including results framing; 36 stage checks. Animation integration: 80 checks including moving lifts. | `evidence/presentation_state.json`, `evidence/lunar_upgrade/stage_scenarios.json`, `evidence/rebuild/animation_scenarios.json` |
| Aggregate runtime gate | PASS: import plus all 11 suites, 4,956 assertions, four settings scenarios, 36 pairings, a four-CPU round and 20 rematches. Every process exits 0 with no logged warnings/errors; all eight original hashes match. | `evidence/validation_all.json` |
| Render-rate independence | PASS: 1,200 combat ticks at fixed 30/144 render deltas produce matching damage/stocks/positions/states, 51 contacts and two KOs. Headless simulation check; frame pacing is measured separately. | `evidence/render_rate_comparison.json` |
| Graphical lifecycle | Final-asset accelerated full-match/results/rematch: 14 checks, zero failures, clean exit. Rooftop: 270 contacts/11 KOs; Lunar: 306 contacts/11 KOs. Exported-PCK UI: 78 checks and 30 fresh 1080p captures. | `evidence/rebuild/full_match/match_flow.json`, `evidence/windows_release_flow/validation.json` |
| Arena readability fixtures | Ten fresh 1920×1080 captures with final assets: High/Low, four overlapping labels, wide recovery and near-ledge recovery on both arenas. | `evidence/rebuild/stages/stage_review.json` |
| Motion and contact | All eight rooftop/right fighter movies, Clutch/Heavy Duty lunar/left movies and labeled pilot baseline comparisons complete. All 28 review MP4s, including the brawls below and every half-speed version, fully decode and have recorded SHA-256 hashes. 32 first-active-frame jab/heavy captures across eight fighters and both facings have zero fixture failures. | `evidence/rebuild/motion_media_validation.json`, `motion/`, `motion_lunar/`, `comparison/`, `contact/contact_review.json` |
| Ordinary four-player captures | Both arenas: 15-second actual-main-scene CPU movies, 900 combat ticks and 43 contacts per case, clean exits. High screenshots are 1080p; native movies are 1600×900. | `evidence/rebuild/brawl/rooftop_riot/capture_validation.json`, `brawl/lunar_reach/capture_validation.json` |
| Torso repair review | Six accepted heavy-pose stills: Fine Print, Rugged Explorer and Midnight Gentleman in both facings. Root and independent assistant review; image hashes recorded. | `evidence/rebuild/torso_visual_acceptance.json` |
| Sustained 1080p performance | Eight isolated 60-second/3,600-tick cases pass at 1080p with source/art/harness unchanged. All four-player frame samples stay below 16.667 ms; every two-player run has one retained 31.140–41.056 ms outlier. CPU/GPU rendering and callback monitors are recorded separately. | `evidence/rebuild/performance/final_20261003/profile_provenance.json`; [full results](PERFORMANCE.md) |
| Windows package | PASS: 467 runtime source files verified before/after, matching EXE/PCK/manifest hashes. PCK UI passes on the matching editor; the actual release EXE runs its own main scene for 600 ticks with four fighters/33 contacts. Both exit 0 with no warnings/errors. | `builds/windows/build_manifest.json`, `evidence/windows_release_flow/validation.json` |

The animation harness checks finite leg poses, bounded stance correction, measured planting improvement, hitstop freeze, unchanged combat roots, walk/run phase, per-instance profiles, same-clip restart and attachment aliases. Clutch and Heavy Duty ride each arena's actual lift through ascent/descent in four additional passing checks. Gameplay checks exercise aerial control, explicit lunge/recovery priority, landing commitment, buffering, recording/playback, CPU decisions and repeated contacts through hitstop. Stage tests preserve authoritative platforms, hazard behavior and arena rematches.

Fine Print's Final Ruling heavy-side hit-region center changed from `(1.45, 1.08)` to `(1.05, 1.25)` in authored combat data to align its straight punch with visible contact. The circle radius, startup, active frames, recovery, damage and other combat values remain unchanged; the maximum horizontal reach decreases by 0.4 units. Move-purpose text now describes a straight rather than a heel strike. The exported 200-move data comparison found only this offset/purpose change (`evidence/rebuild/fine_print_move_data_parity.json`). The final content suite passes 1,777 checks, abilities 193 and gameplay 136. Eight added contact cases cover both facings: the fist center is 0.266 m from the region center, inside its 0.54 m radius; a target at the fist hits and the old distant target at 2.2 m misses.

The native shutdown fault was traced by dump/disassembly to `GDScriptLanguage::finish`, consistent with [Godot issue 117975](https://github.com/godotengine/godot/issues/117975) and its [upstream fix](https://github.com/godotengine/godot/pull/117991). The project moves static keyboard-binding state into a native-base store and preserves the public input API and `controls.cfg`. Diagnosis and the scheduled repeat-run evidence are in `evidence/rebuild/native_exit_diagnosis.json` and `native_exit_fixed.json`. Passing assertions do not override an unsuccessful process exit.

The Windows build was exported at `2026-10-03T20:45:26.2819737Z` using `4.7.2.stable.official.ed1daf0bf`. Its verified SHA-256 hashes are:

| File | SHA-256 |
|---|---|
| `RooftopRiot.exe` | `D34D36F3BE1A6C49C56525AE86469B92E4F417DDF0B43CF00DD80C385C4B0562` |
| `RooftopRiot.pck` | `4A6AC77347738F0A9162BDE474AADD0C51E06B73972035832A11FE4469E0F4D8` |

The executable smoke is launch/gameplay/exit coverage, not native keyboard automation, human controller use or sustained performance acceptance. Its screenshot readback and concurrent validation make its timing unsuitable for the performance table.

Movie fixtures run the actual main scene at 60 Hz with ordinary input snapshots. The roughly 12-second fighter sequence resets positions between labeled movement/combat phrases for comparability; it is not a single uninterrupted competitive exchange. Native movie output is 1600×900; labeled side-by-side pilot comparisons are 1920×540. Stage screenshots and performance runs are 1920×1080. Contact captures use a labeled inspection camera and overlays of authored hit regions, with gameplay collision independent of bones. MP4 full decoding and ordered frame inspection establish usable files and sampled visual evidence, not continuous human motion/audio review. Accelerated match fixtures and movie encoding speed do not measure real-time performance. Human playtesting, physical multiple-controller use and weaker-PC performance remain unverified.

Reproduce with `tools/validation/validate_all.ps1`, `compare_render_rates.ps1`, `capture_rebuild.ps1`, `compare_rebuild_footage.ps1`, `capture_brawl.ps1`, `profile_rebuild.ps1`, `export_windows.ps1` and `validate_windows_build.ps1`. Then run `package_rebuild.ps1 -PerformanceDirectory` with the completed eight-case profile directory. Packaging binds the accepted art, current source inventory, profile reports, manifest and package validation by hashes before archiving the explicit release files and verifying every archive entry. Run profiling separately from captures, encoding and Blender work. See [animation reproduction](animation_pipeline.md) and [current limits](KNOWN_ISSUES.md).

## Historical validation

The sections below describe earlier revisions. Several report paths are refreshed by current tools, so current files take precedence over the historical counts quoted below.

## September 29, 2026: Lunar Reach and signature attacks

The earlier second-arena/attack-presentation delivery is documented in
[LUNAR_UPGRADE.md](LUNAR_UPGRADE.md), with final captures and report in
`evidence/lunar_upgrade/`. It passed 488 focused headless checks, 57 graphical
checks against the exported PCK, a Mobile/Low representative fixture, and a
brief 180-tick actual release EXE launch. The earlier validation below remains
historical evidence for the preceding roster/rooftop revisions.

## Eight-fighter build — September 28, 2026

Rugged Explorer, Urban Sentinel and Midnight Gentleman were added after the scene
graphics revision. Their source GLBs remain byte-identical to the files supplied
by the user; their playable derivatives have 20-bone skins, 77 clips each, model
portraits and 1K Low texture versions. That Windows EXE/PCK contained all
eight fighters.

| Current check | Result | Evidence |
| --- | --- | --- |
| Blender/Godot asset structure | Three 42K-triangle rigs; 77 changing clips each; source hashes, clip timing, skin and Low-tier buffers verified | `evidence/characters/export_validation.json`, `texture_tiers.json` |
| In-engine appearance | All three imported in Forward+; idle, specials, ultimate, deformation poses and +X facing captured; feet within 0.7 mm of floor | `evidence/characters/engine/new/` |
| Full headless gate | Import plus eight suites pass; 1,777 content checks, 95 combat checks, 193 existing ability checks, 67 new-fighter checks, 36 pairings and 20 rematches | `evidence/validation_all.json` |
| Windows package | EXE/PCK exported; manifest verifies 182 runtime source files | `builds/windows/build_manifest.json`, `evidence/windows_build_manifest.json` |
| Packaged UI and runtime | 71 UI checks and 28 fresh captures pass through the exported PCK; actual release EXE completes 600 ticks with the three newcomers and Clutch, producing 30 contacts and a gameplay capture | `evidence/windows_release_flow/validation.json` |

The checks cover the new abilities and counterplay through authoritative match
ticks. Selected visual frames were inspected, while every animation frame,
physical controllers and new performance profiles remain outside this review.

## Earlier scene graphics revision

The following records describe revision 3 before the three-fighter addition.
Detailed delivery notes are in [GRAPHICS_UPGRADE.md](GRAPHICS_UPGRADE.md).

| Current check | Result | Evidence |
| --- | --- | --- |
| Blender scene export | Exit 0; revision 3, 379,996 triangles, 30 runtime materials | `evidence/stage/stage_manifest.json`, `revision3_build.log` |
| Godot import | Exit 0, no logged errors/warnings | `evidence/stage/revision3_final_import.log` |
| Source graphical preview | Three 1920×1080 frozen stills; all inspected; exit 0 | `evidence/visual_overhaul/scene_revision3/final/` |
| Source preservation | 73 checks pass, including original GLBs and unchanged authoritative stage behavior | `scene_revision3/source_integrity.json` |
| Windows export | EXE/PCK produced at 21:26:55 UTC, September 28 | `evidence/windows_build_manifest.json`, `revision3_windows_export.log` |
| Release integrity | 234 checks pass; 158 runtime source records and EXE/PCK hashes match | `scene_revision3/release_integrity.json` |
| Packaged graphics | Explicit PCK loaded by matching editor engine; three fresh stills, exit 0, no errors/warnings; gameplay-angle/architecture inspected | `scene_revision3/release/`, `revision3_package_preview.log` |

Preview folders abbreviated above are under `evidence/visual_overhaul/`; logs are
under `evidence/stage/`. The preview freezes combat, hides HUD locally, mutes audio
for its process and exits automatically. It does not save settings or simulate a
match. The architecture image uses a labeled QA perspective; gameplay does not
gain a rotating camera. Packaged-preview execution uses the editor executable,
not an unsupported external-script override of the release template.

The original full game checks, prior native observations, Forward+/Mobile timings
and recorded gameplay remain in [VALIDATION_BASELINE.md](VALIDATION_BASELINE.md).
That file is a historical snapshot from before scene revision 3; its current/pending
wording describes that earlier audit. Those passes are not presented as new revision
3 match, hardware or performance results. The user's instruction ended further
native-loop work; no new full-match run was required for the graphics pass.

The historical scene-review tools were `tools/validation/scene_look.gd`,
`tools/validation/export_windows.ps1` and `verify_scene_graphics.py --release`.
Use the verified Godot executable from [TOOLCHAIN.md](TOOLCHAIN.md). Physical pads,
human balance, subjective audio and new four-fighter performance remain unverified;
see [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
