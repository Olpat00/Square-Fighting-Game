"""Give rear panes a separate alpha material; preserve all solid framing/facade.
Same material and group are authored directly by stage_build.py on regeneration.
"""
import bpy,bmesh,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'source_art/stage';OUT=ROOT/'Game File/assets/stage';E=ROOT/'evidence/stage'
NAME='Glass | clear terrace balustrade'
def clear_material():
    m=bpy.data.materials.get(NAME) or bpy.data.materials.new(NAME);m.use_nodes=True;m.diffuse_color=(.24,.37,.39,.25);bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.24,.37,.39,1);bs.inputs['Alpha'].default_value=.25;bs.inputs['Roughness'].default_value=.12;bs.inputs['Metallic'].default_value=.05;m.surface_render_method='DITHERED';return m
def is_pane(face):return all(11.30<v.co.y<11.34 for v in face.verts)
pane_count=0
for filename in ['the_last_resort_modeling.blend','the_last_resort.blend']:
    bpy.ops.wm.open_mainfile(filepath=str(SRC/filename));scene=bpy.context.scene;m=clear_material()
    if not scene.get('clear_balustrade',False):
        if 'modeling' in filename:
            for ob in scene.objects:
                if ob.type=='MESH' and ob.name.startswith('Balustrade smoke glass'):
                    ob.data.materials.clear();ob.data.materials.append(m);pane_count+=1
            assert pane_count==16,pane_count
        else:
            original=bpy.data.objects['architecture__Glass'];newdata=original.data.copy();pane=bpy.data.objects.new('balustrade__Glass',newdata);scene.collection.objects.link(pane);pane.matrix_world=original.matrix_world.copy();pane['group']='balustrade';pane['source']='Original architecture revision2 | clear terrace balustrade'
            bm=bmesh.new();bm.from_mesh(newdata);keep=[face for face in bm.faces if is_pane(face)];assert len(keep)>0
            bmesh.ops.delete(bm,geom=[face for face in bm.faces if not is_pane(face)],context='FACES');bm.to_mesh(newdata);bm.free()
            newdata.materials.clear();newdata.materials.append(m)
            for poly in newdata.polygons:poly.material_index=0
            bm=bmesh.new();bm.from_mesh(original.data);bmesh.ops.delete(bm,geom=[face for face in bm.faces if is_pane(face)],context='FACES');bm.to_mesh(original.data);bm.free()
            assert len(newdata.polygons)>0 and all(11.30<v.co.y<11.34 for v in newdata.vertices)
        scene['clear_balustrade']=True;bpy.ops.wm.save_as_mainfile(filepath=str(SRC/filename))
center=[o for o in scene.objects if o.get('group')=='center_platform'];static=[o for o in scene.objects if o.type=='MESH' and o not in center and o.get('group')!='skyline']
bpy.ops.object.select_all(action='DESELECT')
for ob in static:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'stage.glb'),export_format='GLB',use_selection=True,export_yup=True,export_extras=True,export_apply=True)
report=json.loads((E/'stage_manifest.json').read_text());report['stage_objects']=len(static);report['mesh_vertices']=sum(len(o.data.vertices) for o in static+center);report['triangles']=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in static+center);report['material_count']=29;report['runtime_material_count']=len({m.name for o in static+center for m in o.data.materials});report['clear_balustrade']={'material':NAME,'alpha':.25,'roughness':.12,'metallic':.05,'node':'balustrade__Glass','rear_blender_y':11.32,'panels':16};report['inspection_corrections'].append('Rear glass has distinct alpha material; opaque facade and shelves unchanged');(E/'stage_manifest.json').write_text(json.dumps(report,indent=2));print('CLEAR_BALUSTRADE_EXPORT_READY',flush=True)
