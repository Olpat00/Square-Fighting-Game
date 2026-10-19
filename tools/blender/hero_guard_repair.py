"""Restore guard breathing while preserving every other curated action."""
import bpy,json,sys,hashlib,shutil
from pathlib import Path
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/blender'))
from hero_export import export_curated,action_signature
from hero_motion import guard_breath

for fid in sys.argv[sys.argv.index('--')+1:]:
    source=ROOT/'source_art/characters'/fid/'curated.blend';digest=hashlib.sha256(source.read_bytes()).hexdigest()
    revisions=source.parent/'revisions';revisions.mkdir(exist_ok=True)
    shutil.copy2(source,revisions/(datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'_'+digest[:12]+'.blend'))
    bpy.ops.wm.open_mainfile(filepath=str(source));rig=bpy.data.objects['FighterRig']
    before={a.name:action_signature(a) for a in bpy.data.actions if a.name!='shield_hold'}
    seconds=(bpy.data.actions['shield_hold'].frame_range[1]-bpy.data.actions['shield_hold'].frame_range[0])/60
    guard_breath(rig)
    assert before=={a.name:action_signature(a) for a in bpy.data.actions if a.name!='shield_hold'}
    assert seconds==(bpy.data.actions['shield_hold'].frame_range[1]-bpy.data.actions['shield_hold'].frame_range[0])/60
    rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(source));export_curated(fid,source)
    report={'fighter':fid,'changed_clips':['shield_hold'],'changed_bones':['spine','chest'],'all_other_clips_unchanged':True,'clip_seconds_preserved':seconds,'previous_curated_sha256':digest,'new_curated_sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
    (ROOT/'evidence/characters/hero_rebuild'/(fid+'_guard_repair.json')).write_text(json.dumps(report,indent=2))
    print('GUARD_REPAIR',fid,flush=True)
