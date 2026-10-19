"""Promote living-arena notes only after current, bound acceptance receipts pass.

Run from any directory with the completed ten-case profile directory followed
by optional completed repeat-profile directories. Original measurements remain
intact and repeats are shown separately. This script changes documentation only;
packaging remains a separate operation guarded by package_map_expansion.ps1.
"""
from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ARENAS = {
    'rooftop_riot': 'The Last Resort',
    'lunar_reach': 'Lunar Reach',
    'verdant_shrine': 'Verdant Shrine',
    'abyssal_observatory': 'Abyssal Observatory',
    'ember_foundry': 'Ember Foundry',
}
NEW_ARENAS = {'verdant_shrine', 'abyssal_observatory', 'ember_foundry'}
VIEWS = {'high', 'low', 'overlap', 'recovery', 'near_ledge'}
ARCHIVE = 'builds/RooftopRiot-Living-Arenas-Windows.zip'
DELIVERY = 'evidence/background_rebuild/delivery.json'
UNCAPPED_FAILURE = 'evidence/background_rebuild/performance/aborted_uncapped_20261004/failure.json'
BEGIN = '<!-- LIVING_ARENAS_CURRENT_BEGIN -->'
END = '<!-- LIVING_ARENAS_CURRENT_END -->'
HISTORY = '<!-- LIVING_ARENAS_HISTORY_BEGIN -->'
LIMITS = ('Human playtesting, physical multi-controller testing, continuous human '
          'motion/audio acceptance, weaker-PC performance and current Mobile-renderer '
          'performance remain unverified. Assistant visual review of scenery fixtures '
          'and automated CPU matches do not establish competitive balance, sound-mix '
          'quality or zero clipping in every combat pose.')
TRACKED: dict[Path, str] = {}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def path(value):
    result = Path(value)
    return result if result.is_absolute() else ROOT / result


def sha256(value):
    digest = hashlib.sha256()
    with path(value).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest().upper()


def read_json(value):
    file = path(value)
    TRACKED[file] = sha256(file)
    return json.loads(file.read_text(encoding='utf-8-sig'))


def check_hash(value, expected):
    file = path(value)
    require(isinstance(expected, str) and re.fullmatch(r'[0-9a-fA-F]{64}', expected),
            f'Missing SHA-256: {file}')
    actual = sha256(file)
    require(actual == expected.upper(), f'File changed after validation: {file}')
    TRACKED[file] = actual


def file_record(record, base=None):
    file = Path(record['path'])
    if not file.is_absolute():
        file = (base or ROOT) / file
    check_hash(file, record['sha256'])
    require(file.stat().st_size == record['bytes'], f'File size differs: {file}')
    return file


def png_record(record, base=None):
    file = file_record(record, base)
    with file.open('rb') as stream:
        header = stream.read(24)
    require(header[:8] == b'\x89PNG\r\n\x1a\n' and header[12:16] == b'IHDR',
            f'Invalid PNG header: {file}')
    require(struct.unpack('>II', header[16:24]) == (1920, 1080) and
            record['width'] == 1920 and record['height'] == 1080,
            f'Capture is not 1920x1080: {file}')
    return file


def inventory(records):
    result = {r['path'].replace('\\', '/'): (r['bytes'], r['sha256'].upper()) for r in records}
    require(len(result) == len(records), 'Duplicate runtime inventory entries.')
    return result


def review_runtime_binding(runtime, expected_inventory, runtime_hash):
    require(runtime['sha256'].upper() == runtime_hash, 'Visual acceptance runtime digest is stale.')
    if 'files' in runtime:
        require(inventory(runtime['files']) == expected_inventory, 'Visual acceptance runtime entries are stale.')
    else:
        require(runtime.get('file_count') == len(expected_inventory), 'Visual acceptance runtime count is missing or stale.')


def record_identity(record):
    file = path(record['path']).resolve()
    return file, record.get('bytes', file.stat().st_size), record['sha256'].upper()


def validate_bound_temporal_acceptance(visual, motion, report_path, expected_inventory, runtime_hash):
    binding = visual.get('motion_acceptance')
    require(isinstance(binding, dict) and {'path', 'bytes', 'sha256'} <= binding.keys(),
            'Temporal visual acceptance must be an exact bound file record, not review flags alone.')
    acceptance = read_json(file_record(binding))
    require(acceptance.get('passed') is True and acceptance.get('motion_reviewed') is True
            and acceptance.get('visual_aesthetic_passed') is True and acceptance.get('capture_checks_passed') is True
            and not acceptance.get('interim') and not acceptance.get('blocking_findings')
            and acceptance.get('limitations'), 'Current temporal visual acceptance is incomplete or interim.')
    review_runtime_binding(acceptance['runtime'], expected_inventory, runtime_hash)
    require(acceptance['harness_sha256'].upper() == motion['harness_sha256'].upper(),
            'Temporal visual acceptance belongs to another harness.')
    reviewed_report = file_record(acceptance['report_file'])
    require(reviewed_report.resolve() == path(report_path).resolve()
            and acceptance['report_file']['sha256'].upper() == visual['motion_report_sha256'].upper()
            and acceptance.get('capture_checks') == motion['checks'], 'Temporal visual acceptance names another report.')
    expected_cases = {(arena, quality) for arena in ARENAS for quality in ('High', 'Low')}
    cases = acceptance['cases']
    require(len(cases) == 10 and {(case['arena'], case['quality']) for case in cases} == expected_cases,
            'Temporal visual acceptance lacks an arena/tier.')
    for case in cases:
        require(case.get('passed') is True and case['reviewed_frames'] == 7
                and case['sample_seconds'] == [0, 2, 5, 10] and case['paused_frames_reviewed'] == 2
                and case['reset_frames_reviewed'] == 1 and case.get('findings')
                and case.get('pause_pixels_identical') is True
                and case.get('stage_reset_snapshot_matches_initial') is True,
                'A temporal visual case is incomplete or lacks explicit observations.')
    captures = acceptance['captures']
    original = {path(capture['file']).resolve(): capture for capture in motion['captures']}
    require(len(captures) == len(original) == 70 and {path(c['path']).resolve() for c in captures} == set(original),
            'Temporal visual acceptance does not review the exact seventy report images.')
    for capture in captures:
        source = original[path(capture['path']).resolve()]
        require(capture.get('reviewed') is True and capture.get('review_method')
                and record_identity(capture) == record_identity({'path': source['file'], 'sha256': source['sha256']})
                and all(capture[key] == source[key] for key in
                        ('arena', 'quality', 'purpose', 'tick', 'stage_tick', 'seconds', 'width', 'height'))
                and capture['state'].get('saved') is True
                and record_identity(capture['state']) == record_identity(source['state']),
                'Temporal visual acceptance image identity or scene-state binding differs.')
    return acceptance


def validate_bound_movie_acceptance(receipt, expected_inventory, runtime_hash):
    binding = receipt.get('visual_acceptance')
    require(isinstance(binding, dict) and {'path', 'bytes', 'sha256'} <= binding.keys(),
            'Movie review must have an exact bound acceptance file, not reviewed flags alone.')
    acceptance = read_json(file_record(binding))
    require(acceptance.get('passed') is True and acceptance.get('failures') == 0
            and acceptance['checks'] == len(acceptance['results']) and acceptance['checks'] > 0
            and all(result['passed'] for result in acceptance['results'])
            and not acceptance.get('blocking_findings') and acceptance.get('review_method')
            and acceptance.get('limitations'), 'Bound movie visual acceptance is incomplete.')
    review_runtime_binding(acceptance['runtime'], expected_inventory, runtime_hash)
    require(acceptance['harness_sha256'].upper() == receipt['harness_sha256'].upper()
            and acceptance['capture_runner_sha256'].upper() == receipt['runner_sha256'].upper(),
            'Bound movie acceptance belongs to another harness or capture runner.')
    historical_capture = read_json(file_record(acceptance['capture_receipt_before_visual_promotion']))
    require(historical_capture['capture_passed'] is True and historical_capture['unchanged_during_recording'] is True
            and not historical_capture['problems'] and historical_capture['harness_sha256'].upper() == receipt['harness_sha256'].upper()
            and historical_capture['runner_sha256'].upper() == receipt['runner_sha256'].upper(),
            'The separately preserved capture receipt is incomplete or belongs to another recording.')
    review_runtime_binding(historical_capture['runtime'], expected_inventory, runtime_hash)
    cases = acceptance['cases']
    require(len(cases) == 5 and {case['arena'] for case in cases} == set(ARENAS)
            and len(historical_capture['cases']) == 5
            and {case['arena'] for case in historical_capture['cases']} == set(ARENAS),
            'Bound movie acceptance or preserved capture receipt lacks an arena.')
    for reviewed in cases:
        case = next(case for case in receipt['cases'] if case['arena'] == reviewed['arena'])
        historical = next(case for case in historical_capture['cases'] if case['arena'] == reviewed['arena'])
        require(reviewed.get('passed') is True and reviewed.get('reviewed') is True and reviewed['quality'] == case['quality'] == 'High'
                and reviewed.get('observations') and reviewed.get('readability')
                and record_identity(reviewed['movie']) == record_identity(case['movie']) == record_identity(historical['movie'])
                and all(reviewed['movie'][key] == case['movie'][key] for key in
                        ('width', 'height', 'fps', 'duration_seconds', 'video_frames', 'decoded', 'reviewed'))
                and record_identity(reviewed['report_file']) == record_identity(case['report_file'])
                and reviewed['decode_process'] == next(process for process in case['processes']
                                                       if process['label'] == case['arena'] + ' full decode'),
                'Bound movie acceptance clip/report/decode identity differs.')
        report = read_json(file_record(case['report_file']))
        states = report['cases'][0]['samples']
        require(len(reviewed['source_states']) == len(states) == 5
                and all(record_identity(accepted) == record_identity(source['state'])
                        and accepted['tick'] == source['tick'] and accepted['seconds'] == source['seconds']
                        for accepted, source in zip(reviewed['source_states'], states)),
                'Bound movie acceptance scene-state identities differ.')
        require(len(reviewed['samples']) == len(case['samples']) == 4
                and [sample['seconds'] for sample in reviewed['samples']] == [0, 2, 5, 10],
                'Bound movie acceptance lacks four sampled frames.')
        for accepted, source in zip(reviewed['samples'], case['samples']):
            require(accepted.get('reviewed') is True and record_identity(accepted) == record_identity(source)
                    and all(accepted[key] == source[key] for key in ('seconds', 'width', 'height', 'reviewed')),
                    'Bound movie acceptance sampled-frame identity differs.')
    return acceptance


def assertion_count(suite):
    value = suite.get('checks')
    return len(value) if isinstance(value, list) else int(value or 0)


def load_profile_reports(directory, provenance):
    require(provenance.get('passed') is True and provenance['unchanged_during_profiling']
            and len(provenance['cases']) > 0, f'Incomplete profile provenance: {directory}')
    render_cap = provenance.get('render_cap')
    require(type(render_cap) is int and 0 <= render_cap <= 240 and provenance.get('vsync') == 'disabled',
            f'Profile provenance lacks the actual render cap and disabled VSync: {directory}')
    reports = []
    for case in provenance['cases']:
        require(case['arena'] in ARENAS and case['quality'].lower() in {'high', 'low'} and
                case['file'] == f'{case["arena"]}_{case["quality"].lower()}_4p.json',
                f'Unexpected profile case: {directory}')
        file = directory / case['file']
        check_hash(file, case['sha256'])
        report = read_json(file)
        require(case.get('render_cap') == report.get('render_cap') == render_cap
                and case.get('vsync') == report.get('vsync') == provenance['vsync']
                and report.get('renderer') == 'forward_plus',
                f'Profile render cap, VSync or renderer differs from provenance: {file}')
        require(case['requested_seconds'] >= 60 and case['arena'] == report['arena'] and
                case['quality'].lower() == report['quality'].lower() and case['players'] == report['players'] == 4
                and report['duration_seconds'] >= 59 and report['simulation_ticks_in_sample_window'] >= 3300
                and report['frame_intervals']['count'] >= 100 and report['viewport_render_cpu']['available']
                and report['viewport_render_gpu']['available'] and report['captured_pixels'] == '(1920, 1080)'
                and report['readback_inside_sample_window'] is False,
                f'Incomplete isolated 1080p performance case: {file}')
        reports.append(report)
    require(len({(p['arena'], p['quality'].lower(), p['players']) for p in reports}) == len(reports),
            f'Duplicate cases within profile provenance: {directory}')
    return reports


def validate_uncapped_failure():
    failure = read_json(UNCAPPED_FAILURE)
    require(failure['passed'] is False and failure['render_cap'] == 0 and failure['vsync'] == 'disabled'
            and failure['status'] == 'uncapped_matrix_aborted_during_lunar_reach_high'
            and failure['failed_case'] == 'lunar_reach_high_4p' and failure['native_exit_code'] is None
            and set(failure['completed_partial_reports']) == {'rooftop_riot_high_4p.json', 'rooftop_riot_low_4p.json'}
            and failure['cause'].startswith('Unknown') and failure.get('native_receipt_limitation')
            and failure.get('observation'), 'Preserved uncapped failure record is missing or changes the observed scope.')
    folder = path(UNCAPPED_FAILURE).parent.resolve()
    files = {}
    for artifact in failure['artifacts']:
        file = file_record(artifact).resolve()
        require(file.parent == folder and file.name not in files, 'Uncapped failure artifact is duplicated or outside its preserved folder.')
        files[file.name] = file
    engine = files['lunar_reach_high_4p.log'].read_text(encoding='utf-8', errors='replace')
    require('print_lost_device_info' in engine and 'BLIT_PASS' in engine and 'UI_PASS' in engine
            and 'signal 11' in engine and 'nvoglv64.dll' in engine,
            'Preserved engine output does not establish the recorded lost-device crash.')
    for name in ('lunar_reach_high_4p.native.log', 'lunar_reach_high_4p.process_failure.json'):
        data = files[name].read_bytes()
        require(data and data.count(b'\0') == len(data), 'Preserved corrupt native evidence no longer matches the stated NUL-file limitation.')
    return failure


def performance_table(reports):
    table = ('| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |\n'
             '|---|---|---:|---:|---:|---:|---:|---:|\n')
    for report in reports:
        f = report['frame_intervals']
        table += (f'| {ARENAS[report["arena"]]} | {report["quality"]} | {f["count"]:,} | '
                  f'{f["p95_ms"]:.3f} / {f["p99_ms"]:.3f} | {f["max_ms"]:.3f} | {f["over_16_667"]} | '
                  f'{report["viewport_render_cpu"]["p95_ms"]:.3f} | {report["viewport_render_gpu"]["p95_ms"]:.3f} |\n')
    return table


def fresh_record(value, latest_runtime, label):
    file = path(value)
    require(file.stat().st_mtime_ns >= max(latest_runtime,
            (ROOT / 'tools/validation/living_background_review.gd').stat().st_mtime_ns),
            f'{label} predates current runtime or motion harness: {file}')
    return file


def living_state(record, seconds, quality):
    require(record.get('saved') is True, 'A scenery state did not save.')
    check_hash(record['path'], record['sha256'])
    state = read_json(record['path'])
    require(state['stage_tick'] == round(seconds * 60) and state['quality'] == quality
            and not state['engine_time_shaders'], 'Scenery state has wrong clock, tier or engine TIME.')
    clocks = [c for c in state['clocks'].values() if c['name'] != 'blue_hour']
    require(clocks and all(isinstance(c['value'], (int, float)) and
            abs(c['value'] - seconds) < 1e-5 for c in clocks), 'A scenery shader clock is stale.')
    return state


def living_capture(record, seconds, quality):
    require(record['saved'] and record['tick'] == record['stage_tick'] == round(seconds * 60)
            and record['quality'] == quality and abs(record['seconds'] - seconds) < 1e-5
            and record['window_size'] == [1920, 1080], 'Invalid scenery sample identity.')
    file = path(record['file'])
    png_record({'path': str(file), 'bytes': file.stat().st_size, 'sha256': record['sha256'],
                'width': record['width'], 'height': record['height']})
    return living_state(record['state'], seconds, quality)


def validate_living_report(value, latest_runtime):
    file = fresh_record(value, latest_runtime, 'Living scenery report')
    report = read_json(file)
    check_hash('tools/validation/living_background_review.gd', report['harness_sha256'])
    require(report['passed'] and report['failures'] == 0 and not report['movie']
            and report['checks'] == len(report['results']) and all(c['passed'] for c in report['results'])
            and report['renderer'] == 'forward_plus' and set(report['arenas']) == set(ARENAS)
            and set(report['qualities']) == {'High', 'Low'}, 'Living scenery regression is incomplete.')
    require(len(report['cases']) == 10 and {(c['arena'], c['quality']) for c in report['cases']} ==
            {(arena, quality) for arena in ARENAS for quality in ('High', 'Low')}, 'Living regression lacks an arena/tier.')
    require(len(report['captures']) == 70, 'Expected seventy motion/pause/reset scenery captures.')
    case_capture_paths = []
    for case in report['cases']:
        quality = case['quality']
        prefix = case['arena'] + '_' + quality.lower()
        samples = case['samples']
        require(len(samples) == 4 and [s['tick'] for s in samples] == [0, 120, 300, 600],
                f'Incomplete timed samples: {prefix}')
        states = [living_capture(s, seconds, quality) for s, seconds in zip(samples, (0, 2, 5, 10))]
        for sample in samples:
            require(sample['arena'] == case['arena'] and sample['purpose'] == 'motion_sample',
                    'Motion sample arena/purpose differs.')
            case_capture_paths.append(path(sample['file']))
            fresh_record(sample['file'], latest_runtime, 'Timed scenery capture')
            fresh_record(sample['state']['path'], latest_runtime, 'Timed scenery state')
        require(len(case['motion']) == 3 and all(m['visible_pose_changes'] > 0 or
                m['visible_clock_changes'] > 0 for m in case['motion']), 'A tier has no tracked scenery motion.')
        require([(m['from_tick'], m['to_tick']) for m in case['motion']] ==
                [(0, 120), (120, 300), (300, 600)], 'Motion intervals differ from captured samples.')
        pause = case['pause']
        require(pause['render_frames_without_steps'] == 10, 'Pause render-frame window differs.')
        paused_a = living_capture(pause['before'], 10, quality)
        paused_b = living_capture(pause['after'], 10, quality)
        reset = living_capture(case['reset'], 0, quality)
        require(paused_a == paused_b == states[-1], 'Scenery state changed while paused.')
        require(reset == states[0] == living_state(case['initial_state'], 0, quality),
                'Reset did not reproduce initial scenery state.')
        require(living_state(case['final_state'], 10, quality) == states[-1], 'Final scenery state differs.')
        require(all(s['platforms'] == states[0]['platforms'] for s in states), 'Motion fixture changed collision planes.')
        for suffix in ('pause freezes tracked scenery through ten render frames',
                       'paused world rejects sixty requested simulation steps',
                       'graphics roundtrip restores poses, uniforms, visibility and detail counts',
                       'quality changes preserve collision data',
                       'match reset restores initial scenery poses, clocks and quality'):
            require(any(r['name'] == prefix + ' ' + suffix and r['passed'] for r in report['results']),
                    f'Required motion assertion absent: {prefix} {suffix}')
        case_capture_paths.extend(path(c['file']) for c in (pause['before'], pause['after'], case['reset']))
        for capture in (pause['before'], pause['after'], case['reset']):
            fresh_record(capture['file'], latest_runtime, 'Pause/reset capture')
            fresh_record(capture['state']['path'], latest_runtime, 'Pause/reset scenery state')
    require(len(set(case_capture_paths)) == 70 and set(case_capture_paths) ==
            {path(c['file']) for c in report['captures']}, 'Scenery report capture list differs from cases.')
    return report


def validate_movies(value, expected_inventory, runtime_hash, latest_runtime):
    receipt = read_json(value)
    require(receipt.get('passed') is True and not receipt.get('blocking_findings'),
            'Current motion media has not passed review.')
    require(receipt.get('capture_passed') is True and receipt.get('unchanged_during_recording') is True
            and not receipt.get('problems'), 'Current motion capture or source preservation is incomplete.')
    require(inventory(receipt['runtime']['files']) == expected_inventory and
            receipt['runtime']['sha256'].upper() == runtime_hash, 'Motion media source binding is stale.')
    check_hash('tools/validation/living_background_review.gd', receipt['harness_sha256'])
    check_hash(receipt['runner_path'], receipt['runner_sha256'])
    require(len(receipt['cases']) == 5 and {c['arena'] for c in receipt['cases']} == set(ARENAS),
            'Expected five current ambient movies, one per arena.')
    for case in receipt['cases']:
        require(case['quality'] == 'High' and case['capture_passed'] is True
                and case['reviewed'] is True and not case['problems'], 'Ambient clip has unexpected tier or incomplete capture/review.')
        movie = case['movie']
        file = file_record(movie)
        require(file == ROOT / 'evidence/background_rebuild/motion' / case['arena'] / 'ambient.mp4',
                'Unexpected current ambient movie destination.')
        require(movie['width'] >= 1280 and movie['height'] >= 720 and movie['fps'] == 60
                and 11.99 <= movie['duration_seconds'] <= 12.10 and movie['decoded'] is True
                and movie['reviewed'] is True and movie['video_frames'] == 720,
                'Ambient clip is incomplete, undecoded or unreviewed.')
        for log in case['logs'].values(): file_record(log)
        require(len(case['samples']) == 4 and [s['seconds'] for s in case['samples']] == [0, 2, 5, 10],
                'Ambient clip has incomplete visual samples.')
        for sample in case['samples']:
            require(sample['width'] == movie['width'] and sample['height'] == movie['height']
                    and sample['reviewed'] is True, 'Ambient sample is resized or unreviewed.')
            sample_file = file_record(sample)
            with sample_file.open('rb') as stream: header = stream.read(24)
            require(header[:8] == b'\x89PNG\r\n\x1a\n' and header[12:16] == b'IHDR'
                    and struct.unpack('>II', header[16:24]) == (movie['width'], movie['height']),
                    'Ambient sample dimensions differ from measured video.')
        fresh_record(file, latest_runtime, 'Ambient movie')
        report_file = file_record(case['report_file'])
        fresh_record(report_file, latest_runtime, 'Ambient capture report')
        report = read_json(report_file)
        require(report['passed'] and report['failures'] == 0 and report['movie']
                and report['checks'] == len(report['results']) and all(r['passed'] for r in report['results'])
                and report['arenas'] == [case['arena']] and report['qualities'] == ['High']
                and report['renderer'] == 'forward_plus' and report['harness_sha256'].upper() ==
                receipt['harness_sha256'].upper() and len(report['cases']) == 1,
                'Ambient capture source harness report is incomplete.')
        capture = report['cases'][0]
        require(capture['arena'] == case['arena'] and capture['quality'] == 'High'
                and capture['simulation_ticks'] == 720 and capture['simulation_seconds'] == 12.0
                and capture['movie_writer_fps'] == 60 and capture['resolution'] == [1920, 1080]
                and capture['frame_readbacks_during_movie'] == 0 and capture['scenery_draw_frames'] >= 720,
                'Ambient capture did not produce the full requested fixture.')
        require([s['tick'] for s in capture['samples']] == [0, 120, 300, 600, 720], 'Ambient sample ticks differ.')
        for sample in capture['samples']: living_state(sample['state'], sample['seconds'], 'High')
    validate_bound_movie_acceptance(receipt, expected_inventory, runtime_hash)
    return receipt


def promote(document, section, relative):
    """Own one marked current section and retain every earlier record verbatim."""
    document = re.sub(re.escape(BEGIN) + r'\n.*?' + re.escape(END) + r'\n*',
                      '', document, flags=re.S)
    first, separator, remainder = document.partition('\n')
    require(separator and first.startswith('# '), f'Expected document title: {relative}')
    remainder = remainder.lstrip('\n')
    if HISTORY not in remainder:
        # Keep earlier platform/map sections, metrics and failure records
        # verbatim. The heading here explicitly scopes their old current claims.
        historical = ('\n\n' + HISTORY + '\n## Historical records before the living-background upgrade\n\n'
                      'The retained notes below describe earlier build snapshots. Their '
                      'screenshots, movies, runtime counts, metrics and package names are '
                      'historical; current living-background acceptance is above. Any '
                      'earlier heading or text calling a result current applies only to '
                      'its recorded snapshot. The preceding platform runtime, docs, '
                      'tools and Windows build are preserved under '
                      '`evidence/background_rebuild/baseline/`. Earlier failure '
                      'histories remain retained.\n'
                      '<!-- LIVING_ARENAS_HISTORY_END -->\n\n')
        remainder = historical.lstrip('\n') + remainder
    return first + '\n\n' + BEGIN + '\n' + section.strip() + '\n' + END + '\n\n' + remainder


def main():
    require(len(sys.argv) >= 2,
            'Usage: python update_delivery_notes.py COMPLETED_MATRIX_DIRECTORY [COMPLETED_REPEAT_DIRECTORY ...]')
    profiles_dir = Path(sys.argv[1]).resolve()
    repeat_dirs = [Path(value).resolve() for value in sys.argv[2:]]
    require(len(set(repeat_dirs)) == len(repeat_dirs) and profiles_dir not in repeat_dirs,
            'Repeat directories must be distinct from each other and the original matrix.')
    profile_rel = profiles_dir.relative_to(ROOT).as_posix()
    gate = read_json('evidence/validation_all.json')
    build = read_json('builds/windows/build_manifest.json')
    package = read_json('evidence/windows_release_flow/validation.json')
    release = read_json('evidence/map_expansion/release_validation.json')
    flow = read_json('evidence/rebuild/match_flow.json')
    visual = read_json('evidence/background_rebuild/visualreview.json')
    preservation = read_json('evidence/background_rebuild/preservation.json')
    provenance = read_json(profiles_dir / 'profile_provenance.json')
    baseline = read_json('evidence/background_rebuild/baseline.json')
    for name, receipt in (('source gate', gate), ('Windows validation', package),
                          ('map EXE validation', release), ('visual review', visual),
                          ('profiles', provenance), ('preservation', preservation)):
        require(receipt.get('passed') is True, f'{name} has not passed.')
    require(gate['runtime_unchanged_during_validation'] and gate['failed_suites'] == 0 and
            gate['completed_suites'] == gate['expected_suites'] == len(gate['suites']) and
            gate['completed_suites'] >= 12, 'Complete source gate is required.')
    for suite in gate['suites']:
        require(suite['passed'] and suite['exit_code'] == 0 and not suite.get('problems') and
                not suite.get('unexpected_error_lines') and not suite.get('unexpected_warning_lines'),
                f'Source suite is incomplete: {suite["name"]}')
        if suite.get('script_sha256'):
            match = re.search(r'--script\s+"([^"]+)"', suite['command'])
            require(match is not None, f'Cannot identify suite script: {suite["name"]}')
            check_hash(match[1], suite['script_sha256'])
    originals = gate['roster_preflight']['original_sources']
    require(gate['roster_preflight']['originals_preserved'] and len(originals) == 8,
            'Expected eight preserved supplied originals.')
    for original in originals:
        require(original['preserved'] and original['actual_sha256'].upper() == original['expected_sha256'].upper(),
                f'Original preservation failed: {original["path"]}')
        check_hash(original['path'], original['expected_sha256'])
    expected = inventory(build['runtime_source_files'])
    count = len(expected)
    runtime_hash = gate['runtime']['sha256'].upper()
    require(inventory(gate['runtime']['files']) == expected == inventory(provenance['runtime']['files'])
            == inventory(visual['runtime']['files']), 'Acceptance receipts describe different runtime inventories.')
    require(provenance['runtime']['sha256'].upper() == runtime_hash == visual['runtime']['sha256'].upper()
            and provenance['unchanged_during_profiling'], 'Source/profile/visual binding is stale.')
    preserved_runtime = preservation.get('runtime', preservation.get('current_runtime'))
    require(isinstance(preserved_runtime, dict) and inventory(preserved_runtime['files']) == expected
            and preserved_runtime['sha256'].upper() == runtime_hash, 'Preservation runtime binding is stale.')
    preservation_checks = preservation.get('checks', preservation.get('results'))
    require(isinstance(preservation_checks, list) and preservation_checks
            and all(c['passed'] for c in preservation_checks), 'Preservation invariants are incomplete.')
    project = ROOT / 'Game File'
    extensions = {'.gd', '.gdshader', '.godot', '.tscn', '.tres', '.glb', '.png', '.jpg', '.jpeg',
                  '.svg', '.wav', '.ogg', '.json', '.import', '.uid', '.cfg'}
    runtime_files = {p.relative_to(project).as_posix(): p for p in project.rglob('*')
                     if p.is_file() and '.godot' not in p.relative_to(project).parts and p.suffix in extensions
                     and not p.name.startswith('source_') and p.name not in {'validate_input.gd', 'engine.png'}}
    require(runtime_files.keys() == expected.keys(), 'Current runtime file set differs from the exported build.')
    for relative, file in runtime_files.items():
        require(file.stat().st_size == expected[relative][0], f'Runtime file size changed: {relative}')
        check_hash(file, expected[relative][1])
    original_bitmaps = [r for r in baseline['runtime']['files']
                        if Path(r['path']).suffix.lower() in {'.png', '.jpg', '.jpeg'}]
    require(original_bitmaps, 'The preserved baseline has no original bitmap inventory.')
    for original in original_bitmaps:
        file_record(original, project)
    build_hashes = {'executable': build['exe_sha256'].upper(), 'pck': build['pck_sha256'].upper(),
                    'manifest': sha256('builds/windows/build_manifest.json')}
    for key, file in (('executable', 'RooftopRiot.exe'), ('pck', 'RooftopRiot.pck')):
        check_hash(ROOT / 'builds/windows' / file, build_hashes[key])
    require(package['build_unchanged_during_validation'] and release['build_unchanged_during_validation'],
            'Windows build changed during validation.')
    for key, field in (('executable', 'executable_sha256'), ('pck', 'pck_sha256'), ('manifest', 'build_manifest_sha256')):
        require(package[field].upper() == build_hashes[key], f'UI receipt belongs to another {key}.')
        for moment in ('before', 'after'):
            require(release[f'build_hashes_{moment}'][key]['sha256'].upper() == build_hashes[key],
                    f'EXE receipt belongs to another {key}.')
            file_record(release[f'build_hashes_{moment}'][key])
    for moment in ('before', 'after'):
        require(package[f'runtime_source_hashes_verified_{moment}'] == count, 'UI runtime count is stale.')
        current = release[f'runtime_inventory_{moment}']
        require(current['files'] == count and current['sha256'].upper() == runtime_hash and
                current['manifest_inventory_sha256'].upper() == runtime_hash, 'EXE runtime inventory is stale.')
    ui = package['pck_ui_harness']
    require(ui['passed'] and ui['checks'] == 108 and len(ui['captured_images']) == 40 and
            ui['exit_code'] == 0 and not ui['timed_out'] and not ui['errors'] and not ui['warnings']
            and not package.get('problems'), 'Current exported UI acceptance is incomplete.')
    check_hash('tools/validation/ui_flow.gd', ui['harness_sha256'])
    for capture in ui['captured_images']:
        png_record(capture, ROOT / 'evidence/windows_release_flow')
    default_smoke = package['release_executable_smoke']
    require(default_smoke['passed'] and default_smoke['exit_code'] == 0 and not default_smoke['timed_out']
            and default_smoke['ticks'] == 600 and default_smoke['fighters'] == 4 and default_smoke['contacts'] > 0
            and not default_smoke['errors'] and not default_smoke['warnings'], 'Actual default EXE smoke is incomplete.')
    png_record(default_smoke['capture'], ROOT / 'evidence/windows_release_flow')
    require(not release.get('problems') and len(release['cases']) == 3 and
            {c['requested_arena'] for c in release['cases']} == NEW_ARENAS, 'Actual map EXE coverage is incomplete.')
    check_hash('tools/validation/validate_map_release.ps1', release['harness_sha256'])
    for case in release['cases']:
        require(case['passed'] and case['reported_arena'] == case['requested_arena'] and case['exit_code'] == 0
                and not case['timed_out'] and case['ticks'] == 600 and case['contacts'] > 0
                and len(case['fighter_ids']) == 4 and len(case['reported_input_providers']) == 4
                and set(case['reported_input_providers']) == {'res://input/cpu_input_provider.gd'}
                and not case['problems'] and not case['errors'] and not case['warnings']
                and case['renderer'] == 'forward_plus' and case['settings']['graphics'] == 'High'
                and case['settings']['resolution'] == '1920x1080', 'Actual map EXE case is incomplete.')
        png_record(case['capture'])
        file_record(case['runtime_report_file'])
        file_record(case['log_files']['engine'])
        file_record(case['log_files']['native'])
        for moment in ('before', 'after'):
            for key, record in case[f'build_hashes_{moment}'].items():
                require(record['sha256'].upper() == build_hashes[key], 'Map EXE case build binding is stale.')
                file_record(record)
    require(flow['checks'] == 35 and flow['failures'] == 0 and flow['graphical'] and len(flow['matches']) == 5
            and len(flow['results']) == 35 and all(r['passed'] for r in flow['results'])
            and {m['arena'] for m in flow['matches']} == set(ARENAS), 'Five-arena lifecycle acceptance is incomplete.')
    require(all(m['ticks'] > 0 and m['contacts'] > 0 and m['kos'] > 0 and 'winner' in m['result']
                and m['result']['reason'] for m in flow['matches']), 'Lifecycle lacks a natural completed match.')
    latest_runtime = max(p.stat().st_mtime_ns for p in runtime_files.values())
    require((ROOT / 'evidence/rebuild/match_flow.json').stat().st_mtime_ns >=
            max(latest_runtime, (ROOT / 'tools/validation/rebuild_match_flow.gd').stat().st_mtime_ns),
            'Lifecycle report predates current source or harness.')
    check_hash('tools/validation/rebuild_stage_review.gd', visual['harness_sha256'])
    stage_report_file = file_record(visual['capture_report_file'])
    if 'report_path' in visual:
        require(path(visual['report_path']).resolve() == stage_report_file.resolve(), 'Arena review report aliases name different files.')
    if 'report_sha256' in visual:
        require(visual['report_sha256'].upper() == visual['capture_report_file']['sha256'].upper(), 'Arena review report aliases have different hashes.')
    stage_report = read_json(stage_report_file)
    captures = visual['captures']
    require(len(captures) == 25 and {(c['arena'], c['purpose']) for c in captures} ==
            {(arena, view) for arena in ARENAS for view in VIEWS}, 'Expected five current views on each arena.')
    require(not visual.get('blocking_findings'), 'Arena visual review has blocking findings.')
    require(len(stage_report['captures']) == 25 and all(c['saved'] is True for c in stage_report['captures'])
            and {path(c['file']).resolve() for c in stage_report['captures']} == {path(c['path']).resolve() for c in captures},
            'Arena visual review names different images than its bound capture report.')
    for capture in captures:
        require(capture['reviewed'] and capture['quality'].lower() ==
                ('low' if capture['purpose'] == 'low' else 'high'), 'A current arena view is unreviewed or has wrong quality.')
        png_record(capture)
        require(path(capture['path']).stat().st_mtime_ns >= latest_runtime,
                'A reviewed arena capture predates current source.')
    motion_report_path = visual.get('motion_report_path')
    require(motion_report_path and visual.get('motion_report_sha256'), 'Arena review lacks an exact temporal-report binding.')
    motion = validate_living_report(motion_report_path, latest_runtime)
    check_hash(motion_report_path, visual['motion_report_sha256'])
    validate_bound_temporal_acceptance(visual, motion, motion_report_path, expected, runtime_hash)
    movies = validate_movies('evidence/background_rebuild/motion/movie_receipt.json', expected,
                             runtime_hash, latest_runtime)
    media_dimensions = sorted({(c['movie']['width'], c['movie']['height']) for c in movies['cases']})
    movie_dimensions_text = ', '.join(f'{width}×{height}' for width, height in media_dimensions)
    check_hash('tools/validation/rebuild_performance.gd', provenance['harness_sha256'])
    require(provenance['art']['present'], 'Profile fighter-art report is missing.')
    check_hash('evidence/characters/hero_rebuild/release_assets.json', provenance['art']['sha256'])
    require(len(provenance['cases']) == 10, 'Expected ten current High/Low profiles.')
    profiles = load_profile_reports(profiles_dir, provenance)
    render_cap = provenance['render_cap']
    rate_description = (f'a {render_cap} FPS render cap' if render_cap else 'uncapped rendering') + ', with VSync disabled'
    failure = validate_uncapped_failure()
    require({(p['arena'], p['quality'].lower(), p['players']) for p in profiles} ==
            {(arena, quality, 4) for arena in ARENAS for quality in ('high', 'low')}, 'Profile arena/tier coverage differs.')
    repeats = []
    for directory in repeat_dirs:
        relative = directory.relative_to(ROOT).as_posix()
        receipt = read_json(directory / 'profile_provenance.json')
        require(inventory(receipt['runtime']['files']) == expected and
                receipt['runtime']['sha256'].upper() == runtime_hash,
                f'Repeat profile runtime binding is stale: {directory}')
        require(receipt['art']['present'] and receipt['art']['sha256'].upper() == provenance['art']['sha256'].upper()
                and receipt['harness_sha256'].upper() == provenance['harness_sha256'].upper()
                and receipt.get('render_cap') == render_cap and receipt.get('vsync') == provenance['vsync'],
                f'Repeat profile art/harness binding differs: {directory}')
        repeats.append((relative, load_profile_reports(directory, receipt)))
    check_hash(baseline['previous_archive'], baseline['previous_archive_sha256'])
    checks = sum(assertion_count(s) for s in gate['suites'])
    suite_counts = {s['name']: assertion_count(s) for s in gate['suites']}
    missed = sum(p['frame_intervals']['over_16_667'] for p in profiles)
    samples = sum(p['frame_intervals']['count'] for p in profiles)
    performance_claim = (f'The ten cases recorded {missed:,} intervals above 16.667 ms out of '
                         f'{samples:,} render-interval samples. All outliers remain in the original matrix table; '
                         'this is not a clean stable-60-FPS result across every case.'
                         if missed else f'All {samples:,} render intervals measured under {rate_description} stayed below 16.667 ms; this does not certify other rendering rates or uncapped stability.')
    rate_scope = (f'The full matrix uses {rate_description}. It measures this explicitly controlled workload and its '
                  'headroom against a 16.667 ms frame budget; it is not an uncapped stress result or a device/driver fix.')
    failure_summary = ('The earlier uncapped matrix stopped during Lunar Reach High after Vulkan lost-device breadcrumbs '
                       'and a native signal 11 crash; an unclean Windows restart was observed. Only the two Rooftop cases '
                       'completed. The failed native log and process-failure receipt became entirely NUL bytes and cannot '
                       'establish exit status. The intact engine log, partial reports and corrupt files are preserved in '
                       f'`{Path(UNCAPPED_FAILURE).parent.as_posix()}/`, with `failure.json` recording these limitations. '
                       'The root cause remains unknown. The capped matrix does not conceal, supersede or resolve that failure.')
    ticks = ', '.join(f'{ARENAS[p["arena"]]} {p["quality"]}: {p["simulation_ticks_in_sample_window"]:,}' for p in profiles)
    table = performance_table(profiles)
    repeat_section = ''
    repeat_summary = ''
    if repeats:
        repeat_count = sum(len(reports) for _, reports in repeats)
        repeat_summary = (f'An additional {repeat_count} unchanged-source repeat case(s) are recorded separately '
                          'in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers.')
        repeat_section = ('### Additional isolated repeats\n\nThe following completed one-minute repeats use the same '
                          'runtime inventory, accepted fighter-art report, measurement harness, render cap and VSync setting. They are '
                          'additional observations, not replacements for the original ten cases. Different results '
                          'do not establish an outlier cause or an overall clean performance result.\n\n')
        for relative, reports in repeats:
            repeat_missed = sum(p['frame_intervals']['over_16_667'] for p in reports)
            repeat_samples = sum(p['frame_intervals']['count'] for p in reports)
            repeat_section += (f'#### {Path(relative).name}\n\n'
                               f'{repeat_missed:,} intervals above 16.667 ms out of {repeat_samples:,} samples. '
                               f'[Bound repeat receipt](../{relative}/profile_provenance.json). '
                               'Summary JSON reports, native/engine logs and companion captures remain in '
                               f'`{relative}/`; the harness does not save the raw interval series.\n\n'
                               + performance_table(reports) + '\n')
    art_table = '''| Arena | Living background |
|---|---|
| The Last Resort | Drifting skyline clouds, gliding gulls, pool ripples, foliage and subtle guest movement |
| Lunar Reach | Tracking observatory dishes, a moving survey rover, beacons, a passing orbital relay and slow Earth motion |
| Verdant Shrine | Flowing waterfalls, drifting valley mist, swaying foliage and birds crossing the valley |
| Abyssal Observatory | Swimming fish schools, pulsing jellyfish, gliding mantas, suspended particles and drifting water-light rays |
| Ember Foundry | Flowing molten spillways, animated lava, rising smoke and embers around working machinery |
'''
    scope = ('All five arenas now have scene-specific moving backgrounds. The original illustrated '
             'mattes and photographs remain untouched; localized shader animation and layered '
             '3D scenery add movement, depth and setting-specific life. The picture does not wobble '
             'as a whole. Background motion follows the authoritative stage clock, freezes during '
             'pause and resets with the match. Low keeps the main ambient motion with fewer '
             'animals, particles or secondary details. The finished platforms, collision layouts, '
             'combat timing and Party hazard behavior are retained.')
    identity = (f'Exported **{build["build_timestamp_utc"]}** with Godot 4.7.2; **{count} runtime files** match '
                f'the current source, build, still-review, motion-media and performance inventories (`{runtime_hash}`).')
    counts = (f'{checks:,} source assertions; 25 reviewed 1080p arena views; '
              f'{motion["checks"]:,} scenery assertions/70 timed, pause and reset stills across High/Low; '
              f'five fully decoded 12-second/60 FPS ambient clips ({movie_dimensions_text}) with assistant sample-frame review; '
              'five completed CPU matches/35 lifecycle checks; '
              '108 exported-PCK UI checks/40 captures; actual Windows EXE smoke on each of the '
              f'three added arenas; ten isolated 60-second four-player profiles using {rate_description}.')
    reproduction = '''```powershell
$godot = 'D:\\Game Engines\\Godot\\Godot_v4.7.2-stable_win64_console.exe'
$project = Join-Path $PWD 'Game File'
$allArenas = @('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')
$review = Join-Path $PWD 'evidence/background_rebuild/review_reproduced'
$motionReview = Join-Path $PWD 'evidence/background_rebuild/review_motion_reproduced'
$profiles = Join-Path $PWD ('evidence/background_rebuild/performance/local-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& ./tools/validation/validate_all.ps1 -Godot $godot
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_stage_review.gd') -- "--output=$review"
# Inspect all 25 captures and record exact hashes/current runtime in visualreview.json.
& $godot --path $project --script (Join-Path $PWD 'tools/validation/living_background_review.gd') -- "--output=$motionReview"
# Review timed/pause/reset samples and bind the current motion report in visualreview.json.
python ./evidence/background_rebuild/record_movies.py --resume
# The runner trims 720 scenery frames, measures actual dimensions, fully decodes,
# and writes a pending receipt. Inspect all 0/2/5/10-second samples before marking
# movies/samples reviewed and promoting movie_receipt.json to passed. No upscaling.
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_match_flow.gd') -- "--evidence-root=$(Join-Path $PWD 'evidence/rebuild')"
& ./tools/validation/export_windows.ps1 -Godot $godot
& ./tools/validation/validate_windows_build.ps1 -Godot $godot
& ./tools/validation/validate_map_release.ps1
& ./tools/validation/profile_rebuild.ps1 -Arenas $allArenas -Qualities High,Low -Players 4 -Seconds 60 -Output $profiles
python ./evidence/background_rebuild/update_delivery_notes.py $profiles
# Add any completed unchanged-source repeats as further directory arguments:
# python ./evidence/background_rebuild/update_delivery_notes.py $profiles $repeatObservatory $repeatFoundry
& ./tools/validation/package_map_expansion.ps1 -PerformanceDirectory $profiles `
  -ArchivePath (Join-Path $PWD 'builds/RooftopRiot-Living-Arenas-Windows.zip') `
  -DeliveryReceiptPath (Join-Path $PWD 'evidence/background_rebuild/delivery.json')
```
'''
    if render_cap:
        reproduction = reproduction.replace('-Players 4 -Seconds 60 -Output $profiles',
                                            f'-Players 4 -Seconds 60 -RenderCap {render_cap} -Output $profiles')
    sections = {
        'README.md': f'''## Living arenas — validated Windows build

{scope}

{art_table}
Play the matching `builds/windows/RooftopRiot.exe` and `.pck`. The dedicated archive target is `{ARCHIVE}`; successful packaging writes `{DELIVERY}` and verifies every decoded ZIP entry. The preceding Platform-Upgrade archive remains unchanged.

{counts} {identity}

[Arena guide and reproduction](docs/MAP_EXPANSION.md) · [validation](docs/VALIDATION.md) · [current performance](docs/PERFORMANCE.md). The five clips under `evidence/background_rebuild/motion/` show stationary-player ambient presentation; they are not human playtesting or performance measurements. {LIMITS}
''',
        'STATUS.md': f'''## Living arenas — validated source and Windows build

{scope}

{counts} {identity}

{performance_claim} {repeat_summary} {rate_scope} Current data are in `{profile_rel}/`; still review is `evidence/background_rebuild/visualreview.json`, clock/pause/reset acceptance is `{path(motion_report_path).relative_to(ROOT).as_posix()}`, and current ambient media are bound in `evidence/background_rebuild/motion/movie_receipt.json`. Earlier map and fighter movies describe historical presentation.

{failure_summary}

Package target: `{ARCHIVE}`. The receipt `{DELIVERY}` establishes completion of archive packaging; this documentation generator does not certify an archive. Pre-background backups and the prior Platform-Upgrade ZIP are retained. {LIMITS}
''',
        'docs/VALIDATION.md': f'''## Living arenas — current acceptance

{identity}

| Check | Current result | Evidence |
|---|---|---|
| Source and preservation | Import plus all {len(gate['suites']) - 1} suites pass; {checks:,} assertions; eight supplied originals and {len(original_bitmaps)} existing bitmaps preserved | `evidence/validation_all.json`, `evidence/background_rebuild/preservation.json` |
| Stage/presentation/motion regression | {suite_counts['stages']} stage, {suite_counts['presentation_state']} presentation and {suite_counts['rebuild_animation']} animation assertions | Source gate suite records |
| Arena review | 25 exact, reviewed 1080p stills: High, Low, overlap, recovery and near-ledge on every arena | `evidence/background_rebuild/visualreview.json` |
| Scenery clocks and restoration | {motion['checks']:,} assertions across ten arena/tier cases; 0/2/5/10-second samples, pause through render frames and requested world steps, quality roundtrip and reset | `{path(motion_report_path).relative_to(ROOT).as_posix()}` |
| Current ambient clips | Five High/60FPS, 12-second stationary-player fixtures at measured {movie_dimensions_text}; exact media/harness reports hashed, full decode and assistant sample-frame review recorded | `evidence/background_rebuild/motion/movie_receipt.json` |
| Full lifecycle | Five natural CPU matches through results and rematch; 35 checks | `evidence/rebuild/match_flow.json` |
| Exported UI | 108 checks and 40 current 1080p images; matching editor loads the explicit exported PCK | `evidence/windows_release_flow/validation.json` |
| Actual executable | Default 600-tick/four-CPU run plus each added arena at 600 ticks with explicit CPU providers and contacts; clean exits | Windows receipt and `evidence/map_expansion/release_validation.json` |
| Performance | Ten current source/art/harness-bound 60-second High/Low cases, five arenas, four CPU fighters, 1080p; {rate_description} | `{profile_rel}/profile_provenance.json` |

Current stills establish assistant visual review of those exact images, including background composition, player visibility and landing-edge readability. The scenery harness proves clock ownership and deterministic pause/reset/restoration; state changes alone do not prove attractive or visible motion. Current ambient clips are fully decoded and their 0/2/5/10-second samples inspected for five stationary-player fixtures. Actual video dimensions ({movie_dimensions_text}) are measured separately from the 1080p stills and profile window, with no upscaling. These samples do not establish continuous human acceptance or every combat/recovery sequence. Earlier map movies and before/after fighter comparisons remain historical. Screenshot readback and movie capture are excluded from the profile window.

{performance_claim} {repeat_summary} {rate_scope}

{failure_summary}

The dedicated ZIP target is `{ARCHIVE}`. Packaging separately verifies source/build/UI/EXE/lifecycle/profile receipts and every archive entry, writing `{DELIVERY}`. {LIMITS}
''',
        'docs/PERFORMANCE.md': f'''## Living arenas — current four-player measurements

Ten isolated 60-second source-project cases cover all five arenas at 1920×1080 on High and Low, with four CPU fighters and authoritative 60 Hz combat. {rate_scope} {performance_claim} Measurements apply to the Ryzen 7700X / RTX 4080 SUPER workstation; they do not certify weaker PCs, the exported build or the separate Mobile renderer. The game code retains the engine's VSync defaults; this harness deliberately disables VSync and sets its recorded render cap. Its presentation pacing is therefore a different workload from ordinary synchronized play.

CPU rendering work, GPU rendering work and frame intervals are separate measures; their percentiles must not be added. Screenshot readback occurs after measurement. The provenance receipt binds every report to unchanged current runtime, accepted fighter art and the measurement harness. Summary JSON reports, engine/native logs and companion captures are in `{profile_rel}/`; the harness does not save the raw interval series.

Combat ticks by case: {ticks}.

### Completed full matrix at the recorded render rate

[Bound ten-case receipt](../{profile_rel}/profile_provenance.json). These original results remain intact, including every recorded outlier.

{table}
{repeat_section}
### Preserved aborted uncapped stress run

{failure_summary}

[Failure record and retained artifacts](../{UNCAPPED_FAILURE}). The failure record is not a completed performance provenance receipt; its two completed reports do not replace the full current ten-case matrix.

The living-background still and movie fixtures are visual evidence; movie capture and encoding overhead are not included in this matrix and are not performance results. Earlier platform, map and two-arena matrices below are historical workloads. The earlier Vulkan lost-device failure and reboot history remain retained; its cause was not established, and this background pass does not claim a driver fix.
''',
        'docs/WINDOWS_BUILD_README.md': f'''## Living arenas — validated Windows build

All five arenas have animated backgrounds, including swimming sea life in Abyssal Observatory and flowing lava in Ember Foundry. Low retains essential ambient motion with reduced detail. Motion freezes during pause and resets on rematch. The previously rebuilt platforms remain in place. {identity}

Double-click **RooftopRiot.exe** beside its matching **RooftopRiot.pck**. Start a Fight, choose fighters and arena, assign keyboard/controllers/CPUs, then Ready. Party/Fair Fight and rematch remain available. Default rendering uses Forward+; `Launch-Mobile.cmd` chooses the separate Mobile renderer after restart. Godot and Blender are not required to play.

The packaged archive target is `RooftopRiot-Living-Arenas-Windows.zip`; workspace receipt `{DELIVERY}` records successful archive verification. The exported UI passes 108 checks and actual Windows EXE runs cover the three added arenas. Current High/Low scenery-clock and restoration checks pass; five ambient clips provide stationary-player presentation evidence. Ten 1080p High/Low four-player cases are listed in `PERFORMANCE.md`. {performance_claim} {repeat_summary} {rate_scope}

The preceding uncapped Lunar Reach High stress case lost its Vulkan device and crashed. That failure and its unclean restart remain documented in `PERFORMANCE.md`; a driver or hardware fix has not been established.

{LIMITS}
''',
        'docs/MAP_EXPANSION.md': f'''## Living backgrounds — all five arenas

{scope}

{art_table}
Editable motion and shaders live under `Game File/stages/`, with shared distant-art integration in `arena_backdrop.gd` and its shader. Arena scripts own their 3D scenery, movement paths, detail counts and clock updates. The original distant-art bitmap files retain their map-expansion provenance; this pass creates no replacement image or character assets. Every original baseline PNG/JPEG and the supplied fighter originals are checked directly against their preserved hashes.

{identity} {counts}

Current still hashes and findings: `evidence/background_rebuild/visualreview.json`. Clock/pause/reset evidence: `{path(motion_report_path).relative_to(ROOT).as_posix()}`. Reviewed media: `evidence/background_rebuild/motion/movie_receipt.json`, with `motion/<arena>/ambient.mp4` for each arena. These are normal-speed 12-second/60 FPS stationary-player ambient fixtures at actual measured {movie_dimensions_text}, fully decoded with 0/2/5/10-second sample-frame inspection. They are not human gameplay or performance recordings.

Pre-background runtime, docs, tools and Windows build: `evidence/background_rebuild/baseline/`; baseline receipt: `evidence/background_rebuild/baseline.json`; invariant audit: `evidence/background_rebuild/preservation.json`. The prior `builds/RooftopRiot-Platform-Upgrade-Windows.zip` retains SHA-256 `{baseline['previous_archive_sha256']}`. Prior platform/map/fighter evidence remains historical.

### Reproduction

Run graphical still review, ambient movie captures, lifecycle, export, Windows validation and profiling sequentially. Freeze runtime sources before final captures/receipts. The notes generator requires current 25-view acceptance, scenery restoration and media receipts, original preservation, and matching source/build/profile hashes before it writes docs. The strict packager then creates `{ARCHIVE}` and `{DELIVERY}`; visual/media acceptance is independently checked and bound in the final background delivery audit.

{reproduction}
{LIMITS}
''',
        'docs/KNOWN_ISSUES.md': f'''## Living arenas — current validation limits

The five animated arenas pass the current 25-view assistant review, deterministic High/Low scenery-clock and restoration checks, source gate, five-match lifecycle and exported Windows checks. Five fully decoded 12-second ambient clips at measured {movie_dimensions_text} provide current 0/2/5/10-second assistant sample-frame review. {performance_claim} {repeat_summary} {rate_scope} Exact frame maxima and CPU/GPU percentiles are in [PERFORMANCE.md](PERFORMANCE.md); no outlier cause is inferred from aggregate samples.

{failure_summary}

- Still-image review covers High/Low, overlap, recovery and near-ledge fixtures. Scenery clips hold four stationary fighters in normal gameplay framing; this does not cover every moving-camera recovery, combat pose or platform transition.
- Human gameplay, continuous human motion/audio judgment and physical multi-controller operation remain unverified. The ambient clips do not establish sound-mix quality or competitive balance.
- The performance matrix covers this workstation at 1080p with four CPU fighters. Weaker-PC, current Mobile-renderer and exported-build performance remain unverified.
- Prior platform/map movies and historical fighter comparisons describe earlier builds. Current background evidence is limited to the explicitly bound stills, state checks and five ambient clips.
- Archive completion is recorded separately in `{DELIVERY}` after strict packaging; documentation promotion alone does not certify the ZIP.

Original-asset permission records and earlier engine/device failure histories below remain retained verbatim. No new permission or driver-resolution claim is made by this visual pass.
''',
    }
    documents = {}
    for relative, section in sections.items():
        file = ROOT / relative
        previous = file.read_text(encoding='utf-8-sig')
        documents[file] = promote(previous, section, relative)
    # Validate every tracked input once more before the first document write.
    # Failed/stale receipts leave all current docs untouched.
    for file, expected_hash in TRACKED.items():
        require(sha256(file) == expected_hash, f'Acceptance input changed while preparing notes: {file}')
    for file, document in documents.items():
        file.write_text(document, encoding='utf-8')
    print(json.dumps({'source_assertions': checks, 'runtime_files': count, 'arena_views': 25,
                      'scenery_checks': motion['checks'], 'scenery_stills': 70, 'ambient_movies': len(movies['cases']),
                      'original_bitmaps_preserved': len(original_bitmaps),
                      'performance_samples': samples, 'over_budget': missed, 'updated_documents': len(documents),
                      'repeat_directories': [relative for relative, _ in repeats],
                      'repeat_cases': sum(len(reports) for _, reports in repeats),
                      'profile_render_cap': render_cap, 'profile_vsync': provenance['vsync'],
                      'preserved_uncapped_failure': UNCAPPED_FAILURE,
                      'archive_target': ARCHIVE, 'archive_packaging_still_separate': True}))


if __name__ == '__main__':
    main()
