"""Render real source-derived character portraits in an editable studio.

blender --background --python tools/blender/characters_portraits.py -- f01_clutch
Use --preview-only to retain the runtime portrait until the render is reviewed.
No source images/models are uploaded, repainted or replaced.
"""
import bpy, sys, math, json, shutil, hashlib
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender'))
import characters_pipeline as pipeline

ROSTER=['f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall','f05_fine_print',
        'f06_rugged_explorer','f07_urban_sentinel','f08_midnight_gentleman']
POSES=[
    pipeline.pose(lean=-1,twist=-13,head=5,la=(13,12,78),ra=(27,23,120)),
    pipeline.pose(lean=-2,twist=16,head=-6,la=(30,24,94),ra=(9,30,78)),
    pipeline.pose(lean=2,twist=-9,head=3,la=(8,32,85),ra=(16,25,100)),
    pipeline.pose(lean=1,twist=12,head=-4,la=(20,20,105),ra=(9,25,72)),
    pipeline.pose(lean=-1,twist=-10,head=5,la=(10,10,80),ra=(32,8,120)),
    pipeline.pose(lean=-1,twist=12,head=-5,la=(22,12,105),ra=(95,12,108)),
    pipeline.pose(lean=-2,twist=-7,head=3,la=(68,12,120),ra=(53,12,128)),
    pipeline.pose(lean=1,twist=16,head=-6,la=(26,8,132),ra=(83,8,102)),
]

def area(name,location,energy,size,color,target):
    bpy.ops.object.light_add(type='AREA',location=location)
    obj=bpy.context.object;obj.name=name;obj.data.energy=energy
    obj.data.shape='DISK';obj.data.size=size;obj.data.color=color
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()

def render(fid):
    folder=ROOT/'source_art/characters'/fid
    source=folder/'curated.blend'
    if not source.exists():source=folder/(fid+'.blend')
    source_hash=hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    rig=bpy.data.objects['FighterRig'];mesh=bpy.data.objects['CharacterMesh']
    pipeline.restore_source_surface_maps(mesh)
    rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
    # Copy current detail channels, including articulated hands and face, into
    # the portrait-only action. Never save changes to the curated source.
    rig.animation_data.action=bpy.data.actions['idle'].copy()
    rig.animation_data.action.name='PortraitStudioPose';rig.animation_data.action['runtime_clip']=False
    pipeline.key_pose(rig,POSES[ROSTER.index(fid)],1)
    bpy.context.scene.frame_set(1)
    scene=bpy.context.scene
    scene.render.engine='CYCLES';scene.cycles.samples=72;scene.cycles.use_denoising=True
    render_device='CPU'
    try:
        preferences=bpy.context.preferences.addons['cycles'].preferences
        preferences.compute_device_type='OPTIX';preferences.get_devices()
        devices=[device for device in preferences.devices if device.type=='OPTIX']
        if devices:
            for device in preferences.devices:device.use=device in devices
            scene.cycles.device='GPU';render_device='OPTIX: '+', '.join(device.name for device in devices)
    except (TypeError,RuntimeError):
        scene.cycles.device='CPU'
    scene.render.resolution_x=768;scene.render.resolution_y=768;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.render.film_transparent=False
    scene.view_settings.view_transform='AgX'
    scene.view_settings.look='AgX - Medium High Contrast'
    scene.view_settings.exposure=-0.30
    world=bpy.data.worlds.new('Midnight portrait world');scene.world=world;world.use_nodes=True
    world.node_tree.nodes['Background'].inputs['Color'].default_value=(.008,.014,.028,1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value=.22
    # Physical navy backdrop catches a restrained warm/cool gradient from studio lights.
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,1.2,1.45),rotation=(math.pi/2,0,0))
    backdrop=bpy.context.object;backdrop.name='Portrait midnight backdrop'
    material=bpy.data.materials.new('Midnight navy');material.diffuse_color=(.0008,.002,.005,1);material.use_nodes=True
    material.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.0008,.002,.005,1)
    material.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.92
    backdrop.data.materials.append(material)
    area('Warm sculpting key',(-2.3,-1.6,3.3),320,1.25,(1.0,.80,.64),(0,0,1.53))
    area('Soft cool fill',(2,-2.3,1.9),42,2.4,(.57,.74,1.0),(0,0,1.48))
    area('Cool shoulder rim',(1.3,.65,2.4),210,1.35,(.24,.68,1.0),(0,0,1.47))
    area('Warm hair edge',(-1.0,.5,2.9),110,1.0,(1.0,.49,.23),(0,0,1.6))
    height=json.loads(rig['prepared_stats'])['height']
    center=height-.405
    bpy.ops.object.camera_add(location=(.58,-3.6,center+.10))
    camera=bpy.context.object;camera.name='Portrait camera';camera.data.type='ORTHO';camera.data.ortho_scale=.95
    camera.rotation_euler=(Vector((0,0,center))-camera.location).to_track_quat('-Z','Y').to_euler();scene.camera=camera
    out=ROOT/'evidence/characters/portraits';out.mkdir(exist_ok=True)
    target=out/(fid+'.png');scene.render.filepath=str(target)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'portrait_studio.blend'))
    bpy.ops.render.render(write_still=True)
    if '--preview-only' not in sys.argv:
        shutil.copy2(target,ROOT/'Game File/assets/portraits'/(fid+'.png'))
    assert hashlib.sha256(source.read_bytes()).hexdigest()==source_hash
    (out/(fid+'.json')).write_text(json.dumps({'fighter_id':fid,'source_scene':str(source.relative_to(ROOT)),
        'editable_studio':str((folder/'portrait_studio.blend').relative_to(ROOT)),'image':str(target.relative_to(ROOT)),
        'resolution':[768,768],'render_device':render_device,'curated_source_sha256':source_hash,'curated_source_unchanged':True,'albedo_repainted':False,
        'style':'Actual source-derived chest portrait; warm side key, cool rim and physical midnight backdrop','camera_ortho_size':.95},indent=2))
    print('PORTRAIT_COMPLETE',fid,target,flush=True)

args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ROSTER
for fid in args:
    if not fid.startswith('--'):render(fid)
