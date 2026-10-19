import bpy,json
from pathlib import Path
root=Path.cwd();out=[]
for fid in ['f05_fine_print','f06_rugged_explorer','f08_midnight_gentleman']:
    bpy.ops.wm.open_mainfile(filepath=str(root/'source_art/characters'/fid/'curated.blend'))
    rig=bpy.data.objects['FighterRig'];parts=[]
    for mesh in [o for o in bpy.data.objects if o.type=='MESH' and o.get('character_asset')]:
        groups={g.index:g.name for g in mesh.vertex_groups};bad=[]
        for v in mesh.data.vertices:
            p=v.co
            if abs(p.x)<.225 and .95<p.z<1.29 and p.y<.05:
                w={groups[g.group]:g.weight for g in v.groups};arms=sum(value for name,value in w.items() if name.startswith(('forearm','hand.','upper_arm','index_','thumb_','middle_','ring_','pinky_')))
                if arms>.08:bad.append({'vertex':v.index,'rest_position':list(p),'arm_weight':arms,'weights':w})
        if bad:parts.append({'mesh':mesh.name,'count':len(bad),'largest':sorted(bad,key=lambda row:row['arm_weight'],reverse=True)[:12]})
    out.append({'fighter':fid,'parts':parts})
(root/'evidence/characters/hero_rebuild/torso_binding_review.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out))
