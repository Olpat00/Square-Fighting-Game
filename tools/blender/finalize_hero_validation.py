"""Tie final structural evidence to the exact shipped asset bytes."""
import hashlib,json
from pathlib import Path
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[2]
EVIDENCE=ROOT/'evidence/characters/hero_rebuild'
def read(path):return json.loads(path.read_text())
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
assets=read(EVIDENCE/'asset_validation.json')
repro=read(EVIDENCE/'reproducibility.json')
control=read(EVIDENCE/'active_control_export_test.json')
low={row['fighter_id']:row for row in read(ROOT/'evidence/characters/texture_tiers.json')['fighters']}
structural={row['fighter_id']:row for row in read(ROOT/'evidence/characters/export_validation.json')}
assert assets['pass'] and repro['pass'] and control['pass']
rows=[]
for row in assets['fighters']:
    fid=row['fighter'];high=ROOT/'Game File/assets/characters'/(fid+'.glb');tier=high.with_name(fid+'_low.glb')
    source=ROOT/'source_art/characters'/fid/'curated.blend';portrait=ROOT/'Game File/assets/portraits'/(fid+'.png')
    portrait_metadata=read(ROOT/'evidence/characters/portraits'/(fid+'.json'))
    assert row['runtime_sha256']==sha(high)==low[fid]['source_sha256']==sha(EVIDENCE/(fid+'_reproducibility.glb'))
    assert row['curated_sha256']==sha(source)==portrait_metadata['curated_source_sha256']
    assert low[fid]['low_sha256']==sha(tier) and low[fid]['mesh_skin_animation_metadata_and_bytes_identical']
    assert structural[fid]['structural_pass'] and structural[fid]['runtime_sha256']==sha(high)
    assert row['runtime_bone_count']==60 and row['weighted_bone_count']==59
    assert portrait_metadata['curated_source_unchanged'] and portrait_metadata['resolution']==[768,768]
    if fid=='f01_clutch':assert control['source_file_sha256']==sha(source)
    rows.append({'fighter':fid,'curated_sha256':sha(source),'high_sha256':sha(high),'low_sha256':sha(tier),'portrait_sha256':sha(portrait),'high_bytes':high.stat().st_size,'low_bytes':tier.stat().st_size,'runtime_triangles':row['runtime_triangles'],'clips':row['clip_count'],'material_batches':row['runtime_material_batches'],'pass':True})
report={'generated_at_utc':datetime.now(timezone.utc).isoformat(),'fighters':rows,'pass':True,'scope':'Final asset bytes, editable sources, portraits, source preservation, active IK export, clip structure and exact re-export. Runtime playback/performance are separate.'}
(EVIDENCE/'release_assets.json').write_text(json.dumps(report,indent=2))
table='| Fighter | Runtime triangles | Runtime bones | Clips | Material batches | High bytes | Low bytes |\n| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n'
for row in rows:table+=f"| {row['fighter']} | {row['runtime_triangles']:,} | 60 | {row['clips']} | {row['material_batches']} | {row['high_bytes']:,} | {row['low_bytes']:,} |\n"
body='''# Character validation record

Final asset validation completed October 3, 2026 using Blender 5.2.0 LTS. This record covers the rebuilt eight-fighter roster. September engine captures and 20-bone reports are historical; current runtime acceptance lives under `evidence/rebuild/`.

'''+table+'''
All eight runtime skeletons retain 60 semantic bones, including the explicit unweighted root. Their 59 weighted bones include all 30 finger joints, two toes, four arm twists and four small facial deformers. Eleven animator controls remain editable in Blender and are excluded from the GLBs. The roster retains 619 clips and the existing move/attachment names.

## Executed asset checks

- `hero_validate.py` passed all eight editable/runtime contracts: weighted fingers, normalized binding, complete clip and semantic-bone export, control exclusion, and unchanged original supplied GLB hashes.
- Every curated source was re-exported to a separate file. All eight runtime GLBs matched their production files byte for byte, and all eight curated source files retained their hashes throughout export.
- `inspect_exports.py` inspected every exported animation sampler: no missing required clips, constant-only clips, non-finite values or duration errors. Skin sums passed for all eight. Clip starts are zero-based and durations match authored 60 Hz frame counts within 0.001 seconds.
- An active IK hand edit moved the hand by 0.188679 m. Re-imported exported motion matched within '''+f"{control['roundtrip_error_m']:.10f}"+''' m; the semantic root survived and control bones were excluded. The artist-owned source remained unchanged.
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
'''
(ROOT/'docs/animation_validation.md').write_text(body,encoding='utf-8')
print('FINAL_HERO_ASSET_VALIDATION_PASS',len(rows),'fighters',sum(row['clips'] for row in rows),'clips')
