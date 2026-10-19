"""Correct victory-expression clip names without regenerating other motion."""
import bpy,json,sys,hashlib,shutil
from pathlib import Path
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/blender'))
from hero_rebuild import ROSTER
from hero_export import export_curated,action_signature
from hero_motion import curves

for fid in ROSTER:
    source=ROOT/'source_art/characters'/fid/'curated.blend';digest=hashlib.sha256(source.read_bytes()).hexdigest()
    revisions=source.parent/'revisions';revisions.mkdir(exist_ok=True)
    shutil.copy2(source,revisions/(datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'_'+digest[:12]+'.blend'))
    bpy.ops.wm.open_mainfile(filepath=str(source));rig=bpy.data.objects['FighterRig']
    unchanged={a.name:action_signature(a) for a in bpy.data.actions if a.name not in ['win']}
    for name in ['win']:
        action=bpy.data.actions[name];rig.animation_data.action=action
        frames=sorted({round(k.co.x) for c in curves(action) for k in c.keyframe_points})
        for f in frames:
            bpy.context.scene.frame_set(f)
            for side,sign in [('L',1),('R',-1)]:
                bone=rig.pose.bones['mouth.'+side];bone.location=(sign*.0008*.65,.0015*.65,0)
                bone.keyframe_insert('location',frame=f,group=bone.name)
    assert unchanged=={a.name:action_signature(a) for a in bpy.data.actions if a.name in unchanged}
    rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(source));export_curated(fid,source)
    report={'fighter':fid,'changed_clips':['win'],'changed_bones':['mouth.L','mouth.R'],'all_other_clips_unchanged':True,'previous_curated_sha256':digest,'new_curated_sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
    (ROOT/'evidence/characters/hero_rebuild'/(fid+'_expression_repair.json')).write_text(json.dumps(report,indent=2))
    print('EXPRESSION_REPAIR',fid,flush=True)
