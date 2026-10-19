# Five-arena delivery complete

Verdant Shrine, Abyssal Observatory and Ember Foundry are integrated and delivered with the original two arenas. The verified Windows archive is `builds/RooftopRiot-Five-Arenas-Windows.zip`; `delivery.json` records its exact SHA-256, all 22 decoded payload entries, and the source/build/validation bindings. Editable sources and reproduction instructions are in `docs/MAP_EXPANSION.md`.

Current evidence:

- Source: import plus 11 suites, 5,097 assertions and 515 unchanged runtime files (`evidence/validation_all.json`).
- Full match/results/rematch lifecycle: five arenas, 35 passing checks (`evidence/rebuild/match_flow.json`).
- Exported-PCK interface: 108 passing checks and 40 fresh captures (`evidence/windows_release_flow/validation.json`). The prior rebuild receipt and captures are retained under `prior_rebuild_windows_release_flow/`.
- Actual Windows EXE: three new arenas, each completing 600 ticks with four CPU providers, combat contacts, clean exits and fresh 1080p images (`release_validation.json`). Seven fresh UI/gameplay stills were inspected (`release_visual_review.json`).
- Ten isolated 60-second profiles at 1080p, all five arenas on High/Low, four CPUs (`performance/after_reboot_20261003/`). The 645,002 samples contain four intervals over 16.667 ms; worst P99 is 3.724 ms. CPU/GPU metrics and outliers remain in `docs/PERFORMANCE.md`.
- Fifteen earlier accepted new-map stills, three normal/half-speed movies and twelve sampled movie frames remain in their existing evidence folders.

The initial Vulkan lost-device failure remains archived. A user-performed Windows restart restored the GPU; the full subsequent run passed, but the original failure cause is unknown. The first map release validator mistook texture-size metadata for image dimensions. Its failed receipt and case history remain preserved; the corrected validator checks window, readback and decoded PNG dimensions, retains metadata separately, and all fresh reruns pass. Neither correction changed runtime source or art.

The supplied originals, pre-expansion backup and prior `RooftopRiot-Rebuild-Windows.zip` are preserved. Human playtesting, subjective audio/continuous-motion acceptance, physical controllers and weaker-PC performance remain unverified. These are documented limits, not unfinished automated delivery steps. No repeat profiling or packaging is required unless relevant inputs change.
