"""Build the eight curated hero scenes from preserved prepared assets.

Explicit --rebuild-curated is required to replace a curated source. The ordinary
characters_pipeline route exports that source without regenerating its actions.
Immutable originals and prepared.blend are never saved by this stage.
"""
import bpy, bmesh, math, json, sys, hashlib, shutil
from datetime import datetime, timezone
from pathlib import Path
from mathutils import Vector, Quaternion, Matrix
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender'))
import characters_pipeline as base
from hero_motion import sample_source, source_retarget, polish_authored, grounded_cleanup, curves, linear_keys
from hero_export import export_curated

ROSTER=['f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall','f05_fine_print','f06_rugged_explorer','f07_urban_sentinel','f08_midnight_gentleman']
COLORS=[(.015,.55,.82,1),(.94,.45,.045,1),(.48,.23,.075,1),(.40,.085,.045,1),(.045,.28,.24,1),(.72,.36,.085,1),(.63,.025,.025,1),(.53,.35,.10,1)]
STYLE=[0,1,2,3,4,3,0,4]


def hero_proportions(rig,mesh,fid):
    strength=[.10,.08,.17,.13,.075,.11,.14,.08][ROSTER.index(fid)]
    def shape(co):
        p=co.copy();t=max(0,min(1,(p.z-1.0)/.33))*max(0,min(1,(1.60-p.z)/.13))
        p.x*=1+strength*t
        if abs(co.x)<.24:p.y*=1+strength*.50*t
        return p
    for v in mesh.data.vertices:v.co=shape(v.co)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
    for b in rig.data.edit_bones:b.head=shape(b.head);b.tail=shape(b.tail)
    bpy.ops.object.mode_set(mode='OBJECT');mesh.data.update()
    rig['hero_proportions']='Athletic shoulder/chest silhouette; source face, height and UV identity preserved'


def material(name,color,metal=0,rough=.45):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=color
    p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=color
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    return m


def bind(obj,rig,bone):
    obj['character_asset']=True;obj.parent=rig
    vg=obj.vertex_groups.new(name=bone);vg.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    mod=obj.modifiers.new('Hero articulated binding','ARMATURE');mod.object=rig
    for poly in obj.data.polygons:poly.use_smooth=True
    return obj


def capsule_curve(name,points,radius,mat,rig,bone):
    data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=radius;data.bevel_resolution=2;data.resolution_u=12
    poly=data.splines.new('POLY');poly.points.add(len(points)-1)
    for p,co in zip(poly.points,points):p.co=(*co,1)
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj;bpy.ops.object.convert(target='MESH')
    return bind(bpy.context.object,rig,bone)


def sphere(name,loc,scale,mat,rig,bone):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=loc)
    obj=bpy.context.object;obj.name=name;obj.scale=scale
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);obj.data.materials.append(mat)
    return bind(obj,rig,bone)


def shell_patch(mesh,rig,name,selector,mat,bone=None,inset=.006):
    faces=[p for p in mesh.data.polygons if selector(p.center)]
    indices=sorted({i for p in faces for i in p.vertices});lookup={v:i for i,v in enumerate(indices)}
    if not faces:return None
    verts=[mesh.data.vertices[i].co+mesh.data.vertices[i].normal*inset for i in indices]
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],[[lookup[i] for i in p.vertices] for p in faces]);data.update()
    # A face-centre selection on the scanned triangulation produces saw-tooth
    # edges. Relax only boundary loops before thickening the new fitted shell.
    bm=bmesh.new();bm.from_mesh(data)
    boundary=[v for v in bm.verts if any(e.is_boundary for e in v.link_edges)]
    for _ in range(35):
        changed={v:sum((e.other_vert(v).co for e in v.link_edges if e.is_boundary),Vector())/max(1,sum(e.is_boundary for e in v.link_edges)) for v in boundary}
        for v,co in changed.items():v.co=v.co.lerp(co,.45)
    if 'shoulder' in name:
        for _ in range(18):
            changed={v:sum((e.other_vert(v).co for e in v.link_edges),Vector())/len(v.link_edges) for v in bm.verts if v.link_edges}
            for v,co in changed.items():v.co=v.co.lerp(co,.35)
    bm.to_mesh(data);bm.free();data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(mat)
    obj.parent=rig;obj['character_asset']=True
    if bone:
        obj.vertex_groups.new(name=bone).add(list(range(len(verts))),1,'REPLACE')
    else:
        groupmap={g.index:g.name for g in mesh.vertex_groups};groups={n:obj.vertex_groups.new(name=n) for n in groupmap.values()}
        for j,i in enumerate(indices):
            for g in mesh.data.vertices[i].groups:groups[groupmap[g.group]].add([j],g.weight,'REPLACE')
    mod=obj.modifiers.new('Hero articulated binding','ARMATURE');mod.object=rig
    for p in data.polygons:p.use_smooth=True
    solid=obj.modifiers.new('Tailored fabric edge','SOLIDIFY');solid.thickness=.003
    bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.modifier_apply(modifier=solid.name)
    return obj


def fitted_band(mesh,rig,name,bone,t0,t1,mat,radius=.006):
    """Clean quad cuff follows rays onto the real rest surface."""
    b=rig.data.bones[bone];axis=(b.tail_local-b.head_local).normalized()
    u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u).normalized()
    surface=BVHTree.FromPolygons([v.co for v in mesh.data.vertices],[list(p.vertices) for p in mesh.data.polygons])
    verts=[];faces=[];segments=32;rows=5
    for j in range(rows):
        t=t0+(t1-t0)*j/(rows-1);center=b.head_local.lerp(b.tail_local,t)
        for k in range(segments):
            n=u*math.cos(k/segments*math.tau)+v*math.sin(k/segments*math.tau)
            co,normal,polygon,distance=surface.ray_cast(center+n*.16,-n,.30)
            limit=.092 if bone.startswith('forearm') else .12
            if co is None or (co-center).length>limit or (co-center).dot(n)<.012:co=center+n*(.043 if bone.startswith('forearm') else .062)
            verts.append(co+n*radius)
        ringpoints=verts[-segments:]
        radii=[(p-center).length for p in ringpoints]
        for _ in range(4):radii=[.5*radii[k]+.25*radii[(k-1)%segments]+.25*radii[(k+1)%segments] for k in range(segments)]
        verts[-segments:]=[center+(p-center).normalized()*r for p,r in zip(ringpoints,radii)]
    for j in range(rows-1):
        for k in range(segments):a=j*segments+k;bn=j*segments+(k+1)%segments;faces.append((a,bn,bn+segments,a+segments))
    # Finished cuffs are capped underneath their glove/cloth junction. Open
    # cylinder rims created an artificial black cavity at bent wrists.
    faces.append(tuple(reversed(range(segments))))
    faces.append(tuple((rows-1)*segments+k for k in range(segments)))
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(mat)
    bind(obj,rig,bone)
    # Finished rolled edges, as separate same-bone loops, hide no geometry errors.
    for j in [0,rows-1]:capsule_curve(name+' rolled edge '+str(j),[verts[j*segments+k] for k in range(segments)]+[verts[j*segments]],.003,mat,rig,bone)
    return obj


def rebuild_gloves(rig,mesh,fid):
    """Replace damaged scanned digit topology with continuous weighted gloves."""
    idx=ROSTER.index(fid);leather=material(fid+' combat glove',(.024,.034,.043,1),.08,.54)
    inset=material(fid+' knuckle armour',COLORS[idx],.72 if idx==2 else .32,.30)
    groupmap={g.index:g.name for g in mesh.vertex_groups}
    # Cut original hand faces at the wrist transition. The purpose-built cuff
    # overlaps this hidden seam; immutable originals retain their scanned hands.
    remove=[]
    for p in mesh.data.polygons:
        amount=0
        for vi in p.vertices:
            amount+=sum(g.weight for g in mesh.data.vertices[vi].groups if groupmap[g.group].startswith(('hand.','index_','middle_','ring_','pinky_','thumb_')))
        if amount/len(p.vertices)>.52:remove.append(p.index)
    bm=bmesh.new();bm.from_mesh(mesh.data);bm.faces.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.faces[i] for i in remove],context='FACES');bm.to_mesh(mesh.data);bm.free();mesh.data.update()
    for side,sgn in [('L',1),('R',-1)]:
        roots=[rig.data.bones[n+'_01.'+side].head_local.copy() for n in ['index','middle','ring','pinky']]
        center=sum(roots,Vector())/4;wrist=rig.data.bones['hand.'+side].head_local
        palmcenter=center.lerp(wrist,.45)
        sphere(fid+' '+side+' tailored glove palm',palmcenter,(.026,.050,max(.045,(wrist.z-center.z)*.62)),leather,rig,'hand.'+side)
        sphere(fid+' '+side+' glove wrist joint',wrist+Vector((0,0,-.012)),(.032,.039,.040),leather,rig,'hand.'+side)
        # Continuous ring topology across all three phalanges; the boundary rings
        # share weights with the preceding segment for smooth bend volume.
        for digit in ['index','middle','ring','pinky','thumb']:
            chain=[rig.data.bones[f'{digit}_{seg:02d}.{side}'] for seg in range(1,4)]
            verts=[];faces=[];weights=[];rad=.009 if digit=='pinky' else .011
            samples=13;ring=10
            for j in range(samples):
                u=j/(samples-1)*3;seg=min(2,int(u));phase=u-seg if u<3 else 1
                bone=chain[seg];co=bone.head_local.lerp(bone.tail_local,phase);axis=(bone.tail_local-bone.head_local).normalized()
                a=axis.cross(Vector((0,1,0))).normalized();b=axis.cross(a).normalized();r=rad*(1-.22*j/(samples-1))
                if j==samples-1:r*=.25
                for k in range(ring):verts.append(co+(a*math.cos(k/ring*math.tau)+b*math.sin(k/ring*math.tau))*r)
                blend=min(1,phase/.30) if seg else 1
                weights.extend([{chain[seg].name:blend,(chain[seg-1].name if seg else 'hand.'+side):1-blend} for _ in range(ring)])
            for j in range(samples-1):
                for k in range(ring):faces.append((j*ring+k,j*ring+(k+1)%ring,(j+1)*ring+(k+1)%ring,(j+1)*ring+k))
            faces.extend([tuple(reversed(range(ring))),tuple((samples-1)*ring+k for k in range(ring))])
            data=bpy.data.meshes.new(fid+' '+digit+'.'+side);data.from_pydata(verts,[],faces);data.update();obj=bpy.data.objects.new(data.name,data);bpy.context.collection.objects.link(obj);data.materials.append(leather);obj.parent=rig;obj['character_asset']=True
            groups={n:obj.vertex_groups.new(name=n) for n in ['hand.'+side]+[b.name for b in chain]}
            for vi,ws in enumerate(weights):
                for name,weight in ws.items():
                    if weight:groups[name].add([vi],weight,'REPLACE')
            mod=obj.modifiers.new('Articulated glove skin','ARMATURE');mod.object=rig
            for p in data.polygons:p.use_smooth=True
            if digit!='thumb':
                knuckle=chain[0].head_local+Vector((sgn*.012,0,-.008));sphere(fid+' '+digit+' knuckle.'+side,knuckle,(.006,.009,.011),inset,rig,chain[0].name)
        # Wrist seam uses an independent smooth cuff, close to the underlying
        # forearm end, so the replacement is clean through wrist articulation.
        fitted_band(mesh,rig,fid+' '+side+' wrist cuff','forearm.'+side,.65,1.09,leather,.008)


def add_detail_rig(rig,mesh):
    old_groups={g.index:g.name for g in mesh.vertex_groups};hand_points={}
    for side in ['L','R']:
        hand_points[side]=[v.co.copy() for v in mesh.data.vertices if any(old_groups.get(g.group)=='hand.'+side and g.weight>.45 for g in v.groups)]
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
    bones=rig.data.edit_bones;detail=[];fingers={}
    def new(name,head,tail,parent,deform=True):
        b=bones.new(name);b.head=head;b.tail=tail;b.parent=bones[parent] if parent else None;b.use_deform=deform;return b
    for side,sign in [('L',1),('R',-1)]:
        points=hand_points[side];lo=Vector([min(p[k] for p in points) for k in range(3)]);hi=Vector([max(p[k] for p in points) for k in range(3)])
        center=sum(points,Vector())/len(points);length=hi.z-lo.z
        # Bone landmarks use each actual scanned hand's extent, not one universal
        # wrist position. Four digit rays lie in the palm plane; thumb opposes.
        for i,digit in enumerate(['index','middle','ring','pinky']):
            y=lo.y+(hi.y-lo.y)*(.25+i*.19);x=center.x
            rootz=lo.z+length*(.46 if i<3 else .42)
            tipz=lo.z+length*([.075,.025,.075,.19][i]);previous='hand.'+side
            for segment in range(3):
                a=Vector((x,y,rootz+(tipz-rootz)*segment/3));b=Vector((x,y,rootz+(tipz-rootz)*(segment+1)/3))
                name=f'{digit}_{segment+1:02d}.{side}';new(name,a,b,previous);previous=name;detail.append(name);fingers[name]=(a.copy(),b.copy())
        a=Vector((center.x,lo.y+(hi.y-lo.y)*.23,lo.z+length*.70));tip=Vector((center.x-sign*.012,lo.y-.005,lo.z+length*.38))
        for segment in range(3):
            aa=a.lerp(tip,segment/3);bb=a.lerp(tip,(segment+1)/3);name=f'thumb_{segment+1:02d}.{side}'
            new(name,aa,bb,'hand.'+side if segment==0 else f'thumb_{segment:02d}.{side}');detail.append(name);fingers[name]=(aa.copy(),bb.copy())
        foot=bones['foot.'+side];name='toe.'+side
        new(name,(foot.head.x,-.115,.055),(foot.head.x,-.21,.048),'foot.'+side);detail.append(name)
        for limb in ['upper_arm','forearm']:
            p=bones[limb+'.'+side];name=limb+'_twist.'+side
            new(name,p.head.lerp(p.tail,.42),p.tail,limb+'.'+side);detail.append(name)
        for limb,end,pole in [('hand','forearm',Vector((sign*.28,-.65,1.05))),('foot','shin',Vector((sign*.16,-.70,.48)))]:
            deform=bones[limb+'.'+side]
            new('CTRL_'+limb+'.'+side,deform.head,deform.head+Vector((0,0,.12)),None,False)
            new('CTRL_'+limb+'_pole.'+side,pole,pole+Vector((0,0,.12)),None,False)
    for name in ['pelvis','spine','chest']:
        b=bones[name];new('CTRL_'+name,b.head,b.tail,None,False)
    # Small face deformers change expression without altering the face's identity.
    head=bones['head'];h=mesh.dimensions.z
    for name,co in [('brow.L',(.037,-.092,h-.142)),('brow.R',(-.037,-.092,h-.142)),('mouth.L',(.027,-.106,h-.235)),('mouth.R',(-.027,-.106,h-.235))]:
        co=Vector(co);new(name,co,co+Vector((0,0,.018)),'head');detail.append(name)
    bpy.ops.object.mode_set(mode='OBJECT')
    for name in detail:
        if not mesh.vertex_groups.get(name):mesh.vertex_groups.new(name=name)
    def point_dist(p,a,b):
        t=max(0,min(1,(p-a).dot(b-a)/(b-a).length_squared));return (p-a.lerp(b,t)).length
    weighted={n:0 for n in detail}
    for v in mesh.data.vertices:
        weights={old_groups[g.group]:g.weight for g in v.groups if g.group in old_groups};p=v.co
        for side,sign in [('L',1),('R',-1)]:
            hand='hand.'+side;amount=weights.get(hand,0)
            if amount>.12:
                options=[(point_dist(p,a,b),n) for n,(a,b) in fingers.items() if n.endswith('.'+side)]
                distance,name=min(options)
                a,b=fingers[name]
                # Palm remains on semantic hand; digit weight ramps across the
                # knuckle to avoid a disconnected or crushed palm.
                digit=name.split('_')[0];knuckle=fingers[digit+'_01.'+side][0]
                blend=max(0,min(1,(knuckle.z-p.z+.008)/.020))
                if digit=='thumb':blend=max(0,min(1,(knuckle.y-p.y+.003)/.018))
                blend*=max(0,min(1,(.045-distance)/.012))
                moved=amount*blend;weights[hand]-=moved;weights[name]=weights.get(name,0)+moved
            foot='foot.'+side
            if foot in weights:
                factor=max(0,min(1,(-p.y-.10)/.05));moved=weights[foot]*factor;weights[foot]-=moved;weights['toe.'+side]=moved
            for limb in ['upper_arm','forearm']:
                name=limb+'.'+side
                if name in weights:
                    bone=rig.data.bones[name];u=max(0,min(1,(p-bone.head_local).dot(bone.tail_local-bone.head_local)/(bone.length**2)))
                    moved=weights[name]*max(0,min(.7,(u-.35)*1.1));weights[name]-=moved;weights[limb+'_twist.'+side]=moved
        if weights.get('head',0)>.7:
            for n in ['brow.L','brow.R','mouth.L','mouth.R']:
                d=(p-rig.data.bones[n].head_local).length;f=max(0,1-d/.028)*.8
                if f>0 and p.y<-.06:moved=weights['head']*f;weights['head']-=moved;weights[n]=moved
        weights=sorted([(n,w) for n,w in weights.items() if w>.0001],key=lambda v:v[1],reverse=True)[:4];total=sum(w for n,w in weights)
        for g in list(v.groups):mesh.vertex_groups[g.group].remove([v.index])
        for name,w in weights:
            mesh.vertex_groups[name].add([v.index],w/total,'REPLACE')
            if name in weighted:weighted[name]+=1
    rig['ik_hands']=0.0;rig['ik_feet']=0.0;rig['body_controls']=0.0
    for prop in ['ik_hands','ik_feet','body_controls']:rig.id_properties_ui(prop).update(min=0,max=1)
    for side in ['L','R']:
        for limb,end,property_name in [('hand','forearm','ik_hands'),('foot','shin','ik_feet')]:
            c=rig.pose.bones[end+'.'+side].constraints.new('IK');c.name='Animator '+limb+' IK';c.target=rig;c.subtarget='CTRL_'+limb+'.'+side;c.pole_target=rig;c.pole_subtarget='CTRL_'+limb+'_pole.'+side;c.chain_count=2;c.influence=0
            drv=c.driver_add('influence').driver;var=drv.variables.new();var.name='weight';var.targets[0].id=rig;var.targets[0].data_path='["'+property_name+'"]';drv.expression='weight'
    for name in ['pelvis','spine','chest']:
        c=rig.pose.bones[name].constraints.new('COPY_TRANSFORMS');c.name='Animator body control';c.target=rig;c.subtarget='CTRL_'+name;c.influence=0
        drv=c.driver_add('influence').driver;var=drv.variables.new();var.name='weight';var.targets[0].id=rig;var.targets[0].data_path='["body_controls"]';drv.expression='weight'
    collection=rig.data.collections.new('Animator controls');deform=rig.data.collections.new('Runtime deformation')
    for b in rig.data.bones:
        (collection if b.name.startswith('CTRL_') else deform).assign(b)
        if b.name.startswith('CTRL_'):b.color.palette='THEME04'
    return weighted


def separate_heavy_armor(rig,mesh):
    """Extract actual torso/shoulder armor into rigid plates, retain scanned UVs."""
    groups={'Breastplate':('chest',lambda p:1.23<p.z<1.47 and abs(p.x)<.22),
            'Abdominal plate':('spine',lambda p:1.08<p.z<1.23 and abs(p.x)<.20)}
    # Torso cloth cape is mostly rear/top; metal plate selection is limited to
    # front/side torso and the source bronze shoulder, leaving cloth free.
    bm=bmesh.new();bm.from_mesh(mesh.data)
    for z in [1.08,1.23,1.47]:
        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,z),plane_no=(0,0,1),clear_inner=False,clear_outer=False)
    bm.to_mesh(mesh.data);bm.free();mesh.data.update()
    all_parts=[]
    for label,(bone,test) in groups.items():
        bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='DESELECT');bpy.ops.object.mode_set(mode='OBJECT')
        count=0
        for p in mesh.data.polygons:
            c=p.center
            p.select=test(c) and (c.y<.01 if 'plate' in label.lower() else c.y<.04)
            count+=p.select
        if count:
            before=set(bpy.data.objects);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.separate(type='SELECTED');bpy.ops.object.mode_set(mode='OBJECT')
            obj=next(o for o in bpy.data.objects if o not in before);obj.name='Heavy '+label
            # Extend the lower rim behind the next plate. Separate hard plates
            # can articulate without opening black cracks at the torso seams.
            bm=bmesh.new();bm.from_mesh(obj.data)
            edgez=1.23 if label=='Breastplate' else 1.08
            edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-edgez)<.001 for v in e.verts)]
            if edges:
                geom=bmesh.ops.extrude_edge_only(bm,edges=edges)['geom']
                for v in geom:
                    if isinstance(v,bmesh.types.BMVert):v.co.z-=.035;v.co.y+=.004
            bm.to_mesh(obj.data);bm.free()
            obj.vertex_groups.clear();obj.vertex_groups.new(name=bone).add(list(range(len(obj.data.vertices))),1,'REPLACE');obj['character_asset']=True;obj['rigid_plate']=True;all_parts.append(obj.name)
    return all_parts


def costume(rig,mesh,fid):
    idx=ROSTER.index(fid);h=json.loads(rig['prepared_stats'])['height']/1.84
    accent=material('Hero accent '+fid,COLORS[idx],.7 if idx in [1,2,5,7] else .22,.32)
    dark=material('Hero reinforced fabric '+fid,(.013,.020,.029,1),.05,.65)
    trim=material('Hero hardware '+fid,(.37,.42,.45,1),.8,.25)
    # Fitted elbow/forearm protection, shoe panels and waist construction add
    # readable material breaks without replacing recognisable supplied faces.
    surface=BVHTree.FromPolygons([v.co for v in mesh.data.vertices],[list(p.vertices) for p in mesh.data.polygons])
    for side,sgn in [('L',1),('R',-1)]:
        for limb in ['forearm','shin']:
            b=rig.data.bones[limb+'.'+side];c=b.head_local.lerp(b.tail_local,.66)
            if limb=='forearm':
                fitted_band(mesh,rig,f'{fid} {side} {limb} reinforcement',limb+'.'+side,.48,.88,dark if idx!=2 else accent,.004)
            else:
                shell_patch(mesh,rig,f'{fid} {side} fitted shin guard',lambda p,c=c:abs(p.z-c.z)<.09 and abs(p.x-c.x)<.056 and p.y<-.025,dark if idx!=2 else accent,bone=limb+'.'+side,inset=.005)
        # Small layered shoulder shell, following upper arm instead of flexing
        # across the chest. Heavy and Sentinel get the strongest silhouette.
        shoulder=rig.data.bones['upper_arm.'+side].head_local
        if idx in [0,2,3,5,6]:
            width=.072 if idx not in [2,6] else .09
            shell_patch(mesh,rig,f'{fid} {side} shoulder layer',lambda p,s=shoulder,w=width:abs(p.z-s.z)<.075 and abs(p.x-s.x)<w and p.y<.035,accent if idx==2 else dark,bone='upper_arm.'+side,inset=.009 if idx not in [2,6] else .015)
        # Stitch/trim arcs track the actual local surface, retaining fit.
        x=shoulder.x;z=shoulder.z
        pts=[]
        for k in range(9):
            px=x+sgn*(-.025+.055*k/8);pz=z+.012-.034*k/8
            co,_,_,_=surface.ray_cast(Vector((px,-.4,pz)),Vector((0,1,0)),.65)
            if co is not None:pts.append(co+Vector((0,-.013,0)))
        if len(pts)>1:capsule_curve(f'{fid} {side} shoulder piping',pts,.0045,accent,rig,'upper_arm.'+side)
    shell_patch(mesh,rig,f'{fid} waist band',lambda p:1.025*h<p.z<1.070*h and abs(p.x)<.22, dark,inset=.007)
    # Front seam accents conform to real mesh surface at each sample height.
    def front(x,z):
        nearby=[v.co.y for v in mesh.data.vertices if abs(v.co.x-x)<.025 and abs(v.co.z-z)<.018]
        return min(nearby)-.009 if nearby else -.15
    if idx==0:
        for sign in [-1,1]:
            shell_patch(mesh,rig,f'Clutch {sign} technical side panel',lambda p,s=sign:.135<p.x*s<.235 and 1.11*h<p.z<1.38*h and p.y<.04,dark,inset=.005)
    if idx==4:
        for sign in [-1,1]:
            shell_patch(mesh,rig,f'Fine Print {sign} tailored waistcoat',lambda p,s=sign:.026<p.x*s<.21 and 1.09*h<p.z<1.405*h and p.y<-.048,dark,inset=.006)
        for z in [1.16,1.22,1.28]:sphere('Fine Print pewter vest button '+str(z),(0,front(0,z*h)-.004,z*h),(.005,.003,.005),trim,rig,'spine' if z<1.25 else 'chest')
    if idx==6:
        shell_patch(mesh,rig,'Sentinel articulated chest guard',lambda p:abs(p.x)<.16 and 1.265*h<p.z<1.43*h and p.y<-.07,dark,bone='chest',inset=.014)
        for sign in [-1,1]:
            x=sign*.1;z=1.33*h
            capsule_curve('Sentinel red chest armour edge '+str(sign),[(x,front(x,z)-.012,z+.035),(x,front(x,z)-.013,z-.035)],.005,accent,rig,'chest')
    if idx in [0,4,6,7]:
        for sign in [-1,1]:
            points=[]
            for z,x in [(1.40,.10),(1.35,.12),(1.28,.14)]:
                z*=h;x*=sign;points.append((x,front(x,z),z))
            capsule_curve(f'{fid} tailored chest seam {sign}',points,.004 if idx in [4,7] else .006,accent,rig,'chest')
    if idx==1:
        # Sunstruck's solar clasps and cuff trim echo the tropical original.
        for sign in [-1,1]:sphere('Sunstruck solar collar clasp',(sign*.082,front(sign*.082,1.43*h),1.43*h),(.018,.008,.018),accent,rig,'chest')
        x=.105;z=1.32*h;y=front(x,z)
        sphere('Sunstruck solar crest',(x,y-.005,z),(.025,.008,.025),accent,rig,'chest')
        for k in range(8):
            a=k/8*math.tau
            capsule_curve('Sunstruck solar ray '+str(k),[(x+math.sin(a)*.025,y-.007,z+math.cos(a)*.025),(x+math.sin(a)*.037,y-.007,z+math.cos(a)*.037)],.003,accent,rig,'chest')
    if idx in [3,5]:
        for sign in [-1,1]:
            x=sign*.13;z=1.18*h
            shell_patch(mesh,rig,f'{fid} reinforced utility pocket {sign}',lambda p,x=x,z=z:abs(p.x-x)<.06 and abs(p.z-z)<.067 and p.y<-.04,dark,inset=.008)
        if idx==5:
            # Modelled climbing loop and locking carabiner at the hip.
            x=.185;y=front(x,1.025*h);z=1.015*h
            capsule_curve('Explorer locking carabiner',[(x,y,z+.06),(x+.035,y,z+.06),(x+.044,y,z-.045),(x+.002,y,z-.057),(x,y,z+.06)],.007,accent,rig,'pelvis')
            capsule_curve('Explorer carabiner gate',[(x+.034,y-.002,z+.043),(x+.039,y-.002,z-.025)],.004,trim,rig,'pelvis')
    if idx==7:
        x=.06;z=1.21*h;y=front(x,z)
        capsule_curve('Gentleman waist chain',[(x,y,z),(x+.04,y-.006,z-.018),(x+.08,y,z-.010),(x+.10,y,z+.014)],.0024,accent,rig,'spine')
    from hero_tailoring import correct_costume
    correct_costume(rig,mesh,fid)
    return [o.name for o in bpy.data.objects if o.get('character_asset') and o!=mesh]


def detail_actions(rig):
    report=[]
    for action in list(bpy.data.actions):
        if action.name.startswith('Portrait'):continue
        rig.animation_data.action=action;start,end=map(round,action.frame_range)
        # Key detail alongside each existing authored beat; locomotion is sampled
        # every frame so toe rollover tracks ground release without popping.
        frames=range(start,end+1) if action.name in ['walk','run'] else sorted({round(k.co.x) for c in curves(action) for k in c.keyframe_points})
        for f in frames:
            bpy.context.scene.frame_set(f);phase=(f-start)/max(1,end-start)
            open_hand=action.name in ['victim_grab','victim_throw','ledge_hold','ledge_catch','grab','grab_hold','grab_release','shield_hold','shield_enter','shield_exit']
            grasp=.20 if open_hand else .90
            if action.name in ['walk','run']:grasp=.45 if action.name=='walk' else .67
            if action.name.startswith('qa_'):grasp=.5
            if action.name in ['taunt1','taunt2','win','intro']:grasp=.35+.30*math.sin(math.pi*phase)**2
            for side,sgn in [('L',1),('R',-1)]:
                for digit in ['index','middle','ring','pinky','thumb']:
                    for segment in range(1,4):
                        name=f'{digit}_{segment:02d}.{side}';b=rig.pose.bones[name];rest=b.bone.matrix_local.to_quaternion()
                        angle=([85,90,60][segment-1] if digit!='thumb' else [42,50,30][segment-1])*grasp
                        axis=Vector((0,sgn,0)) if digit!='thumb' else Vector((sgn*.3,sgn,.2)).normalized()
                        b.rotation_mode='QUATERNION';b.rotation_quaternion=rest.inverted() @ Quaternion(axis,math.radians(angle)) @ rest
                        b.keyframe_insert('rotation_quaternion',frame=f,group=name)
                toe=rig.pose.bones['toe.'+side];lift=0
                if action.name in ['run','walk']:
                    p=(phase+(0 if side=='L' else .5))%1;stance=.4 if action.name=='run' else .6
                    lift=18*max(0,1-abs(p-(stance-.035))/.085)
                toe.rotation_mode='XYZ';toe.rotation_euler=(math.radians(-lift),0,0);toe.keyframe_insert('rotation_euler',frame=f,group=toe.name)
                for limb,child in [('upper_arm','forearm'),('forearm','hand')]:
                    b=rig.pose.bones[limb+'_twist.'+side];q=rig.pose.bones[child+'.'+side].rotation_quaternion
                    _,twist=q.to_swing_twist('Y');b.rotation_mode='QUATERNION';b.rotation_quaternion=Quaternion((0,1,0),twist*.45);b.keyframe_insert('rotation_quaternion',frame=f,group=b.name)
            effort=(.8 if action.get('purpose')=='attack' else .6 if action.name.startswith(('hit_','launch','tumble')) else 0)*math.sin(math.pi*phase)**2
            victory=.65 if action.name in ['win','taunt1','taunt2'] else 0
            for side,sgn in [('L',1),('R',-1)]:
                b=rig.pose.bones['brow.'+side];b.location=(sgn*-.0012*effort,-.0025*effort,0);b.keyframe_insert('location',frame=f,group=b.name)
                b=rig.pose.bones['mouth.'+side];b.location=(sgn*.0008*victory,.0015*victory-.0015*effort,0);b.keyframe_insert('location',frame=f,group=b.name)
        action['runtime_clip']=True;action['curated_version']=1
        # Auto-clamped authored splines eliminate overshoot between contact beats;
        # source-sampled curves stay linear.
        for c in curves(action):
            for k in c.keyframe_points:
                if k.interpolation=='BEZIER':k.handle_left_type='AUTO_CLAMPED';k.handle_right_type='AUTO_CLAMPED'
        report.append({'clip':action.name,'seconds':(end-start)/60,'detail_keys':len(list(frames))})
    return report


def gait_metadata(rig,fid):
    data={'strides':{},'contacts':{},'transition_ticks':{'move_start':10,'turnaround':10,'move_stop':12},
          'effect_sockets':{'left_hand':'hand.L','right_hand':'hand.R','left_foot':'foot.L','right_foot':'foot.R','chest':'chest'},'measurement':{}}
    for clip,stance in [('walk',.6),('run',.4)]:
        action=bpy.data.actions[clip];rig.animation_data.action=action;start,end=action.frame_range
        samples=[]
        for p in [.05,stance-.05]:
            f=start+p*(end-start);bpy.context.scene.frame_set(int(f),subframe=f%1);samples.append(rig.pose.bones['foot.L'].head.copy())
        stride=(samples[1].y-samples[0].y)/(stance-.1)
        data['strides'][clip]=round(stride,6);data['contacts'][clip]={'L':[.035,stance-.035],'R':[.535,(.5+stance-.035)%1]}
        data['measurement'][clip]={'source':'evaluated foot.L ankle trajectory in curated.blend','sample_phases':[.05,stance-.05],
          'positions':[list(v) for v in samples],'cycle_seconds':(end-start)/60,'max_contact_height_delta':abs(samples[1].z-samples[0].z)}
    (ROOT/'Game File/assets/characters'/(fid+'_presentation.json')).write_text(json.dumps(data,indent=2))
    return data


def build(fid,motions):
    folder=ROOT/'source_art/characters'/fid;curated=folder/'curated.blend'
    if curated.exists() and '--rebuild-curated' not in sys.argv:
        print('CURATED_PRESERVED',fid,flush=True);return
    if curated.exists():
        revisions=folder/'revisions';revisions.mkdir(exist_ok=True)
        digest=hashlib.sha256(curated.read_bytes()).hexdigest()[:12]
        stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        shutil.copy2(curated,revisions/(stamp+'_'+digest+'.blend'))
        print('CURATED_REVISION_SAVED',fid,stamp,digest,flush=True)
    bpy.ops.wm.open_mainfile(filepath=str(folder/'prepared.blend'))
    rig=bpy.data.objects['FighterRig'];mesh=bpy.data.objects['CharacterMesh'];mesh['character_asset']=True
    base.restore_source_surface_maps(mesh)
    hero_proportions(rig,mesh,fid)
    # Preserve prepared anatomy/UVs; the new anatomy and clothes are confined to
    # this derivative. Restore actions from authoritative timing data first.
    for a in list(bpy.data.actions):bpy.data.actions.remove(a)
    rows=json.loads((ROOT/'docs/moves/move_timing.json').read_text())['fighters'][fid]['moves'];base.TIMINGS.clear();base.ANIMS.clear()
    for name,row in rows.items():base.TIMINGS[name]={'startup':row['startup'],'active':row['active_windows'][0][1]-row['startup']+1,'active_windows':row['active_windows'],'recovery':row['recovery'],'total':row['total_ticks']}
    bpy.context.scene.render.fps=60;base.author(rig,STYLE[ROSTER.index(fid)],fid)
    rig.animation_data.action=None
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    weights=add_detail_rig(rig,mesh)
    armor=separate_heavy_armor(rig,mesh) if fid=='f03_heavy_duty' else []
    from hero_skinning import repair_torso,remove_cloth_webs
    repair_torso(rig,fid)
    additions=costume(rig,mesh,fid)
    repair_torso(rig,fid)
    rebuild_gloves(rig,mesh,fid)
    source_records=source_retarget(rig,fid,motions)
    breakdowns=polish_authored(rig,fid,base.TIMINGS)
    grounding=grounded_cleanup(rig,mesh)
    remove_cloth_webs(rig,fid)
    actions=detail_actions(rig);gait=gait_metadata(rig,fid)
    rig['hero_version']=1;rig['curated_policy']='Artist-owned: ordinary export never regenerates actions; controls default disabled, runtime curves baked'
    rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(curated))
    report={'fighter':fid,'weighted_detail_vertices':weights,'weighted_bones':len([n for n,c in weights.items() if c]),
            'rigid_armor':armor,'costume_meshes':additions,'retarget':source_records,'combat_breakdowns':breakdowns,'grounding':grounding,'actions':actions,'gait':gait,
            'original_source_sha256':rig['source_sha256'],'curated_source':str(curated.relative_to(ROOT))}
    out=ROOT/'evidence/characters/hero_rebuild';out.mkdir(parents=True,exist_ok=True)
    (out/(fid+'_build.json')).write_text(json.dumps(report,indent=2))
    export_curated(fid,curated)
    print('HERO_BUILD_COMPLETE',fid,len(actions),flush=True)


if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ROSTER
    motions=sample_source()
    for fid in args:
        if not fid.startswith('--'):build(fid,motions)
