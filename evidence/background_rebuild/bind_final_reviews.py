"""Bind completed still, temporal and sampled movie reviews without altering captures."""
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'evidence/background_rebuild'

def read(p):
    return json.loads(Path(p).read_text(encoding='utf-8-sig'))

def record(p):
    p = Path(p).resolve()
    return {'path': str(p), 'bytes': p.stat().st_size,
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest().upper()}

def check(r):
    actual = record(r['path'])
    assert actual['bytes'] == r['bytes'] and actual['sha256'] == r['sha256'].upper(), r['path']
    return Path(r['path'])

visual_path = BASE / 'visualreview.json'
visual = read(visual_path)
motion_path = BASE / 'motion_acceptance.json'
motion = read(motion_path)
movie_path = BASE / 'movie_acceptance.json'
movie = read(movie_path)
receipt_path = BASE / 'motion/movie_receipt.json'
receipt = read(receipt_path)
gate = read(ROOT / 'evidence/validation_all.json')
expected = gate['runtime']
assert visual['passed'] and motion['passed'] and movie['passed'] and receipt['passed']
assert motion['motion_reviewed'] and motion['visual_aesthetic_passed'] and motion['capture_checks_passed']
for reviewed in (visual, motion, movie, receipt):
    assert reviewed['runtime']['sha256'] == expected['sha256']
    if 'files' in reviewed['runtime']:
        assert reviewed['runtime']['files'] == expected['files']
    else:
        assert reviewed['runtime']['file_count'] == len(expected['files'])
assert len(visual['captures']) == 25 and len(motion['captures']) == 70
assert len(motion['cases']) == 10 and motion['capture_checks'] == 378
for reviewed in visual['captures'] + motion['captures']:
    assert reviewed['reviewed'] is True
    check(reviewed)
    if reviewed.get('state'):
        check(reviewed['state'])
for sample in visual.get('supplementary_temporal_samples', []):
    check(sample)
check(visual['capture_report_file'])
check(motion['report_file'])
assert motion['harness_sha256'] == record(ROOT / 'tools/validation/living_background_review.gd')['sha256']
assert record(movie_path) == receipt['visual_acceptance']
archive = BASE / 'visualreview_before_motion_binding.json'
if not archive.exists():
    shutil.copy2(visual_path, archive)
visual['report_path'] = visual['capture_report_file']['path']
visual['report_sha256'] = visual['capture_report_file']['sha256']
visual['motion_report_path'] = motion['report_file']['path']
visual['motion_report_sha256'] = motion['report_file']['sha256']
visual['motion_reviewed'] = True
visual['motion_acceptance'] = record(motion_path)
visual['movie_acceptance'] = record(movie_path)
visual['movie_receipt'] = record(receipt_path)
visual['motion_report_binding'] = 'Current exact report, all 70 PNG/state identities and 378 clock/pause/reset assertions are bound to completed assistant temporal inspection.'
visual['motion_visual_review'] = 'Accepted assistant inspection of all 70 timed/pause/reset images and 20 extracted native movie frames across five arenas; continuous human viewing remains unverified.'
visual['final_binding_utc'] = datetime.now(timezone.utc).isoformat()
visual_path.write_text(json.dumps(visual, indent=2) + '\n', encoding='utf-8')
print('Bound 25 stills, 70 temporal images and five sampled ambient movies to current source.')
