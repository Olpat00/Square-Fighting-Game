"""Render real deformed hero assets and their motion for visual acceptance."""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/blender'))
import characters_pipeline as base
ids=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['f01_clutch','f03_heavy_duty']
for fid in ids:
    if fid.startswith('--'):continue
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source_art/characters'/fid/'curated.blend'))
    rig=bpy.data.objects['FighterRig'];scene=bpy.context.scene;base.studio(scene)
    scene.cycles.samples=24;scene.cycles.use_denoising=True
    scene.render.resolution_x=600;scene.render.resolution_y=720
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.026,.035,.06,1)
    scene.view_settings.look='AgX - Medium High Contrast'
    cam=scene.camera;cam.location=(2.8,-5,2.0);cam.data.ortho_scale=2.3
    cam.rotation_euler=(Vector((0,-.06,.99))-cam.location).to_track_quat('-Z','Y').to_euler()
    out=ROOT/'evidence/characters/hero_rebuild'/fid;out.mkdir(parents=True,exist_ok=True)
    picks=[('idle',1),('run',5),('run',15),('run',25),('run',35),('jab1',6),('heavy_side',20),('jump_rise',12),('land_hard',7),('ultimate',22)]
    if '--quick' in sys.argv:picks=picks[:2]+[('jab1',6)]
    if '--idle-only' in sys.argv:picks=[('idle',1)]
    timings=json.loads((ROOT/'docs/moves/move_timing.json').read_text())['fighters'][fid]['moves']
    for clip,frame in picks:
        if clip in timings:frame=timings[clip]['startup']+1
        rig.animation_data.action=bpy.data.actions[clip];scene.frame_set(frame)
        scene.render.filepath=str(out/(clip+'_'+str(frame)+'.png'));bpy.ops.render.render(write_still=True)
    rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1);hand=rig.pose.bones['hand.R'].head
    cam.location=hand+Vector((-.45,-.65,.20));cam.data.ortho_scale=.40
    cam.rotation_euler=(hand+Vector((0,-.025,.045))-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(out/'hand_grip.png');bpy.ops.render.render(write_still=True)
    print('HERO_PREVIEW_COMPLETE',fid,flush=True)
