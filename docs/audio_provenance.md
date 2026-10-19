# Original audio provenance

All 23 runtime `.wav` files in `Game File/assets/audio/` were synthesized for this
project from mathematical oscillators and deterministic noise. No source recordings,
commercial game assets, copyrighted melodies, voice cloning, or external services
were used. `tools/generate_audio.py` is the editable source. The seed is `80223`.

The music is an original 16-bar lounge-house composition in A minor at 112 BPM,
with a four-chord progression, independently authored mallet line, bass pattern,
and synthesized percussion. It lasts 34.286 seconds. It is intended to loop quietly
under combat. The ambient loop uses filtered noise for city air and pool motion.

Reproduce on the verified workstation:

```powershell
& 'D:\New folder\5.2\python\bin\python.exe' tools/generate_audio.py
```

The script writes 44.1 kHz stereo, signed 16-bit PCM WAVs and an
`audio_manifest.json` recording durations, peaks, RMS levels, and SHA-256 hashes.
Every file receives a five-millisecond edge fade and conservative peak normalization.
The loudest synthesized peak is -2.16 dBFS before the runtime mix.

Recommended starting runtime gains are music -19 dB, ambience -29 dB, UI -14 dB,
and impacts -9 dB. Runtime voice limits and master bus headroom are still necessary
because multiple individually safe files can sum. The generator does not itself
claim an in-engine listening test or final mix approval.

Asset uses:

| Event | WAV stem |
|---|---|
| Light/heavy impacts | `hit_light_1`–`3`, `hit_heavy_1`–`2` |
| Movement | `jump`, `land`, `swing`, `launch` |
| Defense | `shield`, `parry` |
| UI | `menu_move`, `menu_confirm`, `menu_back` |
| Resource / special | `meter_ready`, `ultimate` |
| Arena | `hazard_warning`, `hazard_fire`, `break_prop` |
| Result | `ko`, `victory` |
| Loops | `last_resort_music`, `rooftop_ambience` |

No real person's voice is present. The sounds have no spoken content.
