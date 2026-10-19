# Known issues and validation limits

<!-- LIVING_ARENAS_CURRENT_BEGIN -->
## Living arenas — current validation limits

The five animated arenas pass the current 25-view assistant review, deterministic High/Low scenery-clock and restoration checks, source gate, five-match lifecycle and exported Windows checks. Five fully decoded 12-second ambient clips at measured 1600×900 provide current 0/2/5/10-second assistant sample-frame review. The ten cases recorded 41 intervals above 16.667 ms out of 71,983 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers. The full matrix uses a 120 FPS render cap, with VSync disabled. It measures this explicitly controlled workload and its headroom against a 16.667 ms frame budget; it is not an uncapped stress result or a device/driver fix. Exact frame maxima and CPU/GPU percentiles are in [PERFORMANCE.md](PERFORMANCE.md); no outlier cause is inferred from aggregate samples.

The earlier uncapped matrix stopped during Lunar Reach High after Vulkan lost-device breadcrumbs and a native signal 11 crash; an unclean Windows restart was observed. Only the two Rooftop cases completed. The failed native log and process-failure receipt became entirely NUL bytes and cannot establish exit status. The intact engine log, partial reports and corrupt files are preserved in `evidence/background_rebuild/performance/aborted_uncapped_20261004/`, with `failure.json` recording these limitations. The root cause remains unknown. The capped matrix does not conceal, supersede or resolve that failure.

- Still-image review covers High/Low, overlap, recovery and near-ledge fixtures. Scenery clips hold four stationary fighters in normal gameplay framing; this does not cover every moving-camera recovery, combat pose or platform transition.
- Human gameplay, continuous human motion/audio judgment and physical multi-controller operation remain unverified. The ambient clips do not establish sound-mix quality or competitive balance.
- The performance matrix covers this workstation at 1080p with four CPU fighters. Weaker-PC, current Mobile-renderer and exported-build performance remain unverified.
- Prior platform/map movies and historical fighter comparisons describe earlier builds. Current background evidence is limited to the explicitly bound stills, state checks and five ambient clips.
- Archive completion is recorded separately in `evidence/background_rebuild/delivery.json` after strict packaging; documentation promotion alone does not certify the ZIP.

Original-asset permission records and earlier engine/device failure histories below remain retained verbatim. No new permission or driver-resolution claim is made by this visual pass.
<!-- LIVING_ARENAS_CURRENT_END -->

<!-- LIVING_ARENAS_HISTORY_BEGIN -->
## Historical records before the living-background upgrade

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current living-background acceptance is above. Any earlier heading or text calling a result current applies only to its recorded snapshot. The preceding platform runtime, docs, tools and Windows build are preserved under `evidence/background_rebuild/baseline/`. Earlier failure histories remain retained.
<!-- LIVING_ARENAS_HISTORY_END -->

<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->
## Platform refinement — current validation limits

The rebuilt platform surfaces on all five arenas pass the current 25-view assistant review, source gate, five-match lifecycle and exported Windows checks. The ten cases recorded 1,650 intervals above 16.667 ms out of 564,786 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers. Exact frame maxima and CPU/GPU percentiles are in [PERFORMANCE.md](PERFORMANCE.md); no outlier cause is inferred from aggregate samples.

- Still-image review covers High/Low, overlap, recovery and near-ledge fixtures. It cannot establish temporal shimmer or every combat pose and moving-platform transition.
- Human gameplay, continuous motion/audio judgment and physical multi-controller operation remain unverified.
- The performance matrix covers this workstation at 1080p with four CPU fighters. Weaker-PC, current Mobile-renderer and exported-build performance remain unverified.
- Prior map movies and historical fighter comparisons predate the platform finishes; they are not current platform-motion acceptance.
- Archive completion is recorded separately in `evidence/platform_refinement/delivery.json` after strict packaging; documentation promotion alone does not certify the ZIP.

Original-asset permission records and earlier engine/device failure histories below remain retained. No new permission or driver-resolution claim is made by this visual pass.
<!-- PLATFORM_REFINEMENT_CURRENT_END -->

<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->
## Historical records before the platform refinement

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current platform acceptance is above. The pre-platform runtime, docs, tools, Windows build and map evidence are preserved under `evidence/platform_refinement/baseline/`. Earlier failure histories remain retained.
<!-- PLATFORM_REFINEMENT_HISTORY_END -->

This document covers the October 3 five-arena source and presentation, including The Last Resort, Lunar Reach, Verdant Shrine, Abyssal Observatory and Ember Foundry. The current [source gate](../evidence/validation_all.json) passes all 11 suites after import, with 5,097 assertions. The completed [ten-case performance receipt](../evidence/map_expansion/performance/after_reboot_20261003/profile_provenance.json) verifies unchanged runtime sources and accepted art during measurement. Windows build and release-executable acceptance are tracked separately in [VALIDATION.md](VALIDATION.md); source and profiling checks alone do not establish packaged-build acceptance. See [current status](../STATUS.md).

## Historical limits before platform refinement

- **Asset and motion acceptance:** all eight articulated rigs and 619 clips pass structure, High/Low parity and protected re-export checks. Final torso repairs passed assistant review in both facings, and 32 first-active-frame jab/heavy fixtures capture successfully. Captured normal/half-speed movies, full MP4 decoding and selected-frame inspection do not establish continuous human judgment of weight, motion or contact. A passing clip/rig assertion is not a judgment of animation quality.
- **Physical controllers:** assignment/isolation, disconnect, input release and pause/resume have synthetic coverage. Actual multiple pads, analog travel, deadzones, triggers, reconnect and rumble remain unverified because no devices were connected. Only one keyboard profile is supported.
- **Frame pacing and hardware scope:** the completed five-arena matrix measures ten isolated 60-second, 1080p, uncapped four-CPU High/Low cases on the Ryzen 7700X/RTX 4080 SUPER workstation, totaling **645,002 render-interval samples**. Case P95 values range from 0.896 to 2.723 ms and P99 values from 1.677 to 3.724 ms. Four samples exceed 16.667 ms: The Last Resort High **23.537 ms**, Lunar Reach High **18.607 ms**, Verdant Shrine Low **23.143 ms**, and Ember Foundry High **18.203 ms**, one in each case. The other six cases have no over-budget samples. Readback occurs after timing; no synchronized spike trace establishes the outliers' cause. These source-project measurements support the 60 FPS target on this machine with the stated exceptions; they are not a zero-stutter, weaker-PC, current Mobile-renderer or exported-build performance claim. Current results and historical two-player measurements remain in [PERFORMANCE.md](PERFORMANCE.md).
- **Human gameplay and audio review:** automated scenarios and accelerated complete matches cover rules, CPU actions, results and rematches. Human playtesting and continuous normal-speed motion/audio review remain outstanding; the checks do not establish competitive balance, movement feel, sound mix quality, repetition fatigue or physical-controller usability.
- **Training tape scope:** one in-memory opponent tape lasts up to ten seconds and is cleared on rematch/leaving training. F6 replaces the previous tape. F7 loops it with a 0.75-second neutral gap and combat reset. There is no tape export/import or collection of saved recordings.
- **Art scope:** background guests are simplified, and source-derived faces/costumes retain some supplied mesh/texture limitations. Torso repairs remove hand-weighted waist spikes, fused sleeve bridges and torn vest edges; small underarm seam darkness/openings and bounded angular cloth folds/lining remain in reviewed poses. New gloves close for strikes; grab poses retain a deliberate partial opening to hold a victim. Bounded foot planting improves contact but cannot guarantee zero clipping in every attack, grab or moving-platform transition. Full model replacement with production facial topology is outside the completed derivative-art work.

Low changes stage/effect costs immediately and selects 1K character textures on the next match; High restores canonical 2K textures at match creation. Deferring model replacement avoids switching a live skeleton mid-attack. At UI scale 1.25, selection/settings/results intentionally scroll and focused controls remain reachable.

The first five identity mappings remain confirmed: Wes → Clutch, Will → Sunstruck, Damion → Heavy Duty, Jaydon → Deadfall and Josh → Fine Print. The other three names come from supplied filenames, without inferred real-person identities. October 3 derivatives change clothing detail, silhouettes and rigging while preserving recognizable faces and immutable originals.

Cosmetic Party breakup uses bounded fragments and never removes authoritative platforms. The KO log's `assists` field contains stock contributors including the credited finisher; last-hit credit expires after ten seconds and contributors reset on respawn.

## Historical evidence and resolved-source issues

- Earlier captures showed fixed hands/scanned expressions, unified flexible Heavy Duty armor and approximate foot placement. The October 3 derivatives add weighted digits/facial bones, separate armor and bounded visual foot planting. Do not treat the old clips as footage of the new models.
- Earlier movie samples showed clipped or overlapping player labels. The current source uses screen-space safe bounds and separation, with four-label/corner regression coverage and rendered overlap fixtures.
- Godot 4.7.2 intermittently exited with `0xc0000005` after successful assertions. A Windows dump and disassembly located the fault in `GDScriptLanguage::finish`, matching [Godot issue 117975](https://github.com/godotengine/godot/issues/117975) and its [upstream fix](https://github.com/godotengine/godot/pull/117991). The project workaround moves static keyboard-binding state from the inherited `HumanInputProvider` script into an explicitly preloaded script extending native `RefCounted`; public input APIs and `controls.cfg` remain unchanged. Historical workaround acceptance includes fifteen predetermined 76-check animation runs, the later 80-check two-arena suite, that rebuild's complete aggregate, exported-PCK UI and actual release EXE, all with normal exits. The current five-arena source gate expands animation coverage to **86 checks**, also passing with exit 0. See [the diagnosis](../evidence/rebuild/native_exit_diagnosis.json), [the repeated-run evidence](../evidence/rebuild/native_exit_fixed.json) and [the current source gate](../evidence/validation_all.json). The game still uses Godot 4.7.2; this is a validated project workaround rather than an engine upgrade.
- The first five-arena performance run stopped during Lunar Reach High after completing only The Last Resort High and Low. Vulkan reported a lost device and a native crash; subsequent graphics initialization failed, and NVIDIA's diagnostic reported `GPU is lost` with a reboot instruction. Windows was restarted before the successful ten-case rerun described above. Preserve [the aborted-run receipt](../evidence/map_expansion/performance/final_20261003/failure.json) and [GPU diagnostic](../evidence/map_expansion/gpu_diagnostic.txt) as failure history; the two partial results are not the current matrix. The underlying cause remains unknown and is not attributed to a particular arena, shader or driver defect.
- Earlier native input-injection regression reached results/rematch, but the user stopped further computer use before one normal-window exit report. This is an archived validation gap, not a restriction on current work.
- The old 600-tick 1600×900/60 fps movie was decoded and reviewed through twenty ordered stills; its mixed audio was measured, not subjectively listened to. It does not establish continuous-motion or performance acceptance for October 3.
- The first package runner attempted unsupported editor-only overrides with a release template. Its failure remains in `evidence/windows_release_flow/historical_unsupported_override.json`. The corrected workflow uses the matching editor for the PCK harness and the release EXE's own main scene for executable launch tests.

This is local play. Seeded checks on one machine do not establish cross-platform determinism, rollback, online play or iOS support. Source-model/texture redistribution permissions and commercial title/likeness clearance remain unverified; see [PROVENANCE.md](PROVENANCE.md).
