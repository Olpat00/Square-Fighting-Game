"""Verify real GLB skins/animated channels/source hashes and assemble labeled real renders."""
import json,struct,hashlib,math,re,io
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'evidence/characters'

def read_glb(path):
    data=path.read_bytes();length,kind=struct.unpack_from('<II',data,12)
    assert kind==0x4e4f534a
    j=json.loads(data[20:20+length]);off=20+length
    blen,bkind=struct.unpack_from('<II',data,off);assert bkind==0x004e4942
    return j,data[off+8:off+8+blen]

def accessor(j,bin,index):
    a=j['accessors'][index];v=j['bufferViews'][a['bufferView']];fmt={5126:'f',5123:'H',5125:'I',5121:'B'}[a['componentType']]
    n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];size=struct.calcsize(fmt)*n;stride=v.get('byteStride',size)
    start=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*n,bin,start+i*stride) for i in range(a['count'])]

def inspect():
    reports=[];mapping=[]
    explicit_path=ROOT/'docs/confirmed_character_mapping.json'
    explicit=json.loads(explicit_path.read_text()) if explicit_path.exists() else {}
    source_ids={'Wes':'f01_clutch','Jaydon':'f04_deadfall','Josh':'f05_fine_print',
      'Rugged Explorer':'f06_rugged_explorer','Urban Sentinel':'f07_urban_sentinel',
      'Midnight Gentleman':'f08_midnight_gentleman'}
    source_ids.update({folder:fid for fid,folder in explicit.items() if fid.startswith('f0') and folder})
    required_source=(ROOT/'Game File/characters/fighter_definition.gd').read_text()
    required=set(re.findall(r'"([a-z_0-9]+)"',re.search(r'const REQUIRED_ANIMATIONS.*?=\s*\[(.*?)\]',required_source,re.S)[1]))
    required.update(re.findall(r'"([a-z_0-9]+)"',re.search(r'const REQUIRED_MOVES.*?=\s*\[(.*?)\]',required_source,re.S)[1]))
    for mp in sorted(OUT.glob('*_manifest.json')):
        m=json.loads(mp.read_text());fid=m['fighter_id'];p=ROOT/m['output']
        if not p.exists():continue
        source_folder=Path(m['source_path']).parts[-2]
        canonical=source_ids.get(source_folder)
        m['canonical_fighter_id']=canonical
        m['selectable_runtime_fighter']=fid==canonical
        if canonical and fid!=canonical:
            m['mapping']='Archived neutral derivative; source identity confirmed as '+canonical
        elif fid in explicit and explicit[fid]:
            m['mapping']='User-confirmed 2026-09-22: '+source_folder+' -> '+fid
        j,b=read_glb(p);names={a['name'] for a in j.get('animations',[])}
        varying={};duration_errors=[];durations={}
        expected={a['name']:(a['frames']-1)/60 for a in m['animations']}
        for a in j.get('animations',[]):
            changed=0
            end=max(max(t[0] for t in accessor(j,b,sam['input'])) for sam in a['samplers'])
            durations[a['name']]=end
            if abs(end-expected.get(a['name'],end))>.001:duration_errors.append([a['name'],end,expected[a['name']]])
            for sam in a['samplers']:
                vals=accessor(j,b,sam['output'])
                if any(any(abs(u-v)>1e-5 for u,v in zip(vals[0],x)) for x in vals[1:]):changed+=1
            varying[a['name']]=changed
        source=ROOT/m['source_path'];sha=hashlib.sha256(source.read_bytes()).hexdigest()
        skin=j.get('skins',[]);stats=dict(fighter_id=fid,canonical_fighter_id=canonical,selectable_runtime_fighter=fid==canonical,skin_count=len(skin),bone_count=len(skin[0]['joints']) if skin else 0,
          animation_count=len(names),missing_animations=sorted(required-names),constant_only_clips=[n for n,k in varying.items() if k==0],
          animated_channel_counts=varying,source_hash_unchanged=sha==m['source_sha256'],runtime_bytes=p.stat().st_size,
          finite_animation_values=True,runtime_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),animation_duration_errors=duration_errors,
          animation_durations=durations,maximum_skin_weight_sum_error=0)
        for mesh in j.get('meshes',[]):
            for primitive in mesh['primitives']:
                if 'WEIGHTS_0' not in primitive['attributes']:continue
                index=primitive['attributes']['WEIGHTS_0'];values=accessor(j,b,index)
                divisor=65535 if j['accessors'][index].get('normalized') and j['accessors'][index]['componentType']==5123 else 255 if j['accessors'][index].get('normalized') and j['accessors'][index]['componentType']==5121 else 1
                stats['maximum_skin_weight_sum_error']=max(stats['maximum_skin_weight_sum_error'],max(abs(sum(row)/divisor-1) for row in values))
        for a in j.get('animations',[]):
            for sam in a['samplers']:
                if not all(math.isfinite(x) for val in accessor(j,b,sam['output']) for x in val):stats['finite_animation_values']=False
        stats['structural_pass']=bool(skin) and not stats['missing_animations'] and not stats['constant_only_clips'] and stats['source_hash_unchanged'] and stats['finite_animation_values'] and not duration_errors and stats['maximum_skin_weight_sum_error']<.001
        engine_report=OUT/'engine/engine_validation.json'
        if (ROOT/'source_art/characters'/fid/'curated.blend').exists():
            # Historical September runtime captures exercised different models.
            # Structural inspection must not promote that evidence to acceptance
            # of a newly exported hero asset.
            m['validation']={'structural_pass':stats['structural_pass'],
                'runtime_sha256':stats['runtime_sha256'],
                'current_asset_evidence':'evidence/characters/hero_rebuild/asset_validation.json',
                'runtime_validation_record':'evidence/rebuild/animation_scenarios.json'}
            m['pending_validation']=['Review current runtime evidence and continuous capture; historical September renders do not validate this export']
            mp.write_text(json.dumps(m,indent=2))
        elif engine_report.exists():
            checked=next((f for f in json.loads(engine_report.read_text())['fighters'] if f['id']==fid),None)
            review=ROOT/'evidence/presentation/VISUAL_REVIEW.md'
            reviewed=fid in ('f01_clutch','f02_sunstruck','f03_heavy_duty','f04_deadfall','f05_fine_print') and fid==canonical and review.exists()
            m['validation']={'structural_pass':stats['structural_pass'],'godot_sampled_all_clips':bool(checked and not checked.get('invalid_bone_transforms')),
                'selected_pose_visual_review':reviewed,'visual_review_record':'evidence/presentation/VISUAL_REVIEW.md' if reviewed else None,
                'engine_evidence':'evidence/characters/engine','source_contact_sheet':'evidence/characters/'+fid+'_contact_sheet.jpg'}
            m['pending_validation']=[] if reviewed else ['Godot visual playback and contact-sheet review'] if fid==canonical else ['Archived source derivative; not part of current canonical gameplay acceptance']
            mp.write_text(json.dumps(m,indent=2))
        # Non-destructive, lower texture tier for future graphics profiles. The shipped
        # GLB keeps 2K texture detail; these are editable/exportable 1K source derivatives.
        variants=ROOT/'source_art/characters'/fid/'texture_variants_1024';variants.mkdir(exist_ok=True)
        texture_variants=[]
        for i,im in enumerate(j.get('images',[])):
            if 'bufferView' not in im:continue
            v=j['bufferViews'][im['bufferView']];start=v.get('byteOffset',0)
            src=Image.open(io.BytesIO(b[start:start+v['byteLength']]))
            src.thumbnail((1024,1024),Image.Resampling.LANCZOS)
            target=variants/(str(i)+'_'+re.sub(r'[^a-zA-Z0-9_-]','_',im.get('name','texture'))+'.png')
            src.save(target);texture_variants.append(str(target.relative_to(ROOT)))
        m['texture_variants_1024']=texture_variants
        reports.append(stats);mapping.append(m)
    (OUT/'export_validation.json').write_text(json.dumps(reports,indent=2))
    (ROOT/'docs/asset_manifest.json').write_text(json.dumps(mapping,indent=2))
    validation_doc=ROOT/'docs/animation_validation.md'
    if validation_doc.exists():
        titles={'f01_clutch':'Clutch / Wes','f02_sunstruck':'Sunstruck / Will','f03_heavy_duty':'Heavy Duty / Damion','f04_deadfall':'Deadfall / Jaydon','f05_fine_print':'Fine Print / Josh',
          'f06_rugged_explorer':'Rugged Explorer','f07_urban_sentinel':'Urban Sentinel','f08_midnight_gentleman':'Midnight Gentleman'}
        table='| Asset | Mapping status | Original triangles | Runtime triangles | Exported bones | Keyed clips | GLB bytes |\n| --- | --- | ---: | ---: | ---: | ---: | ---: |\n'
        for m,s in zip(mapping,reports):
            st=m['stats'];label=titles.get(m['fighter_id'],m['fighter_id']);status='User supplied' if m['fighter_id'] in ('f06_rugged_explorer','f07_urban_sentinel','f08_midnight_gentleman') else 'User confirmed' if m['fighter_id'] in explicit else 'Clothing confirmed' if m['fighter_id'] in titles else 'Archived source copy'
            table+=f"| {label} | {status} | {st['source_triangles']:,} | {st['runtime_triangles']:,} | {s['bone_count']} | {s['animation_count']} | {s['runtime_bytes']:,} |\n"
        body=validation_doc.read_text(encoding='utf-8')
        validation_doc.write_text(re.sub(r'\| Asset \|.*?(?=\n\n)',table.rstrip(),body,flags=re.S),encoding='utf-8')
    for rep in reports:print(rep['fighter_id'],'PASS' if rep['structural_pass'] else 'FAIL','clips',rep['animation_count'],'bones',rep['bone_count'],'missing',rep['missing_animations'],'constant',rep['constant_only_clips'])

def sheets():
    font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',21)
    small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',16)
    names=['idle','run','jump_rise','jab1','special_neutral','special_side','special_up','special_down','ultimate','ultimate_finisher','qa_shoulder_raise','qa_elbow_bend','qa_knee_bend','qa_torso_twist','qa_deep_pose']
    portraits=ROOT/'Game File/assets/portraits';portraits.mkdir(parents=True,exist_ok=True)
    for d in OUT.iterdir():
        # Only actual per-character preview folders may produce portraits.
        # The engine fixture also has idle.png but shows the entire roster.
        if not d.is_dir() or not (d/'idle.png').exists() or not (OUT/(d.name+'_manifest.json')).exists():continue
        selected=[(n,d/(n+'.png')) for n in names if (d/(n+'.png')).exists()]
        cols=5;rows=(len(selected)+cols-1)//cols;w=340;h=365
        sheet=Image.new('RGB',(cols*w,rows*h+65),(13,19,30));draw=ImageDraw.Draw(sheet)
        draw.text((18,14),d.name+' — actual Blender skin and motion evidence',font=font,fill=(233,240,250))
        for i,(name,p) in enumerate(selected):
            im=Image.open(p).convert('RGB');im.thumbnail((w-10,w-10));x=(i%cols)*w+5;y=(i//cols)*h+58
            sheet.paste(im,(x,y));draw.text((x+7,y+w-7),name,font=small,fill=(199,220,240))
        sheet.save(OUT/(d.name+'_contact_sheet.jpg'),quality=92)
        # Hero portraits have their own editable studio. Structural validation
        # must never replace those with an old full-body QA crop.
        if not (OUT/'portraits'/(d.name+'.png')).exists():
            im=Image.open(d/'idle.png').convert('RGB');im.crop((115,32,490,430)).resize((384,408),Image.Resampling.LANCZOS).save(portraits/(d.name+'.png'))

def motion():
    paths=sorted((OUT/'engine/motion_frames').glob('frame_*.png'))
    if not paths:return
    frames=[Image.open(p).convert('RGB').resize((960,540),Image.Resampling.LANCZOS) for p in paths]
    frames[0].save(OUT/'runtime_motion_comparison.webp',save_all=True,append_images=frames[1:],duration=50,loop=0,quality=83,method=4)
    print('MOTION_COMPARISON',len(frames),'actual Godot frames; normalized clip-phase comparison')

if __name__=='__main__':inspect();sheets();motion()
