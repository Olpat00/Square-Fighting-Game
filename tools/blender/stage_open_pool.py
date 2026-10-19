"""Inspection correction: cut a genuine water opening in the terrace substrate.
Same four substrate bands are part of stage_build.py for clean regeneration.
"""
import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'source_art/stage';OUT=ROOT/'Game File/assets/stage';E=ROOT/'evidence/stage'
BANDS=[('front',(0,2.6125,-.505),(22,1.925,.42)),('rear',(0,10.5375,-.505),(22,2.825,.42)),('left',(-9.275,6.35,-.505),(3.45,5.55,.42)),('right',(7.925,6.35,-.505),(6.15,5.55,.42))]
def bands():
    added=[];mat=bpy.data.materials['Slate | fine honed volcanic stone']
    for name,loc,size in BANDS:
        bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name='Pool opening substrate '+name;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
        b=o.modifiers.new('Machined edge radius','BEVEL');b.width=.04;b.segments=3;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');added.append(o)
    return added
for filename in ['the_last_resort_modeling.blend','the_last_resort.blend']:
    bpy.ops.wm.open_mainfile(filepath=str(SRC/filename));scene=bpy.context.scene
    if not scene.get('pool_opening_fixed',False):
        if 'modeling' in filename:
            bpy.data.objects['Hospitality slab'].location.z-=.40;bands()
        else:
            ob=bpy.data.objects['architecture__Slate']
            # The substrate's original vertices lie at z -0.945..-0.295;
            # select its connected component by vertex extents, avoiding other stone.
            adj=[[] for _ in ob.data.vertices]
            for e in ob.data.edges:a,b=e.vertices;adj[a].append(b);adj[b].append(a)
            seen=set()
            for start in range(len(adj)):
                if start in seen:continue
                ids=[];stack=[start];seen.add(start)
                while stack:
                    i=stack.pop();ids.append(i)
                    for j in adj[i]:
                        if j not in seen:seen.add(j);stack.append(j)
                lo=[min(ob.data.vertices[i].co[k] for i in ids) for k in range(3)];hi=[max(ob.data.vertices[i].co[k] for i in ids) for k in range(3)]
                if abs(hi[0]-lo[0]-22)<.01 and abs(hi[1]-lo[1]-10.3)<.01 and abs(hi[2]+.295)<.01:
                    for i in ids:ob.data.vertices[i].co.z-=.40
            added=bands();bpy.ops.object.select_all(action='DESELECT')
            for part in added:
                bpy.context.view_layer.objects.active=part
                for mod in list(part.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
                part.select_set(True)
            ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.join()
        scene['pool_opening_fixed']=True;bpy.ops.wm.save_as_mainfile(filepath=str(SRC/filename))
center=[o for o in scene.objects if o.get('group')=='center_platform'];static=[o for o in scene.objects if o.type=='MESH' and o not in center and o.get('group')!='skyline']
bpy.ops.object.select_all(action='DESELECT')
for o in static:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'stage.glb'),export_format='GLB',use_selection=True,export_yup=True,export_extras=True,export_apply=True)
report=json.loads((E/'stage_manifest.json').read_text());report['mesh_vertices']=sum(len(o.data.vertices) for o in static+center);report['triangles']=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in static+center);report['inspection_corrections'].append('Continuous terrace substrate replaced by four perimeter bands above lower foundation');(E/'stage_manifest.json').write_text(json.dumps(report,indent=2));print('POOL_OPENING_EXPORTED',flush=True)
scene.render.filepath=str(E/'stage_review.png');bpy.ops.render.render(write_still=True)
