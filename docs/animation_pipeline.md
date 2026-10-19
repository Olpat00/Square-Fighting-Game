# Character rig and animation pipeline

Current pipeline: October 3, 2026. The eight selectable fighters use protected curated Blender scenes. The original supplied GLBs, source faces and identity mapping remain preserved. Earlier September contact sheets and 20-bone reports are historical evidence, not validation of these exports.

## Source ownership and stages

| Stage | Editable source | Purpose |
| --- | --- | --- |
| Supplied originals | `Assets/<source folder>/*.glb` | Immutable reference meshes and textures; original hashes remain recorded. |
| Rig preparation | `source_art/characters/<id>/prepared.blend` | Preserved optimized baseline anatomy and binding. |
| Source motion | `source_art/motion/quaternius/standard/` | Local CC0 Standard library, archive and license; never a playable replacement character. |
| Polished character | `source_art/characters/<id>/curated.blend` | Artist-owned geometry, controls, weights, materials and all runtime actions. |
| Runtime export | `Game File/assets/characters/<id>.glb` | In-place sampled animation, stable semantic bones and merged skinned geometry. |
| Low derivative | `Game File/assets/characters/<id>_low.glb` | 1K textures with identical mesh, skin and animation bytes. |
| Portrait studio | `source_art/characters/<id>/portrait_studio.blend` | Separate editable lighting and portrait pose copied from the finished character. |

`hero_rebuild.py` prepares a curated scene only when it does not already exist. Replacing one requires the explicit `--rebuild-curated` flag and first creates a timestamped, hashed copy under that fighter's `revisions/`. Ordinary `characters_pipeline.py` calls detect `curated.blend` and export it without rebuilding actions. The legacy `<id>.blend` filename is refreshed as an alias for inspection tools; it is not the artist-owned source. The legacy `--regenerate-baseline` escape hatch is for historical baseline work, not release production.

## Identity and hero construction

| Stable ID | Supplied folder | Current construction direction |
| --- | --- | --- |
| f01_clutch | Wes | Athletic navy sportswear, fitted cyan seams, articulated combat gloves. |
| f02_sunstruck | Will | Tropical costume, solar chest crest and warm gold details. |
| f03_heavy_duty | Damion | Broader bronze silhouette, separate rigid breast and abdominal plates, flexible tunic and articulated gloves. |
| f04_deadfall | Jaydon | Reinforced flannel, workwear details and a broader brawler silhouette. |
| f05_fine_print | Josh | Fitted dark V-neck waistcoat over the recognizable pale shirt, understated green and pewter tailoring. |
| f06_rugged_explorer | Rugged Explorer | Expedition clothing, fitted sleeves, utility details and a modeled climbing carabiner. |
| f07_urban_sentinel | Urban Sentinel | Charcoal streetwear, red detailing and broader shoulders. |
| f08_midnight_gentleman | Midnight Gentleman | Midnight suit, fitted sleeves, preserved patterned tie and restrained original gold details. |

Will/Sunstruck and Damion/Heavy Duty follow the explicit identity mapping in `confirmed_character_mapping.json`. Faces, heights, original UV identity and source albedo remain recognizable. The authorized derivative redesign changes proportions, adds costume geometry, replaces damaged distal scan hands with weighted gloves, and separates Heavy Duty's torso armor. These changes are confined to derivatives. The armor's breastplate and abdominal plate are rigid separate pieces; this is not cloth simulation or a complete articulated plate suit.

The final contact review also found arm heat weights on Explorer and Gentleman's coat tails. `hero_skinning.py` transfers only those lower-coat arm influences to the pelvis while preserving thigh weights. `hero_cloth_surface.py` replaces fused sleeve/flank surfaces with closed sleeves using arm/twist gradients and fitted side/back panels. The original central fronts, faces, trousers and equipment remain. Original arm-weight metadata distinguishes obsolete scanned cuffs from trouser geometry. Fine Print's smooth vest uses torso binding. Fresh `hero_rebuild.py` generation includes these corrections; ordinary export only reads the accepted curated sources.

The one-time torso migration records its pre-repair revision. Replaying that development operation requires `--replay-pre-repair` and first snapshots the current curated scene. It is not an ordinary export step and should not be used to publish later artist edits; those edits belong in `curated.blend` and are preserved by the standard export route.

## Rig contract and editing

Each curated rig has 71 bones: 60 semantic runtime bones and 11 Blender-only animator controls. The runtime hierarchy preserves `root`, `pelvis`, `spine`, `chest`, `neck`, `head`, both clavicles, upper arms, forearms, hands, thighs, shins and feet. Added deformation bones are 30 finger joints, two toes, four arm twists and four restrained brow/mouth deformers. All 59 non-root runtime bones have weighted vertices. The explicit unweighted root is retained for the runtime contract. Godot attachment names such as `hand.L`, `hand.R`, `foot.L`, `foot.R` and `chest` remain unchanged.

Open `curated.blend`, select `FighterRig`, and use the Animator controls collection. Helpers in `hero_controls.py` snap hand, foot, or body controls to the current evaluated pose before enabling them:

```python
import sys
sys.path.insert(0, r'C:\Users\dayw9\Desktop\Codex\Games\Godot\Fighting Game\tools\blender')
from hero_controls import snap_controls, key_controls
snap_controls('hands')  # also 'feet' or 'body'
# Move the CTRL_hand.L/R targets, then key them on the desired frame.
key_controls('hands')
```

Hand/foot IK uses two-bone chains and pole controls; body controls cover pelvis, spine and chest. `ik_hands`, `ik_feet` and `body_controls` are keyable 0-1 rig properties. They default to zero so the authored FK clips retain their poses. Animator control bones never ship. Active constraints are evaluated during sampled glTF export rather than stripped. The dedicated control round-trip test moves a hand with enabled IK, exports/reimports it, and compares its actual position.

## Motion and timing

The libraries retain 619 runtime clips across eight fighters, including deformation QA clips and stable move IDs. Source motion is retargeted locally using anatomical directions. Walk/run/idle use Quaternius upper-body motion over the authored planted leg paths. Landings and jumps combine source movement with original transition endpoints; reactions use restrained torso/head transfer. Starts, stops and reversals have custom weight shifts. Ordinary strikes receive accelerating approach breakdowns and delayed torso/head recovery while preserving authored contact ticks. Special choreography and throws remain locally authored. The held shield breath is a small chest/spine cycle, leaving stance feet fixed; ground cleanup would cancel a pelvis-only breathing offset.

`docs/moves/move_timing.json` is the authoritative exported combat timing input. Blender runs at 60 fps, with frame 1 representing simulation tick zero. Export slides clips to zero time and samples every frame. Runtime locomotion is in place; visual pelvis settling never supplies authoritative movement. Combat hit regions remain authored gameplay data, independent of rendered bones.

Each `<id>_presentation.json` records measured walk/run stride, stance contact windows, transition ticks and effect sockets. Godot scales gait playback to measured travel, applies transition-specific blends, and constrains visible stance feet independently of collision. Landing presentation may continue beyond the short control lock and remains interruptible by input. Runtime behavior and contact acceptance are tested separately from asset structure.

## Reproduction

Verified tools are Blender 5.2.0 LTS and the bundled Python runtime. Run these commands from the repository directory:

```powershell
# Export the saved, curated actions; do not reconstruct them.
& 'D:\New folder\blender.exe' --background --python-exit-code 1 --python 'tools/blender/characters_pipeline.py' -- f01_clutch f02_sunstruck f03_heavy_duty f04_deadfall f05_fine_print f06_rugged_explorer f07_urban_sentinel f08_midnight_gentleman
# Inspect all assets and re-export each to a separate file for byte comparison.
& 'D:\New folder\blender.exe' --background --python-exit-code 1 --python 'tools/blender/hero_validate.py'
# Prove an active IK edit survives sampled export.
& 'D:\New folder\blender.exe' --background --python-exit-code 1 --python 'tools/blender/hero_control_export_test.py'
# Refresh Low after changing High.
& 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'tools/blender/build_runtime_texture_tiers.py'
# Refresh portraits from the finished curated models.
& 'D:\New folder\blender.exe' --background --python-exit-code 1 --python 'tools/blender/characters_portraits.py'
& 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'tools/blender/compose_hero_portraits.py'
# Inspect every exported sampler, then tie all reports to current delivery hashes.
& 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'tools/blender/inspect_exports.py'
& 'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'tools/blender/finalize_hero_validation.py'
```

`hero_validate.py` verifies source hashes, actual weights on every finger joint, runtime bone retention, control exclusion, complete action export, normalized binding, unchanged curated files and byte-identical re-export. `hero_control_export_test.py` uses a separate temporary source and never overwrites the curated file. Blender can log that it is baking unsupported constraints; this is the intended evaluation path and the round-trip test verifies the result. `inspect_exports.py` separately validates finite animation data, clip durations and skin sums; it does not inherit acceptance from historical engine captures.

`build_runtime_texture_tiers.py` regenerates 1K textures, renormalizes normal maps and verifies every non-image buffer plus mesh/skin/animation metadata unchanged. Both High and Low are imported with Godot mesh LODs. Runtime selection happens at match creation. Stage quality controls also reduce geometry, shadows and effects; the Low character tier itself reduces texture cost, not skeleton complexity.

`characters_portraits.py` copies the finished idle detail channels into a portrait-only pose, builds the separate 768-square studio, and checks the curated source hash unchanged. `--preview-only` renders without publishing the runtime portrait. No source character is uploaded to a service.

## Evidence and limits

Current asset evidence is under `evidence/characters/hero_rebuild/`; current portraits are under `evidence/characters/portraits/`. Failed/earlier pilot renders and baseline copies may remain beside final evidence as development history. The current validation record identifies the final files.

Structural checks and selected Blender poses cannot establish fluidity, complete contact correctness or controller feel. Review current Godot footage in both facings, interruptions, charge releases, grabs and moving platforms. Runtime checks, current performance, full-match acceptance and physical-controller/human playtest status are recorded by the rebuild validation documents. Tiny facial expressions and gloved finger articulation are deliberately restrained; automated retargeting and cleanup do not substitute for an animator's frame-by-frame review of every clip.

