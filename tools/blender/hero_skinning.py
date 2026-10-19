"""Repair cloth at the waist being pulled by nearby arm heat weights."""
import bpy,bmesh,json,math,sys,hashlib,shutil
from pathlib import Path
from datetime import datetime,timezone
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/blender'))

def smooth(a,b,value):
    t=max(0,min(1,(value-a)/(b-a)));return t*t*(3-2*t)

def torso_weights(rig,z):
    h=json.loads(rig['prepared_stats'])['height']/1.84;z/=h
    lower=smooth(.97,1.13,z);upper=smooth(1.19,1.39,z)
    return {n:w for n,w in [('pelvis',1-lower),('spine',lower*(1-upper)),('chest',lower*upper)] if w>.00001}

def repair_torso(rig,fid):
    if fid not in ['f05_fine_print','f06_rugged_explorer','f08_midnight_gentleman']:return []
    reports=[];h=json.loads(rig['prepared_stats'])['height']/1.84
    def distance(point,bone):
        a=bone.head_local;b=bone.tail_local;t=max(0,min(1,(point-a).dot(b-a)/(b-a).length_squared))
        return (point-a.lerp(b,t)).length
    arm_bones=[rig.data.bones[name+'.'+side] for side in ['L','R'] for name in ['upper_arm','forearm','hand']]
    for mesh in [o for o in bpy.data.objects if o.type=='MESH' and o.get('character_asset')]:
        explicit=any(s in mesh.name for s in ['waist band','utility pocket','fitted vest'])
        if mesh.name!='CharacterMesh' and not explicit:continue
        if fid=='f05_fine_print' and mesh.name=='CharacterMesh':continue
        groupmap={g.index:g.name for g in mesh.vertex_groups};changed=0;max_removed=0
        if mesh.name=='CharacterMesh' and fid!='f05_fine_print' and not mesh.data.attributes.get('.original_arm_weight'):
            original=mesh.data.attributes.new('.original_arm_weight','FLOAT','POINT')
            for v in mesh.data.vertices:
                original.data[v.index].value=sum(g.weight for g in v.groups if groupmap[g.group].startswith(('hand.','upper_arm','forearm','index_','middle_','ring_','pinky_','thumb_','clavicle.')))
        for v in mesh.data.vertices:
            p=v.co;z=p.z/h
            if mesh.name=='CharacterMesh' and .72<z<1.075 and abs(p.x)<.295*h:
                # The scan's resting hands overlap the coat tails. Automatic
                # weights assigned up to half a tail to the hand. Preserve all
                # existing leg binding and move only that arm contamination to
                # the pelvis; never flatten the whole upper trouser to torso.
                weights={groupmap[g.group]:g.weight for g in v.groups}
                removed=sum(w for n,w in weights.items() if n.startswith(('hand.','upper_arm','forearm','index_','middle_','ring_','pinky_','thumb_','clavicle.')))
                if removed>.00001:
                    weights={n:w for n,w in weights.items() if not n.startswith(('hand.','upper_arm','forearm','index_','middle_','ring_','pinky_','thumb_','clavicle.'))}
                    weights['pelvis']=weights.get('pelvis',0)+removed
                    for g in list(v.groups):mesh.vertex_groups[g.group].remove([v.index])
                    total=sum(weights.values())
                    for n,w in weights.items():
                        group=mesh.vertex_groups.get(n) or mesh.vertex_groups.new(name=n);group.add([v.index],w/total,'REPLACE')
                    changed+=1;max_removed=max(max_removed,removed)
            if explicit:
                factor=1.0
            else:
                # Trouser vertices must retain the prepared leg binding. The
                # original broad waist mask also caught upper thighs.
                if z<1.045:continue
                limit=.268-.052*smooth(1.03,1.36,z)
                if z<.78 or z>1.36 or abs(p.x)>limit:continue
                # Preserve the actual sleeve even when a loose sleeve comes
                # close to the body. Central waist cloth cannot belong to arms.
                arm_distance=min(distance(p,bone) for bone in arm_bones)
                if arm_distance<.075 and abs(p.x)>.18:continue
                factor=(1-smooth(1.27,1.36,z))*smooth(.78,.86,z)
            weights={groupmap[g.group]:g.weight for g in v.groups}
            arm_amount=sum(w for n,w in weights.items() if n.startswith(('hand.','upper_arm','forearm','index_','middle_','ring_','pinky_','thumb_','clavicle.')))
            if not explicit and arm_amount<.001:continue
            target=torso_weights(rig,p.z)
            result={n:w*(1-factor) for n,w in weights.items()}
            for n,w in target.items():result[n]=result.get(n,0)+w*factor
            result=sorted(((n,w) for n,w in result.items() if w>.00001),key=lambda a:a[1],reverse=True)[:4];total=sum(w for n,w in result)
            for g in list(v.groups):mesh.vertex_groups[g.group].remove([v.index])
            for n,w in result:
                group=mesh.vertex_groups.get(n) or mesh.vertex_groups.new(name=n)
                group.add([v.index],w/total,'REPLACE')
            changed+=1;max_removed=max(max_removed,arm_amount*factor)
        if changed:reports.append({'mesh':mesh.name,'vertices_rebound':changed,'maximum_arm_weight_removed':max_removed})
    return reports


def remove_cloth_webs(rig,fid):
    from hero_cloth_surface import rebuild_coat
    return rebuild_coat(rig,fid)
def repair(fid):
    from hero_export import action_signature,export_curated
    from hero_tailoring import correct_costume
    source=ROOT/'source_art/characters'/fid/'curated.blend'
    previous=ROOT/'evidence/characters/hero_rebuild'/(fid+'_torso_repair.json')
    if previous.exists() and '--replay-pre-repair' not in sys.argv:
        raise RuntimeError('This fighter already has an accepted torso repair. Export curated.blend normally. Replaying the development repair from its preserved original revision requires explicit --replay-pre-repair; the current curated scene will be snapshotted first.')
    digest=hashlib.sha256(source.read_bytes()).hexdigest()
    revisions=source.parent/'revisions';revisions.mkdir(exist_ok=True)
    shutil.copy2(source,revisions/(datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'_'+digest[:12]+'.blend'))
    # Rework from the preserved pre-repair revision, never accumulate trial
    # weight changes on a scene that has not passed the hard-pose review.
    original_digest=json.loads(previous.read_text())['previous_curated_sha256'] if previous.exists() else digest
    candidates=sorted(revisions.glob('*_'+original_digest[:12]+'.blend'))
    input_source=candidates[0] if candidates else source
    bpy.ops.wm.open_mainfile(filepath=str(input_source));rig=bpy.data.objects['FighterRig']
    signatures={a.name:action_signature(a) for a in bpy.data.actions}
    report=repair_torso(rig,fid)
    if fid=='f05_fine_print':
        correct_costume(rig,bpy.data.objects['CharacterMesh'],fid)
        report.extend(repair_torso(rig,fid))
    topology=remove_cloth_webs(rig,fid)
    assert signatures=={a.name:action_signature(a) for a in bpy.data.actions}
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    if '--no-export' not in sys.argv:export_curated(fid,source)
    (ROOT/'evidence/characters/hero_rebuild'/(fid+'_torso_repair.json')).write_text(json.dumps({'fighter':fid,'all_animation_curves_unchanged':True,'previous_curated_sha256':original_digest,'curated_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'repairs':report,'topology':topology},indent=2))
    print('TORSO_BINDING_REPAIRED',fid,flush=True)

if __name__=='__main__':
    for fid in sys.argv[sys.argv.index('--')+1:]:
        if not fid.startswith('--'):repair(fid)
