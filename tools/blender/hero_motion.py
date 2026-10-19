"""CC0 source sampling and anatomical retarget helpers for the curated rig.

Source motion remains separate from authored actions. Sampling is deterministic
at 60 Hz; runtime roots never receive imported translation or source controls.
"""
import bpy, json, math
from pathlib import Path
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
MAP = {'pelvis':'pelvis','spine':'spine_02','chest':'spine_03',
       'neck':'neck_01','head':'Head'}
for side, suffix in [('L','l'),('R','r')]:
    MAP.update({f'clavicle.{side}':f'clavicle_{suffix}',
                f'upper_arm.{side}':f'upperarm_{suffix}',
                f'forearm.{side}':f'lowerarm_{suffix}',
                f'hand.{side}':f'hand_{suffix}',
                f'thigh.{side}':f'thigh_{suffix}',
                f'shin.{side}':f'calf_{suffix}',
                f'foot.{side}':f'foot_{suffix}'})


def sample_source():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps=60
    source=next((ROOT/'source_art/motion/quaternius/standard').rglob('UAL1_Standard.glb'))
    bpy.ops.import_scene.gltf(filepath=str(source))
    rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    result={}
    for name in ['Idle_Loop','Walk_Loop','Walk_Formal_Loop','Jog_Fwd_Loop',
                 'Sprint_Loop','Punch_Jab','Punch_Cross','Hit_Chest','Hit_Head','Jump_Land','Jump_Start','Jump_Loop']:
        action=bpy.data.actions[name]; rig.animation_data.action=action
        start,end=action.frame_range;count=round(end-start)
        frames=[]
        for i in range(count+1):
            t=start+i/count*(end-start)
            bpy.context.scene.frame_set(int(t),subframe=t%1)
            frame={}
            for target,src in MAP.items():
                bone=rig.pose.bones[src];rest=rig.data.bones[src]
                frame[target]={'direction':list((bone.tail-bone.head).normalized()),
                               'delta':list(bone.matrix.to_quaternion() @ rest.matrix_local.to_quaternion().inverted()),
                               'head':list(bone.head)}
            frame['pelvis_offset']=list(rig.pose.bones['pelvis'].head-rig.data.bones['pelvis'].head_local)
            frames.append(frame)
        contact=max(range(len(frames)),key=lambda i:max(-frames[i]['hand.L']['head'][1],-frames[i]['hand.R']['head'][1]))
        result[name]={'seconds':(end-start)/60,'frames':frames,'contact_phase':contact/count}
    dest=ROOT/'source_art/motion/retarget_reference.json'
    dest.write_text(json.dumps({'license':'CC0','source':str(source.relative_to(ROOT)),'fps':60,'clips':result}))
    print('MOTION_SOURCE_SAMPLED',list(result),flush=True)
    return result


def source_frame(motion,phase):
    frames=motion['frames'];t=max(0,min(1,phase))*(len(frames)-1);i=int(t);j=min(len(frames)-1,i+1);alpha=t-i
    out={}
    for name in MAP:
        a,b=frames[i][name],frames[j][name]
        out[name]={'direction':Vector(a['direction']).lerp(Vector(b['direction']),alpha).normalized(),
                   'delta':Quaternion(a['delta']).slerp(Quaternion(b['delta']),alpha)}
    out['pelvis_offset']=Vector(frames[i]['pelvis_offset']).lerp(Vector(frames[j]['pelvis_offset']),alpha)
    return out


def retarget_world(rig,frame):
    """Solve anatomical directions, avoiding T-pose/A-pose double offsets."""
    world={'root':Quaternion()}
    for name in MAP:
        if name.startswith(('upper_arm','forearm','hand','thigh','shin')):
            rest=rig.data.bones[name]
            world[name]=(rest.tail_local-rest.head_local).normalized().rotation_difference(frame[name]['direction'])
        else:
            world[name]=frame[name]['delta'].copy()
    return world


def apply_world(rig,world,frame_no,weight=1.0,names=None):
    names=set(names) if names else set(world)
    for name in names:
        b=rig.pose.bones[name];rest=b.bone.matrix_local.to_quaternion()
        parent=world.get(b.parent.name,Quaternion()) if b.parent else Quaternion()
        rotation=rest.inverted() @ parent.inverted() @ world[name] @ rest
        b.rotation_mode='QUATERNION';b.rotation_quaternion=b.rotation_quaternion.slerp(rotation,weight)
        b.keyframe_insert('rotation_quaternion',frame=frame_no,group=name)


def curves(action):
    return [f for layer in action.layers for strip in layer.strips for bag in strip.channelbags for f in bag.fcurves]


def linear_keys(action):
    for f in curves(action):
        for key in f.keyframe_points:key.interpolation='LINEAR'


def source_retarget(rig,fid,motions):
    """Retarget locomotion upper body + combat approach; keep planted legs/contact.

    Measured legacy foot trajectories supply contact-constrained lower-body polish.
    Quaternius provides torso counterrotation and natural arm acceleration. Combat
    contact is still the original explicitly authored pose on the active tick.
    """
    records=[]
    upper=['pelvis','spine','chest','neck','head','clavicle.L','clavicle.R',
           'upper_arm.L','upper_arm.R','forearm.L','forearm.R','hand.L','hand.R']
    for clip,src in [('walk','Walk_Formal_Loop' if fid in ['f05_fine_print','f08_midnight_gentleman'] else 'Walk_Loop'),
                     ('run','Jog_Fwd_Loop'),('idle','Idle_Loop')]:
        action=bpy.data.actions[clip];rig.animation_data.action=action
        start,end=map(round,action.frame_range);original=[]
        for f in range(start,end+1):
            bpy.context.scene.frame_set(f)
            original.append({n:rig.pose.bones[n].rotation_quaternion.copy() for n in upper})
        for f in range(start,end+1):
            bpy.context.scene.frame_set(f)
            for n in upper:rig.pose.bones[n].rotation_quaternion=original[f-start][n]
            phase=(f-start)/(end-start);world=retarget_world(rig,source_frame(motions[src],phase))
            weight=.20 if clip=='idle' else .85
            # Pelvis translation and rotations remain the planted-trajectory basis;
            # chest/shoulders gain source counter-rotation and arm follow-through.
            apply_world(rig,world,f,weight,[n for n in upper if n!='pelvis'])
        action['source_motion']='Quaternius / '+src; action['retarget_policy']='anatomical world direction; source upper-body over contact-constrained gait'
        linear_keys(action);records.append({'clip':clip,'source':src,'source_weight':weight,'contact_policy':'authored planted legs retained'})
    # Natural chest compression/head lag on reactions; preserve silhouette and
    # reaction endpoint so gameplay animation selection and duration stay stable.
    for clip,src in [('hit_light','Hit_Chest'),('hit_heavy','Hit_Head')]:
        action=bpy.data.actions[clip];rig.animation_data.action=action
        start,end=map(round,action.frame_range)
        original=[]
        for f in range(start,end+1):
            bpy.context.scene.frame_set(f);original.append({n:rig.pose.bones[n].rotation_quaternion.copy() for n in upper})
        for f in range(start,end+1):
            bpy.context.scene.frame_set(f)
            for n in upper:rig.pose.bones[n].rotation_quaternion=original[f-start][n]
            phase=(f-start)/(end-start);world=retarget_world(rig,source_frame(motions[src],phase))
            apply_world(rig,world,f,.32*math.sin(math.pi*phase),['spine','chest','neck','head'])
        linear_keys(action);records.append({'clip':clip,'source':src,'source_weight_max':.32})
    for clip,src in [('land_soft','Jump_Land'),('land_hard','Jump_Land'),('jump_anticipation','Jump_Start'),('jump_rise','Jump_Loop')]:
        action=bpy.data.actions[clip];rig.animation_data.action=action
        start,end=map(round,action.frame_range);original=[]
        names=[n for n in MAP if n!='pelvis']
        for f in range(start,end+1):
            bpy.context.scene.frame_set(f);original.append({n:rig.pose.bones[n].rotation_quaternion.copy() for n in names})
        for f in range(start,end+1):
            bpy.context.scene.frame_set(f)
            for n in names:rig.pose.bones[n].rotation_quaternion=original[f-start][n]
            phase=(f-start)/(end-start)
            # Landing compression happens early; source settle uses the longer
            # tail. Endpoints match the authored state to avoid transition snaps.
            source_phase=min(1,phase*1.8) if clip.startswith('land') else phase
            world=retarget_world(rig,source_frame(motions[src],source_phase))
            weight=(.48 if clip.startswith('land') else .40)*math.sin(math.pi*phase)**.5
            apply_world(rig,world,f,weight,names)
        linear_keys(action);records.append({'clip':clip,'source':src,'source_weight_max':.48,'policy':'whole-body motion with original endpoints and landing timing'})
    return records


def polish_authored(rig,fid,timings):
    """Break down combat acceleration and animate body inertia between states."""
    import characters_pipeline as base
    style={'f01_clutch':0,'f02_sunstruck':1,'f03_heavy_duty':2,'f04_deadfall':3,'f05_fine_print':4,'f06_rugged_explorer':3,'f07_urban_sentinel':0,'f08_midnight_gentleman':4}[fid]
    g=base.guard(style)
    # These remain in-place; physics acceleration and authored travel still own
    # world movement. The loaded run cycle provides exact transition endpoints.
    specifications={
        'move_start':[(0,g),(.18,base.pose(lean=-3,drop=.055,ll=(12,27,0),rl=(8,20,0),la=(24,14,125),ra=(35,12,140))),
                      (.46,base.pose(lean=16,drop=.105,ll=(28,55,0),rl=(-12,15,0),la=(-15,12,60),ra=(48,14,132))),
                      (1,base.pose(lean=12,drop=.12,ll=(38,58,0),rl=(-23,8,0),la=(-27,12,51),ra=(43,14,121)))],
        'move_stop':[(0,base.pose(lean=10,drop=.08,ll=(30,34,0),rl=(-20,12,0))),
                     (.25,base.pose(lean=-12,drop=.14,ll=(27,65,0),rl=(-12,22,0),la=(43,28,105),ra=(15,30,92))),
                     (.57,base.pose(lean=-3,drop=.07,ll=(15,32,0),rl=(7,25,0),la=(37,17,130),ra=(23,20,140))),
                     (1,g)],
        'turnaround':[(0,g),(.2,base.pose(lean=6,twist=-18,head=-32,drop=.065,ll=(16,33,0),rl=(4,16,0))),
                      (.48,base.pose(lean=9,twist=42,head=48,side=-5,drop=.105,ll=(22,48,0),rl=(12,38,0),la=(28,30,110),ra=(15,13,132))),
                      (.76,base.pose(lean=7,twist=12,head=8,drop=.05,ll=(8,20,0),rl=(12,22,0))),
                      (1,g)]}
    for clip,points in specifications.items():
        action=bpy.data.actions[clip];seconds=(action.frame_range[1]-action.frame_range[0])/60
        bpy.data.actions.remove(action);base.add_action(rig,clip,seconds,points,False,'locomotion','custom weight transfer and torso/head settle')
    records=[]
    for clip,timing in timings.items():
        if clip not in bpy.data.actions or not clip.startswith(('jab','tilt_','heavy_','air_','dash')):continue
        if len(timing.get('active_windows',[]))>1:continue
        action=bpy.data.actions[clip];rig.animation_data.action=action
        start=1;s=timing['startup']+1;e=timing['active_windows'][0][1]+1;end=timing['total']+1
        wind=max(1,round(1+(s-1)*.55));names=['pelvis','spine','chest','neck','head','clavicle.L','clavicle.R','upper_arm.L','upper_arm.R','forearm.L','forearm.R','hand.L','hand.R']
        sampled={}
        for f in [wind,s,e,end,max(e+1,round(e+(end-e)*.24)),max(e+1,round(e+(end-e)*.56))]:
            bpy.context.scene.frame_set(f);sampled[f]={n:(rig.pose.bones[n].rotation_quaternion.copy(),rig.pose.bones[n].location.copy()) for n in names}
        # Dense approach breakdowns make the hand accelerate into the unchanged
        # active-frame contact. Heavy attacks retain their long readable windup.
        for f,alpha in [(max(wind,s-3),.09),(max(wind+1,s-2),.28),(max(wind+2,s-1),.65)]:
            if f>=s:continue
            for n in names:
                b=rig.pose.bones[n];b.rotation_quaternion=sampled[wind][n][0].slerp(sampled[s][n][0],alpha)
                b.keyframe_insert('rotation_quaternion',frame=f,group=n)
        # Reinsert exact contact after adding neighbouring keys, and hold body
        # momentum slightly longer than the retracting striking arm.
        for f in [s,e]:
            for n in names:
                b=rig.pose.bones[n];b.rotation_quaternion=sampled[f][n][0];b.keyframe_insert('rotation_quaternion',frame=f,group=n)
        settle=max(e+1,round(e+(end-e)*.56));early=max(e+1,round(e+(end-e)*.24))
        for n in ['spine','chest','neck','head']:
            b=rig.pose.bones[n];b.rotation_quaternion=sampled[early][n][0].slerp(sampled[settle][n][0],.42 if n in ['neck','head'] else .7)
            b.keyframe_insert('rotation_quaternion',frame=settle,group=n)
        records.append({'clip':clip,'contact_tick_preserved':s-1,'active_end_tick_preserved':e-1,'breakdown':'3-frame accelerating strike; delayed torso/head recovery'})
    guard_breath(rig)
    return records


def guard_breath(rig):
    """Chest expansion keeps the guard alive without lifting planted feet.

    The baseline loop used only pelvis translation. Ground-contact cleanup
    correctly canceled that translation; breathing must live above the hips.
    """
    action=bpy.data.actions['shield_hold'];rig.animation_data.action=action
    start,end=map(round,action.frame_range);bpy.context.scene.frame_set(start)
    initial={name:rig.pose.bones[name].rotation_quaternion.copy() for name in ['spine','chest']}
    for frame in range(start,end+1):
        phase=(frame-start)/(end-start);breath=(1-math.cos(phase*math.tau))*.5
        for name,amount in [('spine',.3),('chest',.5)]:
            bone=rig.pose.bones[name];rest=bone.bone.matrix_local.to_quaternion()
            delta=rest.inverted() @ Quaternion((1,0,0),math.radians(amount*breath)) @ rest
            bone.rotation_quaternion=initial[name] @ delta
            bone.keyframe_insert('rotation_quaternion',frame=frame,group=name)
    action['guard_breath']='0.8 degree chest/spine loop; planted lower body and duration preserved'


def grounded_cleanup(rig,mesh):
    """Correct measured support-sole drift in grounded animations, never root."""
    reports=[]
    exclude=('air_','jump','double','fall','helpless','launch','tumble','victim','ledge','throw','roll','special','ultimate','qa_','knockdown','final_ko','respawn')
    for action in bpy.data.actions:
        if action.name.startswith(exclude):continue
        rig.animation_data.action=action;start,end=map(round,action.frame_range);values=[];poses=[]
        for f in range(start,end+1):
            bpy.context.scene.frame_set(f);feet=[]
            for side in ['L','R']:
                b=rig.pose.bones['foot.'+side];rest=b.bone
                matrix=b.matrix @ rest.matrix_local.inverted()
                anchors=[Vector((rest.head_local.x,.035,.012)),Vector((rest.head_local.x,-.13,.012))]
                feet.extend([(matrix@co).z for co in anchors])
            offset=max(-.12,min(.12,.012-min(feet)))
            b=rig.pose.bones['pelvis'];poses.append(b.location+b.bone.matrix_local.to_quaternion().inverted() @ Vector((0,0,offset)));values.append(offset)
        for f,co in zip(range(start,end+1),poses):
            b=rig.pose.bones['pelvis'];b.location=co;b.keyframe_insert('location',frame=f,group='pelvis')
        reports.append({'clip':action.name,'maximum_sole_correction_m':max(map(abs,values))})
    return reports
