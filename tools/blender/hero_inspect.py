import bpy, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
report=[]
for folder in sorted((ROOT/'source_art/characters').glob('f0*')):
    bpy.ops.wm.open_mainfile(filepath=str(folder/(folder.name+'.blend')))
    rig=bpy.data.objects['FighterRig'];mesh=bpy.data.objects['CharacterMesh']
    groups={g.index:g.name for g in mesh.vertex_groups}
    row={'id':folder.name,'bones':{b.name:[list(b.head_local),list(b.tail_local)] for b in rig.data.bones},'regions':{}}
    for region in ['hand.L','hand.R','head','chest','pelvis']:
        points=[v.co for v in mesh.data.vertices if any(groups.get(g.group)==region and g.weight>.5 for g in v.groups)]
        row['regions'][region]={'count':len(points),'min':[min(p[k] for p in points) for k in range(3)],'max':[max(p[k] for p in points) for k in range(3)]}
    report.append(row)
out=ROOT/'evidence/characters/hero_rebuild';out.mkdir(parents=True,exist_ok=True)
(out/'anatomy.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
