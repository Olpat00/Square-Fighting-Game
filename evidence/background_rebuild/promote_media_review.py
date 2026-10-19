"""Bind the inspected, decoded five-movie evidence without changing media."""
from pathlib import Path
import json
import hashlib
from datetime import datetime, timezone

HERE = Path(__file__).resolve().parent
def read(file): return json.loads(file.read_text(encoding='utf-8-sig'))
def digest(file):
    value = hashlib.sha256()
    with file.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''): value.update(block)
    return value.hexdigest().upper()
def record(file): return {'path':str(file), 'bytes':file.stat().st_size, 'sha256':digest(file)}
def verify(item):
    file = Path(item['path'])
    assert file.stat().st_size == item['bytes'] and digest(file) == item['sha256'].upper(), file

file = HERE / 'motion/movie_receipt.json'
acceptance_file = HERE / 'movie_acceptance.json'
value, acceptance = read(file), read(acceptance_file)
assert acceptance['passed'] and acceptance['failures'] == 0 and len(acceptance['cases']) == 5
assert value['capture_passed'] and value['unchanged_during_recording'] and not value['problems']
assert value['runtime']['sha256'] == acceptance['runtime']['sha256']
assert value['harness_sha256'] == acceptance['harness_sha256']
assert digest(file) == acceptance['capture_receipt_before_visual_promotion']['sha256']
archive = HERE / 'motion/movie_receipt_before_visual_promotion.json'
assert not archive.exists()
archive.write_bytes(file.read_bytes())
assert digest(archive) == digest(file)
# Preserve the review's original serialization, then relocate its historical
# capture-receipt reference to the immutable copy before promoting the receipt.
old_acceptance = HERE / 'movie_acceptance_before_receipt_promotion.json'
assert not old_acceptance.exists()
old_acceptance.write_bytes(acceptance_file.read_bytes())
acceptance['capture_receipt_before_visual_promotion']['original_capture_path'] = str(file)
acceptance['capture_receipt_before_visual_promotion']['path'] = str(archive)
acceptance_file.write_text(json.dumps(acceptance, indent=2)+'\n', encoding='utf-8')
for case in value['cases']:
    reviewed = next(c for c in acceptance['cases'] if c['arena'] == case['arena'])
    assert reviewed['passed'] and reviewed['reviewed'] and case['capture_passed']
    assert case['quality'] == reviewed['quality'] == 'High'
    assert case['movie']['sha256'] == reviewed['movie']['sha256']
    verify(case['movie'])
    assert case['movie']['decoded'] and case['movie']['video_frames'] == 720
    assert case['movie']['fps'] == 60 and case['movie']['duration_seconds'] == 12
    for sample in case['samples']:
        accepted = next(s for s in reviewed['samples'] if s['seconds'] == sample['seconds'])
        assert accepted['reviewed'] and accepted['sha256'] == sample['sha256']
        verify(sample)
        sample['reviewed'] = True
    case['reviewed'] = True
    case['movie']['reviewed'] = True
    case['movie']['review_method'] = acceptance['review_method']
    case['visual_observations'] = reviewed['observations']
value['passed'] = True
value['visual_review'] = 'Accepted through bound assistant inspection of all twenty native movie samples; continuous human viewing remains unverified.'
value['visual_acceptance'] = record(acceptance_file)
value['visual_promoted_utc'] = datetime.now(timezone.utc).isoformat()
file.write_text(json.dumps(value, indent=2)+'\n', encoding='utf-8')
print('Promoted all five exact-hash decoded and visually reviewed ambient clips.')
