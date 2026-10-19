"""Fitted garment corrections, applied without regenerating curated motion."""
import bpy, math, json, sys, hashlib, shutil
from pathlib import Path
from datetime import datetime, timezone
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/blender'))


def correct_costume(rig,mesh,fid):
    from hero_rebuild import material, capsule_curve, sphere
    if fid not in ['f01_clutch','f05_fine_print','f07_urban_sentinel']:return
    # Remove projected triangle selections whose boundaries folded at the scan
    # seams. These are additions only; source-derived body geometry is untouched.
    remove=['technical side panel','shoulder layer','waist band','tailored waistcoat',
            'tailored chest seam','articulated chest guard','red chest armour edge',
            'pewter vest button','Refined ']
    for obj in list(bpy.data.objects):
        if obj.type=='MESH' and obj!=mesh and any(tag in obj.name for tag in remove):
            bpy.data.objects.remove(obj,do_unlink=True)
    source_groups={g.index:g.name for g in mesh.vertex_groups}
    torso_faces=[p for p in mesh.data.polygons if sum(sum(g.weight for g in mesh.data.vertices[vi].groups if source_groups[g.group] in ['pelvis','spine','chest','neck']) for vi in p.vertices)/len(p.vertices)>.6]
    surface=BVHTree.FromPolygons([v.co for v in mesh.data.vertices],[list(p.vertices) for p in torso_faces])
    h=json.loads(rig['prepared_stats'])['height']/1.84
    accent=material('Refined accent '+fid,(.015,.46,.64,1) if fid=='f01_clutch' else (.50,.018,.024,1) if fid=='f07_urban_sentinel' else (.10,.15,.14,1),.15,.46)
    dark=material('Refined woven tailoring '+fid,(.019,.029,.038,1),.02,.68)
    groups={g.index:g.name for g in mesh.vertex_groups}

    def front(x,z,offset=.008):
        hit,normal,face,_=surface.ray_cast(Vector((x,-.7,z)),Vector((0,1,0)),1.2)
        if hit is None:
            nearest=surface.find_nearest(Vector((x,-.12,z)))
            hit=nearest[0];normal=nearest[1];face=nearest[2]
        p=Vector((x,hit.y,z))+normal.normalized()*offset+Vector((0,-.004,0))
        if fid=='f05_fine_print':
            # Smooth woven front follows a fitted elliptical chest envelope.
            # Projecting every row onto scan folds produced a saw-tooth side hem.
            t=max(0,min(1,(z/h-.997)/.505));rx=.225-.018*t**5
            depth=.147-.025*t**4
            p=Vector((x,-depth*math.sqrt(max(.08,1-(x/rx)**2))-.010,z))
        # Interpolate the existing torso skin by inverse distance. Preserve four
        # normalized influences, so the garment follows the underlying body.
        weights={};total=0
        for vi in torso_faces[face].vertices:
            vertex=mesh.data.vertices[vi];w=1/max(.001,(vertex.co-hit).length)**2;total+=w
            for group in vertex.groups:
                name=groups[group.group];weights[name]=weights.get(name,0)+group.weight*w
        if fid=='f05_fine_print':
            from hero_skinning import torso_weights
            weights=list(torso_weights(rig,z).items())
        else:
            weights=sorted(((n,w/total) for n,w in weights.items()),key=lambda item:item[1],reverse=True)[:4]
        norm=sum(w for n,w in weights)
        return p,{n:w/norm for n,w in weights}

    def garment(name,verts,faces,weights,mat):
        data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
        obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);obj.parent=rig
        obj['character_asset']=True;data.materials.append(mat)
        vertexgroups={n:obj.vertex_groups.new(name=n) for n in sorted({n for ws in weights for n in ws})}
        for vi,ws in enumerate(weights):
            for n,w in ws.items():vertexgroups[n].add([vi],w,'REPLACE')
        for poly in data.polygons:poly.use_smooth=True
        solid=obj.modifiers.new('Finished woven edge','SOLIDIFY');solid.thickness=.002
        bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.modifier_apply(modifier=solid.name)
        arm=obj.modifiers.new('Fitted torso binding','ARMATURE');arm.object=rig
        return obj

    def seam(name,points,radius,mat):
        # The trim follows precisely the same skin weights as its garment.
        centers=[front(x,z,.013) for x,z in points];verts=[];weights=[];faces=[]
        for j,(center,ws) in enumerate(centers):
            tangent=(centers[min(j+1,len(centers)-1)][0]-centers[max(0,j-1)][0]).normalized()
            a=tangent.cross(Vector((0,1,0))).normalized();b=tangent.cross(a).normalized()
            for k in range(8):
                verts.append(center+radius*(a*math.cos(k*math.tau/8)+b*math.sin(k*math.tau/8)));weights.append(ws)
        for j in range(len(centers)-1):
            for k in range(8):faces.append((j*8+k,j*8+(k+1)%8,(j+1)*8+(k+1)%8,(j+1)*8+k))
        return garment(name,verts,faces,weights,mat)

    if fid!='f05_fine_print':
        for sign in ([-1,1] if fid=='f01_clutch' else []):
            # Narrow fitted seams retain original sportswear/hoodie construction.
            seam('Refined '+fid+' chest seam '+str(sign),[(sign*(.112+.012*math.sin(i/12*math.pi)),(1.18+.19*i/12)*h) for i in range(13)],.0025,accent)
        if fid=='f07_urban_sentinel':
            # A slim central red zip line echoes the existing jacket; shoulder
            # bulk now comes from the broadened silhouette, without loose plates.
            seam('Refined Sentinel chest zip',[(.012,(1.17+.23*i/12)*h) for i in range(13)],.0028,accent)
        return

    # Two halves meet below the V neck, extending to a pointed waist hem. Smooth
    # regular quads have continuous garment edges independent of scan triangles.
    rows=31;columns=19
    for sign in [-1,1]:
        verts=[];weights=[];faces=[]
        for j in range(rows):
            t=j/(rows-1);z=(.997+.505*t)*h
            inner=max(0,(t-.56)/.44)*.087
            outer=.183+.009*math.sin(t*math.pi)-.025*t**5
            for k in range(columns):
                u=k/(columns-1);x=sign*(inner+(outer-inner)*u)
                # Pointed hem and curved armhole provide a recognizable waistcoat.
                zz=z+(1-t)**9*(.027*u)*h
                p,ws=front(x,zz,.010);verts.append(p);weights.append(ws)
        for j in range(rows-1):
            for k in range(columns-1):
                a=j*columns+k;face=(a,a+1,a+columns+1,a+columns)
                faces.append(face if sign>0 else tuple(reversed(face)))
        garment('Refined Fine Print fitted vest '+str(sign),verts,faces,weights,dark)
        neckline=[]
        for j in range(14):
            t=.56+.44*j/13;neckline.append((sign*(max(0,(t-.56)/.44)*.087+.003),(.997+.505*t)*h))
        seam('Refined Fine Print rolled lapel '+str(sign),neckline,.0035,accent)
    seam('Refined Fine Print button placket',[(0,(1.035+.235*i/15)*h) for i in range(16)],.002,accent)
    buttonmat=material('Refined Fine Print pewter',(.25,.29,.28,1),.7,.3)
    for z in [1.075,1.140,1.205,1.270]:
        p,_=front(0,z*h,.017)
        sphere('Refined Fine Print button '+str(z),p,(.005,.0025,.005),buttonmat,rig,'spine' if z<1.25 else 'chest')


def repair(fid):
    from hero_export import action_signature,export_curated
    folder=ROOT/'source_art/characters'/fid;source=folder/'curated.blend'
    before=hashlib.sha256(source.read_bytes()).hexdigest()
    revisions=folder/'revisions';revisions.mkdir(exist_ok=True)
    shutil.copy2(source,revisions/(datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'_'+before[:12]+'.blend'))
    bpy.ops.wm.open_mainfile(filepath=str(source));rig=bpy.data.objects['FighterRig'];mesh=bpy.data.objects['CharacterMesh']
    signatures={a.name:action_signature(a) for a in bpy.data.actions}
    correct_costume(rig,mesh,fid)
    assert signatures=={a.name:action_signature(a) for a in bpy.data.actions},'Costume edit changed choreography'
    bpy.ops.wm.save_as_mainfile(filepath=str(source));export_curated(fid,source)
    report={'fighter':fid,'previous_curated_sha256':before,'new_curated_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'all_animation_curves_preserved':True}
    (ROOT/'evidence/characters/hero_rebuild'/(fid+'_tailoring.json')).write_text(json.dumps(report,indent=2))
    print('TAILORING_REPAIR',json.dumps(report),flush=True)


if __name__=='__main__':
    for fid in sys.argv[sys.argv.index('--')+1:]:repair(fid)
