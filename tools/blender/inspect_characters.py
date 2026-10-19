"""Read-only source GLB inspection and contact render. Run with Blender --background --python."""
import bpy, json, hashlib, math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'evidence/characters'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
report = []
for i, path in enumerate(sorted((ROOT/'Assets').glob('*/*.glb'))):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    obs = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in obs if o.type == 'MESH']
    pts = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
    lo = Vector([min(p[k] for p in pts) for k in range(3)])
    hi = Vector([max(p[k] for p in pts) for k in range(3)])
    factor = 1.85/(hi.z-lo.z)
    record = {'source':str(path.relative_to(ROOT)), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'bounds_blender':[list(lo),list(hi)], 'objects':[], 'actions':list(bpy.data.actions.keys()),
        'images':[{'name':im.name,'size':list(im.size)} for im in {n.image for o in meshes for mat in o.data.materials if mat and mat.use_nodes for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image} if im.size[0]>0]}
    for o in obs:
        rec={'name':o.name,'type':o.type}
        if o.type=='MESH': rec.update(vertices=len(o.data.vertices),polygons=len(o.data.polygons),
           materials=[m.name if m else None for m in o.data.materials],uv_layers=len(o.data.uv_layers),
           vertex_groups=list(o.vertex_groups.keys()),modifiers=[m.type for m in o.modifiers])
        if o.type=='ARMATURE': rec['bones']=[{'name':b.name,'head':list(b.head_local),'tail':list(b.tail_local)} for b in o.data.bones]
        record['objects'].append(rec)
    report.append(record)
    for o in obs:
        if not o.parent:
            o.location = o.location * factor + Vector(((i-2)*1.35,-(lo.y+hi.y)*factor*.5,-lo.z*factor))
            o.scale *= factor
    bpy.ops.object.text_add(location=((i-2)*1.35-.4,-.45,0.025), rotation=(math.pi/2,0,0))
    lab=bpy.context.object;lab.data.body=path.parent.name;lab.data.size=.15

floor=bpy.data.materials.new('Inspection floor');floor.diffuse_color=(.07,.09,.13,1)
bpy.ops.mesh.primitive_plane_add(size=200);bpy.context.object.data.materials.append(floor)
world=bpy.data.worlds.new('Inspection studio');bpy.context.scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.13,.17,.24,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.4
for loc,energy,size in [((1,-5,7),1500,7),((-5,-2,4),900,5),((2,3,5),1300,4)]:
    bpy.ops.object.light_add(type='AREA',location=loc);bpy.context.object.data.energy=energy;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=size
    bpy.context.object.rotation_euler=(Vector((0,0,1))-bpy.context.object.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(0,-10,3.2));cam=bpy.context.object
cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=7.2
s=bpy.context.scene;s.camera=cam;s.render.engine='CYCLES';s.cycles.samples=24;s.render.resolution_x=1800;s.render.resolution_y=700;s.render.resolution_percentage=100
s.view_settings.view_transform='AgX';s.render.filepath=str(OUT/'source_roster_front.png');bpy.ops.render.render(write_still=True)
cam.location=(0,10,3.2);cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler()
s.render.filepath=str(OUT/'source_roster_back.png');bpy.ops.render.render(write_still=True)
(OUT/'source_inspection.json').write_text(json.dumps(report,indent=2))
print('SOURCE_INSPECTION_COMPLETE',str(OUT))
