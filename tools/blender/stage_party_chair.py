"""Original matching teak lounge chair; separate Party cosmetic, no collision."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'source_art/stage';OUT=ROOT/'Game File/assets/stage';TEX=SRC/'textures'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;M={};parts=[]
def material(key,color,metal=0):
    m=bpy.data.materials.new('Party chair | '+key);m.diffuse_color=(*color,1);m.use_nodes=True;bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.47;bs.inputs['Metallic'].default_value=metal
    for suffix,socket in (('color','Base Color'),('roughness','Roughness'),('normal','Normal')):
        path=TEX/(key+'_'+suffix+'.png')
        if not path.exists():continue
        im=bpy.data.images.load(str(path));im.pack()
        if suffix!='color':im.colorspace_settings.name='Non-Color'
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im
        if suffix=='normal':
            normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.35;m.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs['Normal'],bs.inputs[socket])
        else:m.node_tree.links.new(tex.outputs['Color'],bs.inputs[socket])
    M[key]=m
material('wood',(.235,.132,.062));material('linen',(.51,.49,.42));material('brass',(.42,.29,.14),.78)
def box(name,loc,size,key,bevel=.02,tilt=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.rotation_euler.x=tilt
    uv=o.data.uv_layers.active
    for f in o.data.polygons:
        axes=[i for i in range(3) if i!=max(range(3),key=lambda i:abs(f.normal[i]))]
        for idx in f.loop_indices:
            co=o.data.vertices[o.data.loops[idx].vertex_index].co;uv.data[idx].uv=(co[axes[0]],co[axes[1]])
    b=o.modifiers.new('Soft timber edge','BEVEL');b.width=min(bevel,min(size)*.42);b.segments=4;o.modifiers.new('Weighted normal','WEIGHTED_NORMAL');o.data.materials.append(M[key]);parts.append(o);return o
def beam(name,a,b,r,key):
    a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(M[key]);parts.append(o)
    be=o.modifiers.new('Rounded end','BEVEL');be.width=.007;be.segments=3;o.modifiers.new('Weighted normal','WEIGHTED_NORMAL')
    for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
for x in (-.28,.28):
    for y in (-.245,.245):beam('Splayed teak leg',(x,y,.025),(x*.86,y*.87,.44),.026,'wood')
    beam('Slender back upright',(x,.21,.36),(x,.37,.93),.025,'wood')
    box('Rounded solid teak arm',(x,-.018,.615),(.061,.60,.052),'wood',.021)
    beam('Arm front support',(x,-.22,.405),(x,-.22,.588),.019,'wood')
    beam('Side stretcher',(x,-.228,.27),(x,.237,.27),.013,'wood')
box('Open seat frame',(0,0,.407),(.60,.57,.052),'wood',.017)
box('Tailored linen seat',(0,-.014,.451),(.535,.515,.081),'linen',.039)
for i in range(6):
    z=.58+i*.061;y=.252+(z-.40)*.27
    box('Horizontal sculpted back slat',(0,y,z),(.565,.035,.043),'wood',.015,math.radians(-15))
box('Rounded top rail',(0,.366,.945),(.62,.056,.052),'wood',.023,math.radians(-15))
for x in (-.279,.279):
    for y in (-.245,.245):box('Recessed brass foot',(x,y,.018),(.034,.034,.015),'brass',.006)
for o in parts:
    bpy.context.view_layer.objects.active=o
    for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
minimum=min((o.matrix_world@v.co).z for o in parts for v in o.data.vertices)
for o in parts:o.location.z-=minimum
scene.unit_settings.system='METRIC'
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'party_chair.blend'))
material_parts={key:[o for o in parts if o.data.materials[0]==mat] for key,mat in M.items()}
for key,objs in material_parts.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=bpy.context.object;o.name='Party chair__'+key
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True);scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
objects=[o for o in scene.objects if o.type=='MESH'];bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/'party_chair.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
bounds=[min((o.matrix_world@v.co)[i] for o in objects for v in o.data.vertices) for i in range(3)],[max((o.matrix_world@v.co)[i] for o in objects for v in o.data.vertices) for i in range(3)]
report={'source':'tools/blender/stage_party_chair.py','meshes':len(objects),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objects),'blender_bounds':bounds,'godot_height':bounds[1][2],'ground_origin':True,'forward_godot':'+Z','runtime_scale':1.0}
(ROOT/'evidence/stage/party_chair_manifest.json').write_text(json.dumps(report,indent=2));print('PARTY_CHAIR_OK',report)
