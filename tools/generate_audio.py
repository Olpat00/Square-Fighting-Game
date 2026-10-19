"""Deterministic, original synthesis for UNSUPERVISED: ROOFTOP RIOT.
Requires NumPy (bundled with the verified Blender installation). No external samples.
Run: D:\\New folder\\5.2\\python\\bin\\python.exe tools/generate_audio.py
"""
from pathlib import Path
import numpy as np
import wave, json, hashlib

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'Game File/assets/audio';OUT.mkdir(parents=True,exist_ok=True)
SR=44100
rng=np.random.default_rng(80223)
manifest=[]

def tone(freq,t,phase=0):return np.sin(2*np.pi*freq*t+phase)
def timeline(seconds):return np.arange(round(SR*seconds))/SR
def noise(n,smooth=1):
    x=rng.uniform(-1,1,n)
    if smooth>1:x=np.convolve(x,np.ones(smooth)/smooth,mode='same')*np.sqrt(smooth)
    return x
def env(t,decay=10,attack=.005):return np.minimum(1,t/attack)*np.exp(-decay*t)
def chirp(t,f0,f1,length):return np.sin(2*np.pi*(f0*t+(f1-f0)*t*t/(2*length)))
def save(name,x,desc,loop=False):
    x=np.asarray(x,dtype=float)
    if x.ndim==1:
        # Very short reflections retain a focused center image without hard mono.
        r=x*.985+np.roll(x,139)*.015
        x=np.column_stack([x,r])
    peak=np.max(np.abs(x))
    if peak>0:x=x*(.78 if not loop else .49)/max(peak,.01)
    fade=min(220,len(x)//10)
    x[:fade]*=np.linspace(0,1,fade)[:,None];x[-fade:]*=np.linspace(1,0,fade)[:,None]
    pcm=(np.clip(x,-.95,.95)*32767).astype('<i2')
    path=OUT/(name+'.wav')
    with wave.open(str(path),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
    manifest.append({'file':path.name,'seconds':round(len(x)/SR,3),'peak_dbfs':round(20*np.log10(max(np.max(np.abs(x)),1e-8)),2),'rms_dbfs':round(20*np.log10(max(np.sqrt(np.mean(x*x)),1e-8)),2),'loop':loop,'description':desc,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

for variant in range(3):
    t=timeline(.21+variant*.014)
    punch=.6*chirp(t,155+variant*21,48,.12)*env(t,29)+noise(len(t),2)*env(t,49)*.36
    punch+=.11*tone(1900+variant*317,t)*env(t,90)
    save(f'hit_light_{variant+1}',punch,'Short pitched body impact with softened high-frequency contact transient.')
for variant in range(2):
    t=timeline(.49)
    heavy=.7*chirp(t,105+variant*20,34,.3)*env(t,10)+noise(len(t),5)*env(t,17)*.4
    heavy+=.14*tone(320+variant*70,t)*env(t,40)
    save(f'hit_heavy_{variant+1}',heavy,'Low impact with a broad short thump and textured transient.')
t=timeline(.43);save('launch',chirp(t,310,1080,.43)*env(t,6)*.25+noise(len(t),7)*env(t,8)*.6,'Air rush, bright rising trajectory cue.')
t=timeline(.25);save('swing',noise(len(t),4)*np.sin(np.pi*t/.25)**2*.7+chirp(t,640,220,.25)*env(t,14)*.1,'Short air movement before a committed strike.')
t=timeline(.33);save('shield',sum(tone(f,t)*a for f,a in ((320,1),(510,.5),(740,.2)))*env(t,13)+noise(len(t),6)*env(t,35)*.1,'Resonant low shield contact.')
t=timeline(.6);save('parry',sum(tone(f,t)*a for f,a in ((1174,1),(1761,.36),(2348,.16)))*env(t,9),'Clear original bell interval for perfect defense.')
t=timeline(.21);save('jump',chirp(t,260,510,.21)*env(t,19)*.33+noise(len(t),7)*env(t,23)*.3,'Gentle pitched spring and air pulse.')
t=timeline(.20);save('land',tone(78,t)*env(t,28)*.65+noise(len(t),8)*env(t,35)*.4,'Soft shoe/deck landing thud.')
t=timeline(.09);save('menu_move',tone(660,t)*env(t,55),'Brief low-level menu navigation blip.')
t=timeline(.24);save('menu_confirm',(tone(523.25,t)+tone(783.99,t)*.5)*env(t,20),'Two-note menu confirmation.')
t=timeline(.19);save('menu_back',chirp(t,392,261.63,.19)*env(t,26),'Falling UI cancel cue.')
t=timeline(1.1);ready=np.zeros(len(t))
for onset,freq in ((0,523.25),(.12,659.25),(.24,783.99),(.40,1046.50)):
    tt=np.maximum(t-onset,0);ready+=(t>=onset)*tone(freq,tt)*env(tt,8)*.4
save('meter_ready',ready,'Original rising major-seventh-flavored resource-ready chime.')
t=timeline(1.05);warning=np.zeros(len(t))
for onset in (0,.33,.66):
    tt=np.maximum(t-onset,0);warning+=(t>=onset)*(tone(620,tt)+tone(930,tt)*.3)*env(tt,22)
save('hazard_warning',warning,'Three evenly spaced amber warning beeps over one second.')
t=timeline(.85);save('hazard_fire',noise(len(t),5)*env(t,5)*.7+chirp(t,95,36,.6)*env(t,8)*.45,'Low pyrotechnic burst with no explosive crack spike.')
t=timeline(1.35);ko=chirp(t,100,32,1.1)*env(t,4)*.4+noise(len(t),9)*env(t,7)*.5
for onset,f in ((.06,261.63),(.10,329.63),(.15,392),(.22,523.25)):
    tt=np.maximum(t-onset,0);ko+=(t>=onset)*tone(f,tt)*env(tt,4)*.16
save('ko',ko,'Broad musical ring-out impact; original non-vocal sound.')
t=timeline(1.6);win=np.zeros(len(t))
for onset,f in ((0,392),(.17,523.25),(.34,659.25),(.52,783.99)):
    tt=np.maximum(t-onset,0);win+=(t>=onset)*(tone(f,tt)+tone(f*2,tt)*.12)*env(tt,3.7)*.3
save('victory',win,'Short four-tone match-result flourish.')
t=timeline(.65);save('ultimate',chirp(t,140,890,.65)*env(t,2)*.3+noise(len(t),8)*np.sin(np.pi*t/.65)**2*.22,'Build-up whoosh to precede an ultimate attack.')
t=timeline(.38);save('break_prop',noise(len(t),2)*env(t,15)*.45+tone(143,t)*env(t,16)*.25,'Dry cosmetic prop-break crunch.')

# Original 16-bar lounge-house loop in A minor, 112 BPM. Short marimba-like plucks,
# warm electric chords, syncopated bass, kick, snare and sparse shakers.
bpm=112;beat=60/bpm;bars=16;duration=bars*4*beat;n=round(SR*duration)
song=np.zeros((n,2));t=timeline(duration)
def mix(signal,start,pan=0):
    offset=round(start*SR);count=min(len(signal),n-offset)
    if count<=0:return
    gainL=np.sqrt((1-pan)/2);gainR=np.sqrt((1+pan)/2)
    song[offset:offset+count,0]+=signal[:count]*gainL
    song[offset:offset+count,1]+=signal[:count]*gainR
def hz(midi):return 440*2**((midi-69)/12)
progression=((45,52,55,59),(41,48,52,57),(48,55,59,62),(43,50,53,57))
melody=(76,79,83,79,74,76,79,71,72,76,79,83,74,77,79,74)
for bar in range(bars):
    chord=progression[(bar//2)%4];start=bar*4*beat
    for step in range(4):
        tt=timeline(.4);kick=tone(53,tt+(.003*np.exp(-tt*28)))*env(tt,13)+noise(len(tt),6)*env(tt,100)*.05
        mix(kick*.16,start+step*beat)
        if step%2:
            tt=timeline(.17);snare=noise(len(tt),3)*env(tt,34)+tone(174,tt)*env(tt,38)*.24
            mix(snare*.052,start+step*beat, -.12)
    for eighth in range(8):
        tt=timeline(.05);hat=noise(len(tt))*env(tt,85)
        mix(hat*(.010 if eighth%2==0 else .021),start+eighth*beat/2,.3 if eighth%2 else -.3)
    for pulse in (0,1.5,2.75):
        tt=timeline(1.3);sig=np.zeros(len(tt))
        for note in chord[1:]:
            sig+=(tone(hz(note+12),tt)+tone(hz(note+24),tt)*.15)*env(tt,3.3,.017)*.024
        mix(sig,start+pulse*beat,-.28)
    for pulse,note in ((0,chord[0]),(.75,chord[0]),(1.5,chord[0]+7),(2.5,chord[0]),(3.25,chord[0]+12)):
        tt=timeline(.35);sig=(tone(hz(note-12),tt)+tone(hz(note),tt)*.22)*env(tt,8,.005)*.10
        mix(sig,start+pulse*beat)
    for j,pulse in enumerate((.5,1.75,3.0)):
        note=melody[(bar+j*3)%len(melody)];tt=timeline(.65)
        sig=(tone(hz(note),tt)+tone(hz(note)*3.99,tt)*np.exp(-tt*17)*.25)*env(tt,7,.003)*.038
        mix(sig,start+pulse*beat,.24)
        mix(sig*.20,start+(pulse+.75)*beat,-.4)
# Limit gently, wrap delay tails into the opening for a continuous repeating groove.
song=np.tanh(song*1.7)
save('last_resort_music',song,'Original 16-bar, 112 BPM A-minor rooftop lounge-house composition; synthesized drums, bass, chords and mallets.',True)

# Continuous atmosphere: low city air, distant traffic and soft pool motion.
t=timeline(12);city=noise(len(t),1200)*.019;water=noise(len(t),25)*.008*(.6+.4*np.sin(t*1.8)**2)
amb=city+water+tone(56,t)*.0015
save('rooftop_ambience',amb,'Original city-air and pool-water synthesis; quiet ambient loop.',True)
(OUT/'audio_manifest.json').write_text(json.dumps({'sample_rate':SR,'channels':2,'format':'PCM signed 16-bit WAV','generator':'tools/generate_audio.py','seed':80223,'assets':manifest},indent=2),encoding='utf-8')
print(json.dumps({'count':len(manifest),'seconds':sum(i['seconds'] for i in manifest),'max_peak_dbfs':max(i['peak_dbfs'] for i in manifest)},indent=2))
