"""Original signature props, Blender 5.2. All helper arguments use Godot XYZ/Y-up.
Run Blender --background --python tools/blender/props_build.py.
Exports visual-only GLBs; gameplay collision and state remain in the engine.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'Game File/assets/props'; SRC=ROOT/'source_art/props'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
random.seed(491)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for m in list(bpy.data.materials):bpy.data.materials.remove(m)
scene=bpy.context.scene;scene.unit_settings.system='METRIC'
def B(v):return Vector((v[0],-v[2],v[1]))
def material(name,c,rough=.5,metal=0,glow=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1)
    p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=glow
    return m
M={
'bark':material('Deadfall · cedar bark',(.22,.083,.031),.82),
'bark_light':material('Deadfall · split bark',(.37,.16,.055),.8),
'wood':material('Deadfall · endgrain',(.61,.36,.14),.68),
'grain':material('Deadfall · growth rings',(.28,.11,.037),.75),
'plank':material('Deadfall · sawn timber',(.45,.24,.08),.72),
'leaf':material('Deadfall · pine needles',(.06,.18,.085),.69),
'steel':material('Brushed stainless steel',(.37,.45,.49),.27,.8),
'dark':material('Graphite fixture',(.045,.060,.074),.5,.35),
'amber':material('Sunstruck · luminous amber',(.98,.28,.008),.35,.1,1.4),
'gold':material('Sunstruck · solar yellow',(.98,.66,.09),.29,.25,.6),
'hot':material('Sunstruck · hot rim',(.95,.86,.42),.25,.1,2.1),
'mirror':material('Sunstruck · polished reflector',(.50,.73,.79),.12,.92),
'mint':material('Fine Print · mint enamel',(.15,.55,.44),.36,.12),
'paper':material('Fine Print · contract paper',(.84,.80,.64),.8),
'ink':material('Fine Print · precise ink',(.055,.17,.16),.62),
'chair':material('Heavy Duty · folding chair finish',(.15,.22,.27),.38,.45),
}
assets={};current=''
def register(o,mat):
    o.data.materials.append(M[mat]);assets[current].append(o);return o
def mesh(name,verts,faces,mat):
    me=bpy.data.meshes.new(name);me.from_pydata([B(v) for v in verts],[],faces);me.update()
    o=bpy.data.objects.new(name,me);scene.collection.objects.link(o);return register(o,mat)
def box(name,p,s,mat,bevel=.02):
    x,y,z=(v/2 for v in s);px,py,pz=p
    vs=[(px+a*x,py+b*y,pz+c*z) for a,b,c in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
    o=mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat)
    if bevel:
        mod=o.modifiers.new('Rounded manufactured edges','BEVEL');mod.width=bevel;mod.segments=3
        o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
    return o
def cylinder(name,p,r,depth,mat,axis=(0,1,0),verts=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=B(p))
    o=bpy.context.object;o.name=name;o.rotation_euler=B(axis).to_track_quat('Z','Y').to_euler()
    mod=o.modifiers.new('Soft rim','BEVEL');mod.width=min(.018,r*.09);mod.segments=2
    for f in o.data.polygons:f.use_smooth=True
    return register(o,mat)
def beam(name,a,b,r,mat,verts=12):
    va,vb=Vector(a),Vector(b);return cylinder(name,(va+vb)/2,r,(vb-va).length,mat,vb-va,verts)
def tapered_beam(name,a,b,r0,r1,mat):
    va,vb=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=r0,radius2=r1,depth=(vb-va).length,location=B((va+vb)/2))
    o=bpy.context.object;o.name=name;o.rotation_euler=B(vb-va).to_track_quat('Z','Y').to_euler()
    for f in o.data.polygons:f.use_smooth=True
    return register(o,mat)
def ring(name,p,r,minor,mat,axis=(0,0,1),sx=1,sy=1):
    bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=6,major_radius=r,minor_radius=minor,location=B(p))
    o=bpy.context.object;o.name=name;o.rotation_euler=B(axis).to_track_quat('Z','Y').to_euler();o.scale=(sx,sy,1)
    for f in o.data.polygons:f.use_smooth=True
    return register(o,mat)
def sphere(name,p,s,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=B(p));o=bpy.context.object;o.name=name
    o.scale=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for f in o.data.polygons:f.use_smooth=True
    return register(o,mat)
def start(name):
    global current
    current=name;assets[name]=[]
def bark_log(name,length,radius,axis=(0,0,1),origin=(0,0,0)):
    # Explicit radial end grain and varied raised strips, avoiding a plain cylinder silhouette.
    a=Vector(axis).normalized();base=Vector(origin)
    u=a.cross(Vector((0,1,0)))
    if u.length<.1:u=a.cross(Vector((1,0,0)))
    u.normalize();v=a.cross(u).normalized()
    cylinder(name+' core',base,radius,length,'bark',a,14)
    for i in range(13):
        angle=i*2*math.pi/13;radial=u*math.cos(angle)+v*math.sin(angle)
        start=base-a*length*.47+radial*radius*.94;end=base+a*length*.47+radial*radius*.96
        beam(name+' bark ridge',start,end,.035 if radius>.3 else .019,'bark_light' if i%3==0 else 'grain',6)
    for sign in (-1,1):
        face=base+a*(length*.5+.006)*sign
        cylinder(name+' cut end',face,radius*.91,.012,'wood',a,24)
        for r in (.22,.44,.67,.85):ring(name+' growth ring',face+a*.010*sign,radius*r,.009 if radius>.3 else .005,'grain',a)
        # One radial checking split on each cut end.
        beam(name+' checked end',face+u*radius*.45+a*.020*sign,face+(u*.75+v*.34)*radius+a*.02*sign,.009,'grain',6)

start('solar_disc')
ring('Radiant cap orbit',(0,0,0),.405,.029,'hot')
cylinder('Cap disc base',(0,0,0),.365,.08,'amber',(0,0,1),40)
sphere('Low crown',(-.065,.055,.035),(.265,.267,.105),'gold')
# The cap bill projects forward; three crown seams make the cap identity visible.
mesh('Swept cap bill',[(.04,-.20,.07),(.29,-.23,.07),(.49,-.13,.04),(.50,.015,.04),(.25,.02,.07),(.11,.15,.07)],[(0,1,2,3,4,5)],'gold')
for delta in (-.14,0,.14):
    pts=[(-.065+delta*math.sin(j*math.pi/8),-.18+j*.058,.127-.04*abs(j-4)/4) for j in range(9)]
    for j in range(8):beam('Crown seam',pts[j],pts[j+1],.008,'hot',6)
mesh('Solar bolt',[(-.10,.14,.15),(.035,.14,.15),(-.035,.03,.15),(.05,.03,.15),(-.13,-.13,.15),(-.075,0,.15),(-.15,0,.15)],[(0,1,2,3,4,5,6)],'hot')

start('reflector')
cylinder('Reflector weighted foot',(0,.035,0),.33,.07,'dark',(0,1,0),24)
ring('Foot hazard ring',(0,.075,0),.29,.018,'gold',(0,1,0))
beam('Reflector pivot stem',(0,.075,0),(0,.245,0),.045,'steel')
# Mirror long direction follows a 15 degree up/forward plane in XY.
normal=Vector((-.258819,.965926,0));tangent=Vector((.965926,.258819,0))
center=Vector((0,.245,0))
cylinder('Angled reflector body',center,.4,.055,'gold',normal,32)
cylinder('Reflective plate',center+normal*.032,.355,.012,'mirror',normal,32)
ring('Reflector rim',center+normal*.041,.375,.018,'hot',normal)
for x in (-.21,.21):
    p=center+tangent*x+normal*.043
    cylinder('Mirror retaining screw',p,.021,.022,'dark',normal,12)
# A forward/up chevron floats only 4 cm above its front, readable from the play camera.
a=Vector((-.23,.20,.36));b=a+Vector((.49,.283,0));beam('Thirty degree route',a,b,.018,'hot',8)
beam('Route arrow upper',b,b+Vector((-.14,.0,0)),.018,'hot',8)
beam('Route arrow lower',b,b+Vector((-.07,-.125,0)),.018,'hot',8)

start('log')
bark_log('Rolling cedar',.65,.48)
beam('Snapped twig',(.28,.26,-.1),(.43,.40,-.04),.056,'bark',8)
cylinder('Twig break',(.43,.40,-.04),.047,.022,'wood',(.7,.7,.2),10)

start('plank')
box('Sawn plank',(0,.072,0),(1.8,.144,.48),'plank',.028)
for z in (-.16,-.075,.055,.16):
    beam('Long grain',(-.86,.147,z),(.87,.147,z+random.uniform(-.02,.02)),.005,'grain',5)
for x in (-.65,.65):
    for z in (-.15,.15):cylinder('Countersunk nail',(x,.153,z),.017,.008,'steel',(0,1,0),10)
for x in (-.54,.49):ring('Timber knot',(x,.149,.018),.045,.007,'grain',(0,1,0),1.9,.6)

start('branch')
bark_log('Overhead branch',2.4,.12,(1,0,0))
for sign in (-1,1):
    beam('Forked limb',(sign*.72,0,0),(sign*.98,.23,-.1),.065,'bark',10)
    beam('Fork tip',(sign*.98,.23,-.1),(sign*1.10,.31,-.06),.029,'bark_light',8)
ring('Rope attachment band',(0,0,0),.132,.024,'wood',(1,0,0))
beam('Suspension rope',(0,.04,.14),(0,-.33,.14),.018,'wood',8)

start('chair')
# Folding chair silhouette; front points +X, broad back plane spans Z.
for z in (-.27,.27):
    beam('Front tubular leg',(.29,.025,z),(-.22,.69,z),.026,'steel')
    beam('Rear tubular leg',(-.29,.025,z),(.24,.69,z),.026,'steel')
    beam('Back upright',(-.26,.46,z),(-.34,1.08,z),.028,'steel')
    cylinder('Hinge pin',(0,.41,z),.051,.058,'dark',(0,0,1),12)
    for x in (-.29,.29):box('Rubber foot',(x,.025,z),(.09,.05,.075),'dark',.022)
box('Rounded chair seat',(0,.51,0),(.57,.075,.60),'chair',.06)
back=box('Curved stamped back',(-.317,.88,0),(.065,.29,.61),'chair',.065)
for z in (-.19,0,.19):box('Back pressed rib',(-.278,.88,z),(.022,.20,.024),'steel',.01)
beam('Chair lower crossbar',(-.21,.18,-.27),(-.21,.18,.27),.019,'steel')

start('tree')
# The 5.6 m falling trunk remains readable inside the actual diagonal hit capsule.
points=[(0,0,0),(.035,1.0,.02),(-.025,2.05,.015),(.035,3.0,0),(.01,4.1,.02),(0,5.6,0)]
radii=[.23,.205,.175,.14,.10,.045]
trunk_vertices=[];trunk_faces=[];sides=20
for p,r in zip(points,radii):
    for j in range(sides):
        a=j*2*math.pi/sides
        trunk_vertices.append((p[0]+r*math.cos(a),p[1],p[2]+r*math.sin(a)))
for i in range(len(points)-1):
    for j in range(sides):trunk_faces.append((i*sides+j,(i+1)*sides+j,(i+1)*sides+(j+1)%sides,i*sides+(j+1)%sides))
trunk_faces.extend([tuple(range(sides)),tuple(reversed(range((len(points)-1)*sides,len(points)*sides)))])
trunk=mesh('Continuous tapered falling trunk',trunk_vertices,trunk_faces,'bark')
for face in trunk.data.polygons:
    if len(face.vertices)==4:face.use_smooth=True
for i in range(15):
    angle=i*2*math.pi/15
    beam('Trunk bark seam',(.205*math.cos(angle),.08,.205*math.sin(angle)),(.13*math.cos(angle),2.9,.13*math.sin(angle)),.021,'bark_light' if i%4==0 else 'grain',6)
cylinder('Visible stump cut',(0,.012,0),.22,.024,'wood',(0,1,0),24)
for r in (.07,.13,.19):ring('Stump growth ring',(0,-.001,0),r,.005,'grain',(0,1,0))
for height,width in ((3.4,.62),(4.03,.52),(4.63,.39),(5.03,.25)):
    # Asymmetric tiered pine boughs, leaving clear trunk negative space.
    for i in range(5):
        ang=i*2*math.pi/5+.3*height
        tip=(width*math.cos(ang),height-.19,width*.70*math.sin(ang))
        beam('Pine branch',(0,height+.18,0),tip,.027,'bark',8)
        u=Vector((-math.sin(ang),0,math.cos(ang)))*width*.24
        root=Vector((0,height+.57,0));end=Vector(tip)
        mesh('Needle spray',[root,end-u,end+u,end+Vector((0,.14,0))],[(0,1,3),(0,3,2),(1,2,3)],'leaf')

start('clipboard')
# Fine Print's contract board faces camera (+Z). Bottom-center is a grip origin.
box('Mint clipboard',(0,.30,0),(.43,.60,.035),'mint',.045)
box('Paper contract',(0,.29,.024),(.36,.49,.008),'paper',.008)
box('Steel clip',(0,.566,.038),(.20,.095,.03),'steel',.015)
beam('Clip hinge',(-.082,.586,.06),(.082,.586,.06),.012,'dark',10)
box('Contract headline',(-.055,.466,.031),(.21,.018,.003),'ink',.002)
for j in range(8):
    box('Clause line',(-.020,.422-j*.036,.031),(.25-(.05 if j%3==0 else 0),.006,.003),'ink',0)
mesh('Approval check',[(.053,.09,.032),(.07,.073,.032),(.123,.131,.032),(.113,.14,.032),(.069,.094,.032),(.060,.103,.032)],[(0,1,2,3,4,5)],'mint')
beam('Attached pencil',(.233,.12,.015),(.233,.47,.015),.012,'gold',6)

# Bake modifiers and batch by material separately for every prop.
report=[];roots=[]
for asset,objects in assets.items():
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects:
        bpy.context.view_layer.objects.active=ob
        for modifier in list(ob.modifiers):
            try:bpy.ops.object.modifier_apply(modifier=modifier.name)
            except RuntimeError:pass
    bymat={}
    for ob in objects:bymat.setdefault(ob.data.materials[0].name,[]).append(ob)
    joined=[]
    for mat,obs in bymat.items():
        bpy.ops.object.select_all(action='DESELECT')
        for ob in obs:ob.select_set(True)
        bpy.context.view_layer.objects.active=obs[0]
        if len(obs)>1:bpy.ops.object.join()
        ob=bpy.context.object;ob.name=asset+'__'+mat.split(' · ')[-1]
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');joined.append(ob)
    root=bpy.data.objects.new(asset,None);scene.collection.objects.link(root);roots.append(root)
    for ob in joined:ob.parent=root
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
    for ob in joined:ob.select_set(True)
    path=OUT/(asset+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
    vertices=[ob.matrix_world@v.co for ob in joined for v in ob.data.vertices]
    vmin=[min(v[i] for v in vertices) for i in range(3)];vmax=[max(v[i] for v in vertices) for i in range(3)]
    gmin=[vmin[0],vmin[2],-vmax[1]];gmax=[vmax[0],vmax[2],-vmin[1]]
    report.append({'id':asset,'path':'res://assets/props/'+path.name,'bytes':path.stat().st_size,
        'mesh_batches':len(joined),'triangles':sum(sum(len(p.vertices)-2 for p in ob.data.polygons) for ob in joined),
        'bounds_min':gmin,'bounds_max':gmax,'dimensions':[gmax[i]-gmin[i] for i in range(3)]})

# Gallery positions affect saved editable source only. Runtime exports stay at origin.
positions={'solar_disc':(-4,0,0),'reflector':(-1.8,0,0),'log':(.5,.5,0),'plank':(3,0,0),
'branch':(-4,2.2,0),'chair':(-1.8,2.2,0),'tree':(5.4,0,-.4),'clipboard':(.7,2.2,0)}
for root in roots:root.location=B(positions[root.name])
def text(body,p,size=.16):
    cv=bpy.data.curves.new('Preview label','FONT');cv.body=body.upper();cv.size=size;cv.align_x='CENTER';cv.extrude=.001
    ob=bpy.data.objects.new(body+' · label',cv);scene.collection.objects.link(ob);ob.location=B(p);ob.rotation_euler=(math.pi/2,0,0);cv.materials.append(M['paper'])
for asset,p in positions.items():
    if asset=='solar_disc':text('solar disc',(p[0],-.73,.02))
    elif asset=='log':text('rolling log',(p[0],-.35,.02))
    elif asset=='branch':text('branch / suspension',(p[0],p[1]-.62,.02))
    elif asset=='tree':text('falling tree',(p[0],-.48,.02))
    else:text(asset.replace('_',' '),(p[0],p[1]-.42,.02))
world=bpy.data.worlds.new('Prop gallery world');scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.028,.041,.058,1);world.node_tree.nodes['Background'].inputs[1].default_value=.4
for name,p,energy,color,size in [('Key',(-4,8,8),1800,(1,.78,.53),8),('Fill',(5,4,5),1100,(.42,.7,1),7),('Rim',(0,6,-3),1400,(.65,.94,1),6)]:
    data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.color=color;data.shape='DISK';data.size=size
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=B(p)
    ob.rotation_euler=(B((0,2,0))-ob.location).to_track_quat('-Z','Y').to_euler()
cam_data=bpy.data.cameras.new('Props gallery camera');cam=bpy.data.objects.new('Props gallery camera',cam_data);scene.collection.objects.link(cam)
cam.location=B((0,5,20));cam.rotation_euler=(B((.2,2.2,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.type='ORTHO';cam_data.ortho_scale=12.8;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1600;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(SRC/'props_preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'signature_props.blend'))
bpy.ops.render.render(write_still=True)
(SRC/'props_manifest.json').write_text(json.dumps({'generator':'tools/blender/props_build.py','coordinate_system':'Godot Y-up; forward +X','visual_only':True,'assets':report},indent=2),encoding='utf-8')
print('PROPS_BUILD_OK',json.dumps(report))
