"""Structured coat surfaces around preserved source fronts and trousers.

The input scan joins its sleeves to the flank in a resting pose. Reweighting
that web alone stretches triangles across an open armpit. Rebuild those cloth
surfaces with separate sleeve and torso topology, never touching actions.
"""
import bpy, bmesh, math, json
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def rebuild_coat(rig, fid):
    if fid not in ['f06_rugged_explorer', 'f08_midnight_gentleman']:
        return {}
    from hero_skinning import torso_weights, smooth
    mesh = bpy.data.objects['CharacterMesh']
    h = json.loads(rig['prepared_stats'])['height'] / 1.84
    for obj in list(bpy.data.objects):
        if obj!=mesh and obj.type=='MESH' and any(s in obj.name for s in ['waist band','tailored chest seam','Gentleman waist chain']):
            bpy.data.objects.remove(obj,do_unlink=True)
    # Retained front fabric and new side panels share the same smooth torso
    # weights; different automatic bind gradients otherwise separate their seam.
    for v in mesh.data.vertices:
        if v.co.y<-.02 and abs(v.co.x)<.20*h and 1.06*h<v.co.z<1.51*h:
            for g in list(v.groups):mesh.vertex_groups[g.group].remove([v.index])
            for n,w in torso_weights(rig,v.co.z).items():
                group=mesh.vertex_groups.get(n) or mesh.vertex_groups.new(name=n);group.add([v.index],w,'REPLACE')
    # Cut actual edges at the waist replacement boundaries. Selecting faces by
    # center alone leaves long scanned triangles protruding beyond the new hem.
    bm=bmesh.new();bm.from_mesh(mesh.data)
    for z in [1.075*h,1.115*h]:
        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
            dist=.000001,plane_co=Vector((0,0,z)),plane_no=Vector((0,0,1)),
            clear_inner=False,clear_outer=False)
    bm.to_mesh(mesh.data);bm.free();mesh.data.update()
    mesh.data.calc_loop_triangles()
    points = [v.co.copy() for v in mesh.data.vertices]
    triangles = [tuple(t.vertices) for t in mesh.data.loop_triangles]
    source_surface = BVHTree.FromPolygons(points, triangles, all_triangles=True)
    from hero_rebuild import material
    # The scan has discontinuous packed UV islands across its fused sleeves.
    # Nearest-UV transfer cannot interpolate those islands onto regular quads.
    # Purpose-built woven panels use a coherent cloth material instead.
    fabric = material('Tailored coat fabric '+fid,
        (.115,.087,.057,1) if fid=='f06_rugged_explorer' else (.025,.036,.053,1),.025,.79)
    materials = [fabric]

    def make_surface(name, verts, faces, weights):
        data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
        obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
        obj.parent=rig;obj['character_asset']=True
        for material in materials:data.materials.append(material)
        uv=data.uv_layers.new(name='UVMap')
        for poly in data.polygons:
            poly.use_smooth=True
            poly.material_index=0
            for li in poly.loop_indices:
                point=data.vertices[data.loops[li].vertex_index].co
                uv.data[li].uv=(point.x,point.z)
        groups={name:obj.vertex_groups.new(name=name) for name in sorted({n for ws in weights for n in ws})}
        for i,ws in enumerate(weights):
            total=sum(ws.values())
            for name,w in ws.items():
                if w>0.00001:groups[name].add([i],w/total,'REPLACE')
        mod=obj.modifiers.new('Tailored cloth skin','ARMATURE');mod.object=rig
        return obj

    # Continuous torso rings replace the fused flank region. Collars, heads,
    # central front textures, trousers and independent equipment remain source.
    verts=[];faces=[];weights=[];rows=39;segments=64
    for j in range(rows):
        t=j/(rows-1);z=(.90+.61*t)*h
        # Sculpted waist, chest and shoulder envelope in normalized body units.
        rx=(.222+.010*math.sin(t*math.pi)-.033*t**8)*h
        ry=(.137+.007*math.sin(t*math.pi)-.024*t**5)*h
        for k in range(segments):
            theta=k*math.tau/segments
            p=Vector((rx*math.cos(theta),.005+ry*math.sin(theta),z))
            # Source front/back wrinkles are shallow: retain their depth without
            # including the fused arm geometry at the sides of the torso.
            if abs(math.sin(theta))>.5:
                hit,normal,_,distance=source_surface.find_nearest(p)
                if distance<.035 and abs(hit.x-p.x)<.02:
                    p.y=p.y*.65+hit.y*.35
            if p.y<0:p.y*=.45
            verts.append(p);weights.append(torso_weights(rig,z))
    for j in range(rows-1):
        for k in range(segments):
            a=j*segments+k;b=j*segments+(k+1)%segments
            face=(a,b,b+segments,a+segments)
            center=sum((verts[i] for i in face),Vector())/4
            # Keep the original shirt, tie, lapels and front closure visible.
            # A narrow overlap hides the boundary behind the retained front.
            if not(center.y<0 and abs(center.x)<.140*h):faces.append(face)
    make_surface('Retopologized fitted coat body '+fid,verts,faces,weights)
    # A continuous inset lining closes the retained front/side overlap, even
    # where the original open-front scan has no interior cloth surface.
    inner_verts=[];inner_faces=[];inner_weights=[]
    for j in range(25):
        z=(.95+.51*j/24)*h
        for k in range(48):
            theta=k*math.tau/48
            inner_verts.append(Vector((.181*h*math.cos(theta),.004+.025*h*math.sin(theta),z)))
            inner_weights.append(torso_weights(rig,z))
    for j in range(24):
        for k in range(48):
            a=j*48+k;b=j*48+(k+1)%48;inner_faces.append((a,b,b+48,a+48))
    make_surface('Continuous coat lining '+fid,inner_verts,inner_faces,inner_weights)

    # Each sleeve is a continuous shoulder-to-cuff surface. A rounded shoulder
    # cap overlaps the torso and shoulder fabric; the elbow has shared influences.
    for side in ['L','R']:
        upper=rig.data.bones['upper_arm.'+side];fore=rig.data.bones['forearm.'+side]
        axis=(upper.tail_local-upper.head_local).normalized()
        a=axis.cross(Vector((0,1,0))).normalized();b=axis.cross(a).normalized()
        verts=[];faces=[];weights=[];rows=37;segments=32
        for j in range(rows):
            t=j/(rows-1)
            if t<.51:
                q=(t-.035)/.475
                center=upper.head_local.lerp(upper.tail_local,q)
                radius=(.079-.018*max(0,q))*h
                radius*=smooth(0,.055,t)*.45+.55
            else:
                q=(t-.51)/.49
                center=fore.head_local.lerp(fore.tail_local,q)
                radius=(.061-.017*q)*h
            shoulder=1-smooth(.0,.15,t)
            elbow=smooth(.40,.64,t)
            ws={'chest':shoulder*.35,'clavicle.'+side:shoulder*.30,
                'upper_arm.'+side:(1-shoulder*.65)*(1-elbow),'forearm.'+side:(1-shoulder*.65)*elbow}
            for limb,amount in [('upper_arm',.25*smooth(.08,.30,t)),('forearm',.35*smooth(.56,.90,t))]:
                moved=ws[limb+'.'+side]*amount;ws[limb+'.'+side]-=moved;ws[limb+'_twist.'+side]=moved
            for k in range(segments):
                theta=k*math.tau/segments
                # Subtle controlled seam folds remain convex and cannot create
                # the open scan flaps that this replacement removes.
                fold=1+.025*math.sin(theta*4+t*22)*math.sin(math.pi*t)**2
                p=center+radius*fold*(a*math.cos(theta)+b*math.sin(theta))
                verts.append(p);weights.append(ws)
        for j in range(rows-1):
            for k in range(segments):
                a0=j*segments+k;b0=j*segments+(k+1)%segments
                faces.append((a0,b0,b0+segments,a0+segments))
        faces.append(tuple(reversed(range(segments))))
        faces.append(tuple((rows-1)*segments+k for k in range(segments)))
        make_surface('Retopologized fitted sleeve '+side+' '+fid,verts,faces,weights)
        from hero_rebuild import sphere
        sphere('Tailored shoulder join '+side,upper.head_local,(.081,.086,.091),fabric,rig,'upper_arm.'+side)

    # Delete complete source regions, rather than isolated triangles selected in
    # a bent pose. New body/sleeve surfaces cover both sides of the clean overlap.
    selected=[];groupmap={g.index:g.name for g in mesh.vertex_groups}
    for p in mesh.data.polygons:
        z=p.center.z/h;x=abs(p.center.x)/h
        front=p.center.y<-.02 and x<.198 and z>1.065
        leg=sum(sum(g.weight for g in mesh.data.vertices[i].groups if groupmap[g.group].startswith(('thigh.','shin.','foot.','toe.'))) for i in p.vertices)/len(p.vertices)
        arm=sum(sum(g.weight for g in mesh.data.vertices[i].groups if groupmap[g.group].startswith(('upper_arm','forearm','hand.'))) for i in p.vertices)/len(p.vertices)
        original_arm=sum(mesh.data.attributes['.original_arm_weight'].data[i].value for i in p.vertices)/len(p.vertices)
        body=1.075<z<1.505 and x<.275 and not front and leg<.1
        sleeve=(.935<z<1.535 and x>.19 and leg<.02 and (arm>.45 or z>1.115)) or (.78<z<1.16 and x>.20 and original_arm>.72 and leg<.20)
        old_hem=1.075<z<1.115 and x<.40 and leg<.02 and not front
        if body or sleeve or old_hem:selected.append(p.index)
    # Remove residual fused wrist-to-hip triangles lying across the regional
    # boundary. These are objectively identified from edge stretch in hard poses.
    selected=set(selected);rest=[v.co.copy() for v in mesh.data.vertices]
    from pathlib import Path
    root=Path(__file__).resolve().parents[2]
    tick=json.loads((root/'docs/moves/move_timing.json').read_text())['fighters'][fid]['moves']['heavy_side']['startup']+1
    for clip,frame in [('heavy_side',tick),('qa_shoulder_raise',31),('qa_torso_twist',31)]:
        rig.animation_data.action=bpy.data.actions[clip];bpy.context.scene.frame_set(frame)
        evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());data=evaluated.to_mesh()
        for polygon in mesh.data.polygons:
            if polygon.index in selected or not .76<polygon.center.z/h<1.57:continue
            ids=list(polygon.vertices)
            for a,b in zip(ids,ids[1:]+ids[:1]):
                before=(rest[a]-rest[b]).length;after=(data.vertices[a].co-data.vertices[b].co).length
                if after>.055 and after>before*2.5:selected.add(polygon.index);break
        evaluated.to_mesh_clear()
    bm=bmesh.new();bm.from_mesh(mesh.data);bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[bm.faces[i] for i in selected],context='FACES')
    # Remove isolated old coat scraps at the waist left behind by the fused
    # surface cut. Connected trouser legs and the retained front are excluded.
    remaining=set(bm.faces);scraps=[]
    while remaining:
        first=remaining.pop();island={first};stack=[first]
        while stack:
            face=stack.pop()
            for edge in face.edges:
                for other in edge.link_faces:
                    if other in remaining:remaining.remove(other);island.add(other);stack.append(other)
        zs=[v.co.z/h for face in island for v in face.verts]
        if min(zs)>.76 and max(zs)<1.17:scraps.extend(island)
    if scraps:bmesh.ops.delete(bm,geom=scraps,context='FACES')
    for vertex in bm.verts:
        if any(e.is_boundary for e in vertex.link_edges) and 1.09*h<vertex.co.z<1.14*h:
            vertex.co.z=1.115*h
    bm.to_mesh(mesh.data);bm.free();mesh.data.update()
    return {'source_faces_replaced':len(selected),'coverage':'structured woven coat panels and continuous capped sleeves; original trouser geometry and leg weights retained'}
