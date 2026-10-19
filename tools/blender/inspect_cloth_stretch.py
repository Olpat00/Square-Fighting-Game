import bpy,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
for fid in sys.argv[sys.argv.index('--')+1:]:
    bpy.ops.wm.open_mainfile(filepath=str(root/'source_art/characters'/fid/'curated.blend'))
    rig=bpy.data.objects['FighterRig'];rig.animation_data.action=bpy.data.actions['heavy_side']
    tick=json.loads((root/'docs/moves/move_timing.json').read_text())['fighters'][fid]['moves']['heavy_side']['startup']+1
    bpy.context.scene.frame_set(tick);report=[]
    for mesh in [bpy.data.objects['CharacterMesh']]:
        evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());data=evaluated.to_mesh();rows=[]
        for p in mesh.data.polygons:
            ids=list(p.vertices)
            from mathutils import Vector
            center=sum((data.vertices[i].co for i in ids),Vector())/len(ids)
            if .78<p.center.z<1.13 and (center-p.center).length>.3:
                rows.append({'polygon':p.index,'rest_center':list(p.center),'after_edge':(center-p.center).length,'posed_center':list(center),'ratio':0,'vertex_weights':[{mesh.vertex_groups[g.group].name:round(g.weight,3) for g in mesh.data.vertices[i].groups} for i in ids]})
            for a,b in zip(ids,ids[1:]+ids[:1]):
                before=(mesh.data.vertices[a].co-mesh.data.vertices[b].co).length;after=(data.vertices[a].co-data.vertices[b].co).length
                if after>.10 and after>before*2.5:
                    rows.append({'polygon':p.index,'rest_center':list(p.center),'after_edge':after,'ratio':after/max(.00001,before),'vertex_weights':[{mesh.vertex_groups[g.group].name:round(g.weight,3) for g in mesh.data.vertices[i].groups} for i in [a,b]]});break
        if rows:report.append({'mesh':mesh.name,'count':len(rows),'examples':sorted(rows,key=lambda r:-r['after_edge'])[:6]})
        evaluated.to_mesh_clear()
    print('STRETCH',fid,json.dumps(report),flush=True)
