# UNSUPERVISED: ROOFTOP RIOT — production status

<!-- LIVING_ARENAS_CURRENT_BEGIN -->
## Living arenas — validated source and Windows build

All five arenas now have scene-specific moving backgrounds. The original illustrated mattes and photographs remain untouched; localized shader animation and layered 3D scenery add movement, depth and setting-specific life. The picture does not wobble as a whole. Background motion follows the authoritative stage clock, freezes during pause and resets with the match. Low keeps the main ambient motion with fewer animals, particles or secondary details. The finished platforms, collision layouts, combat timing and Party hazard behavior are retained.

5,097 source assertions; 25 reviewed 1080p arena views; 378 scenery assertions/70 timed, pause and reset stills across High/Low; five fully decoded 12-second/60 FPS ambient clips (1600×900) with assistant sample-frame review; five completed CPU matches/35 lifecycle checks; 108 exported-PCK UI checks/40 captures; actual Windows EXE smoke on each of the three added arenas; ten isolated 60-second four-player profiles using a 120 FPS render cap, with VSync disabled. Exported **2026-10-04T19:39:14.0345852Z** with Godot 4.7.2; **537 runtime files** match the current source, build, still-review, motion-media and performance inventories (`F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825`).

The ten cases recorded 41 intervals above 16.667 ms out of 71,983 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers. The full matrix uses a 120 FPS render cap, with VSync disabled. It measures this explicitly controlled workload and its headroom against a 16.667 ms frame budget; it is not an uncapped stress result or a device/driver fix. Current data are in `evidence/background_rebuild/performance/final_capped120/`; still review is `evidence/background_rebuild/visualreview.json`, clock/pause/reset acceptance is `evidence/background_rebuild/review_motion/living_background_review.json`, and current ambient media are bound in `evidence/background_rebuild/motion/movie_receipt.json`. Earlier map and fighter movies describe historical presentation.

The earlier uncapped matrix stopped during Lunar Reach High after Vulkan lost-device breadcrumbs and a native signal 11 crash; an unclean Windows restart was observed. Only the two Rooftop cases completed. The failed native log and process-failure receipt became entirely NUL bytes and cannot establish exit status. The intact engine log, partial reports and corrupt files are preserved in `evidence/background_rebuild/performance/aborted_uncapped_20261004/`, with `failure.json` recording these limitations. The root cause remains unknown. The capped matrix does not conceal, supersede or resolve that failure.

Package target: `builds/RooftopRiot-Living-Arenas-Windows.zip`. The receipt `evidence/background_rebuild/delivery.json` establishes completion of archive packaging; this documentation generator does not certify an archive. Pre-background backups and the prior Platform-Upgrade ZIP are retained. Human playtesting, physical multi-controller testing, continuous human motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant visual review of scenery fixtures and automated CPU matches do not establish competitive balance, sound-mix quality or zero clipping in every combat pose.
<!-- LIVING_ARENAS_CURRENT_END -->

<!-- LIVING_ARENAS_HISTORY_BEGIN -->
## Historical records before the living-background upgrade

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current living-background acceptance is above. Any earlier heading or text calling a result current applies only to its recorded snapshot. The preceding platform runtime, docs, tools and Windows build are preserved under `evidence/background_rebuild/baseline/`. Earlier failure histories remain retained.
<!-- LIVING_ARENAS_HISTORY_END -->

<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->
## Platform refinement — validated source and Windows build

Main decks and raised platforms on all five arenas have rebuilt surface construction. Flat face normals and chamfered geometry give the slabs distinct top, edge and underside planes. The authored landing planes, arena layouts and lift behavior are retained. Materials and detail follow each arena's setting; High and Low retain readable platform edges.

5,097 source assertions; 25 current 1080p platform views; five completed CPU matches/35 lifecycle checks; 108 exported-PCK UI checks/40 captures; actual Windows EXE smoke on each of the three added arenas; ten isolated 60-second four-player profiles. Exported **2026-10-04T17:42:41.6458493Z** with Godot 4.7.2; **525 runtime files** match the current source, build, visual-review and performance inventories (`5D87C1AAB5E7C45183D0AFD7AD941C8BC2456A96F0A1326730F16A60C202B7B0`).

The ten cases recorded 1,650 intervals above 16.667 ms out of 564,786 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers. Current data are in `evidence/platform_refinement/performance/final/`; still review is `evidence/platform_refinement/visualreview.json`. Earlier map and fighter movies describe the pre-platform presentation.

Package target: `builds/RooftopRiot-Platform-Upgrade-Windows.zip`. The receipt `evidence/platform_refinement/delivery.json` establishes completion of archive packaging; this documentation generator does not certify an archive. Pre-platform backups and the prior Five-Arenas ZIP are retained. Human playtesting, physical multi-controller testing, continuous motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant still review and automated CPU matches do not establish competitive balance or zero clipping in every pose.
<!-- PLATFORM_REFINEMENT_CURRENT_END -->

<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->
## Historical records before the platform refinement

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current platform acceptance is above. The pre-platform runtime, docs, tools, Windows build and map evidence are preserved under `evidence/platform_refinement/baseline/`. Earlier failure histories remain retained.
<!-- PLATFORM_REFINEMENT_HISTORY_END -->

<!-- MAP_EXPANSION_HISTORICAL_BEGIN -->
## Historical five-arena expansion before platform refinement — verified Windows build

Three new maps are integrated: **Verdant Shrine**, **Abyssal Observatory**, and **Ember Foundry**. Each has a distinct layout, generated distant scenery, locally editable 3D geometry/materials, animated details and Party hazards. Existing fighters, move timing, the original two collision layouts, inputs and 60 Hz combat remain intact. Shared recovery/CPU logic now reads actual arena dimensions.

Current validation: 5,097 source assertions, 108 packaged UI checks/40 captures, five full matches/35 lifecycle checks, three actual Windows EXE arena smokes and ten isolated 1080p four-player performance cases. The ten cases contain 4 intervals above 16.667 ms out of 645,002 samples; the full table retains those outliers.

Play `builds/windows/RooftopRiot.exe` or extract `builds/RooftopRiot-Five-Arenas-Windows.zip`. Exact export time is 2026-10-03T22:40:09.3475549Z; all 515 runtime file hashes are checked. Prior archive `builds/RooftopRiot-Rebuild-Windows.zip` and `Fighting Game Map Expansion Backup 20261003-174209` remain preserved.

[Map sources and reproduction](docs/MAP_EXPANSION.md) · [validation](docs/VALIDATION.md) · [performance](docs/PERFORMANCE.md). Human/physical-controller playtesting and weaker-PC performance remain open. The following section records the earlier rebuild, not the current package manifest.
<!-- MAP_EXPANSION_HISTORICAL_END -->

## Prior eight-fighter rebuild — historical state before arena expansion

The approved scope is [REBUILD_PLAN.md](docs/REBUILD_PLAN.md): all eight fighters and both existing arenas, led by The Last Resort, with stylized realism, clearer motion and weightier combat. This remains a local Windows game with stable fighter/move IDs and 60 Hz combat.

The sibling folder `Fighting Game Backup 20261002-103700` preserves the pre-edit source, editable art, supplied originals, exported build and uncommitted work. Supplied originals remain untouched. `builds/windows/` now contains the matching October 3 EXE/PCK, exported at 20:45:26 UTC and verified against 467 runtime source files.

### Integrated source work

- All eight hero derivatives have 71-bone editable rigs, including 11 animator controls, and 60-bone runtime rigs. Thirty finger joints, toes, twist joints and restrained expressions are weighted. The roster has 619 runtime clips, matching 2K/1K tiers and refreshed portraits. Final torso repairs pass both-facing still inspection; all eight asset-structure, tier-parity and protected re-export checks pass.
- Fighter presentation profiles, transition-specific blends, stride/contact metadata and bounded visual foot planting. Curated Blender actions survive re-export; active animator controls are sampled into runtime clips without exporting control bones.
- Closer shared camera with fast zoom-out, gradual zoom-in and recovery containment; separated/clamped player labels; elapsed-time shake and effect lifetimes that freeze during pause.
- Rooftop warm/cool lighting and quieter background guests/sky. Lunar contrast and geometry now leave a readable recovery corridor. High/Low changes scenery, decorative lighting/shadows, postprocessing, shaders, terrain and effects as well as next-match character textures.
- Per-move aerial steering and explicit movement priority, revised impact/landing tuning, CPU spacing/recovery/punish/confirm behavior, and training move-phase/combo diagnostics.
- F6 records/saves player-two input; F7 loops/stops playback. Tapes are bounded to ten seconds, pause with combat and reset combat state between loops.
- Fine Print's Corporate Ladder uses elapsed move ticks for repeated melee contacts, preventing hitstop from continually restarting the same contact. Sunstruck's repeating effect contacts use the effect's own age. Attack collision remains independent of the rendered skeleton.
- Fine Print's Final Ruling hit-region center moves from `(1.45, 1.08)` to `(1.05, 1.25)` to match its straight punch. Radius, damage and combat timings stay the same; its horizontal reach is 0.4 units shorter. This is an explicit combat-data change, separate from visual posing.
- Results-camera framing follows staged winners and losers, including finishes at distant stage positions.

See [presentation integration](docs/REBUILD_PRESENTATION.md), [controls](docs/controls.md) and [animation pipeline](docs/animation_pipeline.md) for interfaces and reproduction.

### Validation and evidence

The final source gate passes import plus all 11 suites with zero failed processes or logged warnings/errors: 4,956 assertions, four settings scenarios, 36 pairings, a four-CPU round and 20 rematches. Scene-node count remains 91 before/after the rematch soak. All eight supplied original hashes are preserved. The animation suite includes 80 checks, presentation 130 and stages 36. Final-asset accelerated complete-match/results/rematch fixtures pass 14 across both arenas, and all ten final 1080p arena readability fixtures capture successfully. Final High/Low/source/portrait hashes are recorded in `evidence/characters/hero_rebuild/release_assets.json`.

An intermittent Godot 4.7.2 shutdown access violation was traced to inherited-script static-state cleanup. Keyboard binding state now lives in an explicitly preloaded native-base store, preserving controls and settings. Fifteen scheduled animation-suite runs each passed 76 checks and exited normally after this workaround; the expanded 80-check suite and complete final aggregate also exit cleanly. See `evidence/rebuild/native_exit_diagnosis.json`, `native_exit_fixed.json` and the [upstream engine issue](https://github.com/godotengine/godot/issues/117975).

The final 30/144 render-delta comparison matches all compared combat state after 1,200 ticks, including 51 contacts and two KOs. That is a headless simulation check, not a frame-pacing result. All eight isolated 1080p cases complete 60 seconds/3,600 ticks with unchanged source/art/harness hashes. Every four-player High/Low sample is below 16.667 ms, with frame P99 of 1.546–2.436 ms. Each two-player run has one 31.140–41.056 ms outlier; the cause remains unassigned. All requested fighters stay alive throughout these runs. See [performance](docs/PERFORMANCE.md) for separate CPU/GPU/callback measurements and the related, nonidentical baseline workloads.

Normal/half-speed fighter movies cover all eight on the rooftop plus Clutch/Heavy Duty facing left on Lunar Reach. Pilot before/rebuild comparisons and 15-second four-CPU samples on both arenas are also available. Each brawl advances 900 ticks with 43 contacts; its High screenshots are 1080p while native movie output is 1600×900. All 28 MP4s pass full decoding with SHA-256 receipts in `evidence/rebuild/motion_media_validation.json`. The 32 first-active-frame jab/heavy fixtures cover all eight fighters in both facings. These are captured and sampled visual evidence, not continuous human review.

### Windows delivery and remaining review

The Windows build passes 78 packaged UI checks with 30 fresh 1080p captures, plus an actual executable run of 600 ticks/four fighters/33 contacts. Both processes exit 0 without warnings/errors and source/build hashes remain unchanged. Exact EXE/PCK hashes and export time are in `builds/windows/build_manifest.json` and [validation](docs/VALIDATION.md). The packaging tool creates `builds/RooftopRiot-Rebuild-Windows.zip` only after matching source, art, profile and Windows receipts, and writes archive-entry hash verification to `evidence/rebuild/delivery.json`.

Physical multi-controller operation, continuous human motion/audio review, human gameplay testing and weaker-PC performance remain unverified. Minor source-derived cloth seam/fold limitations remain documented in [known issues](docs/KNOWN_ISSUES.md).

## Historical deliveries

The September 29 delivery introduced Lunar Reach and the eight-fighter attack presentation pass. Its focused record contains 488 headless assertions, 57 exported-PCK fixture checks and a 180-tick executable launch. That short verification was not a performance certification. See [LUNAR_UPGRADE.md](docs/LUNAR_UPGRADE.md) and `evidence/lunar_upgrade/`.

The September 28 package included eight fighters, with 71 graphical UI checks, 28 captures, a 600-tick executable smoke run and 36 mirror/distinct pairings. The earlier rooftop scene pass preserved gameplay while refining architecture/materials; its record is in [GRAPHICS_UPGRADE.md](docs/GRAPHICS_UPGRADE.md), [CHECKPOINT.md](docs/CHECKPOINT.md) and `evidence/visual_overhaul/scene_revision3/release/`.

Earlier notes about fixed hands/faces, unified flexible armor, overlapping labels and callback-only performance profiles describe those older revisions. They are not an assessment of the October 3 source. Earlier native-computer-use work stopped before one normal-window exit report; that historical gap does not replace the current rebuild's acceptance work.
