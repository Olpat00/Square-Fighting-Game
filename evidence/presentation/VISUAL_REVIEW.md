# Actual gameplay presentation review — 2026-09-22

Final run: **54 genuine 1920×1080 captures, 113 trigger checks, zero trigger failures**. Godot 4.7.2, Forward+, NVIDIA GeForce RTX 4080 SUPER, Fair Fight, seed 4261. `presentation_scenarios.json` records the exact input, simulation tick, move tick, animation time, positions, camera, damage, objects and capture state for every frame. `../presentation_run.log` is the executed log.

These images come from the real `main.tscn`, arena, HUD, imported rigs and live abilities. Initial positions/resources are controlled fixtures. Scripted inputs enter the normal gameplay path. The harness advances actual combat at 60 Hz and pauses at the recorded tick for a viewport screenshot; it does not seek attack poses, invent hits, composite effects, or manufacture marks. This is graphical acceptance evidence, not a frame-time measurement or a human playtest.

## Framing and scope

`match_1v1_action.png` and `high_damage_launch.png` use the actual game camera and its 12.5 minimum size. Their corresponding `_detail` images show the same frozen simulation through a closer setting of that same camera. Most ability images also use this explicitly labeled closer QA framing, retaining the camera angle and ordinary arena lights. The five `_normal_light` frames intentionally focus on one fighter. These closer views must not be presented as the default match view.

The run covers five recognizable confirmed models, a real jab contact, a high-damage launch, all 20 directional specials, all five ultimate warnings and active phases, Clutch/Fine Print finishers, all three Sunstruck solar pulses, Heavy Duty grab/lift/slam and chair finisher, grounded stomp and airborne elbow/landing wave, both counter responses, Deadfall trap arming, Fine Print trace during hitstop, and Heavy Duty's seated chair taunt/cleanup. UI navigation, four-player play, and headless rules validation have separate reports.

## Inspected results and corrections

| Area | Observed result in current game captures |
| --- | --- |
| Identity and ordinary light | Clutch/Wes quarter-zip, Sunstruck/Will tropical clothing, Heavy Duty/Damion armor, Deadfall/Jaydon flannel and Fine Print/Josh polo retain source faces, proportions, clothing and textures. The latter two source mappings were explicitly supplied by the user; the costumes were not repainted to resemble the brief's photographic labels. No missing textures or exploded skin appeared in reviewed poses. |
| Clutch contact | The rush now closes to bodily shoulder contact, with the leading arm tucked behind the brace. The opener no longer damages from the former 1.75m separation. The final uppercut reaches the captured opponent at 0.7m; compare `f01_clutch_special_side.png` and `f01_clutch_ultimate_finisher.png`. Thin kinetic rims leave faces and limbs visible. |
| Sunstruck | Backhand disc, curved ribbon, raised-arm recovery, low reflector placement and alternating ultimate gestures are distinct. The reflector sits on the deck; the three real solar pulses appear inside the visible warning region. The target and attacker remain visible through the open impact ring, rather than a full-screen flash. |
| Heavy Duty | The narrower command grab closes to an actual reaching distance. The old trajectory raised the victim's feet above the hands; the final fixed tick path holds the victim's waist/upper body near the hands. Side/ultimate lift and final slam frames show continued bodily contact. The chair is aligned under the slam. The source's unified costume bends without detached plates or torn joints in these poses. |
| Heavy airborne down special | A separate tucked elbow action is visible while genuinely airborne at move tick 17, Y=5.259, downward velocity=-18.367. The same move later lands and creates the real ground wave. This test exposed and prompted removal of down-input fast fall during attack startup; descent is now owned by the ability. |
| Heavy chair taunt | `f03_heavy_duty_taunt1_chair.png` shows the pelvis on the 0.55m seat and shoes near the deck. An authored opening gesture precedes the sit, then a standing recovery. The temporary chair is spawned by the live kit and expires afterward; the harness also checks cleanup. |
| Deadfall | The planted shoe now sits above the visible plank surface instead of intersecting through it. The raised other foot is intentional. Log, temporary recovery branch and armed tripline are present. The tree and diagonal warning show the affected region while retaining readable fighters. |
| Fine Print | The advancing kick no longer travels deeply through the victim before contact. The outer-range thrust has a visible shaft starting at the measured palm and ending in the authoritative hit region. `f05_fine_print_special_neutral_hitstop.png` shows the real 10% hit, persistent trace and earned **P1** Citations ticket above P2 during hitstop. Three non-colliding recovery steps and a bounded rectangular ultimate trace support the actual move shapes. |
| Camera and background | Default action and launch views retain both fighters and the stage. No exposed sky-backdrop boundary was visible in the sampled framing, including the high airborne test. Near views preserve readable HUD, player markers and attack effects. The broad default view makes hands/faces small; it is for positional combat rather than facial detail. |

`../characters/contact_measurements.json` contains actual evaluated Blender surface and bone measurements at the recorded game clip times. It is a static replay of the source action and does not reproduce Godot transition blending. Examples: final Clutch shoulder contact roots 0.97m apart with forward mesh reach 0.46m plus the 0.42m victim hurt radius; Heavy side contact roots 1.25m apart with mesh reach 0.92m; Deadfall planted surface minimum approximately 0.096m above a 0.09m plank; Fine Print palm approximately (forward 0.63m, height 1.47m).

## Remaining visual limitations

- Hands and faces preserve the scans. There are no finger or facial bones, so a grasp reads through hand/forearm placement rather than closed fingers, and expressions remain fixed.
- Heavy Duty's armor and tunic form one skinned mesh. They flex with the body instead of behaving as separate rigid plates or simulated cloth.
- Some committed Heavy poses place the lowest boot vertices roughly 2–9cm below the nominal floor. This minor sole penetration is visible on close inspection; ordinary standing and the chair sit are seated correctly. It is not an authoritative collision change.
- Foot planting during starts, turns, acceleration and contact blends is approximate. The separately measured run/walk stance is stable at matched nominal speed; that measurement does not prove every transition is free of sliding.
- Brief impact overlap and a 0.06-second presentation blend remain. Numeric coverage and these selected screenshots are not exhaustive inspection of all animation frames or a claim of motion-capture-quality performance.

## Reproduce

From the workspace root:

```powershell
& 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'Game File' --resolution 1920x1080 --script '../tools/validation/presentation_scenarios.gd'
```

Use `-- --case=f03_heavy_duty --output=<absolute-directory>` for an isolated subset without overwriting the full report. The machine report deliberately leaves visual grading to this separate inspected record.
