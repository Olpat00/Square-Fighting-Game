"""Apply revision2 inspection corrections to both editable/batched scenes.
The primary stage_build.py contains identical corrections for fresh regeneration.
"""
import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'source_art/stage';OUT=ROOT/'Game File/assets/stage';E=ROOT/'evidence/stage'
def material_adjust():
    for m in bpy.data.materials:
        color=None
        if m.name=='Guests | warm gray linen':color=(.045,.065,.065,1)
        if m.name=='Guests | shaded neutral complexion':color=(.04,.043,.045,1)
        if color:m.diffuse_color=color;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=color
def stretches(ob,old_bottom,new_bottom,top):
    # Preserve upper facade vertices and move every lower vertex by a continuous
    # affine mapping. The top silhouette and authoritative surfaces do not move.
    for v in ob.data.vertices:
        world_z=(ob.matrix_world@v.co).z
        ratio=(top-world_z)/(top-old_bottom)
        v.co.z+=(new_bottom-old_bottom)*ratio
def components(ob):
    adj=[[] for _ in ob.data.vertices]
    for edge in ob.data.edges:
        a,b=edge.vertices;adj[a].append(b);adj[b].append(a)
    seen=set();out=[]
    for start in range(len(adj)):
        if start in seen:continue
        ids=[];stack=[start];seen.add(start)
        while stack:
            i=stack.pop();ids.append(i)
            for j in adj[i]:
                if j not in seen:seen.add(j);stack.append(j)
        out.append(ids)
    return out
def bounds(ob,ids):
    return [min(ob.data.vertices[i].co[k] for i in ids) for k in range(3)],[max(ob.data.vertices[i].co[k] for i in ids) for k in range(3)]
def shift(ob,ids,z):
    for i in ids:ob.data.vertices[i].co.z+=z
def stretch_component(ob,ids,bottom,new_bottom,top):
    for i in ids:
        v=ob.data.vertices[i];ratio=(top-v.co.z)/(top-bottom);v.co.z+=(new_bottom-bottom)*ratio

bpy.ops.wm.open_mainfile(filepath=str(SRC/'the_last_resort_modeling.blend'))
if not bpy.context.scene.get('surface_inspection_fixed',False):
    for ob in bpy.context.scene.objects:
        name=ob.name
        if name.startswith('Combat deck structural slab'):ob.location.z-=.06
        elif 'beveled stone edge' in name:ob.location.z-=.035
        elif 'inset dark field' in name:ob.location.z-=.015
        elif name.startswith('Pool structural liner'):ob.location.z-=.24
        elif name.startswith('Hotel podium undercroft'):stretches(ob,-8.4,-40,-.5)
        elif name.startswith('Podium facade glass bay'):stretches(ob,-8.15,-40,-.65)
        elif name.startswith('City tower mass') or name.startswith('Curtain-wall glazing'):
            coords=[(ob.matrix_world@v.co).z for v in ob.data.vertices];bottom,top=min(coords),max(coords);stretches(ob,bottom,bottom-30,top)
    material_adjust();bpy.context.scene['surface_inspection_fixed']=True
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'the_last_resort_modeling.blend'))
bpy.ops.wm.open_mainfile(filepath=str(SRC/'the_last_resort.blend'))
if not bpy.context.scene.get('surface_inspection_fixed',False):
    for ob in bpy.context.scene.objects:
        if ob.type!='MESH':continue
        group=ob.get('group','');material=ob.data.materials[0].name
        if group=='architecture' and material.startswith('Pool | deep'):shift(ob,list(range(len(ob.data.vertices))),-.24)
        elif group in ('architecture','fixed_platforms','center_platform','skyline'):
            for ids in components(ob):
                lo,hi=bounds(ob,ids);width=hi[0]-lo[0];height=hi[2]-lo[2]
                if group=='architecture' and material.startswith('Slate') and abs(width-18)<.01 and abs(hi[2])<.01:shift(ob,ids,-.06)
                elif group=='architecture' and material.startswith('Slate') and abs(width-16.6)<.01 and height>7:stretch_component(ob,ids,lo[2],-40,hi[2])
                elif group=='architecture' and material.startswith('Glass') and height>7:stretch_component(ob,ids,lo[2],-40,hi[2])
                elif group in ('fixed_platforms','center_platform') and material.startswith('Slate'):shift(ob,ids,-.035)
                elif group in ('fixed_platforms','center_platform') and material.startswith('Graphite') and .040<height<.048:shift(ob,ids,-.015)
                elif group=='skyline' and (material.startswith('City | close') or material.startswith('City | glass')) and height>5:stretch_component(ob,ids,lo[2],lo[2]-30,hi[2])
    material_adjust();bpy.context.scene['surface_inspection_fixed']=True
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'the_last_resort.blend'))
center=[o for o in bpy.context.scene.objects if o.get('group')=='center_platform'];static=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in center and o.get('group')!='skyline']
def export(objects,path):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_extras=True,export_apply=True)
for ob in center:ob.location.z=0
export(center,OUT/'center_platform.glb');export(static,OUT/'stage.glb')
for ob in center:ob.location.z=5.5
report=json.loads((E/'stage_manifest.json').read_text());report['inspection_corrections']=['Structural tops below finished timber; no coplanar cap faces','Pool liner top below water surface','Podium and nearby towers extend below review framing','Background guest complexion/clothing subdued'];(E/'stage_manifest.json').write_text(json.dumps(report,indent=2))
print('SURFACE_CORRECTIONS_EXPORTED',flush=True)
bpy.context.scene.render.filepath=str(E/'stage_review.png');bpy.ops.render.render(write_still=True)
print('SURFACE_REVIEW_COMPLETE',flush=True)
