"""Inspect final editable hero sources, exported contracts and source preservation."""
import bpy,json,sys,hashlib,math,struct
from datetime import datetime,timezone
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/blender'))
from hero_export import action_signature,export_curated
ROSTER=['f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall','f05_fine_print','f06_rugged_explorer','f07_urban_sentinel','f08_midnight_gentleman']
out=ROOT/'evidence/characters/hero_rebuild';reports=[]
for fid in ROSTER:
    source=ROOT/'source_art/characters'/fid/'curated.blend';bpy.ops.wm.open_mainfile(filepath=str(source))
    rig=bpy.data.objects['FighterRig'];meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.get('character_asset')]
    counts={b.name:0 for b in rig.data.bones};sumerror=0;triangles=0
    for mesh in meshes:
        groups={g.index:g.name for g in mesh.vertex_groups};triangles+=sum(len(p.vertices)-2 for p in mesh.data.polygons)
        for v in mesh.data.vertices:
            sumerror=max(sumerror,abs(sum(g.weight for g in v.groups)-1))
            for g in v.groups:
                if g.weight>.001:counts[groups[g.group]]=counts.get(groups[g.group],0)+1
    data=(ROOT/'Game File/assets/characters'/(fid+'.glb')).read_bytes();length=struct.unpack_from('<I',data,12)[0];glb=json.loads(data[20:20+length])
    names={a['name'] for a in glb['animations']};runtime_bones={glb['nodes'][n]['name'] for n in glb['skins'][0]['joints']}
    actions=[{'name':a.name,'seconds':(a.frame_range[1]-a.frame_range[0])/60,'frames':round(a.frame_range[1]-a.frame_range[0])+1,
              'loop':bool(a.get('loop',False)),'category':a.get('purpose','shared'),'source_motion':a.get('source_motion','custom choreography'),
              'curve_sha256':action_signature(a)} for a in bpy.data.actions if a.get('runtime_clip',True)]
    digits=[f'{d}_{i:02d}.{s}' for s in ['L','R'] for d in ['index','middle','ring','pinky','thumb'] for i in range(1,4)]
    row={'fighter':fid,'editable_bone_count':len(rig.data.bones),'runtime_bone_count':len(runtime_bones),'weighted_bone_count':sum(v>0 for n,v in counts.items()),
         'weighted_vertex_counts':counts,'all_30_digit_joints_weighted':all(counts[d]>0 for d in digits),'runtime_controls_excluded':not any(n.startswith('CTRL_') for n in runtime_bones),
         'runtime_mesh_count':len(glb['meshes']),'runtime_material_batches':sum(len(m['primitives']) for m in glb['meshes']),
         'editable_mesh_count':len(meshes),'runtime_triangles':triangles,'maximum_editable_skin_sum_error':sumerror,
         'all_curated_clips_exported':names=={a['name'] for a in actions},'clip_count':len(actions),
         'all_semantic_bones_retained':runtime_bones=={b.name for b in rig.data.bones if not b.name.startswith('CTRL_')},
         'source_hash_preserved':hashlib.sha256((ROOT/rig['source_path']).read_bytes()).hexdigest()==rig['source_sha256'],
         'curated_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'runtime_sha256':hashlib.sha256(data).hexdigest()}
    row['pass']=row['all_30_digit_joints_weighted'] and row['runtime_controls_excluded'] and row['all_curated_clips_exported'] and row['all_semantic_bones_retained'] and row['source_hash_preserved'] and sumerror<.0001
    reports.append(row)
    # Update current manifests; historical source inspection stays untouched.
    manifest=ROOT/'evidence/characters'/(fid+'_manifest.json');m=json.loads(manifest.read_text())
    m['animations']=actions;m['editable_source']=str(source.relative_to(ROOT));m['stats']['runtime_triangles']=triangles;m['stats']['semantic_bones']=sorted(runtime_bones)
    m['hero_rebuild_report']='evidence/characters/hero_rebuild/asset_validation.json';m['pending_validation']=['Final Godot playback and full-match acceptance tracked by root rebuild evidence']
    manifest.write_text(json.dumps(m,indent=2));(ROOT/'docs'/('animation_'+fid+'.json')).write_text(json.dumps(actions,indent=2))
    buildpath=out/(fid+'_build.json');build=json.loads(buildpath.read_text());build['weighted_detail_vertices']={n:counts[n] for n in build['weighted_detail_vertices']};build['weighted_bones']=sum(v>0 for v in build['weighted_detail_vertices'].values());buildpath.write_text(json.dumps(build,indent=2))
    print('HERO_ASSET_VALIDATE',fid,row['pass'],row['runtime_bone_count'],row['clip_count'],flush=True)
(out/'asset_validation.json').write_text(json.dumps({'generated_at_utc':datetime.now(timezone.utc).isoformat(),'fighters':reports,'pass':all(r['pass'] for r in reports)},indent=2))
# Re-export every complete curated scene and compare actual runtime binaries.
repros=[]
for row in reports:
    fid=row['fighter'];source=ROOT/'source_art/characters'/fid/'curated.blend';before=hashlib.sha256(source.read_bytes()).hexdigest()
    dest=out/(fid+'_reproducibility.glb');export_curated(fid,source,dest,publish=False)
    same=hashlib.sha256(dest.read_bytes()).hexdigest()==row['runtime_sha256']
    repro={'fighter':fid,'identical_runtime_glb_bytes':same,'curated_source_unchanged':before==hashlib.sha256(source.read_bytes()).hexdigest(),'pass':same and before==hashlib.sha256(source.read_bytes()).hexdigest()}
    repros.append(repro);print('HERO_REPRODUCIBILITY',json.dumps(repro),flush=True)
(out/'reproducibility.json').write_text(json.dumps({'generated_at_utc':datetime.now(timezone.utc).isoformat(),'fighters':repros,'pass':all(r['pass'] for r in repros)},indent=2))
assert all(r['pass'] for r in reports) and all(r['pass'] for r in repros)
