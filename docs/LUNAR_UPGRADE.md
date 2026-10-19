# Lunar Reach and signature attacks

September 29, 2026. Adds a second selectable arena and a presentation upgrade for all eight supplied fighters. The existing rooftop and character identities are retained.

## Playing the new arena

Launch `builds/windows/RooftopRiot.exe`, choose **Start a Fight** or **Training**, and choose **Lunar Reach** beneath the fighter cards. New setup defaults to Lunar Reach. The same selector switches back to **The Last Resort**. Rematch preserves the arena. Both use the established floor/platform collision layout and combat rules; the apparent environment scale does not alter attack reach or blast zones.

Lunar Reach is a crater-edge aerospace outpost, with detailed regolith, layered distant terrain, a NASA-textured Earth, cold reflected light, hard sunlight, structural trusses, grilles, fasteners and equipment. The Party rules use announced vent bursts and a moving central lift. Fair Fight and Training fix the platforms and disable hazards.

## Fighter presentation

All eight retain their supplied face, clothing, proportions, rig and authored animation clips. New attack presentation follows actual animated limbs and the move's active windows. Charge anticipation, motion ribbons, contact wakes, character-specific impact materials and temporary local light add weight without changing damage or reach.

| Fighter | Visual identity |
| --- | --- |
| Clutch | Compressed-air wakes, kinetic filaments and cool momentum arcs |
| Sunstruck | Warm solar discs, brass details and rhythmic concentric accents |
| Heavy Duty | Steel, grit, dense impact shockwaves and hot metal sparks |
| Deadfall | Timber, splinters, fieldcraft traps and organic debris |
| Fine Print | Layered paper, precise citation geometry and sharp ink-like strokes |
| Rugged Explorer | Machined grapnel, visible cable, climbing hardware and mineral impacts |
| Urban Sentinel | Armored geometry, segmented fields and structured pulse effects |
| Midnight Gentleman | Dark crescents, violet filaments and restrained gold details |

Effect lifetimes are bounded; pause and hitstop preserve attack timing. Low graphics reduces detail, and the flash slider controls effect brightness and temporary lighting. The supplied model textures remain the source of character surface detail.

## Reproduction and verification

The arena is authored in `Game File/stages/lunar_reach/`; selection lives in `stages/stage_catalog.gd`, `combat/match_world.gd`, `main.gd` and `ui/game_ui.gd`. Attack presentation lives under `presentation/` and the ability renderer in `combat/ability_controller.gd` and its visual helper.

`tools/validation/stage_scenarios.gd` checks arena switching, landing surfaces, Party warnings and Training/rematch resets. `tools/validation/lunar_visual_review.gd` captures short deterministic real-input fixtures using the ordinary runtime. Attack close-ups are labeled as QA framing. The review does not save user settings or run a prolonged CPU match. Results are recorded in `evidence/lunar_upgrade/`.

The September 29 Windows package was exported and checked with Godot 4.7.2 on
the RTX 4080 SUPER. Final results:

- 488 headless checks passed: combat 95, abilities 193, expanded roster 67,
  arena switching/rules 36, and presentation lifecycle/settings 97.
- The exported PCK passed 57 graphical fixture checks and produced 26 recorded
  gameplay/attack captures plus five arena/menu stills in
  `evidence/lunar_upgrade/release/`. All eight fighters were checked through
  real heavy, neutral-special and ultimate inputs.
- A representative Sentinel fixture passed three captures on Mobile + Low,
  stored in `evidence/lunar_upgrade/mobile_low/`.
- The actual release executable completed a 180-tick (three simulated seconds)
  four-player Lunar Reach launch check with five resolved contacts, a saved
  screenshot, and clean shutdown. Results are in `evidence/lunar_upgrade/exe/`.

These were short scripted visual and functionality checks, not a prolonged
play session or a new performance certification. Source/packaging integrity is
recorded in `evidence/lunar_upgrade/final_validation.json`. Earlier intermediate
capture folders document visual fixes and are not the delivered appearance.

The built-in ImageGen-created horizon is saved at
`Game File/assets/lunar_reach/crater_horizon.png`; the complete final prompt is
in `Game File/assets/lunar_reach/crater_horizon_generation.json`. Foreground
terrain, equipment, shadows and playable platform surfaces are rendered in 3D.
