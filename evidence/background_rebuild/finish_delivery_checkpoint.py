"""Save the finished background scope and its verified delivery, retaining old checkpoints."""
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'evidence/background_rebuild'
ARENAS = {'rooftop_riot', 'lunar_reach', 'verdant_shrine', 'abyssal_observatory', 'ember_foundry'}

def read(p):
    return json.loads(Path(p).read_text(encoding='utf-8-sig'))

def record(p):
    p = Path(p).resolve()
    return {'path': str(p), 'bytes': p.stat().st_size,
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest().upper()}

def preserve(name):
    p = BASE / name
    target = BASE / (p.stem + '_before_delivery' + p.suffix)
    if p.exists() and not target.exists():
        shutil.copy2(p, target)

gate = read(ROOT / 'evidence/validation_all.json')
audit = read(BASE / 'final_audit.json')
delivery = read(BASE / 'delivery.json')
visual = read(BASE / 'visualreview.json')
temporal = read(BASE / 'motion_acceptance.json')
movies = read(BASE / 'motion/movie_receipt.json')
preservation = read(BASE / 'preservation.json')
assert all(r['passed'] is True for r in (gate, audit, delivery, visual, temporal, movies, preservation))
assert audit['problems'] == []
assert audit['runtime_source_sha256'] == delivery['runtime_source_sha256'] == gate['runtime']['sha256']
assert record(delivery['archive'])['sha256'] == audit['archive_sha256'] == delivery['archive_sha256']
assert set(visual['arenas']) == ARENAS and all(a['accepted'] for a in visual['arenas'].values())
assert {(c['arena'], c['quality']) for c in temporal['cases']} == {(a, q) for a in ARENAS for q in ('High', 'Low')}
assert all(c['passed'] and c['reviewed_frames'] == 7 and c['findings']
           and c['pause_pixels_identical'] and c['stage_reset_snapshot_matches_initial']
           for c in temporal['cases'])
assert {c['arena'] for c in movies['cases']} == ARENAS
assert all(c['reviewed'] and c['movie']['reviewed'] and len(c['samples']) == 4
           and all(s['reviewed'] for s in c['samples']) for c in movies['cases'])

proofs = {
    'still_review': record(BASE / 'visualreview.json'),
    'temporal_review': record(BASE / 'motion_acceptance.json'),
    'ambient_movies': record(BASE / 'motion/movie_receipt.json'),
    'preservation': record(BASE / 'preservation.json'),
    'source_gate': record(ROOT / 'evidence/validation_all.json'),
    'delivery': record(BASE / 'delivery.json'),
    'independent_final_audit': record(BASE / 'final_audit.json'),
}
requirements = [
    {'requirement': 'All five maps have visible setting-specific background activity.', 'verified': True,
     'evidence': ['still_review', 'temporal_review', 'ambient_movies'],
     'observations': {a: next(c['findings'] for c in temporal['cases'] if c['arena'] == a and c['quality'] == 'High') for a in sorted(ARENAS)}},
    {'requirement': 'Ocean fish visibly swim and the lava arena has visible flowing molten material.', 'verified': True,
     'evidence': ['temporal_review', 'ambient_movies'], 'arenas': ['abyssal_observatory', 'ember_foundry']},
    {'requirement': 'Backgrounds remain coherent and fighters, platforms and recovery paths remain readable.', 'verified': True,
     'evidence': ['still_review'], 'coverage': '25 inspected 1080p High/Low, overlap, recovery and near-ledge fixtures, all five arenas.'},
    {'requirement': 'Low retains ambient activity; scene motion pauses and resets correctly.', 'verified': True,
     'evidence': ['temporal_review'], 'coverage': '70 reviewed image/state records, 378 assertions, all ten arena/tier cases; pause pairs are pixel-identical and reset stage snapshots match.'},
    {'requirement': 'Existing platform collision, combat behavior, original artwork and preceding release are preserved.', 'verified': True,
     'evidence': ['preservation', 'source_gate'], 'coverage': '72 preservation checks, 106 original bitmaps, eight supplied originals, eight curated sources and unchanged preceding platform ZIP; 5097 source assertions.'},
    {'requirement': 'Updated Windows build and reproducible editable scene/shader tools are delivered with current validation notes and motion previews.', 'verified': True,
     'evidence': ['delivery', 'independent_final_audit', 'ambient_movies'],
     'coverage': 'Matching EXE/PCK and 22 fully decoded archive entries; live editable Godot sources, tools and five 12-second 1600x900/60-FPS ambient clips; Windows UI, executable smoke and full-match checks.'},
    {'requirement': 'Performance is measured and material limitations are documented.', 'verified': True,
     'evidence': ['independent_final_audit'],
     'coverage': 'Ten isolated 60-second 1080p four-CPU High/Low cases at explicit 120 FPS cap, plus two retained repeats. Frame-pacing spikes and the aborted uncapped lost-device run are documented; stable frame pacing or a driver fix is not claimed.'},
]
completion = {'recorded_utc': datetime.now(timezone.utc).isoformat(), 'passed': True,
              'scope': 'Requested living-background upgrade across all five maps.',
              'requirements': requirements, 'evidence': proofs,
              'limitations': ['Sampled assistant visual review does not establish continuous human motion/audio acceptance.',
                              'Frame-pacing stalls and the uncapped GPU device-loss crash remain unresolved; this delivery does not claim clean stable 60 FPS.',
                              'Human playtesting, physical controllers, weaker-PC, exported-build performance and current Mobile-renderer performance remain unverified.']}
(BASE / 'completion_requirements.json').write_text(json.dumps(completion, indent=2) + '\n', encoding='utf-8')
preserve('progress.json')
preserve('RESUME.md')
progress = {'recorded_utc': completion['recorded_utc'], 'complete': True,
            'state': 'background_upgrade_delivered_and_verified', 'goal_status': 'active_pending_completion_call',
            'runtime': gate['runtime'], 'archive': record(delivery['archive']),
            'evidence': proofs, 'completion_audit': record(BASE / 'completion_requirements.json'),
            'limitations': completion['limitations']}
(BASE / 'progress.json').write_text(json.dumps(progress, indent=2) + '\n', encoding='utf-8')
(BASE / 'RESUME.md').write_text('''# Living-background upgrade delivered

The requested five-map background pass is complete and independently audited. Current runtime: 537 files, SHA-256 `F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825`.

The Windows release is [RooftopRiot-Living-Arenas-Windows.zip](../../builds/RooftopRiot-Living-Arenas-Windows.zip), with matching editable sources under `Game File/stages/`. [Delivery](delivery.json), [final audit](final_audit.json) and [requirement audit](completion_requirements.json) bind the exact current artifacts. Five ambient previews are under `motion/<arena>/ambient.mp4`.

Current visual, motion, pause/reset, preservation, source, Windows and full-match checks pass. The ten-case performance matrix uses an explicit 120 FPS cap. Frame-pacing stalls and the earlier uncapped GPU device-loss failure remain unresolved and documented in [performance notes](../../docs/PERFORMANCE.md); no driver fix or clean stable-60-FPS claim is made. Human/controller testing and weaker-PC performance remain unverified.

Earlier interrupted checkpoint instructions are preserved separately in [RESUME_before_delivery.md](RESUME_before_delivery.md) and [progress_before_delivery.json](progress_before_delivery.json). They are historical and must not replace the completed current receipts.
''', encoding='utf-8')
print('Saved complete five-map requirement audit and current delivery checkpoint; historical checkpoints retained.')
