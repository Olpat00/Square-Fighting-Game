"""Read-only structural/bounds validation of the authored ability GLBs."""
from pathlib import Path
import json,struct
ROOT=Path(__file__).resolve().parents[2]
expected={'solar_disc','reflector','log','plank','branch','chair','tree','clipboard'}
rows=[]
for name in sorted(expected):
    f=ROOT/'Game File/assets/props'/f'{name}.glb';raw=f.read_bytes()
    magic,version,size=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and version==2 and size==len(raw)
    length,kind=struct.unpack_from('<II',raw,12)
    assert kind==0x4e4f534a
    gltf=json.loads(raw[20:20+length]);assert gltf['meshes']
    mins=[float('inf')]*3;maxs=[-float('inf')]*3
    for mesh in gltf['meshes']:
        for primitive in mesh['primitives']:
            acc=gltf['accessors'][primitive['attributes']['POSITION']]
            mins=[min(mins[i],acc['min'][i]) for i in range(3)]
            maxs=[max(maxs[i],acc['max'][i]) for i in range(3)]
    assert all(-6<v<6 for v in mins+maxs),'Export appears to include gallery translation'
    if name in {'reflector','plank','chair','clipboard'}:assert abs(mins[1])<.001
    if name=='tree':assert 5.5<maxs[1]<5.75 and -.015<mins[1]<.015
    if name=='log':assert -.52<mins[1]<-.46 and .46<maxs[1]<.52
    if name=='branch':assert 2.4<maxs[0]-mins[0]<2.55
    rows.append({'id':name,'bytes':len(raw),'mesh_nodes':len(gltf['meshes']),'materials':len(gltf['materials']),'bounds_min':mins,'bounds_max':maxs})
(ROOT/'source_art/props/validation.json').write_text(json.dumps({'passed':True,'validated_assets':rows},indent=2),encoding='utf-8')
print('PROPS_VALIDATION_PASS',len(rows),'assets',sum(r['bytes'] for r in rows),'bytes')
