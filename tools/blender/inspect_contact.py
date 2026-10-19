"""Measure actual deformed asset reach at recorded gameplay capture clip times.

Read-only Blender diagnostic. Does not modify source .blend files or runtime GLBs.
Blender local -Y forward becomes Godot +X after runtime facing rotation.
"""
import bpy, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
capture_path = ROOT / 'evidence/presentation/presentation_scenarios.json'
captures = json.loads(capture_path.read_text())['captures']
names = {'f01_clutch_special_side', 'f01_clutch_ultimate_opener',
         'f01_clutch_ultimate_finisher', 'f05_fine_print_special_neutral',
         'f05_fine_print_special_side', 'f04_deadfall_special_side',
         'f03_heavy_duty_special_side', 'f03_heavy_duty_special_side_lift',
         'f03_heavy_duty_special_side_slam', 'f03_heavy_duty_ultimate_opener',
         'f03_heavy_duty_ultimate_lift', 'f03_heavy_duty_ultimate_finisher'}
rows = []

for row in captures:
    if row['name'] not in names:
        continue
    actor, victim = row['fighters']
    fid = actor['id']
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'source_art/characters' / fid / (fid + '.blend')))
    rig = bpy.data.objects['FighterRig']
    mesh = bpy.data.objects['CharacterMesh']
    clip = actor['clip'].split('/')[-1]
    rig.animation_data.action = bpy.data.actions[clip]
    frame = 1 + actor['clip_seconds'] * 60
    bpy.context.scene.frame_set(int(frame), subframe=frame-int(frame))
    bpy.context.view_layer.update()
    evaluated = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    deformed = evaluated.to_mesh()
    points = [evaluated.matrix_world @ v.co for v in deformed.vertices]
    reach = max(-p.y for p in points)
    # Original vertex heights identify actual shoulder cloth/skin rather than raised hands.
    shoulder_points = [points[v.index] for v in mesh.data.vertices
                       if 1.30 < v.co.z < 1.57 and abs(v.co.x) < 0.30]
    shoulder_reach = max(-p.y for p in shoulder_points)
    bones = {}
    for name in ['chest','upper_arm.L','upper_arm.R','forearm.L','forearm.R','hand.L','hand.R','foot.L','foot.R']:
        bone = rig.pose.bones[name]
        bones[name] = {'head_forward_height': [-bone.head.y, bone.head.z],
                       'tail_forward_height': [-bone.tail.y, bone.tail.z]}
    separation = abs(victim['position'][0] - actor['position'][0])
    rows.append({'capture': row['name'], 'fighter': fid, 'clip': clip, 'frame': frame,
                 'source_foot_origin_separation': separation,
                 'max_deformed_forward_reach': reach,
                 'shoulder_surface_forward_reach': shoulder_reach,
                 'minimum_deformed_height': min(p.z for p in points),
                 'gap_to_target_hurt_capsule_near_edge': separation - 0.42 - reach,
                 'bones': bones})
    evaluated.to_mesh_clear()

out = ROOT / 'evidence/characters/contact_measurements.json'
out.write_text(json.dumps({'rows': rows, 'method': 'Loaded final editable Blender actions at actual capture clip time. Exact evaluated linear-skinned vertex reach; no gameplay blending in this static replay. Gameplay hurt capsule radius is 0.42m. No files modified except this diagnostic report.'}, indent=2))
print(json.dumps(rows, indent=2))
