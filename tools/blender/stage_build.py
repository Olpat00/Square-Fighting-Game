"""Original Last Resort architectural revision 3. Blender X/Y/Z -> Godot X/Z/-Y.
Run Blender 5.2 --background --python tools/blender/stage_build.py [-- --no-render].
Geometry/material authoring only: four authoritative gameplay platforms unchanged.
"""
import bpy, math, random, json, sys
import numpy as np
from mathutils import Vector,Matrix
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'Game File/assets/stage';SRC=ROOT/'source_art/stage';EVIDENCE=ROOT/'evidence/stage';TEX=SRC/'textures'
for p in (OUT,SRC,EVIDENCE,TEX):p.mkdir(parents=True,exist_ok=True)
random.seed(80223)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for m in list(bpy.data.materials):bpy.data.materials.remove(m)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';groups={};M={}

def image_file(name,rgb,noncolor=False):
    h,w=rgb.shape[:2];im=bpy.data.images.new(name,width=w,height=h,alpha=False)
    if noncolor:im.colorspace_settings.name='Non-Color'
    rgba=np.ones((h,w,4),dtype=np.float32);rgba[:,:,:3]=np.clip(rgb,0,1)
    im.pixels.foreach_set(rgba.ravel());im.filepath_raw=str(TEX/(name+'.png'));im.file_format='PNG';im.save();return im
def texture_set(name,color,kind):
    # Original seamless material maps, exported as conventional glTF PBR textures.
    n=1024;yy,xx=np.mgrid[0:n,0:n].astype(np.float32)/n;rng=np.random.default_rng(sum(map(ord,name)))
    noise=np.zeros((n,n),dtype=np.float32)
    for f,amp in ((2,.36),(5,.23),(12,.16),(27,.09),(63,.055),(119,.025)):
        for k in range(3):
            a,b=rng.integers(-f,f+1,size=2);noise+=np.sin(math.tau*(xx*a+yy*b)+rng.random()*math.tau)*amp/3
    fine=rng.random((n,n)).astype(np.float32)-.5
    if kind=='wood':
        grain=np.sin(math.tau*(yy*76+np.sin(xx*math.tau*2+yy*math.tau)*.23))+.38*np.sin(math.tau*(yy*191+noise*.35))
        pores=np.maximum(0,np.sin(math.tau*(yy*317+noise*.2))-.86)
        value=1+noise*.13+grain*.09+fine*.022-pores*.17;height=noise*.055+grain*.038-pores*.08;rough=.34+noise*.06+grain*.025
    elif kind=='stone':
        # Fine mineral pores rather than the previous broad, cloudy marble bands.
        pores=np.maximum(0,fine-.42)*7
        strata=np.sin(math.tau*(yy*51+noise*.19))
        value=1+noise*.10+fine*.024-pores*.055+strata*.015;height=noise*.10+fine*.018-pores*.11;rough=.49+noise*.045+pores*.08
    elif kind=='linen':
        weave=np.sin(xx*math.tau*180)*np.sin(yy*math.tau*180);value=1+noise*.08+weave*.024;height=weave*.07;rough=np.ones_like(noise)*.79
    elif kind=='brass':
        grain=np.sin(yy*math.tau*211)+fine*.25;value=1+grain*.035+noise*.055;height=grain*.023;rough=.34+grain*.025
    else:value=1+noise*.10+fine*.025;height=noise*.18;rough=.63+noise*.06
    rgb=np.clip(np.array(color)[None,None,:]*value[:,:,None],0,1)
    dx=(np.roll(height,-1,1)-np.roll(height,1,1))*2;dy=(np.roll(height,-1,0)-np.roll(height,1,0))*2
    normal=np.stack((-dx,-dy,np.ones_like(dx)),axis=-1);normal/=np.linalg.norm(normal,axis=-1)[:,:,None]
    return image_file(name+'_color',rgb),image_file(name+'_roughness',np.repeat(np.clip(rough,0,1)[:,:,None],3,axis=2),True),image_file(name+'_normal',normal*.5+.5,True)
def mat(key,name,color,rough=.5,metal=0,emission=0,texture=None):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    if texture:
        maps=texture_set(key,color,texture)
        for i,socket in enumerate(('Base Color','Roughness','Normal')):
            node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=maps[i];node.extension='REPEAT'
            if i==2:
                norm=m.node_tree.nodes.new('ShaderNodeNormalMap');norm.inputs['Strength'].default_value=.45
                m.node_tree.links.new(node.outputs['Color'],norm.inputs['Color']);m.node_tree.links.new(norm.outputs['Normal'],bs.inputs[socket])
            else:m.node_tree.links.new(node.outputs['Color'],bs.inputs[socket])
    if emission:bs.inputs['Emission Color'].default_value=(*color,1);bs.inputs['Emission Strength'].default_value=emission
    M[key]=m;return m
mat('slate','Slate | fine honed volcanic stone',(.070,.083,.085),texture='stone')
mat('stone','Travertine | warm cut limestone',(.40,.375,.325),texture='stone')
mat('wood','Teak | quarter-sawn oiled timber',(.195,.092,.039),texture='wood')
mat('wood2','Teak | naturally weathered grain',(.25,.127,.052),texture='wood')
mat('brass','Brass | satin champagne alloy',(.42,.29,.14),metal=.78,texture='brass')
mat('linen','Linen | woven natural upholstery',(.51,.49,.42),texture='linen')
mat('dark','Graphite | recessed metal',(.029,.038,.040),.42,.38)
mat('glass','Glass | smoked balustrade',(.10,.19,.20),.13,.48)
mat('hotel_glass','Hotel | deep reflective glazing',(.017,.035,.045),.16,.66)
mat('hotel_interior','Hotel | occupied warm interior',(.36,.19,.072),.57,0,.55)
mat('hotel_curtain','Hotel | partly drawn bronze curtain',(.09,.065,.043),.81)
mat('ceramic','Hospitality | glazed ivory ceramic',(.64,.62,.53),.19)
mat('leather','Hospitality | cognac leather',(.13,.043,.020),.42)
mat('hair','Guests | dark warm hair',(.023,.016,.012),.74)
mat('trousers','Guests | tailored charcoal trousers',(.027,.034,.044),.83)
clear_glass=mat('clear_glass','Glass | clear terrace balustrade',(.24,.37,.39),.12,.05)
clear_glass.diffuse_color=(.24,.37,.39,.25)
clear_glass.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.25
clear_glass.surface_render_method='DITHERED'
mat('water','Water | infinity turquoise',(.018,.205,.212),.12,.25)
mat('pool','Pool | deep teal porcelain',(.025,.16,.165),.27)
mat('tile','Pool | pale mosaic grout',(.095,.23,.23),.6)
mat('bark','Palm | fibrous bark',(.18,.127,.076),texture='other')
mat('leaf','Foliage | deep waxy jade',(.020,.073,.026),.37)
mat('leaf2','Foliage | olive sunlit tips',(.067,.116,.032),.42)
mat('earth','Planter | dark earth',(.031,.036,.026),.95)
mat('amber','Lighting | warm concealed strip',(.9,.57,.27),.33,.1,2.5)
mat('soft_light','Lighting | frosted warm diffuser',(.83,.67,.42),.45,0,1.3)
mat('neon','Lighting | small venue inscription',(.45,.71,.64),.3,.1,1.5)
mat('bottle','Hospitality | olive bottle glass',(.028,.085,.047),.21,.28)
mat('bottle2','Hospitality | amber bottle glass',(.17,.083,.026),.22,.25)
mat('crowd','Guests | midnight formalwear',(.031,.054,.061),.72)
mat('crowd2','Guests | warm gray linen',(.22,.19,.145),.84)
mat('skin','Guests | shaded neutral complexion',(.23,.115,.063),.65)
mat('city_near','City | close blue graphite',(.043,.062,.075),.78,.15)
mat('city_glass','City | glass curtain wall',(.058,.095,.114),.26,.45)
mat('city_fins','City | architectural mullions',(.099,.13,.139),.64,.22)
mat('city_windows','City warm pinlights',(.39,.28,.15),.7,0,.55)
mat('city_cool','City cool pinlights',(.15,.23,.27),.7,0,.25)

def add(ob,key,group='architecture'):
    ob.data.materials.append(M[key]);ob['group']=group;groups.setdefault(group,[]).append(ob);return ob
def uv_planar(ob):
    uv=ob.data.uv_layers.new(name='Architectural metres')
    for face in ob.data.polygons:
        axis=max(range(3),key=lambda i:abs(face.normal[i]));axes=[i for i in range(3) if i!=axis]
        for index in face.loop_indices:
            v=ob.data.vertices[ob.data.loops[index].vertex_index].co
            uv.data[index].uv=(v[axes[0]]+ob.location[axes[0]],v[axes[1]]+ob.location[axes[1]])
def mesh(name,verts,faces,key,group='architecture'):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();ob=bpy.data.objects.new(name,me);scene.collection.objects.link(ob);uv_planar(ob);return add(ob,key,group)
def cube(name,loc,size,key,bevel=.025,group='architecture'):
    x,y,z=[v*.5 for v in size]
    verts=[(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]
    ob=mesh(name,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],key,group);ob.location=loc
    for layer in list(ob.data.uv_layers):ob.data.uv_layers.remove(layer)
    uv_planar(ob)
    if bevel:
        mod=ob.modifiers.new('Machined edge radius','BEVEL');mod.width=min(bevel,min(size)*.42);mod.segments=3;ob.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return ob
def sphere(name,loc,scale,key,group='architecture',segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=10,location=loc);ob=bpy.context.object;ob.name=name;ob.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for p in ob.data.polygons:p.use_smooth=True
    return add(ob,key,group)
def cylinder(name,loc,radius,depth,key,vertices=20,group='architecture'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc);ob=bpy.context.object;ob.name=name
    b=ob.modifiers.new('Turned edge','BEVEL');b.width=min(.016,radius*.08);b.segments=2
    for f in ob.data.polygons:f.use_smooth=len(f.vertices)==4
    ob.modifiers.new('Weighted normals','WEIGHTED_NORMAL');return add(ob,key,group)
def beam(name,a,b,r,key,group='architecture',vertices=10):
    a,b=Vector(a),Vector(b);ob=cylinder(name,(a+b)*.5,r,(b-a).length,key,vertices,group);ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return ob
def tube(name,points,r,key,group='architecture',sides=10):
    pts=[Vector(p) for p in points];verts=[];faces=[]
    for i,p in enumerate(pts):
        tangent=pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)];u=tangent.cross(Vector((0,1,0))).normalized();v=tangent.normalized().cross(u);radius=r*(1-i/max(1,len(pts)-1)*.26)
        for j in range(sides):verts.append(p+(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides))*radius)
    for i in range(len(pts)-1):
        for j in range(sides):faces.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    ob=mesh(name,verts,faces,key,group)
    for p in ob.data.polygons:p.use_smooth=True
    return ob
def text_obj(name,body,loc,size,key,group='signage'):
    cv=bpy.data.curves.new(name,'FONT');cv.body=body;cv.size=size;cv.align_x='CENTER';cv.extrude=.003;cv.bevel_depth=.0008;cv.space_character=1.15
    ob=bpy.data.objects.new(name,cv);scene.collection.objects.link(ob);ob.location=loc;ob.rotation_euler=(math.pi/2,0,0)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH');return add(ob,key,group)
def ring(name,loc,r,minor,key,group='architecture'):
    bpy.ops.mesh.primitive_torus_add(major_segments=40,minor_segments=6,location=loc,major_radius=r,minor_radius=minor);ob=bpy.context.object;ob.name=name;return add(ob,key,group)

# Combat deck: fine horizontal timber runs and a honed stone picture frame.
cube('Combat deck structural slab',(0,.65,-.30),(18,3.30,.48),'slate',.055)
cube('Deck fine front lip',(0,-1.018,-.03),(17.96,.085,.06),'stone',.012)
cube('Deck recessed shadow line',(0,-1.035,-.16),(17.80,.025,.045),'dark',.004)
cube('Deck concealed warm line',(0,-1.047,-.156),(17.65,.012,.012),'amber',.003,'ReactionGlow')
for x in (-8.87,8.87):cube('End coping',(x,.63,-.022),(.26,3.16,.044),'stone',.014)
for row in range(22):
    y=-.858+row*.139;offset=(row%3)*.72;cuts=sorted(set([-8.72,8.72]+[p for p in np.arange(-10+offset,10,2.20) if -8.72<p<8.72]))
    for j in range(len(cuts)-1):
        start,end=cuts[j],cuts[j+1];cube('Quarter-sawn teak board',((start+end)*.5,y,-.019),(end-start-.008,.131,.038),'wood2' if (row+j)%7==0 else 'wood',.005)
for i in range(12):cube('Fascia cut basalt panel',(-8.23+i*1.497,-.972,-.30),(1.473,.065,.21),'slate',.010)
for x in (-8.94,8.94):
    cube('Recovery ledge fine brass marker',(x,-.20,-.02),(.022,1.35,.028),'brass',.003)
    cube('Under-ledge warm pocket',(x,-.20,-.22),(.014,.75,.023),'amber',.003,'ReactionGlow')
# Recessed hotel tower face preserves open recovery room beside the main deck.
cube('Hotel podium undercroft',(0,6.3,-20.25),(16.6,7.8,39.5),'slate',.08)
for x in np.arange(-8.15,8.2,1.02):
    cube('Podium facade glazing',(float(x),2.345,-20.325),(.91,.035,39.35),'hotel_glass',.003)
    cube('Facade bronze mullion',(float(x)+.465,2.28,-20.325),(.035,.15,39.35),'dark',.005)
for floor,z in enumerate(np.arange(-2.35,-39,-2.2)):
    cube('Hotel horizontal stone spandrel',(0,2.22,float(z)),(16.6,.21,.23),'slate',.018)
    cube('Floor thin bronze reveal',(0,2.097,float(z)+.11),(16.58,.018,.018),'brass',.003)
    for bay,x in enumerate(np.arange(-8.15,8.2,1.02)):
        if (floor*17+bay*7)%11<4:
            cube('Warm hotel room behind glazing',(float(x),2.315,float(z)+1.06),(.85,.018,1.56),'hotel_interior',.004)
            side=-1 if bay%2 else 1
            cube('Partly drawn hotel curtain',(float(x)+side*.25,2.287,float(z)+1.07),(.28,.018,1.57),'hotel_curtain',.003)
            cube('Room shadow transom',(float(x),2.274,float(z)+1.55),(.88,.032,.025),'dark',.002)
for x in (-8.28,8.28):
    cube('Hotel corner blade',(x,2.20,-20.22),(.095,.24,39.45),'stone',.014)
for x in (-7.5,7.5):cube('Hidden cantilever root',(x,1.9,-1.00),(.26,.38,1.35),'dark',.03)
def platform(name,x,z,width,group):
    cube(name+' beveled stone edge',(x,.10,z-.180),(width,1.45,.29),'slate',.045,group)
    cube(name+' inset dark field',(x,.10,z-.037),(width-.16,1.28,.044),'dark',.015,group)
    for row in range(8):cube(name+' timber slat',(x,-.459+row*.158,z-.015),(width-.24,.150,.030),'wood',.005,group)
    cube(name+' bronze nose',(x,-.630,z-.04),(width-.16,.035,.045),'brass',.008,group)
    cube(name+' lower warm reveal',(x,-.645,z-.195),(width-.26,.014,.018),'amber',.003,group)
    cube(name+' recessed keel',(x,.14,z-.29),(width-.55,.83,.11),'dark',.035,group)
for x in (-5.,5.):
    platform('Cantilever terrace',x,3.6,4.5,'fixed_platforms')
    for dx in (-1.65,1.65):
        cube('Rear cantilever fin',(x+dx,2.8,1.4),(.095,.35,4.35),'dark',.012)
        cube('Rear cantilever arm',(x+dx,1.9,3.34),(.095,2.0,.12),'dark',.012)
platform('Service lift',0,0,3.5,'center_platform')

# Recessed terrace/infinity pool: quiet stone surround, overflow channel and drains.
deck_z=-.28
cube('Hospitality slab',(0,6.8,-1.02),(22.0,10.3,.65),'slate',.08)
for name,loc,size in (
    ('front',(0,2.6125,-.505),(22,1.925,.42)),
    ('rear',(0,10.5375,-.505),(22,2.825,.42)),
    ('left',(-9.275,6.35,-.505),(3.45,5.55,.42)),
    ('right',(7.925,6.35,-.505),(6.15,5.55,.42))):
    cube('Pool opening substrate '+name,loc,size,'slate',.04)
for row in range(7):
    for col in range(15):
        x=-10.25+col*1.46;y=2.03+row*1.44
        if -7.25<x<4.6 and 3.7<y<8.6:continue
        cube('Large format limestone paver',(x,y,deck_z-.03),(1.444,1.424,.060),'stone',.006)
px,py,pw,pd=-1.35,6.35,11.6,4.95
cube('Pool structural liner',(px,py,-.89),(pw,pd,.55),'pool',.09)
cube('Pool water surface',(px,py,-.386),(pw-.16,pd-.16,.018),'water',.09,'Water')
for y in (py-pd/2-.15,py+pd/2+.15):cube('Pool honed coping',(px,y,-.29),(pw+.70,.30,.18),'stone',.035)
for x in (px-pw/2-.20,px+pw/2+.20):cube('Pool side coping',(x,py,-.29),(.40,pd+.28,.18),'stone',.035)
cube('Pool overflow weir',(px,py+pd/2-.03,-.40),(pw-.2,.025,.025),'glass',.004)
cube('Infinity overflow trough',(px,py+pd/2+.23,-.45),(pw+.05,.12,.12),'dark',.012)
for x in np.arange(px-pw/2+.20,px+pw/2,.24):cube('Overflow drain grate',(float(x),py+pd/2+.23,-.38),(.018,.11,.016),'brass',.003)
cube('Pool underwater ribbon',(px,py-pd/2+.04,-.55),(pw-.25,.022,.022),'soft_light',.003,'ReactionGlow')
for x in (px-pw/2+.10,px+pw/2-.10):
    for y in np.arange(py-pd/2+.15,py+pd/2,.28):cube('Pool perimeter mosaic seam',(x,float(y),-.372),(.08,.013,.010),'tile',0,'WaterDetail')
for i in range(3):cube('Pool entry stone step',(4.03-i*.26,4.7,-.35-i*.16),(.48,1.5,.16),'stone',.025)
for x in (-7.64,4.86):
    for y in np.arange(3.83,8.91,.24):cube('Pool linear drain',(x,float(y),-.275),(.09,.025,.016),'dark',.002)
for x in np.arange(-10.25,10.4,1.36):
    cube('Balustrade smoke glass',(float(x),11.32,.29),(1.31,.018,1.10),'clear_glass',.003,'balustrade')
    cube('Balustrade base shoe',(float(x),11.30,-.235),(1.34,.075,.09),'dark',.009)
    cube('Balustrade slender upright',(float(x)-.67,11.30,.29),(.018,.042,1.10),'brass',.004)
beam('Balustrade satin top rail',(-10.93,11.29,.85),(10.93,11.29,.85),.018,'brass')

# Compact asymmetric hospitality pavilion: sky/combat space stays open.
for x in (5.1,10.3):cube('Pavilion bronze column',(x,9.4,1.43),(.075,.12,3.42),'brass',.012)
cube('Pavilion roof',(7.7,9.4,3.13),(5.7,3.25,.17),'dark',.035)
cube('Pavilion upper bronze cap',(7.7,9.4,3.226),(5.73,3.28,.026),'brass',.006)
for i in range(32):
    cube('Pavilion top louvre',(4.94+i*.178,9.40,3.29),(.054,3.05,.10),'wood',.014)
cube('Pavilion fine lit cornice',(7.7,7.77,3.08),(5.52,.018,.023),'amber',.003,'ReactionGlow')
for i in range(28):cube('Pavilion ceiling timber battens',(5.02+i*.20,9.34,3.015),(.085,2.94,.063),'wood',.009)
cube('Bar monolithic stone base',(7.55,9.04,.25),(4.55,1.03,1.06),'slate',.07)
for i in range(46):cube('Bar rounded timber flute',(5.32+i*.099,8.494,.25),(.077,.058,.91),'wood',.026)
cube('Bar limestone countertop',(7.55,9.00,.84),(4.76,1.29,.12),'stone',.027)
cube('Bar recessed toe light',(7.55,8.49,-.195),(4.2,.018,.018),'amber',.003,'ReactionGlow')
cube('Backbar screen',(7.55,10.61,1.12),(4.60,.13,2.23),'dark',.025)
for i in range(37):cube('Backbar ribbed brass reflector',(5.29+i*.126,10.515,1.15),(.028,.052,2.15),'brass',.008)
for x in (5.55,7.15,8.8,9.55):
    beam('Pendant black flex',(x,8.1,3.04),(x,8.1,2.31),.009,'dark')
    cylinder('Pendant bronze hood',(x,8.1,2.26),.155,.09,'brass',32)
    sphere('Pendant frosted globe',(x,8.1,2.16),(.10,.10,.115),'soft_light','ReactionGlow',24)
for z in (.68,1.45,2.12):
    cube('Backbar glass shelf',(7.55,10.39,z),(4.39,.38,.035),'glass',.007)
    cube('Backbar shelf glow',(7.55,10.48,z-.018),(4.18,.015,.012),'soft_light',.002,'ReactionGlow')
for i in range(15):
    x=5.66+i*.273;z=.89 if i%3 else 1.66;h=random.uniform(.20,.30)
    cylinder('Bar bottle body',(x,10.36,z),.036,h,'bottle2' if i%4==0 else 'bottle',12)
    cylinder('Bar bottle neck',(x,10.36,z+h*.5+.033),.014,.070,'brass',10)
    cylinder('Bar bottle label',(x,10.36,z+.015),.037,.055,'linen',12)
for x in (5.75,7.10,8.45,9.55):
    cylinder('Stool upholstered seat',(x,7.89,.40),.225,.12,'linen',24)
    cylinder('Stool pedestal',(x,7.89,.035),.026,.64,'dark',12)
    ring('Stool footrest',(x,7.89,-.025),.16,.013,'brass')
    cylinder('Stool foot',(x,7.89,-.255),.18,.035,'dark',20)
cube('Venue inset plaque',(-8.7,10.12,1.30),(3.05,.10,1.16),'slate',.07,'signage')
text_obj('Venue title','THE LAST RESORT',(-8.7,10.05,1.30),.218,'brass')
text_obj('Venue subtitle','ROOFTOP SOCIAL CLUB',(-8.7,10.05,1.07),.088,'linen')
text_obj('Bar identity','AFTER HOURS',(7.65,10.49,2.51),.15,'neon')
# A raised illuminated venue wordmark gives the pavilion a designed silhouette.
text_obj('Pavilion raised wordmark','THE LAST RESORT',(7.65,7.69,3.44),.235,'soft_light','ReactionGlow')
for x in (5.95,7.65,9.25):
    cylinder('Bar ivory plate',(x,8.78,.918),.103,.012,'ceramic',32)
    cylinder('Bar low tumbler',(x+.18,8.90,.984),.045,.13,'glass',20)
    cube('Folded linen napkin',(x-.18,8.89,.912),(.17,.21,.014),'linen',.008)

# Individually modeled waxy leaflets, curved rachises and layered planters.
def leaf(name,a,b,width,key='leaf',group='planting'):
    a,b=Vector(a),Vector(b);d=b-a;side=d.cross(Vector((0,0,1))).normalized()*width;c=a+d*.48+Vector((0,0,.035))
    return mesh(name,[a,c-side,c+Vector((0,0,.035)),c+side,b],[(0,1,2),(0,2,3),(1,4,2),(2,4,3)],key,group)
def agave(x,y,z,size=1):
    for i in range(15):
        a=i*2.39996;length=random.uniform(.3,.62)*size
        leaf('Agave tapered leaf',(x,y,z),(x+math.cos(a)*length,y+math.sin(a)*length,z+random.uniform(.18,.50)*size),.075*size,'leaf2' if i%4==0 else 'leaf')
def grasses(x,y,z,size=.6):
    verts=[];faces=[]
    for i in range(32):
        angle=random.random()*math.tau;reach=random.uniform(.10,.4)*size;height=random.uniform(.35,.75)*size
        a=Vector((x+random.uniform(-.09,.09),y+random.uniform(-.09,.09),z));b=a+Vector((math.cos(angle)*reach,math.sin(angle)*reach,height));mid=(a+b)*.5+Vector((0,0,height*.20));side=Vector((-math.sin(angle),math.cos(angle),0))*.014
        k=len(verts);verts.extend([a-side,a+side,mid+side*.8,mid-side*.8,b]);faces.extend([(k,k+1,k+2,k+3),(k+3,k+2,k+4)])
    mesh('Fine ornamental grasses',verts,faces,'leaf2','planting')
def planter(x,y,w,d):
    cube('Planter limestone vessel',(x,y,-.04),(w,d,.48),'stone',.055,'planting');cube('Planter dark recess',(x,y,.19),(w-.13,d-.13,.028),'earth',.035,'planting')
    for i in range(max(2,int(w/.42))):grasses(x-w*.40+i*w*.8/max(1,int(w/.42)-1),y,.21,.85)
for x,y,w,d in ((-9.45,3.38,2.45,1.10),(9.45,3.6,2.38,1.1),(-9.3,9.75,3.0,1.0),(-3.8,10.77,3.1,.8),(1.0,10.75,2.65,.8)):
    planter(x,y,w,d)
    for i in (-1,1):agave(x+i*w*.3,y,.22,.75)
def palm(x,y,h,lean=.35):
    base=.17;pts=[(x+lean*(t/18)**1.45,y+.10*math.sin(t/8),base+h*t/18) for t in range(19)];tube('Sculpted palm trunk',pts,.11,'bark','planting',14)
    for i in range(5,29):
        t=i/30;ring('Palm bark growth scar',(x+lean*t**1.45,y+.10*math.sin(t*18/8),base+h*t),.11*(1-t*.26),.005,'bark','planting')
    top=Vector(pts[-1])
    for i in range(12):
        angle=i*math.tau/12+random.uniform(-.08,.08);length=random.uniform(1.45,2.04);axis=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-axis.y,axis.x,0))
        def center(q):return top+axis*(length*q)+Vector((0,0,.53*math.sin(q*math.pi)-.62*q*q))
        tube('Palm curved rachis',[center(j/14) for j in range(15)],.018,'leaf','planting',6)
        for j in range(2,22):
            q=j/23;c=center(q);spread=(.17+.28*math.sin(math.pi*q))*(1-q*.43)
            for sign in (-1,1):
                tip=c+side*spread*sign+axis*(.23+.13*q)+Vector((0,0,-.085-.10*q))
                leaf('Individual palm leaflet',c,tip,.033*(1-q*.55),'leaf2' if (i+j)%7==0 else 'leaf')
    sphere('Palm crown',top-Vector((0,0,.04)),(.16,.16,.23),'leaf','planting')
for v in ((-9.9,3.7,5.4,.48),(10.0,4.0,5.85,-.32),(-9.9,9.7,4.6,.30)):palm(*v)

# Restrained lounge furniture with cushion seams, slim frames and realistic scale.
def lounge(x,y,rotation=0):
    g='furniture';before=set(scene.objects)
    for xx in (-.62,.62):
        for yy in (-.40,.40):cube('Sofa slender foot',(x+xx,y+yy,-.19),(.035,.035,.18),'brass',.006,g)
    cube('Sofa timber frame',(x,y,-.005),(1.46,.98,.17),'wood',.047,g)
    for xx in (-.34,.34):cube('Sofa separate cushion',(x+xx,y,.13),(.654,.84,.19),'linen',.08,g)
    back=cube('Sofa reclined backrest',(x,y+.40,.435),(1.45,.20,.69),'linen',.085,g);back.rotation_euler.x=math.radians(-7)
    for xx in (-.69,.69):cube('Sofa slim timber arm',(x+xx,y,.32),(.085,.91,.095),'wood',.027,g)
    for xx in (-.68,0,.68):cube('Sofa cushion seam',(x+xx,y-.428,.14),(.008,.006,.10),'stone',.001,g)
    for ob in set(scene.objects)-before:
        offset=ob.location-Vector((x,y,0));a=math.radians(rotation);ob.location=Vector((x+offset.x*math.cos(a)-offset.y*math.sin(a),y+offset.x*math.sin(a)+offset.y*math.cos(a),offset.z));ob.rotation_euler.z+=a
for v in ((-9.48,6.12,-10),(-8.80,8.32,12),(9.27,5.86,15)):lounge(*v)
for x,y in ((-8.9,4.84),(8.62,5.05),(-8.62,7.26)):
    cylinder('Cocktail table pedestal',(x,y,-.005),.045,.53,'dark',12,'furniture')
    cylinder('Cocktail table stone top',(x,y,.285),.34,.055,'stone',32,'furniture')
    cylinder('Cocktail table brass rim',(x,y,.279),.347,.022,'brass',32,'furniture')
    cylinder('Small frosted votive',(x+.08,y,.398),.043,.17,'soft_light',16,'ReactionGlow')
    cylinder('Votive brass foot',(x+.08,y,.319),.049,.018,'brass',16,'furniture')
    cylinder('Cocktail glass',(x-.13,y+.04,.38),.033,.125,'glass',12,'furniture')
for x,y in ((-7.8,10.9),(3.50,10.9),(10.3,6.55)):
    cube('Architectural bollard',(x,y,.25),(.065,.10,1.07),'dark',.017)
    cube('Bollard warm inset',(x,y-.053,.62),(.040,.012,.16),'soft_light',.005,'ReactionGlow')

# Six original anonymous, clothed guests grouped behind the pool. No stick crowd row.
def guest(x,y,h,pose=0,key='crowd',angle=0):
    z=deck_z;g='Crowd';s=h/1.75;before=set(scene.objects)
    def p(xx,yy,zz):return (x+xx*s,y+yy*s,z+zz*s)
    sphere('Guest jacket torso',p(0,0,1.16),(.195*s,.115*s,.28*s),key,g);sphere('Guest tailored hips',p(0,.005,.86),(.16*s,.105*s,.16*s),key,g)
    cylinder('Guest neck',p(0,0,1.48),.043*s,.10*s,'skin',12,g);sphere('Guest head',p(0,-.005,1.605),(.091*s,.085*s,.123*s),'skin',g);sphere('Guest hair',p(0,.022,1.673),(.094*s,.092*s,.065*s),'hair',g)
    sphere('Guest nose',p(0,-.085,1.594),(.021*s,.026*s,.029*s),'skin',g)
    for side in (-1,1):
        sphere('Guest ear',p(side*.091,0,1.60),(.014*s,.022*s,.034*s),'skin',g)
        lapel=cube('Guest linen collar',p(side*.050,-.073,1.428),(.073*s,.025*s,.085*s),'linen',.009,g);lapel.rotation_euler.y=side*.25
    for side in (-1,1):
        knee=p(side*.093,.01,.46);ankle=p(side*(.11 if pose%2 else .15),-.025,.09)
        tube('Guest trouser leg',[p(side*.085,0,.85),knee,ankle],.061*s,'trousers',g,10)
        sphere('Guest shoe',p(side*(.11 if pose%2 else .15),-.062,.04),(.063*s,.13*s,.043*s),'dark',g)
        shoulder=p(side*.17,0,1.34);elbow=p(side*.27,-.025,1.02 if side<0 else 1.17);hand=p(side*.22,-.15,.87 if side<0 else 1.35 if pose%2 else 1.02)
        tube('Guest jacket sleeve',[shoulder,elbow,hand],.055*s,key,g,10);sphere('Guest hand',hand,(.043*s,.033*s,.059*s),'skin',g)
    bpy.context.view_layer.update()
    turn=Matrix.Translation(Vector((x,y,0)))@Matrix.Rotation(math.radians(angle),4,'Z')@Matrix.Translation(Vector((-x,-y,0)))
    for ob in set(scene.objects)-before:ob.matrix_world=turn@ob.matrix_world
for v in ((-5.8,11.65,1.73,0,'crowd',45),(-5.1,11.68,1.64,1,'crowd2',-50),(2.4,11.65,1.79,1,'crowd',40),(3.15,11.68,1.68,0,'crowd2',-55),(6.1,10.15,1.76,1,'crowd',30),(9.2,10.2,1.69,0,'crowd',-30)):guest(*v)
for x in (-8.,8.):
    cylinder('Flush pyrotechnic housing',(x,.46,.024),.18,.048,'dark',24,'Vents');ring('Vent brushed bronze rim',(x,.46,.047),.16,.012,'brass','Vents')
    for i in range(5):cube('Vent dark grille',(x-.105+i*.0525,.46,.045),(.014,.21,.016),'brass',.003,'Vents')

# Only six quiet nearer towers: the engine's matte carries the distant skyline.
def tower(x,y,w,d,h,base,style):
    g='skyline';top=base+h;cube('City tower mass',(x,y,base+h/2-15),(w,d,h+30),'city_near',.025,g)
    cube('Curtain-wall glazing',(x,y-d/2-.016,base+h*.51-15),(w-.10,.025,h+30-.12),'city_glass',.003,g)
    stories=max(3,int(h/.48));step=h/stories;cols=max(3,int(w/.32));cw=(w-.16)/cols
    for floor in range(1,stories):
        z=base+floor*step;cube('City floor spandrel',(x,y-d/2-.034,z),(w-.06,.025,.018),'city_fins',0,g)
        for col in range(cols):
            if random.random()<.23:
                xx=x-w*.5+.10+(col+.5)*cw
                cube('City occupied window',(xx,y-d/2-.050,z+step*.41),(cw*.48,.012,step*.49),'city_windows' if random.random()<.8 else 'city_cool',0,g)
    for i in range(cols+1):cube('City curtain mullion',(x-w*.5+.08+i*cw,y-d/2-.04,base+h*.5),(.012,.022,h-.04),'city_fins',0,g)
    if style==0:
        cube('Tower setback',(x,y,top+.21),(w*.73,d*.78,.42),'city_near',.02,g);cube('Tower service penthouse',(x+.1,y+.1,top+.60),(w*.42,d*.49,.40),'city_near',.02,g)
    elif style==1:
        for j in range(3):cube('Stepped tower crown',(x,y,top+.16+j*.24),(w*(.8-j*.17),d*(.8-j*.15),.27),'city_near',.02,g)
        beam('City slender spire',(x,y,top+.8),(x,y,top+1.5),.015,'city_near',g)
    else:cube('Tower recessed roof cabin',(x-w*.18,y+.1,top+.22),(w*.35,d*.38,.44),'city_near',.018,g)
for v in ((-24,29,2.7,2.6,9.0,-9.8,0),(-18,32,2.1,2.0,7.5,-9.5,1),(-13.4,35,1.9,2.2,6.2,-10,2),(14.2,33,2.2,2.1,6.9,-10,0),(19,31,2.8,2.5,8.2,-10,2),(25,35,2.2,2.3,10.2,-11,1)):tower(*v)
for x in (-19,17):
    cube('Distant road deck',(x,20,-5.8),(8.0,.6,.08),'city_near',0,'skyline')
    for i in range(14):cube('Distant traffic lights',(x-3.8+i*.58,19.67,-5.72),(.047,.01,.015),'city_windows',0,'skyline')

print('MODELING_COMPLETE',len(scene.objects),flush=True)
scene['surface_inspection_fixed']=True
scene['pool_opening_fixed']=True
scene['crowd_depth_fixed']=True
scene['skyline_runtime_excluded']=True
scene['clear_balustrade']=True
for ob in groups['skyline']:ob.hide_render=True
for ob in groups['center_platform']:ob.location.z+=5.5
for im in bpy.data.images:
    if im.filepath:im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'the_last_resort_modeling.blend'))
for ob in groups['center_platform']:ob.location.z-=5.5
if '--source-only' in sys.argv:raise SystemExit(0)
for group,objects in groups.items():
    bymat={}
    for ob in objects:
        if ob.name in bpy.data.objects:bymat.setdefault(ob.data.materials[0].name,[]).append(ob)
    for material,objs in bymat.items():
        print('BATCH',group,material,len(objs),flush=True);bpy.ops.object.select_all(action='DESELECT')
        for ob in objs:ob.select_set(True)
        bpy.context.view_layer.objects.active=objs[0]
        # Bake this entire material batch in one dependency-graph evaluation.
        # Applying two modifiers with separate operators to each of thousands
        # of parts repeatedly rebuilds the entire scene graph.
        bpy.ops.object.convert(target='MESH')
        if len(objs)>1:bpy.ops.object.join()
        ob=bpy.context.object;ob.name=group+'__'+material.split(' | ')[0];bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');ob['group']=group;ob['source']='Original architecture revision 3 | tools/blender/stage_build.py'
center=[o for o in scene.objects if o.get('group')=='center_platform'];static=[o for o in scene.objects if o.type=='MESH' and o not in center and o.get('group')!='skyline']
def export(objs,path):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objs:ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_extras=True,export_apply=True)
export(center,OUT/'center_platform.glb');export(static,OUT/'stage.glb')
for ob in center:ob.location.z=5.5
def area(name,loc,power,color,size,target):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.shape='DISK';data.size=size
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=loc;ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
area('Warm architectural key',(-10,-8,13),1700,(1,.74,.49),9,(0,3,0));area('Cool sky fill',(6,-2,14),1500,(.53,.70,1),15,(0,3,1));area('Pool reflection fill',(-2,7,2),260,(.21,.68,.66),8,(0,0,1));area('Pavilion warm glow',(7.7,8.8,2.7),120,(1,.61,.29),3,(7.7,8,0))
sun_data=bpy.data.lights.new('Low evening sun','SUN');sun_data.energy=1.1;sun_data.color=(1,.75,.52);sun_data.angle=.09
sun=bpy.data.objects.new('Low evening sun',sun_data);scene.collection.objects.link(sun);sun.rotation_euler=(.7,-.7,-.65)
world=bpy.data.worlds.new('Blue hour architecture studio');scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.19,.27,1);world.node_tree.nodes['Background'].inputs[1].default_value=.45
cam_data=bpy.data.cameras.new('Architectural review camera');cam=bpy.data.objects.new('Architectural review camera',cam_data);scene.collection.objects.link(cam)
cam.location=(0,-28,13);target=Vector((0,4.8,1.5));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.type='ORTHO';cam_data.ortho_scale=25;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True;scene.render.resolution_x=1920;scene.render.resolution_y=1080;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(EVIDENCE/'stage_review.png')
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'the_last_resort.blend'))
report={'revision':3,'source':'tools/blender/stage_build.py','stage_objects':len(static),'center_objects':len(center),'mesh_vertices':sum(len(o.data.vertices) for o in static+center),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in static+center),'material_count':len(M),'original_texture_pngs':len(list(TEX.glob('*.png'))),'coordinate_contract':{'main_top_y':0,'main_x':[-9,9],'fixed_platforms':[{'x':-5,'y':3.6,'width':4.5},{'x':5,'y':3.6,'width':4.5}],'center_local_top_y':0,'center_default_y':5.5,'center_width':3.5,'platform_depth':1.45,'visual_only':True,'pyro_positions':[[-8,0,-.46],[8,0,-.46]],'pool_center':[-1.35,-.386,-6.35]}}
report['excluded_runtime_groups']=['skyline']
report['runtime_material_count']=len({m.name for o in static+center for m in o.data.materials})
(EVIDENCE/'stage_manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print('STAGE_EXPORT_OK',json.dumps(report),flush=True)
if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)
print('STAGE_BUILD_OK',flush=True)
