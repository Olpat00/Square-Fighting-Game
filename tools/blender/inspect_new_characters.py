"""Inspect and render the three newly supplied static Meshy sources."""
import bpy
import hashlib
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "evidence/characters"
PATHS = [
    ROOT / "Assets/Rugged Explorer/Meshy_AI_Rugged_Explorer_0928211551_texture.glb",
    ROOT / "Assets/Urban Sentinel/Meshy_AI_Urban_Sentinel_0928211602_texture.glb",
    ROOT / "Assets/Midnight Gentleman/Meshy_AI_Midnight_Gentleman_0928211534_texture.glb",
]

bpy.ops.wm.read_factory_settings(use_empty=True)
report = []
for i, path in enumerate(PATHS):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in objects if o.type == "MESH"]
    points = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
    lo = Vector(min(p[k] for p in points) for k in range(3))
    hi = Vector(max(p[k] for p in points) for k in range(3))
    factor = 1.85 / (hi.z - lo.z)
    record = {
        "source": str(path.relative_to(ROOT)),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "bounds_blender": [list(lo), list(hi)],
        "source_height": hi.z - lo.z,
        "mesh_count": len(meshes),
        "vertices": sum(len(o.data.vertices) for o in meshes),
        "polygons": sum(len(o.data.polygons) for o in meshes),
        "arms_and_skin": [
            {"vertex_groups": list(o.vertex_groups.keys()), "modifiers": [m.type for m in o.modifiers]}
            for o in meshes
        ],
    }
    report.append(record)
    for o in objects:
        if not o.parent:
            o.location = o.location * factor + Vector(((i - 1) * 1.25, -(lo.y + hi.y) * factor * .5, -lo.z * factor))
            o.scale *= factor
    bpy.ops.object.text_add(location=((i - 1) * 1.25 - .32, -.42, .02), rotation=(math.pi / 2, 0, 0))
    label = bpy.context.object
    label.data.body = path.parent.name
    label.data.size = .11

floor = bpy.data.materials.new("Inspection floor")
floor.diffuse_color = (.07, .09, .13, 1)
bpy.ops.mesh.primitive_plane_add(size=200)
bpy.context.object.data.materials.append(floor)
world = bpy.data.worlds.new("Inspection studio")
bpy.context.scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (.13, .17, .24, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = .4
for loc, energy, size in [((1, -5, 7), 1500, 7), ((-5, -2, 4), 900, 5), ((2, 3, 5), 1300, 4)]:
    bpy.ops.object.light_add(type="AREA", location=loc)
    light = bpy.context.object
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = size
    light.rotation_euler = (Vector((0, 0, 1)) - light.location).to_track_quat("-Z", "Y").to_euler()

bpy.ops.object.camera_add(location=(0, -9, 3.0))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 1)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 4.8
scene = bpy.context.scene
scene.camera = camera
scene.render.engine = "CYCLES"
scene.cycles.samples = 18
scene.render.resolution_x = 1400
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = "AgX"
scene.render.filepath = str(OUT / "new_source_front.png")
bpy.ops.render.render(write_still=True)
camera.location = (0, 9, 3.0)
camera.rotation_euler = (Vector((0, 0, 1)) - camera.location).to_track_quat("-Z", "Y").to_euler()
scene.render.filepath = str(OUT / "new_source_back.png")
bpy.ops.render.render(write_still=True)
(OUT / "new_source_inspection.json").write_text(json.dumps(report, indent=2))
print("NEW_SOURCE_INSPECTION_COMPLETE", str(OUT), flush=True)
