"""Save the unfinished background pass without promoting pending evidence."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent

def sha(file):
    h = hashlib.sha256()
    with file.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest().upper()

def record(file):
    return {'path': str(file), 'bytes': file.stat().st_size, 'sha256': sha(file)}

gate_file = ROOT / 'evidence/validation_all.json'
gate = json.loads(gate_file.read_text(encoding='utf-8-sig'))
assert gate['passed']
inventory = gate['runtime']
for item in inventory['files']:
    file = ROOT / 'Game File' / item['path']
    assert file.stat().st_size == item['bytes'] and sha(file) == item['sha256']

manifest_file = ROOT / 'builds/windows/build_manifest.json'
manifest = json.loads(manifest_file.read_text(encoding='utf-8-sig'))
assert manifest['runtime_source_files'] == inventory['files']
assert sha(ROOT / 'builds/windows/RooftopRiot.exe') == manifest['exe_sha256']
assert sha(ROOT / 'builds/windows/RooftopRiot.pck') == manifest['pck_sha256']

# The previous payload manifest is already preserved in the baseline. It must
# not describe this newly exported, not yet graphically validated candidate.
stale_manifest = ROOT / 'builds/windows/package_manifest.json'
baseline_manifest = HERE / 'baseline/builds_windows/package_manifest.json'
if stale_manifest.exists():
    assert stale_manifest.resolve().parent == (ROOT / 'builds/windows').resolve()
    assert baseline_manifest.exists() and sha(stale_manifest) == sha(baseline_manifest)
    stale_manifest.unlink()

readme = ROOT / 'builds/windows/README.md'
header = ('<!-- LIVING_ARENAS_CANDIDATE -->\n'
          '# Living arenas: candidate build, validation pending\n\n'
          'This EXE/PCK contains the new animated backgrounds. Source validation passes, '
          'but the graphics device was lost before final captures, full-match review, '
          'Windows smoke checks and four-player profiling. This folder is not a validated '
          'release. The previous validated ZIP is preserved unchanged.\n\n'
          'All material below is historical documentation from the previous platform release. '
          'It does not establish acceptance or performance of this candidate.\n\n---\n\n')
body = readme.read_text(encoding='utf-8-sig')
if not body.startswith('<!-- LIVING_ARENAS_CANDIDATE -->'):
    readme.write_text(header + body, encoding='utf-8')

gpu = subprocess.run(['nvidia-smi', '--query-gpu=name,driver_version,display_active,memory.used',
                      '--format=csv,noheader'], capture_output=True, text=True, timeout=15)
gpu_log = HERE / 'gpu_recovery_diagnostic.log'
gpu_log.write_text('STDOUT:\n' + gpu.stdout + '\nSTDERR:\n' + gpu.stderr, encoding='utf-8')
assert gpu.returncode != 0 and 'GPU is lost' in gpu.stdout + gpu.stderr

baseline = json.loads((HERE / 'baseline.json').read_text(encoding='utf-8-sig'))
old_zip = ROOT / 'builds/RooftopRiot-Platform-Upgrade-Windows.zip'
assert sha(old_zip) == baseline['previous_archive_sha256']
progress = {
    'recorded_utc': datetime.now(timezone.utc).isoformat(),
    'complete': False,
    'state': 'awaiting_graphics_recovery',
    'goal_status': 'active',
    'consecutive_blocking_goal_turns_observed': 1,
    'source_assertions': 5097,
    'runtime': inventory,
    'source_gate': record(gate_file),
    'preservation': record(HERE / 'preservation.json'),
    'candidate_build': {'validated_release': False,
                        'manifest': record(manifest_file),
                        'exe': record(ROOT / 'builds/windows/RooftopRiot.exe'),
                        'pck': record(ROOT / 'builds/windows/RooftopRiot.pck')},
    'previous_release_preserved': record(old_zip),
    'graphics_failure': {'diagnostic': record(gpu_log), 'exit_code': gpu.returncode,
                         'failed_engine_log': record(HERE / 'review_final_stdout.log'),
                         'owned_failed_processes_stopped': [25500, 35356],
                         'driver_cause_established': False,
                         'required_external_action': 'Save open work and restart Windows; NVIDIA diagnostic requests reboot.'},
    'historical_motion': {'path': str(HERE / 'temporal_first/living_background_review.json'),
                         'checks': 378, 'captures': 70,
                         'covers_final_runtime': False,
                         'reason': 'Recorded before the last rooftop gull silhouette/height refinement.'},
    'pending': ['25 final arena view captures and assistant review',
                '70 current scenery captures, clock/pause/reset checks and visual review',
                'Five 12-second ambient clips, full decode and sampled visual review',
                'Five full match/results/rematch graphical checks',
                'Current Windows UI/default-scene and three added-arena EXE checks',
                'Ten isolated four-player High/Low 1080p 60-second profiles',
                'Current release notes, strict new ZIP and independent final audit'],
    'new_release_archive_created': False,
    'resume_notes': str(HERE / 'RESUME.md')
}
(HERE / 'progress.json').write_text(json.dumps(progress, indent=2) + '\n', encoding='utf-8')
print('Saved pending progress; 537 source files verified, candidate export and prior ZIP hashed.')
