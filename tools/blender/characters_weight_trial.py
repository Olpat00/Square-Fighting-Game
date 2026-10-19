"""Compare Blender heat weighting against anatomical initial weights; never changes release output."""
import bpy,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender'))
import characters_pipeline as pipeline
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source_art/characters/f01_clutch/f01_clutch.blend'))
mesh=bpy.data.objects['CharacterMesh'];rig=bpy.data.objects['FighterRig']
rig.animation_data.action=None
for b in rig.pose.bones:b.rotation_quaternion=(1,0,0,0);b.location=(0,0,0)
mesh.parent=None
for modifier in list(mesh.modifiers):
    if modifier.type=='ARMATURE':mesh.modifiers.remove(modifier)
mesh.vertex_groups.clear()
bpy.context.view_layer.objects.active=mesh
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.remove_doubles(threshold=.00015);bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
rig['weight_trial']='Blender heat weighting'
unweighted=sum(1 for v in mesh.data.vertices if not v.groups)
print('HEAT_TRIAL_UNWEIGHTED',unweighted,flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source_art/characters/f01_clutch/heat_weld_trial.blend'))
pipeline.studio(bpy.context.scene)
for name,frame in [('idle',1),('qa_shoulder_raise',31),('qa_deep_pose',31),('qa_knee_bend',31),('special_up',8)]:
    rig.animation_data.action=bpy.data.actions[name];bpy.context.scene.frame_set(frame)
    bpy.context.scene.render.filepath=str(ROOT/'evidence/characters'/('heat_weld_'+name+'.png'));bpy.ops.render.render(write_still=True)
