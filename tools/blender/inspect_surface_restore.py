"""Verify the material refresh did not change geometry, weights or keyed actions.

Uses Blender's pre-save .blend1 backups from characters_materials.py. Read-only.
"""
import bpy, json, hashlib, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ROSTER=['f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall','f05_fine_print']

def snapshot(path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    mesh=bpy.data.objects['CharacterMesh']
    geometry=hashlib.sha256()
    for vertex in mesh.data.vertices:
        geometry.update(struct.pack('<fff',*vertex.co))
        for group in vertex.groups:geometry.update(struct.pack('<If',group.group,group.weight))
    for face in mesh.data.polygons:
        geometry.update(struct.pack('<'+'I'*len(face.vertices),*face.vertices))
    for uv in mesh.data.uv_layers.active.data:geometry.update(struct.pack('<ff',*uv.uv))
    actions={}
    for action in bpy.data.actions:
        rows=[]
        for layer in action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        rows.append([curve.data_path,curve.array_index,[[*k.co,*k.handle_left,*k.handle_right,k.interpolation] for k in curve.keyframe_points]])
        actions[action.name]=hashlib.sha256(json.dumps(sorted(rows),separators=(',',':')).encode()).hexdigest()
    return {'geometry_skin_uv_sha256':geometry.hexdigest(),'actions':actions}

rows=[]
for fid in ROSTER:
    path=ROOT/'source_art/characters'/fid/(fid+'.blend')
    before=snapshot(Path(str(path)+'1'));after=snapshot(path)
    row={'fighter_id':fid,'geometry_skin_uv_unchanged':before['geometry_skin_uv_sha256']==after['geometry_skin_uv_sha256'],
         'action_count':len(after['actions']),'action_keys_handles_interpolation_unchanged':before['actions']==after['actions'],
         'geometry_skin_uv_sha256':after['geometry_skin_uv_sha256'],'action_fingerprints':after['actions']}
    row['pass']=row['geometry_skin_uv_unchanged'] and row['action_keys_handles_interpolation_unchanged']
    rows.append(row)
report={'method':'Read-only comparison of pre-material .blend1 and current editable .blend; vertex/topology/UV/weights and all action keys, handles and interpolation hashed.',
        'all_pass':all(r['pass'] for r in rows),'fighters':rows}
(ROOT/'evidence/characters/surface_restore_validation.json').write_text(json.dumps(report,indent=2))
print('SURFACE_RESTORE_VALIDATION',report['all_pass'],sum(r['action_count'] for r in rows),'actions',flush=True)
