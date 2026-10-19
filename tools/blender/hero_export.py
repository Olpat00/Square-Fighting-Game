"""Export protected artist-owned character scenes without regenerating their actions.

The curated file is the source of truth. Control bones stay in Blender; existing
semantic deform bones remain stable for Godot attachments and presentation.
"""
import bpy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def action_signature(action):
    rows = []
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for curve in bag.fcurves:
                    rows.append([curve.data_path, curve.array_index,
                                 [[*key.co, *key.handle_left, *key.handle_right,
                                   key.interpolation] for key in curve.keyframe_points]])
    return hashlib.sha256(json.dumps(rows, separators=(",", ":")).encode()).hexdigest()


def export_curated(fid, source=None, output=None, publish=True):
    folder = ROOT / 'source_art/characters' / fid
    source = Path(source) if source else folder / 'curated.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    rig = bpy.data.objects['FighterRig']
    # The semantic root has no vertex weights, but remains part of the runtime
    # skeleton contract. Mark it exportable only in this disposable scene.
    rig.data.bones['root'].use_deform = True
    actions = {a.name: action_signature(a) for a in bpy.data.actions
               if a.get('runtime_clip', True) and not a.name.startswith('Portrait')}
    for action in list(bpy.data.actions):
        if action.name not in actions:
            action.use_fake_user = False
    rig.animation_data.action = bpy.data.actions.get('idle') or bpy.data.actions[next(iter(actions))]
    bpy.context.scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    meshes = [o for o in bpy.data.objects if o.type == 'MESH' and o.get('character_asset')]
    if not meshes:
        meshes = [bpy.data.objects['CharacterMesh']]
    for mesh in meshes:
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = rig
    # Keep constraints during sampled export: artist-authored IK and control
    # animation must be evaluated into runtime deform-bone transforms. Controls
    # themselves are excluded by export_def_bones. Never strip a live solver.
    # Keep individual costume pieces editable in Blender, but combine their
    # skinned geometry for runtime. Material batches stay bounded by the palette.
    mesh_names = [o.name for o in meshes]
    bpy.ops.object.select_all(action='DESELECT')
    for mesh in meshes:
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = bpy.data.objects['CharacterMesh']
    bpy.ops.object.join()
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    output = Path(output) if output else ROOT / 'Game File/assets/characters' / (fid + '.glb')
    bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', use_selection=True,
        export_animations=True, export_animation_mode='ACTIONS', export_anim_single_armature=True,
        export_bake_animation=False, export_anim_slide_to_zero=True, export_force_sampling=True,
        export_frame_range=False, export_frame_step=1, export_skins=True, export_yup=True,
        export_apply=False, export_def_bones=True, export_optimize_animation_size=True)
    assert actions == {name: action_signature(bpy.data.actions[name]) for name in actions}, 'Export changed authored curves'
    # The established filename continues to serve preview/contact tools. Curated
    # stays separate so procedural legacy paths cannot erase the artist source.
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if publish:
        bpy.ops.wm.save_as_mainfile(filepath=str(folder / (fid + '.blend')))
    evidence = ROOT / 'evidence/characters/hero_rebuild'
    evidence.mkdir(parents=True, exist_ok=True)
    report = {'fighter': fid, 'source': str(source.relative_to(ROOT)), 'output': str(output.relative_to(ROOT)),
              'curated_source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
              'glb_sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
              'action_signatures': actions, 'export_did_not_mutate_actions': True,
              'mesh_objects': mesh_names, 'controls_exported': False}
    (evidence / ((fid if publish else output.stem) + '_export.json')).write_text(json.dumps(report, indent=2))
    print('CURATED_EXPORT', fid, len(actions), len(meshes), flush=True)
    return report
