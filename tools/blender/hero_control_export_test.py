"""Round-trip an ACTIVE IK edit through the actual protected runtime exporter."""
import bpy,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/blender'))
from hero_controls import snap_controls,key_controls
from hero_export import export_curated

fid='f01_clutch';source=ROOT/'source_art/characters'/fid/'curated.blend'
digest=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source));rig=bpy.data.objects['FighterRig']
action=bpy.data.actions['idle'].copy();action.name='qa_active_ik_export';action.use_fake_user=True
rig.animation_data.action=action
for a in list(bpy.data.actions):
    if a!=action:bpy.data.actions.remove(a)
bpy.context.scene.frame_set(1);before=(rig.matrix_world@rig.pose.bones['hand.L'].head).copy()
snap_controls('hands',rig)
control=rig.pose.bones['CTRL_hand.L'];matrix=control.matrix.copy();matrix.translation+=Vector((0,-.16,.10));control.matrix=matrix
key_controls('hands',1,rig);key_controls('hands',145,rig)
bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
expected=(rig.matrix_world@rig.pose.bones['hand.L'].head).copy()
assert (expected-before).length>.09,('IK did not move the hand',before,expected)
out=ROOT/'evidence/characters/hero_rebuild';temporary=out/'active_control_source.blend';runtime=out/'active_control_roundtrip.glb'
bpy.ops.wm.save_as_mainfile(filepath=str(temporary))
export_curated(fid,temporary,runtime,publish=False)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=60
bpy.ops.import_scene.gltf(filepath=str(runtime));imported=next(o for o in bpy.data.objects if o.type=='ARMATURE')
imported.animation_data.action=bpy.data.actions['qa_active_ik_export'];bpy.context.scene.frame_set(0)
actual=(imported.matrix_world@imported.pose.bones['hand.L'].head).copy()
error=(actual-expected).length
report={'source_file_sha256':digest,'source_file_unchanged':hashlib.sha256(source.read_bytes()).hexdigest()==digest,
        'active_ik_hand_displacement_m':(expected-before).length,'source_hand':list(expected),'reimported_hand':list(actual),
        'roundtrip_error_m':error,'runtime_bone_count':len(imported.data.bones),
        'semantic_root_retained':'root' in imported.data.bones,
        'control_bones_excluded':not any(b.name.startswith('CTRL_') for b in imported.data.bones),
        'pass':error<.002 and len(imported.data.bones)==60 and 'root' in imported.data.bones and not any(b.name.startswith('CTRL_') for b in imported.data.bones) and hashlib.sha256(source.read_bytes()).hexdigest()==digest}
(out/'active_control_export_test.json').write_text(json.dumps(report,indent=2));print('ACTIVE_CONTROL_EXPORT_TEST',json.dumps(report),flush=True)
assert report['pass']
