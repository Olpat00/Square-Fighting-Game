"""Read-only views of repaired costume binding at the actual heavy contact tick."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/blender'))
from characters_pipeline import studio
for fid in sys.argv[sys.argv.index('--')+1:]:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source_art/characters'/fid/'curated.blend'))
    scene=bpy.context.scene;rig=bpy.data.objects['FighterRig'];studio(scene)
    scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.resolution_x=700;scene.render.resolution_y=800
    tick=json.loads((ROOT/'docs/moves/move_timing.json').read_text())['fighters'][fid]['moves']['heavy_side']['startup']
    rig.animation_data.action=bpy.data.actions['heavy_side'];scene.frame_set(tick+1)
    camera=scene.camera;camera.data.ortho_scale=2.1
    folder=ROOT/'evidence/characters/hero_rebuild'/fid
    for side in [-1,1]:
        camera.location=(side*4,-2.8,1.85);camera.rotation_euler=(Vector((0,-.05,1.0))-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(folder/('repaired_heavy_'+str(side)+'.png'));bpy.ops.render.render(write_still=True)
    print('REPAIRED_HEAVY_PREVIEW',fid,flush=True)
