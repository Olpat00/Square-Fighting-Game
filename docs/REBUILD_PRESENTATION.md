# Rebuild presentation integration — October 3, 2026

The live match now uses `MatchCamera`: close exchanges use a 9.6-unit minimum height for two players or 11.8 for three/four, with faster expansion than contraction. Small idle motion falls inside a focus dead zone. An outer safety frame overrides smoothing for launches and recoveries. The bottom of that frame reserves room for the HUD. Shake uses elapsed seconds; focus, zoom, shake and particles retain their paused state.

`PlayerLabels` places four stable screen-space labels inside safe margins, resolving shared positions in slot order and drawing short leader lines where needed. The existing model-review Label3D remains available when fighters are used outside the main match UI. Training shortcuts ignore auto-repeat and are inactive while paused.

When a match ends, camera bounds follow the staged winner/loser presentation positions. A final KO near or beyond a blast boundary cannot leave the results cast outside the camera frame.

The Last Resort retains its architecture and four collision planes, with a warmer key/cooler fighter fill, quieter sky and guests, restrained foliage movement and pool reflections. Lunar Reach now stands over a clear recovery chasm: foreground boulders and front support clutter have moved out of the fight plane, the central distant ridge is lower, central torso-height railings are removed, and the horizon/terrain have quieter cool contrast. Alloy finish variation is restrained so it does not resemble camouflage under direct light. Both arenas' gameplay platform dimensions, hazards and motion solver are unchanged.

`stage.apply_quality("High" | "Low")` restores captured original presentation settings when switching back to High. Low disables decorative point lights, secondary scenery and expensive postprocessing, reduces decorative shadow work, and selects simplified water/foliage/terrain/metal shaders. Lunar Low uses one ninth of the main terrain triangles and one quarter of scattered rocks. Character model and effect limits continue to use the existing tier interface.

Impact feedback separates compact shield contacts, launches, light hits, heavy hits and KOs. Existing audio now rotates available impact samples with restrained pitch variation, prefers free voices, briefly ducks the background mix under heavy impacts, and pauses active effect voices with combat.

## Verification

- `tools/validation/presentation_state.gd`: 130 checks, zero failures. Covers 30/60/144 render FPS, paused camera/effects, asymmetric zoom, four labels crowded at all screen corners, High/Low restoration, terrain cost reduction and recovery geometry clearance. Twelve results-camera cases exercise actual four-player finishes on both arenas.
- `tools/validation/stage_scenarios.gd`: 36 checks, zero failures.
- `tools/validation/rebuild_stage_review.gd`: 10 fresh 1920×1080 captures with the final hero assets, covering both arenas' High/Low neutral view, overlapping players, wide recovery and near-ledge recovery. Output: `evidence/rebuild/stages/`; production shaders compiled successfully on Vulkan Forward+.
- `tools/validation/rebuild_match_flow.gd`: 14 graphical lifecycle checks pass across both arenas, including final results, rematch and return to setup/menu. Fresh results/rematch captures are under `evidence/rebuild/full_match/`.
- `tools/validation/rebuild_lunar_light_probe.gd`: reproducible separate SSAO/SSIL/shadow diagnostic frames. The visible alloy speckle survived removal of each lighting feature and was fixed in the material's metallic/roughness variation. Diagnostic output is historical and is not the final material.

These fixtures verify rendering and state behavior. Final arena/results captures were refreshed after the eight-fighter art import. They are separate from CPU/GPU/frame-pacing measurements and continuous human motion reviews. No physical-controller operation or human feel judgment is claimed by automated checks.
