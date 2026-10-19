"""Restore legacy surface masks, or preserve and export artist-owned materials.

Curated scenes are authoritative. Edit their materials in Blender; this legacy
entry point must not replace their costume meshes, bindings, controls or actions.
"""
import bpy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender'))
from characters_pipeline import restore_source_surface_maps

ids=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall','f05_fine_print']
for fid in ids:
    curated=ROOT/'source_art/characters'/fid/'curated.blend'
    if curated.exists():
        from hero_export import export_curated
        export_curated(fid,curated)
        print('CURATED_MATERIALS_PRESERVED',fid,flush=True)
        continue
    source=ROOT/'source_art/characters'/fid/(fid+'.blend')
    bpy.ops.wm.open_mainfile(filepath=str(source))
    rig=bpy.data.objects['FighterRig'];mesh=bpy.data.objects['CharacterMesh']
    restore_source_surface_maps(mesh)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
    runtime=ROOT/'Game File/assets/characters'/(fid+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(runtime),export_format='GLB',use_selection=True,export_animations=True,
      export_animation_mode='ACTIONS',export_anim_single_armature=True,export_bake_animation=False,
      export_anim_slide_to_zero=True,export_force_sampling=True,export_frame_range=False,export_frame_step=1,
      export_skins=True,export_yup=True,export_apply=False,export_def_bones=False,export_optimize_animation_size=True)
    manifest=ROOT/'evidence/characters'/(fid+'_manifest.json')
    data=json.loads(manifest.read_text())
    data['surface_policy']='Original 2K source albedo, normal, roughness and per-pixel metallic restored; no UV/geometry/weight/action edits'
    data['portrait_studio']=str((source.parent/'portrait_studio.blend').relative_to(ROOT))
    data['portrait']='Game File/assets/portraits/'+fid+'.png'
    manifest.write_text(json.dumps(data,indent=2))
    print('CHARACTER_MATERIAL_EXPORT_COMPLETE',fid,len(bpy.data.actions),flush=True)
