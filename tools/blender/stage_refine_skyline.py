"""Remove distracting near-city blockout from runtime; continue podium storeys.
Retain all excluded city construction meshes in editable Blender source.
"""
import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'source_art/stage';OUT=ROOT/'Game File/assets/stage';E=ROOT/'evidence/stage'
def reveals():
    result=[];z=-9.5
    while z>-40:
        bpy.ops.mesh.primitive_cube_add(size=1,location=(0,2.30,z));o=bpy.context.object;o.name='Podium extended floor reveal';o.scale=(16.6,.08,.07);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        o.data.materials.append(bpy.data.materials['Brass | satin champagne alloy']);b=o.modifiers.new('Machined edge radius','BEVEL');b.width=.012;b.segments=3;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');result.append(o);z-=2.9
    return result
for filename in ['the_last_resort_modeling.blend','the_last_resort.blend']:
    bpy.ops.wm.open_mainfile(filepath=str(SRC/filename));scene=bpy.context.scene
    if not scene.get('skyline_runtime_excluded',False):
        added=reveals()
        if 'modeling' not in filename:
            ob=bpy.data.objects['architecture__Brass'];bpy.ops.object.select_all(action='DESELECT')
            for part in added:
                bpy.context.view_layer.objects.active=part
                for mod in list(part.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
                part.select_set(True)
            ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.join()
        for ob in scene.objects:
            if ob.get('group')=='skyline' or any(ob.name.startswith(prefix) for prefix in ['City tower','Curtain-wall','City floor','City occupied','City curtain','Tower setback','Tower service','Stepped tower','City slender','Tower recessed','Distant road','Distant traffic']):ob.hide_render=True
        scene['skyline_runtime_excluded']=True;bpy.ops.wm.save_as_mainfile(filepath=str(SRC/filename))
center=[o for o in scene.objects if o.get('group')=='center_platform'];static=[o for o in scene.objects if o.type=='MESH' and o not in center and o.get('group')!='skyline']
bpy.ops.object.select_all(action='DESELECT')
for ob in static:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'stage.glb'),export_format='GLB',use_selection=True,export_yup=True,export_extras=True,export_apply=True)
report=json.loads((E/'stage_manifest.json').read_text());report['stage_objects']=len(static);report['mesh_vertices']=sum(len(o.data.vertices) for o in static+center);report['triangles']=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in static+center);report['excluded_runtime_groups']=['skyline'];report['inspection_corrections'].append('Near skyline retained only in editable source; main podium floor reveals continue down extension');(E/'stage_manifest.json').write_text(json.dumps(report,indent=2));print('SKYLINE_EXCLUDED_EXPORT_READY',flush=True)
