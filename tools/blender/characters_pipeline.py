"""Rooftop Riot non-destructive character rig, motion authoring and GLB export.

Blender 5.2: blender --background --python tools/blender/characters_pipeline.py -- f01_clutch
No originals are changed. A measured A-pose is mapped separately for each source.
The script authors pose-bone quaternion keys; runtime movement stays in gameplay.
"""
import bpy, math, json, hashlib, sys, re, shutil
from pathlib import Path
from mathutils import Vector, Quaternion, Euler

ROOT = Path(__file__).resolve().parents[2]
SOURCES = {
    'f01_clutch':dict(folder='Wes',height=1.84,shoulder=.207,elbow=.267,wrist=.310,hip=.087,knee=.122,ankle=.160,style=0,mapping='confirmed: navy quarter-zip'),
    'f04_deadfall':dict(folder='Jaydon',height=1.85,shoulder=.220,elbow=.324,wrist=.397,hip=.097,knee=.136,ankle=.177,style=3,mapping='confirmed: red flannel'),
    'f05_fine_print':dict(folder='Josh',height=1.83,shoulder=.235,elbow=.338,wrist=.417,hip=.101,knee=.137,ankle=.166,style=4,mapping='confirmed: pale green polo'),
    'source_damion':dict(folder='Damion',height=1.90,shoulder=.223,elbow=.337,wrist=.416,hip=.104,knee=.154,ankle=.190,style=2,mapping='unresolved: supplied Roman armor, no matching clothing description'),
    'source_will':dict(folder='Will',height=1.80,shoulder=.214,elbow=.267,wrist=.279,hip=.086,knee=.123,ankle=.165,style=1,mapping='unresolved: supplied tropical shirt, no matching clothing description'),
    'f06_rugged_explorer':dict(folder='Rugged Explorer',height=1.85,shoulder=.200,elbow=.270,wrist=.295,hip=.095,knee=.125,ankle=.165,style=3,mapping='user supplied: tan field jacket, cap, satchel and boots'),
    'f07_urban_sentinel':dict(folder='Urban Sentinel',height=1.86,shoulder=.220,elbow=.300,wrist=.325,hip=.100,knee=.140,ankle=.170,style=0,mapping='user supplied: dark red-trimmed hoodie and field gear'),
    'f08_midnight_gentleman':dict(folder='Midnight Gentleman',height=1.87,shoulder=.230,elbow=.300,wrist=.325,hip=.100,knee=.135,ankle=.170,style=4,mapping='user supplied: navy suit, blue patterned tie and gloves'),
}
OUT=ROOT/'evidence/characters';OUT.mkdir(parents=True,exist_ok=True)
RUNTIME=ROOT/'Game File/assets/characters';RUNTIME.mkdir(parents=True,exist_ok=True)
ANIMS=[]
TIMINGS={}
ALIASES={'jump_start':'jump_anticipation','land':'land_soft','shield':'shield_hold','captured':'victim_grab',
    'taunt_1':'taunt1','taunt_2':'taunt2','jab_1':'jab1','jab_2':'jab2','jab_3':'jab3',
    'light_side':'tilt_side','light_up':'tilt_up','light_down':'tilt_down','dash_attack':'dash',
    'aerial_neutral':'air_neutral','aerial_forward':'air_forward','aerial_back':'air_back','aerial_up':'air_up','aerial_down':'air_down',
    'thrown_forward':'victim_throw'}

def blend_pose(a,b,t):
    keys=set(a)|set(b)
    return {k:tuple(x+(y-x)*t for x,y in zip(a.get(k,(0,0,0)),b.get(k,(0,0,0)))) if isinstance(a.get(k,b.get(k)),tuple) else a.get(k,0)+(b.get(k,0)-a.get(k,0))*t for k in keys}

def pose(**kw):
    p=dict(lean=3,twist=0,side=0,head=0,drop=0,hip_y=0,
      la=(27,16,120),ra=(30,16,125),ll=(0,0,0),rl=(0,0,0))
    p.update(kw);return p

def guard(style=0):
    return [pose(la=(25,13,130),ra=(30,15,140),twist=-7),
       pose(la=(5,30,115),ra=(22,22,140),side=-3,twist=-11),
       pose(la=(20,29,102),ra=(20,29,102),lean=4),
       pose(la=(19,24,110),ra=(26,16,132),twist=10),
       pose(la=(17,9,125),ra=(30,10,148),lean=1,twist=-6)][style]

def restore_source_surface_maps(mesh):
    """Keep the source's measured skin/cloth/metal split, including armor.

    Cached first-pass rigs retain the original packed texture and separator;
    reconnecting Blue restores its mask without repainting albedo or touching UVs.
    """
    for mat in mesh.data.materials:
        if not mat or not mat.use_nodes:continue
        p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if not p:continue
        rough_links=list(p.inputs['Roughness'].links)
        if rough_links and rough_links[0].from_node.type=='SEPARATE_COLOR':
            packed=rough_links[0].from_node
            for link in list(p.inputs['Metallic'].links):mat.node_tree.links.remove(link)
            mat.node_tree.links.new(packed.outputs['Blue'],p.inputs['Metallic'])
        else:
            p.inputs['Metallic'].default_value=0.0
        for link in list(p.inputs['Emission Color'].links):mat.node_tree.links.remove(link)
        p.inputs['Emission Color'].default_value=(0,0,0,1)
        mat['surface_policy']='Original 2K albedo, roughness, metallic mask and tangent normals; no painted identity changes'

def prepare(fid,cfg):
    directory=ROOT/'source_art/characters'/fid;directory.mkdir(parents=True,exist_ok=True)
    cache=directory/'prepared.blend'
    if cache.exists() and '--rebuild' not in sys.argv:
        bpy.ops.wm.open_mainfile(filepath=str(cache))
        for m in bpy.data.objects['CharacterMesh'].modifiers:
            if m.type=='ARMATURE':m.use_deform_preserve_volume=False
        return bpy.data.objects['FighterRig'],bpy.data.objects['CharacterMesh']
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source=next((ROOT/'Assets'/cfg['folder']).glob('*.glb'))
    bpy.ops.import_scene.gltf(filepath=str(source))
    mesh=next(o for o in bpy.data.objects if o.type=='MESH');mesh.name='CharacterMesh'
    bpy.context.view_layer.objects.active=mesh;mesh.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    lo=Vector([min(v.co[k] for v in mesh.data.vertices) for k in range(3)])
    hi=Vector([max(v.co[k] for v in mesh.data.vertices) for k in range(3)])
    scale=cfg['height']/(hi.z-lo.z);center=(lo+hi)*.5
    for v in mesh.data.vertices:
        v.co=(v.co-Vector((center.x,center.y,lo.z)))*scale
    original_vertices=len(mesh.data.vertices);original_faces=len(mesh.data.polygons)
    # glTF stores UV seam duplicates as disconnected vertices. Weld coincident positions
    # BEFORE reduction so adjacent seam edges collapse together and bone heat sees continuity.
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=.00003)
    bpy.ops.object.mode_set(mode='OBJECT')
    welded_vertices=len(mesh.data.vertices)
    # Edge collapse affects derivative only. UVs and high-resolution source remain intact.
    dec=mesh.modifiers.new('Runtime geometry budget','DECIMATE');dec.ratio=min(1,42000/len(mesh.data.polygons));dec.use_collapse_triangulate=True
    bpy.ops.object.modifier_apply(modifier=dec.name)
    for poly in mesh.data.polygons:poly.use_smooth=True
    # Preserve the source's skin/cloth/metal masks and scanned normals.
    for mat in mesh.data.materials:
        if mat and mat.use_nodes:
            p=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
            if p:
                for link in list(p.inputs['Emission Color'].links):mat.node_tree.links.remove(link)
                p.inputs['Emission Color'].default_value=(0,0,0,1)
            mat.diffuse_color=(.6,.6,.6,1)
    h=cfg['height']/1.84
    joints={'root':((0,0,0),(0,0,.12),None),'pelvis':((0,0,.93*h),(0,0,1.055*h),'root'),
      'spine':((0,0,1.055*h),(0,0,1.27*h),'pelvis'),
      'chest':((0,0,1.27*h),(0,0,1.49*h),'spine'),
      'neck':((0,0,1.49*h),(0,0,1.60*h),'chest'),
      'head':((0,0,1.60*h),(0,0,1.78*h),'neck')}
    for side,sgn in [('L',1),('R',-1)]:
        sh=(sgn*cfg['shoulder'],0,1.47*h);el=(sgn*cfg['elbow'],0,1.19*h);wr=(sgn*cfg['wrist'],-.018,.955*h)
        hand=(sgn*(cfg['wrist']+.018),-.025,.827*h)
        hip=(sgn*cfg['hip'],0,.94*h);knee=(sgn*cfg['knee'],-.004,.51*h);ank=(sgn*cfg['ankle'],0,.115*h)
        joints.update({f'clavicle.{side}':((0,0,1.455*h),sh,'chest'),f'upper_arm.{side}':(sh,el,f'clavicle.{side}'),
          f'forearm.{side}':(el,wr,f'upper_arm.{side}'),f'hand.{side}':(wr,hand,f'forearm.{side}'),
          f'thigh.{side}':(hip,knee,'pelvis'),f'shin.{side}':(knee,ank,f'thigh.{side}'),
          f'foot.{side}':(ank,(sgn*cfg['ankle'],-.16,.05*h),f'shin.{side}')})
    bpy.ops.object.select_all(action='DESELECT');bpy.ops.object.armature_add()
    rig=bpy.context.object;rig.name='FighterRig';rig.data.name='RooftopHumanoid';rig.show_in_front=True
    bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0])
    for name,(start,end,parent) in joints.items():
        bone=rig.data.edit_bones.new(name);bone.head=start;bone.tail=end
        if parent:bone.parent=rig.data.edit_bones[parent]
        bone.use_deform=name!='root'
    bpy.ops.object.mode_set(mode='OBJECT')
    # Use bounded anatomical partitions before distance blending. A torso bone may not drag
    # a hand or opposite knee, which is a common automatic binding failure on relaxed A poses.
    segs={n:(Vector(a),Vector(b)) for n,(a,b,p) in joints.items()}
    def dist(v,n):
        a,b=segs[n];d=b-a;t=max(0,min(1,(v-a).dot(d)/d.length_squared));return (v-(a+d*t)).length
    groups={n:mesh.vertex_groups.new(name=n) for n in joints if n!='root'}
    max_err=0
    for v in mesh.data.vertices:
        p=v.co;z=p.z/h;s='L' if p.x>=0 else 'R';ax=abs(p.x)
        if z>1.59:
            weights={'head':1.0} if z>1.65 else {'head':(z-1.59)/.06,'neck':1-(z-1.59)/.06}
        elif z<.89 and not (z>.72 and ax>cfg['wrist']*.70):
            names=[f'thigh.{s}',f'shin.{s}',f'foot.{s}']
            if z>.77:names+=['pelvis']
            ds=sorted([(dist(p,n),n) for n in names])[:2]
            weights={n:1/(d+.025)**5 for d,n in ds}
        else:
            # The A-pose forearm remains outside the trunk; blend its closest adjacent joints.
            shoulder=cfg['shoulder'];elbow=cfg['elbow'];wrist=cfg['wrist']
            threshold=shoulder*.77 if z>1.30 else (elbow*.74 if z>1.12 else wrist*.72)
            if ax>threshold and z<1.56:
                names=[f'upper_arm.{s}',f'forearm.{s}',f'hand.{s}']
                if z>1.32:names+=['chest',f'clavicle.{s}']
                ds=sorted([(dist(p,n),n) for n in names])[:2]
                weights={n:1/(d+.018)**5 for d,n in ds}
            else:
                # Height-controlled torso weights retain volume under chest twist.
                anchors=[(.92,'pelvis'),(1.13,'spine'),(1.385,'chest'),(1.545,'neck')]
                if z<=anchors[0][0]:weights={'pelvis':1}
                elif z>=anchors[-1][0]:weights={'neck':1}
                else:
                    for (za,na),(zb,nb) in zip(anchors,anchors[1:]):
                        if za<=z<=zb:
                            t=(z-za)/(zb-za);weights={na:1-t,nb:t};break
        total=sum(weights.values())
        for n,w in weights.items():
            if w>0:groups[n].add([v.index],w/total,'REPLACE')
        max_err=max(max_err,abs(sum(weights.values())/total-1))
    anatomical=[[(mesh.vertex_groups[g.group].name,g.weight) for g in v.groups] for v in mesh.data.vertices]
    mesh.vertex_groups.clear()
    bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
    try:
        bpy.ops.object.parent_set(type='ARMATURE_AUTO')
        binding='welded topology + Blender bone heat, repaired unweighted vertices and normalized top-four influences'
    except RuntimeError:
        binding='anatomical partition fallback after unsuccessful bone heat'
    repaired=0;normalized=[]
    for v in mesh.data.vertices:
        weights=[(mesh.vertex_groups[g.group].name,g.weight) for g in v.groups if g.weight>.00001 and mesh.vertex_groups[g.group].name!='root']
        if not weights:weights=anatomical[v.index];repaired+=1
        weights=sorted(weights,key=lambda x:x[1],reverse=True)[:4];total=sum(w for n,w in weights)
        normalized.append([(n,w/total) for n,w in weights])
    mesh.vertex_groups.clear();groups={n:mesh.vertex_groups.new(name=n) for n in joints if n!='root'}
    for index,weights in enumerate(normalized):
        for n,w in weights:groups[n].add([index],w,'REPLACE')
    mod=next((m for m in mesh.modifiers if m.type=='ARMATURE'),None)
    if not mod:mod=mesh.modifiers.new('Humanoid skin','ARMATURE')
    # Godot/glTF uses linear skinning. Preview the exact same deformation model;
    # dual-quaternion preserve-volume produces different high-angle shoulder bulges.
    mod.object=rig;mod.use_deform_preserve_volume=False;mesh.parent=rig
    cfg['prepared_stats']=dict(source_vertices=original_vertices,source_triangles=original_faces,
        runtime_vertices=len(mesh.data.vertices),runtime_triangles=len(mesh.data.polygons),source_scale_factor=scale,
        weight_sum_error=max_err,semantic_bones=list(joints),height=cfg['height'],welded_source_vertices=welded_vertices,
        binding=binding,repaired_vertices=repaired)
    rig['prepared_stats']=json.dumps(cfg['prepared_stats']);rig['source_sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
    rig['mapping']=cfg['mapping'];rig['source_path']=str(source.relative_to(ROOT))
    bpy.ops.wm.save_as_mainfile(filepath=str(cache))
    return rig,mesh

def key_pose(rig,p,frame):
    """Convert anatomical world directions into actual local deform-bone rotations."""
    world={}
    world['root']=Quaternion((1,0,0,0));world['pelvis']=Euler((0,0,math.radians(p.get('twist',0)*.3)),'XYZ').to_quaternion()
    world['spine']=Euler((math.radians(p.get('lean',0)*.5),math.radians(p.get('side',0)),math.radians(p.get('twist',0)*.65)),'XYZ').to_quaternion()
    world['chest']=Euler((math.radians(p.get('lean',0)),math.radians(p.get('side',0)),math.radians(p.get('twist',0))),'XYZ').to_quaternion()
    world['neck']=world['chest'].slerp(Quaternion((1,0,0,0)),.35)
    world['head']=Euler((math.radians(p.get('lean',0)*.25),0,math.radians(p.get('head',0))),'XYZ').to_quaternion()
    for side,sgn,akey,lkey in [('L',1,'la','ll'),('R',-1,'ra','rl')]:
        up,spread,low=p.get(akey,(25,18,125));leg,knee,foot=p.get(lkey,(0,0,0))
        world[f'clavicle.{side}']=world['chest']
        for name,pitch,abduction in [(f'upper_arm.{side}',up,spread),(f'forearm.{side}',low,spread*.35),(f'hand.{side}',low,spread*.25)]:
            pr=math.radians(pitch);ab=math.radians(abduction)
            direction=Vector((sgn*math.sin(ab)*abs(math.cos(pr)),-math.sin(pr),-math.cos(pr)*math.cos(ab)))
            bone=rig.data.bones[name];rest=bone.tail_local-bone.head_local
            world[name]=rest.rotation_difference(direction)
            if p.get('arm_yaw'):world[name]=Quaternion((0,0,1),math.radians(p['arm_yaw'])) @ world[name]
        for name,pitch in [(f'thigh.{side}',leg),(f'shin.{side}',leg-knee)]:
            bone=rig.data.bones[name];rest=bone.tail_local-bone.head_local
            direction=Vector((sgn*.075,-math.sin(math.radians(pitch)),-math.cos(math.radians(pitch))))
            world[name]=rest.rotation_difference(direction)
        world[f'foot.{side}']=Quaternion((1,0,0),math.radians(foot))
    for b in rig.pose.bones:
        if b.name not in world:
            # Curated hero rigs carry weighted detail bones and Blender-only
            # controls. Legacy pose helpers must not reset their authored pose.
            continue
        rest=b.bone.matrix_local.to_quaternion();parentdelta=world[b.parent.name] if b.parent else Quaternion((1,0,0,0))
        b.rotation_mode='QUATERNION';b.rotation_quaternion=rest.inverted() @ parentdelta.inverted() @ world[b.name] @ rest
        b.keyframe_insert('rotation_quaternion',frame=frame,group=b.name)
        b.location=(0,0,0)
        if b.name=='pelvis':
            # Convert desired world vertical drop / fore-aft shift to bone-local space.
            b.location=rest.inverted() @ Vector((0,p.get('hip_y',0),-p.get('drop',0)))
        b.keyframe_insert('location',frame=frame,group=b.name)

def add_action(rig,name,seconds,poses,loop=False,category='shared',note=''):
    name=ALIASES.get(name,name)
    timing=TIMINGS.get(name)
    if timing:
        seconds=timing['total']/60
        contact=timing['startup']/timing['total'];end=(timing['startup']+timing['active']-1)/timing['total']
        if note=='absolute_combat_ticks':
            pass
        elif len(timing.get('active_windows',[]))>1:
            initial=poses[0][1];wind=poses[1][1];hit=poses[2][1];staged=[(0,initial)]
            for i,(start,stop) in enumerate(timing['active_windows']):
                target=dict(hit)
                if i%2:
                    target['ll'],target['rl']=hit.get('rl',(0,0,0)),hit.get('ll',(0,0,0))
                    target['la'],target['ra']=hit.get('ra',(25,18,130)),hit.get('la',(25,18,130))
                staged.extend([((start-3)/timing['total'],wind),(start/timing['total'],target),(stop/timing['total'],target)])
            poses=staged+[(1,initial)]
        elif name=='ultimate':
            # First committed contact agrees with the opener. Follow-up pose progression
            # occupies its documented recovery/capture interval; gameplay owns confirmation.
            poses=[((phase/.28*contact) if phase<=.28 else contact+(phase-.28)/.72*(1-contact),p) for phase,p in poses]
        elif len(poses)==5 and abs(poses[2][0]-.36)<.001:
            poses=[(0,poses[0][1]),(contact*.58,poses[1][1]),(contact,poses[2][1]),(max(contact+.001,end),poses[3][1]),(1,poses[4][1])]
        elif name=='grab':poses=[(0,poses[0][1]),(contact,poses[1][1]),(max(contact+.01,end),poses[2][1]),(1,poses[3][1])]
        elif name.startswith('throw_'):poses=[(0,poses[0][1]),(contact*.5,poses[1][1]),(contact,poses[2][1]),(1,poses[3][1])]
    action=bpy.data.actions.new(name);action.use_fake_user=True
    rig.animation_data_create();rig.animation_data.action=action
    for phase,p in poses:key_pose(rig,p,round(phase*seconds*60)+1)
    action['loop']=loop;action['authored_seconds']=seconds;action['purpose']=category
    # Linear sampled transitions preserve explicit anticipation/contact/recovery timing.
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for fcurve in bag.fcurves:
                    for key in fcurve.keyframe_points:key.interpolation='BEZIER'
    ANIMS.append(dict(name=name,seconds=seconds,frames=round(seconds*60)+1,loop=loop,category=category,note=note,
         keyed_bones=len(rig.pose.bones),pose_count=len(poses),combat_timing=timing))

def author(rig,style,fighter_id=''):
    g=guard(style)
    def clip(n,t,points,loop=False,cat='shared',note=''):add_action(rig,n,t,points,loop,cat,note)
    def act(n,seconds,wind,hit,end=None):clip(n,seconds,[(0,g),(.23,wind),(.36,hit),(.56,hit if end is None else end),(1,g)],cat='attack')
    clip('idle',2.4,[(0,g),(.5,dict(g,lean=g['lean']+1.5,head=3,la=(g['la'][0]+3,g['la'][1],g['la'][2]-5))),(1,g)],True,'stance')
    clip('intro',1.8,[(0,pose(la=(0,17,0),ra=(0,17,0)) ),(.3,pose(la=(55,20,110),ra=(70,15,150),twist=-18)),(.6,pose(la=(80,20,95),ra=(80,18,95),head=12)),(1,g)],cat='personality')
    for name,seconds,angle in [('walk',1.05,24),('run',.62,48)]:
        pts=[]
        # Explicit planted-foot trajectories, solved onto the actual measured leg lengths.
        # During stance the foot travels backward at a constant speed relative to the
        # in-place pelvis. At nominal runtime stride travel this cancels body movement.
        stance=.4 if name=='run' else .6
        sweep=.8 if name=='run' else .6
        def leg_ik(side,phase,drop):
            phase=phase%1.0
            if phase<stance:
                foot_y=-sweep*.5+sweep*phase/stance;lift=0.0
            else:
                u=(phase-stance)/(1-stance)
                foot_y=sweep*.5*math.cos(u*math.pi)
                lift=(.23 if name=='run' else .09)*math.sin(u*math.pi)
            upper=rig.data.bones['thigh.'+side];lower=rig.data.bones['shin.'+side]
            l1=upper.length/math.sqrt(1+.075**2);l2=lower.length/math.sqrt(1+.075**2)
            down=upper.head_local.z-drop-(lower.tail_local.z+lift)
            distance=min(l1+l2-.001,math.sqrt(foot_y*foot_y+down*down))
            knee=math.acos(max(-1,min(1,(distance*distance-l1*l1-l2*l2)/(2*l1*l2))))
            hip=math.atan2(-foot_y,down)+math.atan2(l2*math.sin(knee),l1+l2*math.cos(knee))
            return (math.degrees(hip),math.degrees(knee),0)
        sample_count=round(seconds*60)
        for j in range(sample_count+1):
            ph=j/sample_count;sn=math.sin(ph*math.tau);cs=math.cos(ph*math.tau)
            drop=(.12 if name=='run' else .065)+(.008 if name=='run' else .006)*math.cos(ph*math.tau*2)
            arm=cs*(38 if name=='run' else 18);bend=78 if name=='run' else 23
            pts.append((ph,pose(lean=12 if name=='run' else 3,drop=drop,
                la=(-arm,16,bend-arm),ra=(arm,16,bend+arm),
                ll=leg_ik('L',ph,drop),rl=leg_ik('R',ph+.5,drop),twist=sn*5)))
        clip(name,seconds,pts,True,'locomotion')
    clip('move_start',.25,[(0,g),(.35,pose(lean=18,ll=(18,30,0),rl=(-14,10,0),la=(-22,12,65),ra=(53,15,120))),(1,pose(lean=12,ll=(30,40,0),rl=(-28,5,0)))],cat='locomotion')
    clip('move_stop',.3,[(0,pose(lean=-15,ll=(35,30,0),rl=(-15,0,0),drop=.07)),(.45,pose(lean=-5,la=(60,30,100),ra=(30,30,100),drop=.05)),(1,g)],cat='locomotion')
    clip('turnaround',.24,[(0,g),(.5,pose(twist=40,head=-40,ll=(5,20,0),rl=(5,20,0),drop=.04)),(1,g)],cat='locomotion')
    crouch=pose(drop=.17,lean=19,ll=(38,75,0),rl=(38,75,0),la=(30,20,100),ra=(25,20,100))
    clip('crouch',.5,[(0,crouch),(.5,dict(crouch,lean=21)),(1,crouch)],True)
    clip('jump_start',.16,[(0,g),(.5,crouch),(1,pose(la=(130,15,160),ra=(130,15,160),ll=(-10,0,-15),rl=(-10,0,-15)))])
    rise=pose(lean=6,la=(100,23,145),ra=(75,23,135),ll=(40,100,15),rl=(-20,30,-5))
    clip('jump_rise',.6,[(0,rise),(.5,dict(rise,ll=(25,75,0),rl=(-10,35,0))),(1,dict(rise,la=(60,25,110)))])
    clip('double_jump',.5,[(0,rise),(.4,pose(lean=35,la=(120,30,155),ra=(120,30,155),ll=(65,110,0),rl=(55,110,0))), (1,rise)])
    falling=pose(lean=-5,la=(20,48,75),ra=(15,40,65),ll=(5,15,0),rl=(-5,25,0))
    clip('fall',.9,[(0,falling),(.5,dict(falling,la=(25,45,70),rl=(-10,35,0))),(1,falling)],True)
    clip('helpless',.8,[(0,pose(lean=-9,la=(0,50,30),ra=(0,45,30),ll=(5,15,0),rl=(-5,35,0))),(.5,falling),(1,pose(lean=-9,la=(0,50,30),ra=(0,45,30),ll=(5,15,0),rl=(-5,35,0)))],True)
    for n,t in [('land',.25),('land_hard',.48)]:clip(n,t,[(0,falling),(.22,crouch),(1,g)])
    shield=pose(lean=-2,la=(55,7,170),ra=(65,8,170),drop=.045,ll=(9,18,0),rl=(9,18,0))
    clip('shield_enter',.14,[(0,g),(1,shield)]);clip('shield',1,[(0,shield),(.5,dict(shield,drop=.055)),(1,shield)],True)
    clip('shield_exit',.18,[(0,shield),(1,g)])
    clip('parry',.28,[(0,shield),(.25,pose(la=(100,35,105),ra=(80,10,155),twist=-22,lean=-8)),(1,g)])
    clip('shield_break',1.4,[(0,shield),(.12,pose(lean=-23,la=(-30,50,70),ra=(-30,50,70))),(.5,pose(lean=20,la=(0,10,35),ra=(0,10,35),drop=.17,ll=(30,60,0),rl=(30,60,0))),(1,g)])
    clip('spot_dodge',.42,[(0,g),(.3,pose(lean=-23,twist=35,drop=.14,ll=(20,45,0),rl=(20,45,0),la=(15,40,90),ra=(20,30,100))),(.65,crouch),(1,g)])
    for n,sgn in [('roll_forward',1),('roll_back',-1),('air_dodge',1)]:
        clip(n,.6,[(0,g),(.2,crouch),(.45,pose(lean=65*sgn,drop=.33,la=(75,15,160),ra=(75,15,160),ll=(70,120,20),rl=(60,120,20))),(.72,crouch),(1,g)])
    clip('hit_light',.3,[(0,g),(.15,pose(lean=-18,twist=17,head=-16,la=(10,25,90),ra=(10,25,100))),(1,g)])
    clip('hit_heavy',.65,[(0,g),(.2,pose(lean=-31,twist=-24,la=(-20,45,50),ra=(-30,50,55),ll=(20,20,0),rl=(-20,35,0))),(.6,falling),(1,g)])
    tumble=pose(lean=-55,la=(60,45,90),ra=(-40,55,65),ll=(65,110,20),rl=(-20,75,20))
    clip('launch',.42,[(0,g),(.2,tumble),(1,dict(tumble,lean=-30))])
    clip('tumble',.85,[(0,tumble),(.5,pose(lean=45,twist=20,la=(-40,65,20),ra=(80,35,130),ll=(-10,95,0),rl=(70,100,0))),(1,tumble)],True)
    down=pose(lean=72,drop=.54,la=(65,20,115),ra=(65,20,115),ll=(80,105,0),rl=(60,115,0))
    clip('knockdown',.65,[(0,tumble),(.45,down),(1,dict(down,lean=65))])
    clip('getup',.8,[(0,down),(.45,crouch),(1,g)])
    ledge=pose(la=(155,10,175),ra=(155,10,175),ll=(12,20,0),rl=(-8,35,0))
    clip('ledge_catch',.3,[(0,falling),(1,ledge)]);clip('ledge_hold',1,[(0,ledge),(.5,dict(ledge,ll=(15,30,0))),(1,ledge)],True)
    clip('ledge_release',.35,[(0,ledge),(1,falling)])
    # Common attack vocabulary, individualized upper-body arcs and contact postures.
    broad=style==2;precise=style==4;scrap=style==3;show=style==1
    spread=32 if broad else 9 if precise else 20
    jabwind=pose(la=(10,spread,145),ra=(35,18,140),twist=18,lean=-3)
    jab=pose(la=(88,spread,88),ra=(30,14,140),twist=-15,lean=8)
    act('jab_1',.34,jabwind,jab)
    act('jab_2',.4,pose(ra=(5,spread,150),la=(35,18,135),twist=-18),pose(ra=(95,spread,88),la=(25,18,145),twist=22,lean=11))
    act('jab_3',.58,pose(twist=35,la=(-15,45,110)),pose(la=(90,45,135),ra=(35,15,140),twist=-38,lean=13,arm_yaw=-30))
    act('light_side',.47,jabwind,pose(la=(88,spread,85),ra=(20,16,140),twist=-20,lean=14))
    act('light_up',.52,pose(drop=.12,ll=(20,40,0),rl=(20,40,0),ra=(15,20,75)),pose(ra=(165,15,170),la=(30,20,130),lean=-8,twist=15))
    act('light_down',.55,crouch,pose(drop=.24,lean=25,ll=(75,10,0),rl=(35,65,0),la=(40,20,100),ra=(25,25,80)))
    act('dash_attack',.67,pose(lean=30,la=(-25,25,85),ra=(35,15,130),ll=(30,50,0),rl=(-30,25,0)),pose(lean=42,twist=-25,la=(48,25,150),ra=(55,20,150),ll=(-15,0,0),rl=(28,70,0)))
    charge=pose(lean=-12,twist=35,la=(-20,26,140),ra=(10,25,145),drop=.1,ll=(20,40,0),rl=(20,40,0))
    clip('heavy_charge',1,[(0,charge),(.5,dict(charge,twist=39,drop=.11)),(1,charge)],True,'attack')
    act('heavy_side',.86,charge,pose(lean=28,twist=-40,la=(90,spread+10,84),ra=(52,20,145),ll=(15,30,0),rl=(-15,0,0),drop=.03))
    act('heavy_up',.92,crouch,pose(lean=-13,la=(150,25,170),ra=(155,25,170),ll=(-8,0,0),rl=(-8,0,0)))
    act('heavy_down',.96,pose(la=(150,28,170),ra=(150,28,170),lean=-10),pose(lean=45,drop=.2,ll=(25,45,0),rl=(25,45,0),la=(40,14,40),ra=(45,14,45)))
    act('aerial_neutral',.7,rise,pose(lean=-7,la=(75,70,90),ra=(75,70,90),ll=(70,10,5),rl=(-35,25,0)))
    act('aerial_forward',.64,pose(ll=(70,120,0),rl=(-15,30,0),la=(35,20,130),ra=(35,20,130)),pose(lean=-20,ll=(85,5,0),rl=(-35,55,0),la=(40,35,120),ra=(25,35,120)))
    act('aerial_back',.66,pose(lean=15,rl=(-15,70,0)),pose(lean=25,rl=(-72,5,0),ll=(25,65,0),twist=30,la=(40,25,110)))
    act('aerial_up',.64,pose(ll=(55,110,0),rl=(30,70,0)),pose(lean=-27,ll=(145,8,0),rl=(40,85,0),la=(35,30,135),ra=(35,30,135)))
    act('aerial_down',.78,pose(ll=(70,120,0),rl=(70,120,0),la=(135,25,150),ra=(135,25,150)),pose(lean=15,ll=(-5,0,-15),rl=(-5,0,-15),la=(40,45,100),ra=(40,45,100)))
    # Signature choreography: authored stances and limb trajectories differ per identity.
    if style==0:
        special=[(pose(la=(25,15,145),ra=(30,15,145),twist=24),pose(la=(90,12,88),ra=(88,12,90),lean=16,twist=-10)),
          # The near shoulder leads a compact body check. The striking arm folds
          # behind that shoulder instead of presenting two hands into empty space.
          # Gameplay's measured shoulder capsule owns reach; the mesh is not stretched.
          (pose(lean=-12,twist=-25,la=(25,25,150)),pose(lean=48,twist=52,la=(30,18,128),ra=(-8,12,153),ll=(20,35,0),rl=(-35,0,0),drop=.01)),
          (crouch,pose(ra=(168,10,176),la=(30,20,145),lean=-12,ll=(40,90,0),rl=(-15,15,0))),
          (shield,pose(la=(90,25,92),ra=(90,25,92),lean=14,twist=-12))]
    elif style==1:
        special=[(pose(ra=(135,7,170),head=-15,twist=35),pose(ra=(90,50,110),la=(25,35,110),arm_yaw=35,twist=-35)),
          (pose(twist=45,la=(-15,55,95)),pose(la=(90,60,105),arm_yaw=-55,twist=-45,ll=(35,65,0),rl=(-15,20,0))),
          (pose(drop=.2,ll=(35,60,0),rl=(35,60,0),la=(20,40,105),ra=(20,40,105)),pose(la=(155,60,172),ra=(155,60,172),lean=-15,ll=(20,80,0),rl=(-15,70,0))),
          (pose(ra=(90,15,145),head=12),pose(lean=30,drop=.18,ra=(25,25,50),la=(65,40,130),ll=(35,65,0),rl=(25,45,0)))]
    elif style==2:
        special=[(pose(la=(55,80,95),ra=(55,80,95),lean=-14),pose(la=(95,3,92),ra=(95,3,92),lean=23)),
          (pose(la=(50,55,75),ra=(50,55,75),lean=-10),pose(la=(85,22,105),ra=(85,22,105),lean=32,drop=.07,ll=(15,25,0),rl=(-15,0,0))),
          (crouch,pose(ra=(100,70,92),la=(100,70,92),lean=-5,ll=(20,60,0),rl=(-10,20,0))),
          (pose(ll=(65,100,0),la=(70,35,130),ra=(70,35,130),lean=-10),pose(lean=23,ll=(-5,0,0),rl=(10,20,0),la=(5,40,90),ra=(5,40,90)))]
    elif style==3:
        special=[(pose(ra=(0,40,100),twist=38,drop=.07),pose(ra=(80,50,90),la=(20,30,110),twist=-38,arm_yaw=28,lean=18)),
          # The planted shoe sits ~0.096m above the floor on the live 0.09m plank.
          (crouch,pose(lean=-20,drop=.11,ll=(65,20,0),rl=(50,80,0),la=(70,25,135),ra=(155,18,170))),
          (pose(ra=(155,20,165),la=(120,20,155),drop=.14,ll=(30,55,0),rl=(30,55,0)),pose(ra=(175,15,175),la=(100,35,130),lean=-25,ll=(60,105,0),rl=(-20,35,0))),
          (pose(ra=(40,20,135),head=-15),pose(lean=42,drop=.28,ll=(35,65,0),rl=(40,75,0),la=(30,35,45),ra=(35,35,48)))]
    else:
        special=[(pose(la=(20,5,160),ra=(35,5,150),twist=12,lean=-3),pose(la=(91,2,90),ra=(35,5,150),lean=7,twist=-12)),
          (pose(ll=(65,120,0),la=(30,6,145),ra=(30,6,145)),pose(lean=-12,ll=(88,4,0),rl=(0,4,0),la=(30,8,150),ra=(35,8,155))),
          (pose(ll=(65,115,0),rl=(0,8,0)),pose(lean=-18,ll=(130,8,0),rl=(25,70,0),la=(30,9,155),ra=(40,9,155))),
          (pose(la=(75,8,155),ra=(35,8,150),lean=-4),pose(la=(92,8,92),ra=(35,8,150),twist=-16,lean=5))]
    if fighter_id=='f06_rugged_explorer':
        # Cast a hook, rush along its line, climb, then brace for a low strike.
        special=[(pose(lean=-7,twist=28,ra=(5,18,115),la=(35,25,140)),
                  pose(lean=12,twist=-24,ra=(96,8,96),la=(25,14,130),arm_yaw=-12)),
                 (pose(lean=-19,drop=.10,ll=(28,45,0),rl=(12,35,0),ra=(20,20,135)),
                  pose(lean=47,twist=20,ra=(34,12,145),la=(40,15,120),ll=(28,40,0),rl=(-20,5,0))),
                 (pose(drop=.19,ll=(42,70,0),rl=(42,70,0),ra=(115,16,145)),
                  pose(lean=-17,ra=(175,12,177),la=(130,25,165),ll=(55,95,0),rl=(20,45,0))),
                 (pose(drop=.24,lean=20,ll=(35,65,0),rl=(35,65,0),la=(28,20,105),ra=(34,18,110)),
                  pose(drop=.22,lean=34,ll=(45,65,0),rl=(35,55,0),la=(38,20,55),ra=(45,20,60)))]
    elif fighter_id=='f07_urban_sentinel':
        # Deliberate spacing and shoulder-led offense suit the armored zone holder.
        special=[(pose(lean=-4,la=(45,12,150),ra=(55,12,155),twist=9),
                  pose(lean=10,la=(95,8,95),ra=(95,8,95),twist=-8)),
                 (pose(lean=-15,drop=.10,twist=-19,la=(20,15,140),ra=(35,15,140)),
                  pose(lean=43,twist=35,la=(31,15,145),ra=(-8,10,153),ll=(24,35,0),rl=(-20,8,0))),
                 (pose(drop=.17,ll=(42,70,0),rl=(42,70,0),la=(55,12,160),ra=(55,12,160)),
                  pose(lean=-13,la=(150,12,170),ra=(150,12,170),ll=(35,80,0),rl=(-10,20,0))),
                 (pose(drop=.17,ll=(37,60,0),rl=(37,60,0),la=(60,18,155),ra=(60,18,155)),
                  pose(drop=.14,lean=8,la=(92,38,95),ra=(92,38,95)))]
    elif fighter_id=='f08_midnight_gentleman':
        # An arm sweep, a feinting step, upward flourish and evasive bow.
        special=[(pose(lean=-5,twist=30,ra=(55,10,140),la=(15,10,145)),
                  pose(lean=10,twist=-32,ra=(92,46,92),la=(30,10,140),arm_yaw=25)),
                 (pose(drop=.07,lean=-18,twist=35,la=(15,8,145),ra=(65,9,120)),
                  pose(lean=29,twist=-28,la=(93,6,89),ra=(31,8,145),ll=(25,55,0),rl=(-18,8,0))),
                 (pose(drop=.14,ll=(45,75,0),rl=(20,55,0),la=(65,12,145),ra=(65,12,145)),
                  pose(lean=-20,la=(145,10,170),ra=(120,12,155),ll=(65,100,0),rl=(25,55,0))),
                 (pose(lean=-12,twist=24,head=-8,la=(45,10,130),ra=(35,8,135)),
                  pose(lean=-31,twist=-28,head=15,la=(35,14,100),ra=(105,16,100),ll=(-25,35,0),rl=(28,65,0)))]
    def combat_clip(name,points):
        total=TIMINGS.get(name,{}).get('total',80)
        clip(name,total/60,[(t/total,p) for t,p in points],cat='signature',note='absolute_combat_ticks')
    for n,(w,c),duration in zip(['special_neutral','special_side','special_up','special_down'],special,[.9,.78,.86,.85]):
        if fighter_id=='f07_urban_sentinel' and n=='special_down':
            t=TIMINGS[n];start=t['startup'];end=t['total']
            combat_clip(n,[(0,g),(5,w),(max(5,start-2),w),(start,c),
              (start+4,dict(c,lean=13,la=(100,42,88),ra=(100,42,88))),(end,g)])
        elif fighter_id=='f08_midnight_gentleman' and n=='special_down':
            t=TIMINGS[n];start=t['startup'];end=t['total']
            combat_clip(n,[(0,g),(start*.55,w),(start,c),
              (start+6,dict(c,lean=-20,twist=-10)),(end,g)])
        elif style==2 and n=='special_side' and n in TIMINGS:
            t=TIMINGS[n];start=t['startup'];end=t['total']
            combat_clip(n,[(0,g),(start*.55,w),(start,c),(start+7,pose(la=(135,20,158),ra=(135,20,158),lean=-15)),
              (start+25,pose(lean=48,drop=.12,ll=(25,45,0),rl=(25,45,0),la=(20,23,30),ra=(20,23,30))),(end,g)])
        elif style in [0,4] and n=='special_down' and not fighter_id.startswith(('f06_','f07_','f08_')):
            act(n,duration,w,dict(w,lean=w.get('lean',0)-3))
            act('counter_success',.38,w,c)
        else:act(n,duration,w,c)
    if style==2:
        # An airborne down-special is an elbow-led descent, not a standing stomp.
        # The gameplay state selects this optional clip when the move starts in air.
        TIMINGS['special_down_air']=dict(TIMINGS['special_down'])
        act('special_down_air',.92,
          pose(lean=-12,la=(70,25,140),ra=(155,12,165),ll=(65,115,0),rl=(45,105,0)),
          pose(lean=52,twist=18,la=(75,20,130),ra=(15,8,158),ll=(70,95,0),rl=(20,90,0)))
    # Attacker contact and finisher keys share the actual authoritative capture ticks.
    ut=TIMINGS.get('ultimate',{'startup':26,'total':80});start=ut['startup'];end=ut['total']
    if fighter_id=='f06_rugged_explorer':
        combat_clip('ultimate',[(0,g),(start*.55,pose(drop=.12,lean=-18,ra=(20,12,145),la=(35,14,135))),
          (start,pose(lean=42,ra=(82,10,94),la=(70,12,100),ll=(28,45,0),rl=(-20,8,0))),
          (start+9,pose(lean=-8,ra=(72,12,120),la=(72,12,120),twist=16)),
          (start+20,pose(lean=-25,la=(135,18,155),ra=(135,18,155),ll=(35,60,0),rl=(25,45,0))),
          (start+35,pose(lean=50,drop=.22,la=(27,25,35),ra=(27,25,35),ll=(45,70,0),rl=(40,70,0))),
          (end,g)])
    elif fighter_id=='f07_urban_sentinel':
        combat_clip('ultimate',[(0,g),(start*.3,pose(drop=.10,lean=-8,la=(35,18,155),ra=(35,18,155))),
          (start*.76,pose(drop=.16,la=(75,18,160),ra=(75,18,160),lean=-7)),
          (start,pose(lean=9,la=(100,45,93),ra=(100,45,93),drop=.08)),
          (start+8,pose(lean=15,la=(112,50,85),ra=(112,50,85))), (end,g)])
    elif fighter_id=='f08_midnight_gentleman':
        combat_clip('ultimate',[(0,g),(start*.55,pose(drop=.08,lean=-20,twist=38,ra=(70,8,130),la=(22,8,150))),
          (start,pose(lean=37,twist=-23,ra=(98,28,90),la=(55,8,135),ll=(26,45,0),rl=(-22,10,0))),
          (start+10,pose(ra=(100,8,85),la=(38,8,150),twist=22,head=-10)),
          (start+22,pose(lean=-17,la=(28,8,155),ra=(28,8,155),rl=(98,8,0))),
          (start+35,pose(lean=28,la=(90,8,90),ra=(35,8,145),twist=-28)),(end,g)])
    elif style==0:
        # Captured opponents stand 0.70m ahead. A forward-rising uppercut meets
        # that target, whereas the recovery's vertical reach passed behind it.
        clutch_finish=pose(ra=(120,8,128),la=(30,18,145),lean=14,twist=12,
          ll=(32,70,0),rl=(-12,12,0))
        combat_clip('ultimate',[(0,g),(start*.6,special[1][0]),(start,special[1][1]),
          (start+9,pose(la=(90,12,90),ra=(25,15,140),twist=-22,lean=14)),
          (start+18,pose(ra=(95,12,88),la=(25,15,140),twist=22,lean=14)),
          (start+29,crouch),(min(start+40,end-2),clutch_finish),(end,g)])
    elif style==2:
        combat_clip('ultimate',[(0,g),(start*.6,pose(la=(25,55,90),ra=(25,55,90),lean=-10)),
          (start,pose(la=(85,20,100),ra=(85,20,100),lean=20)),
          (start+12,pose(la=(135,20,160),ra=(135,20,160),lean=-18)),
          (start+28,pose(la=(160,25,170),ra=(160,25,170),lean=-24)),
          (min(start+45,end-2),pose(lean=53,drop=.15,ll=(25,45,0),rl=(25,45,0),la=(20,25,35),ra=(20,25,35))), (end,g)])
    elif style==4:
        combat_clip('ultimate',[(0,g),(start*.6,pose(la=(70,15,100),ra=(70,15,100),lean=0)),(start,special[0][1]),
          (start+8,pose(ra=(93,5,91),la=(35,6,145),twist=17)),
          (start+17,pose(lean=-15,rl=(100,7,0),ll=(0,3,0),la=(30,7,150),ra=(30,7,150))),
          (start+27,pose(ll=(65,120,0),rl=(0,5,0))),
          (min(start+37,end-2),special[1][1]),(end,g)])
    elif style==3:
        combat_clip('ultimate',[(0,g),(start*.35,pose(la=(80,15,120),ra=(80,15,120),head=-15)),
          (start*.75,pose(la=(145,35,170),ra=(145,35,170),lean=-12)),
          (start,pose(lean=35,la=(55,25,65),ra=(55,25,65),drop=.1,ll=(20,35,0),rl=(20,35,0))),
          (start+8,pose(la=(40,20,100),ra=(100,35,110),head=16)),(end,g)])
    else:
        points=[(0,g),(start*.6,pose(la=(140,30,165),ra=(140,30,165),lean=-10))]
        for i,(a,b) in enumerate(ut.get('active_windows',[[start,start+2],[start+8,start+10],[start+16,start+18]])):
            points.extend([(a,pose(la=(110 if i%2 else 65,35,145),ra=(65 if i%2 else 110,35,145),twist=(-15 if i%2 else 15))),
              (b+2,pose(la=(135,45,160),ra=(135,45,160),head=i*7))])
        combat_clip('ultimate',points+[(end,g)])
    grab=pose(la=(83,20,90),ra=(83,20,90),lean=13)
    hold=pose(la=(68,15,120),ra=(68,15,120),lean=-3,drop=.04)
    clip('grab',.6,[(0,g),(.35,grab),(.65,hold),(1,g)],cat='grapple')
    clip('grab_hold',.8,[(0,hold),(.5,dict(hold,lean=-5)),(1,hold)],True,'grapple')
    clip('grab_release',.4,[(0,hold),(.35,grab),(1,g)],cat='grapple')
    for name,c in [('throw_forward',pose(la=(100,15,95),ra=(100,15,95),lean=30)),
        ('throw_back',pose(twist=70,la=(80,30,95),ra=(80,30,95),arm_yaw=100)),
        ('throw_up',pose(la=(160,15,173),ra=(160,15,173),lean=-14)),
        ('throw_down',pose(la=(22,20,35),ra=(22,20,35),lean=45,drop=.16,ll=(25,45,0),rl=(25,45,0)))]:
        clip(name,.78,[(0,hold),(.3,dict(hold,lean=-15)),(.5,c),(1,g)],cat='grapple')
    clip('captured',.85,[(0,pose(la=(40,45,80),ra=(40,45,80),ll=(20,70,0),rl=(10,60,0),lean=-15)),(.5,tumble),(1,pose(la=(40,45,80),ra=(40,45,80),ll=(20,70,0),rl=(10,60,0),lean=-15))],True,'victim')
    for name,target in [('thrown_forward',tumble),('thrown_back',dict(tumble,lean=45)),('thrown_up',rise),('thrown_down',down)]:clip(name,.7,[(0,hold),(.35,target),(1,falling)],cat='victim')
    clip('respawn',1.2,[(0,pose(la=(120,65,150),ra=(120,65,150),ll=(10,35,0),rl=(10,35,0))),(.6,crouch),(1,g)])
    personality=[
      (pose(ra=(125,10,145),la=(20,15,110),head=-20),pose(la=(80,8,165),ra=(80,8,165),head=10)),
      (pose(ra=(148,5,165),la=(20,35,100),head=-15),pose(lean=32,la=(40,60,70),ra=(40,60,70))),
      (pose(drop=.38,ll=(80,90,0),rl=(80,90,0),la=(10,20,80),ra=(10,20,80)),pose(la=(15,45,125),ra=(15,45,125),head=-12)),
      (pose(la=(90,15,120),ra=(60,10,140),head=18,lean=7),pose(ra=(130,20,160),la=(30,30,110),head=-15)),
      (pose(la=(65,10,100),ra=(60,5,130),head=12),pose(la=(85,8,155),ra=(45,9,120),head=-7))][style]
    for i,target in enumerate(personality):
        if style==2 and i==0:
            # Runtime normalizes the source to 55 ticks. Hands mime opening
            # the temporary chair before the pelvis settles over its .55m seat.
            clip('taunt_1',1.8,[(0,g),
              (.12,pose(lean=16,la=(65,8,90),ra=(65,8,90),head=-12)),
              (.28,pose(lean=25,la=(35,48,55),ra=(35,48,55),head=-18,drop=.08,ll=(15,25,0),rl=(15,25,0))),
              (.52,target),(.76,dict(target,head=7)),(.88,dict(target,lean=22,la=(35,20,90),ra=(35,20,90))),
              (1,g)],cat='personality',note='chair appears at runtime tick 12; seated 29–42; stand by 55')
        else:
            clip(f'taunt_{i+1}',1.8,[(0,g),(.3,target),(.65,dict(target,head=target.get('head',0)+9)),(1,g)],cat='personality')
    victory=pose(la=(150,40,168),ra=(150,40,168),head=-10) if style in [0,1] else personality[1]
    clip('win',2.2,[(0,g),(.3,victory),(.65,dict(victory,head=8)),(1,victory)],cat='personality')
    clip('lose',2,[(0,g),(.4,pose(la=(5,15,30),ra=(5,15,30),lean=13,head=-18)),(1,pose(la=(5,15,30),ra=(5,15,30),lean=11,head=15))],cat='personality')
    clip('final_ko',1.6,[(0,g),(.3,personality[1]),(.7,dict(personality[1],head=-10)),(1,g)],cat='personality')
    # Dedicated anatomical stress clips expose the real mesh deformation, not a stand-in rig.
    for n,target in [('shoulder_raise',pose(la=(80,70,90),ra=(80,70,90))),('elbow_bend',pose(la=(20,18,150),ra=(20,18,150))),
      ('knee_bend',pose(ll=(70,105,0),rl=(0,0,0))),('torso_twist',pose(twist=40)),('deep_pose',crouch)]:
        clip('qa_'+n,1,[(0,pose(la=(0,15,0),ra=(0,15,0))),(.5,target),(1,pose(la=(0,15,0),ra=(0,15,0)))],cat='deformation_qa')

def studio(scene):
    scene.render.engine='CYCLES';scene.cycles.samples=20
    scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
    scene.render.film_transparent=False
    world=bpy.data.worlds.new('Character QA studio');scene.world=world;world.use_nodes=True
    world.node_tree.nodes['Background'].inputs[0].default_value=(.045,.065,.11,1);world.node_tree.nodes['Background'].inputs[1].default_value=.35
    mat=bpy.data.materials.new('QA floor');mat.diffuse_color=(.055,.07,.10,1)
    bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;floor.name='QA_Floor';floor.data.materials.append(mat)
    for loc,en,size in [((2,-4,5),450,4),((-3,-1,3),250,3),((2,3,4),650,3)]:
        bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name='QA_Light';o.data.energy=en;o.data.shape='DISK';o.data.size=size
        o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=(2.5,-5,2.3));cam=bpy.context.object;cam.name='QA_Camera';cam.data.type='ORTHO';cam.data.ortho_scale=2.65
    cam.rotation_euler=(Vector((0,-.06,1.08))-cam.location).to_track_quat('-Z','Y').to_euler();scene.camera=cam;scene.view_settings.view_transform='AgX'

def run(fid):
    curated=ROOT/'source_art/characters'/fid/'curated.blend'
    if curated.exists() and '--regenerate-baseline' not in sys.argv:
        sys.path.insert(0,str(ROOT/'tools/blender'))
        from hero_export import export_curated
        export_curated(fid,curated)
        return
    ANIMS.clear();cfg=SOURCES[fid];rig,mesh=prepare(fid,cfg)
    if '--prepare-only' in sys.argv:
        print('CHARACTER_PREPARE_COMPLETE',fid,cfg['prepared_stats'],flush=True)
        return
    restore_source_surface_maps(mesh)
    rig['mapping']=cfg['mapping']
    TIMINGS.clear()
    timing_id=fid if fid in ('f06_rugged_explorer','f07_urban_sentinel','f08_midnight_gentleman') else {0:'f01_clutch',1:'f02_sunstruck',2:'f03_heavy_duty',3:'f04_deadfall',4:'f05_fine_print'}[cfg['style']]
    timing_path=ROOT/'Game File/characters/definitions'/(timing_id+'.gd')
    if timing_path.exists():
        for m in re.finditer(r'\["([a-z_0-9]+)",\s*"[^"]+",\s*(\d+),\s*(\d+),\s*(\d+),',timing_path.read_text(encoding='utf-8')):
            n,s,a,r=m.groups();TIMINGS[n]={'startup':int(s),'active':int(a),'recovery':int(r),'total':int(s)+int(a)+int(r)}
    runtime_timings=ROOT/'docs/moves/move_timing.json'
    if runtime_timings.exists():
        rows=json.loads(runtime_timings.read_text(encoding='utf-8'))['fighters'].get(timing_id,{}).get('moves',{})
        for n,row in rows.items():
            TIMINGS[n]={'startup':row['startup'],'active':row['active_windows'][0][1]-row['startup']+1,
              'active_windows':row['active_windows'],'recovery':row['recovery'],'total':row['total_ticks']}
    for action in list(bpy.data.actions):bpy.data.actions.remove(action)
    bpy.context.scene.render.fps=60;author(rig,cfg['style'],fid)
    rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
    # All exported animation channels are rooted on this one semantic armature.
    bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
    directory=ROOT/'source_art/characters'/fid
    bpy.ops.wm.save_as_mainfile(filepath=str(directory/(fid+'.blend')))
    runtime=RUNTIME/(fid+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(runtime),export_format='GLB',use_selection=True,export_animations=True,
      export_animation_mode='ACTIONS',export_anim_single_armature=True,export_bake_animation=False,
      export_anim_slide_to_zero=True,
      export_force_sampling=True,export_frame_range=False,export_frame_step=1,export_skins=True,
      export_yup=True,export_apply=False,export_def_bones=False,export_optimize_animation_size=True)
    report=dict(fighter_id=fid,mapping=cfg['mapping'],source_path=rig['source_path'],source_sha256=rig['source_sha256'],
      output=str(runtime.relative_to(ROOT)),editable_source=str((directory/(fid+'.blend')).relative_to(ROOT)),
      stats=json.loads(rig['prepared_stats']),animations=list(ANIMS),forward_godot='+Z',up_godot='+Y',
      materials=[mat.name for mat in mesh.data.materials],texture_images=[{'name':n.image.name,'size':list(n.image.size),'color_space':n.image.colorspace_settings.name} for mat in mesh.data.materials for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image],
      source_rig=False,source_animations=0,source_pose='relaxed A pose',rig_binding=json.loads(rig['prepared_stats']).get('binding','anatomical partition'),
      pending_validation=['Godot visual playback of all clips','manual contact-sheet review'])
    (OUT/(fid+'_manifest.json')).write_text(json.dumps(report,indent=2))
    (ROOT/'docs'/('animation_'+fid+'.json')).write_text(json.dumps(report['animations'],indent=2))
    if '--no-preview' in sys.argv:
        print('CHARACTER_EXPORT_COMPLETE',fid,len(ANIMS),runtime,flush=True)
        return
    # Real model portraits and individual stress/motion frames; compose contact sheets externally.
    studio(bpy.context.scene)
    preview=OUT/fid;preview.mkdir(exist_ok=True)
    picks=[('idle',1),('run',10),('jump_rise',12),('jab1',6),('special_neutral',15),('special_side',12),('special_up',8),('special_down',6),('ultimate',40),
           ('qa_shoulder_raise',31),('qa_elbow_bend',31),('qa_knee_bend',31),('qa_torso_twist',31),('qa_deep_pose',31)]
    for name,frame in picks:
        if name in TIMINGS:frame=TIMINGS[name]['startup']+1
        rig.animation_data.action=bpy.data.actions[name];bpy.context.scene.frame_set(frame)
        bpy.context.scene.render.filepath=str(preview/(name+'.png'));bpy.ops.render.render(write_still=True)
    print('CHARACTER_EXPORT_COMPLETE',fid,len(ANIMS),runtime,flush=True)

if __name__=='__main__':
    # Populate this file only from explicit identity confirmation. Null/unset mappings
    # keep the two supplied costumes under neutral source IDs, never guessed roster IDs.
    mapping_path=ROOT/'docs/confirmed_character_mapping.json'
    if mapping_path.exists():
        mapping=json.loads(mapping_path.read_text(encoding='utf-8'))
        for fid,style in [('f02_sunstruck',1),('f03_heavy_duty',2)]:
            folder=mapping.get(fid)
            if folder:
                source_id=next((n for n,c in SOURCES.items() if c['folder']==folder),None)
                if source_id is None:raise ValueError('Confirmed source folder unavailable: '+folder)
                cfg=dict(SOURCES[source_id]);cfg.update(style=style,mapping='user-confirmed source folder: '+folder)
                SOURCES[fid]=cfg
                src_cache=ROOT/'source_art/characters'/source_id/'prepared.blend'
                dst_cache=ROOT/'source_art/characters'/fid/'prepared.blend'
                if src_cache.exists() and not dst_cache.exists():
                    dst_cache.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src_cache,dst_cache)
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['f01_clutch']
    for fid in args:
        if not fid.startswith('--'):run(fid)
