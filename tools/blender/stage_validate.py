"""Validate authored stage GLBs and audio without requiring a graphical engine."""
from pathlib import Path
import json, struct, wave, numpy as np
ROOT=Path(__file__).resolve().parents[2]
evidence=ROOT/'evidence/stage'
audio=[]
for f in sorted((ROOT/'Game File/assets/audio').glob('*.wav')):
    with wave.open(str(f)) as w:
        samples=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2')/32768.
        item={'file':f.name,'channels':w.getnchannels(),'sample_rate':w.getframerate(),
            'peak':float(np.abs(samples).max()),'dc_offset':float(samples.mean()),
            'nonzero_samples':int(np.count_nonzero(samples)),
            'clipped_samples':int((np.abs(samples)>=.999).sum())}
        assert item['nonzero_samples']>0 and item['clipped_samples']==0
        assert item['channels']==2 and item['sample_rate']==44100
        audio.append(item)
assert len(audio)==23
(evidence/'audio_validation.json').write_text(json.dumps(audio,indent=2))
stages=[]
for f in sorted((ROOT/'Game File/assets/stage').glob('*.glb')):
    data=f.read_bytes();magic,version,size=struct.unpack_from('<III',data)
    assert magic==0x46546c67 and version==2 and size==len(data)
    jsize,ctype=struct.unpack_from('<II',data,12);g=json.loads(data[20:20+jsize])
    assert ctype==0x4e4f534a and g.get('meshes')
    mins=np.array([1e9]*3);maxs=-mins
    for mesh in g['meshes']:
        for primitive in mesh['primitives']:
            acc=g['accessors'][primitive['attributes']['POSITION']]
            mins=np.minimum(mins,acc['min']);maxs=np.maximum(maxs,acc['max'])
    item={'file':f.name,'bytes':size,'meshes':len(g['meshes']),'materials':len(g['materials']),
        'local_bounds_min':mins.tolist(),'local_bounds_max':maxs.tolist(),
        'node_names':[x.get('name','') for x in g['nodes']]}
    if f.name=='center_platform.glb':
        assert abs(maxs[1])<.001,'Central platform local top must be Y=0'
        assert abs(mins[0]+1.75)<.001 and abs(maxs[0]-1.75)<.001
    stages.append(item)
assert len(stages)>=2
(evidence/'stage_export_validation.json').write_text(json.dumps(stages,indent=2))
print(json.dumps({'non_silent_unclipped_wavs':len(audio),'valid_glbs':len(stages)}))
