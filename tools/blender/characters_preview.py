"""Render final editable action libraries without changing exported GLBs."""
import bpy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender'))
import characters_pipeline as pipeline
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(pipeline.SOURCES)
for fid in args:
    if fid.startswith('--'):continue
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source_art/characters'/fid/(fid+'.blend')))
    rig=bpy.data.objects['FighterRig']
    pipeline.studio(bpy.context.scene)
    manifest=json.loads((ROOT/'evidence/characters'/(fid+'_manifest.json')).read_text())
    timings={a['name']:a.get('combat_timing') for a in manifest['animations'] if a.get('combat_timing')}
    out=ROOT/'evidence/characters'/fid;out.mkdir(exist_ok=True)
    picks=[('idle',1),('run',10),('jump_rise',12),('jab1',6),('special_neutral',15),('special_side',12),('special_up',8),('special_down',6),('ultimate',40),
      ('qa_shoulder_raise',31),('qa_elbow_bend',31),('qa_knee_bend',31),('qa_torso_twist',31),('qa_deep_pose',31)]
    if '--locomotion-only' in args:picks=[('run',8),('walk',15)]
    for name,frame in picks:
        if name in timings:frame=timings[name]['startup']+1
        rig.animation_data.action=bpy.data.actions[name];bpy.context.scene.frame_set(frame)
        bpy.context.scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
    if 'ultimate' in timings and '--locomotion-only' not in args:
        rig.animation_data.action=bpy.data.actions['ultimate'];bpy.context.scene.frame_set(max(1,timings['ultimate']['total']-3))
        bpy.context.scene.render.filepath=str(out/'ultimate_finisher.png');bpy.ops.render.render(write_still=True)
    print('CHARACTER_PREVIEW_COMPLETE',fid,flush=True)
