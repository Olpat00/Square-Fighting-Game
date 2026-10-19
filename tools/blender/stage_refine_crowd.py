"""Group quiet profile silhouettes behind rear glass, away from the combat center.
Primary stage_build.py regenerates this arrangement directly.
"""
import bpy,math,json
from mathutils import Vector,Matrix
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'source_art/stage';OUT=ROOT/'Game File/assets/stage';E=ROOT/'evidence/stage'
OLD=[(-5.8,10.1),(-5.1,10.4),(-.1,10.1),(.64,10.4),(6.1,10.15),(9.2,10.2)]
NEW=[(-5.8,11.65,45),(-5.1,11.68,-50),(2.4,11.65,40),(3.15,11.68,-55),(6.1,10.15,30),(9.2,10.2,-30)]
def index_at(point):return min(range(6),key=lambda i:(point.x-OLD[i][0])**2+(point.y-OLD[i][1])**2)
def transform(i):
    old,new=OLD[i],NEW[i]
    return Matrix.Translation(Vector((new[0],new[1],0)))@Matrix.Rotation(math.radians(new[2]),4,'Z')@Matrix.Translation(Vector((-old[0],-old[1],0)))
for filename in ['the_last_resort_modeling.blend','the_last_resort.blend']:
    bpy.ops.wm.open_mainfile(filepath=str(SRC/filename));scene=bpy.context.scene
    if not scene.get('crowd_depth_fixed',False):
        if 'modeling' in filename:
            for ob in scene.objects:
                if ob.type=='MESH' and ob.name.startswith('Guest'):
                    center=sum((ob.matrix_world@v.co for v in ob.data.vertices),Vector())/len(ob.data.vertices);ob.matrix_world=transform(index_at(center))@ob.matrix_world
        else:
            for ob in scene.objects:
                if ob.get('group')=='Crowd':
                    for v in ob.data.vertices:v.co=transform(index_at(v.co))@v.co
        scene['crowd_depth_fixed']=True;bpy.ops.wm.save_as_mainfile(filepath=str(SRC/filename))
static=[o for o in scene.objects if o.type=='MESH' and o.get('group') not in ('center_platform','skyline')];bpy.ops.object.select_all(action='DESELECT')
for ob in static:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'stage.glb'),export_format='GLB',use_selection=True,export_yup=True,export_extras=True,export_apply=True)
report=json.loads((E/'stage_manifest.json').read_text());report['inspection_corrections'].append('Crowd groups turned into subdued social profiles behind glass/bar; central view cleared');(E/'stage_manifest.json').write_text(json.dumps(report,indent=2));print('CROWD_DEPTH_EXPORTED',flush=True)
scene.render.filepath=str(E/'stage_review.png');bpy.ops.render.render(write_still=True)
