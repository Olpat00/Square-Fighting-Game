# Character validation record

Final asset validation completed October 3, 2026 using Blender 5.2.0 LTS. This record covers the rebuilt eight-fighter roster. September engine captures and 20-bone reports are historical; current runtime acceptance lives under `evidence/rebuild/`.

| Fighter | Runtime triangles | Runtime bones | Clips | Material batches | High bytes | Low bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| f01_clutch | 50,550 | 60 | 78 | 6 | 11,195,392 | 8,153,492 |
| f02_sunstruck | 55,094 | 60 | 77 | 5 | 15,369,424 | 10,376,388 |
| f03_heavy_duty | 59,453 | 60 | 78 | 5 | 14,490,168 | 10,204,420 |
| f04_deadfall | 53,672 | 60 | 77 | 5 | 13,061,832 | 9,212,052 |
| f05_fine_print | 56,224 | 60 | 78 | 8 | 11,987,072 | 8,690,764 |
| f06_rugged_explorer | 62,082 | 60 | 77 | 7 | 14,703,972 | 10,260,444 |
| f07_urban_sentinel | 51,264 | 60 | 77 | 6 | 13,288,684 | 9,372,292 |
| f08_midnight_gentleman | 55,762 | 60 | 77 | 6 | 12,484,648 | 9,114,620 |

All eight runtime skeletons retain 60 semantic bones, including the explicit unweighted root. Their 59 weighted bones include all 30 finger joints, two toes, four arm twists and four small facial deformers. Eleven animator controls remain editable in Blender and are excluded from the GLBs. The roster retains 619 clips and the existing move/attachment names.

## Executed asset checks

- `hero_validate.py` passed all eight editable/runtime contracts: weighted fingers, normalized binding, complete clip and semantic-bone export, control exclusion, and unchanged original supplied GLB hashes.
- Every curated source was re-exported to a separate file. All eight runtime GLBs matched their production files byte for byte, and all eight curated source files retained their hashes throughout export.
- `inspect_exports.py` inspected every exported animation sampler: no missing required clips, constant-only clips, non-finite values or duration errors. Skin sums passed for all eight. Clip starts are zero-based and durations match authored 60 Hz frame counts within 0.001 seconds.
- An active IK hand edit moved the hand by 0.188679 m. Re-imported exported motion matched within 0.0000002980 m; the semantic root survived and control bones were excluded. The artist-owned source remained unchanged.
- The Low builder verified identical mesh, skin, animation, accessor and material metadata and every non-image buffer byte for all eight. Texture images are at most 1024 pixels per dimension; normal averages are renormalized.
- All eight 768-square portraits were rendered from final curated models using Cycles/OptiX on the RTX 4080 SUPER. Separate editable portrait studios and metadata were saved. Portrait rendering left each curated source unchanged.
- `finalize_hero_validation.py` cross-checked report hashes against the actual current High, Low, curated and portrait files. `release_assets.json` identifies these exact delivery bytes.

## Visual corrections and evidence

Actual pilot renders exposed crumpled scan-derived costume patches. Clutch and Urban Sentinel now use simpler fitted trims; Fine Print has a continuous fitted V-neck vest with a button placket. These costume edits preserved every existing animation curve. Heavy Duty has separate rigid breast/abdominal plates with overlapping edges and flexible surrounding costume. Purpose-built articulated gloves replace the damaged distal scan hands, while supplied originals stay untouched.

The first-active-frame Godot contact fixtures exposed additional cloth fans on Fine Print, Explorer and Gentleman. Fine Print received smooth torso-bound vest edges. Explorer and Gentleman received closed replacement sleeves and fitted side/back cloth; retained coat-tail arm influences were transferred to pelvis without flattening thigh binding. Their original fronts, trousers and equipment remain. The old scanned arm/cuff remnants were removed using original arm-weight metadata. Both-facing previews and final front portraits were reviewed before publication, and all existing action curves were checked unchanged. The fresh-build recipe includes the accepted repairs.

The focused visual review included heavy_side in both facings for all eight fighters and selected jab1 fixtures, with inspection-camera/debug overlays. It checked silhouette, gross limb/cloth defects, planted feet and gripping hands at first contact. It is not an every-move or human-playback acceptance. Final portraits show the preserved front clothing clearly. Small angular source-cloth folds, exposed lining and dark underarm seams remain close-view limitations on the two repaired jackets; current Godot footage is the authority for motion and gameplay contact.

The final independent clip inspection found that grounded sole cleanup had canceled the old pelvis-only shield breath. The repaired `shield_hold` uses a small chest/spine cycle with unchanged duration and planted legs; all other clips were hash-checked unchanged. The `win` mouth channels were also repaired after identifying the wrong victory-clip alias. Fresh `hero_rebuild.py` generation includes the accepted tailoring, breathing and victory-expression corrections; separate repair scripts preserve timestamped curated revisions before modifying existing scenes.

Selected current Blender views are in `evidence/characters/hero_rebuild/<id>/`; the final portrait contact sheet is `final_portrait_roster.jpg`. Earlier pilot images, historical contact sheets and revision files remain development evidence and must not be mistaken for exhaustive final approval. Current engine captures take precedence for real gameplay contact, both facings, transitions and interruptions.

## Acceptance boundaries

Asset structure and exact reproduction passed. These checks do not certify every animation frame, gameplay feel, human playtesting, physical controllers or weaker-PC performance. Facial motion is restrained and the glove articulation is custom authored; no scanned person's appearance was replaced. Heavy Duty's two torso plates are rigid, but remaining clothing and costume details still use skin deformation rather than cloth simulation. Current Godot animation, combat, full-match and performance results are reported separately in the rebuild validation notes.

Key reports: `hero_rebuild/asset_validation.json`, `hero_rebuild/reproducibility.json`, `hero_rebuild/active_control_export_test.json`, `hero_rebuild/release_assets.json`, `export_validation.json`, `texture_tiers.json`, and `portraits/<id>.json` under `evidence/characters/`.
