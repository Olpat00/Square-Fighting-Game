# Executable milestone plan

Preserve `Assets/` byte-for-byte and retain the existing `Game File/` project layout. Keep runtime-only derivatives inside the Godot project. Write source rigs and scenery to `source_art/`, scripts to `tools/`, and genuine evidence to `evidence/`.

1. **Preflight and mapping.** Run engine/editor import, Blender background Python and graphical renderer probes. Inspect all five supplied meshes, render contact sheets, record source hashes/skeleton/material/texture data and mapping confidence. Save reports.
2. **Vertical slice.** Integrate the first real rigged character with authored clips. Implement fixed-tick movement/platform support, input abstraction, authoritative contact collection/resolution, stocks and respawn, fixed blast zones, shared camera. Run timing/movement/stock tests and inspect a running two-character scene.
3. **Complete combat/Clutch.** Implement move states, charge/cancels, shields/parries/dodges, grabs/throws, ownership cleanup, resources, and Clutch mechanics. Add same-arena training and stage-aware CPU. Test before expanding dependencies.
4. **Five distinct fighters.** Integrate processed rigged models, data definitions and focused mechanics. Validate every clip/move, unique abilities, mirrors, all pairings, recovery and asset mapping.
5. **Single signature arena and complete loop.** Integrate Blender architecture, one-way support/moving lift, announced hazards, local slots, selection/title/pause/results/rematch.
6. **Polish and usability.** Complete audio, VFX, model portraits, content/accessibility/settings controls, input remapping, personality/flourishes. Inspect normal 1v1/four-player gameplay and all ultimates.
7. **Stability and handoff.** Run seeded fuzz/stress/rematch/scenario suites and measure graphical frame times at 1080p, test separate Mobile renderer profile, export and launch Windows build, write concise source/controls/extensibility/iOS/provenance notes.

Each milestone updates STATUS.md with exact executed commands, evidence, failures and next action. No milestone is marked achieved while its exit criteria are missing. Keep reversible source checkpoints in local Git.
