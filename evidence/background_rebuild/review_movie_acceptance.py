"""Bind assistant sample-frame findings to all five verified ambient clips.

Read-only media/source verification; this script never launches an engine or decoder.
Full decode evidence is independently checked against saved process and log records.
The visual observations were authored after inspecting all twenty actual MP4 samples.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import re
import struct
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'evidence/background_rebuild'
MOTION = EVIDENCE / 'motion'
RECEIPT = MOTION / 'movie_receipt.json'
HARNESS = ROOT / 'tools/validation/living_background_review.gd'
EXPECTED_RUNTIME = 'F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825'
EXPECTED_HARNESS = '5357D265B380F710F05F7875C85CB4136317F9514FCBE754A79095D27F6ADB69'
ARENAS = ('rooftop_riot', 'lunar_reach', 'verdant_shrine', 'abyssal_observatory', 'ember_foundry')
checks = []


def check(condition, name):
    checks.append({'name': name, 'passed': bool(condition)})
    if not condition:
        raise ValueError(name)


def sha(file):
    digest = hashlib.sha256()
    with Path(file).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest().upper()


def record(file):
    file = Path(file).resolve()
    return {'path': str(file), 'bytes': file.stat().st_size, 'sha256': sha(file)}


def read_json(file):
    return json.loads(Path(file).read_text(encoding='utf-8-sig'))


def verify_record(item, label):
    file = Path(item['path']).resolve()
    check(file.is_file() and file.stat().st_size == item['bytes']
          and sha(file) == item['sha256'].upper(), label + ' exact saved bytes and hash')
    return file


def boxes(blob, start=0, stop=None):
    stop = len(blob) if stop is None else stop
    while start < stop:
        if start + 8 > stop:
            raise ValueError('Truncated MP4 box header')
        size, kind = struct.unpack_from('>I4s', blob, start)
        header = 8
        if size == 1:
            size = struct.unpack_from('>Q', blob, start + 8)[0]
            header = 16
        elif size == 0:
            size = stop - start
        if size < header or start + size > stop:
            raise ValueError('Invalid MP4 box extent')
        yield kind, start + header, start + size
        start += size


def child(blob, parent, kind):
    candidates = [(a, b) for tag, a, b in boxes(blob, *parent) if tag == kind]
    if len(candidates) != 1:
        raise ValueError(f'Expected one MP4 {kind!r} box, found {len(candidates)}')
    return candidates[0]


def container_metadata(file):
    # Independent inspection of the current MP4 container, without FFmpeg.
    data = file.read_bytes()
    moov = child(data, (0, len(data)), b'moov')
    tracks = [(a, b) for tag, a, b in boxes(data, *moov) if tag == b'trak']
    video_tracks = []
    for track in tracks:
        mdia = child(data, track, b'mdia')
        hdlr = child(data, mdia, b'hdlr')
        if data[hdlr[0] + 8:hdlr[0] + 12] == b'vide':
            video_tracks.append(mdia)
    check(len(tracks) == len(video_tracks) == 1, file.parent.name + ' has one video track and no audio')
    mdia = video_tracks[0]
    mdhd = child(data, mdia, b'mdhd')
    version = data[mdhd[0]]
    if version == 0:
        timescale, duration = struct.unpack_from('>II', data, mdhd[0] + 12)
    elif version == 1:
        timescale = struct.unpack_from('>I', data, mdhd[0] + 20)[0]
        duration = struct.unpack_from('>Q', data, mdhd[0] + 24)[0]
    else:
        raise ValueError('Unknown MP4 mdhd version')
    minf = child(data, mdia, b'minf')
    stbl = child(data, minf, b'stbl')
    stsz = child(data, stbl, b'stsz')
    sample_count = struct.unpack_from('>I', data, stsz[0] + 8)[0]
    stts = child(data, stbl, b'stts')
    timing_count = struct.unpack_from('>I', data, stts[0] + 4)[0]
    timings = [struct.unpack_from('>II', data, stts[0] + 8 + index * 8)
               for index in range(timing_count)]
    sample_ticks = sum(count * delta for count, delta in timings)
    stsd = child(data, stbl, b'stsd')
    descriptions = list(boxes(data, stsd[0] + 8, stsd[1]))
    check(len(descriptions) == 1 and descriptions[0][0] == b'avc1', file.parent.name + ' current container is AVC video')
    _, avc_start, _ = descriptions[0]
    width, height = struct.unpack_from('>HH', data, avc_start + 24)
    return {'width': width, 'height': height, 'fps': sample_count * timescale / sample_ticks,
            'duration_seconds': duration / timescale, 'video_frames': sample_count,
            'timing_samples': sum(count for count, _ in timings), 'timescale': timescale,
            'duration_ticks': duration}


FINDINGS = {
    'rooftop_riot': {
        'observations': [
            'White gulls occupy different positions across the upper sky: visible left of the center platform at 2 seconds, toward the left at 5 seconds, and nearer the center again at 10 seconds.',
            'Pool ripple highlights change across the four samples; palm fronds show small position changes. The hotel and rail architecture remain stable.',
            'The guest bodies remain coherent. Small window-light variations and crowd motion support the rooftop ambience without covering the fighters.'
        ],
        'readability': 'Gulls stay above the exchange area; water and guest motion remain behind the fighters. Platform edges and all four fighters are clear.',
        'limits': ['Most painted clouds remain artwork; this sampled review does not claim that all cloud shapes visibly move.']
    },
    'lunar_reach': {
        'observations': [
            'The six-wheel rover advances left along the rear causeway from the middle gap toward Heavy Duty over the 0/2/5/10-second sequence.',
            'The large dish at the upper left changes its aim; its central receiver and projected silhouette shift over the sequence.',
            'Terrain and fighting platforms remain stable while the base activity changes behind them.'
        ],
        'readability': 'The rover is behind the main fighting deck and the dish is offset to the left. Their silhouettes do not cover the fighters or usable platform edges.',
        'limits': ['Earth/cloud rotation is very slow and is not conspicuous at gameplay distance over these four sample times. Orbital-relay flight is not asserted visible in this sample set. Visible-life acceptance relies on the clearly moving rover and dish.']
    },
    'verdant_shrine': {
        'observations': [
            'Bird silhouettes travel across the upper valley between the samples and clear the central platform.',
            'Native waterfall crops show changing irregular bright/dark ribbons and small refraction offsets confined to the cascade. Stone cliff and temple edges retain their positions.',
            'Mist and lagoon shading vary subtly around the waterfall foot; foliage changes remain restrained rather than moving the whole artwork.'
        ],
        'readability': 'The fighting area is foreground stone; bird activity is high in the valley and water activity stays on the painted falls. All four fighters and ledges remain readable.',
        'limits': ['Water and mist movement is subtle in separated still samples; the stored 60 FPS clip is the continuous preview. This receipt is assistant sample inspection, not a continuous human viewing claim.']
    },
    'abyssal_observatory': {
        'observations': [
            'Fish schools visibly travel laterally: the near window school crosses from the left toward the middle, while the lower right school swims left across the undercroft over 0/2/5/10 seconds.',
            'Jellyfish occupy changing positions; their bell proportions and trailing-filament shapes change. The right jellyfish rises while the left jellyfish drifts downward and left.',
            'A manta traverses the right window and exits to the right; the second manta glides past the lower left. The painted whale and reef remain a stable distant layer.'
        ],
        'readability': 'Fish, manta and jellyfish are behind the gallery. They make the window clearly active without covering the fighters or producing a central opaque layer.',
        'limits': ['The large whale and some distant fish are part of the supplied painted image; this review does not claim every painted animal is independently animated.']
    },
    'ember_foundry': {
        'observations': [
            'Native spillway crops show orange molten ribbons with cooled/bright streaks at different heights over 0/2/5/10 seconds. Advected material coordinates run downstream in the reviewed shader source.',
            'The left and right flywheel spokes turn between sample times, while their housings and chain routes remain fixed.',
            'Smoke and ember placements change around the rear structures. The molten palette stays orange and copper rather than the earlier pale cream.'
        ],
        'readability': 'Molten streams stay at the sides and behind the arena. Rear smoke remains thin, leaving the central fighters and platform lips clear.',
        'limits': ['Direction of flow is supported by the moving-material source and local changes in sampled frames; four stills alone do not establish continuous motion smoothness.']
    }
}


def main():
    receipt = read_json(RECEIPT)
    check(receipt['capture_passed'] and receipt['finished_utc'] and receipt['unchanged_during_recording']
          and not receipt['problems'], 'All five capture operations finished successfully before review')
    check(receipt['runtime']['sha256'] == EXPECTED_RUNTIME, 'Expected frozen runtime is the captured runtime')
    check(receipt['harness_sha256'] == EXPECTED_HARNESS and sha(HARNESS) == EXPECTED_HARNESS,
          'Captured movie harness is the current movie harness')
    spec = importlib.util.spec_from_file_location('background_movie_capture', EVIDENCE / 'record_movies.py')
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    runner.verify_runtime(receipt['runtime'])
    check(True, 'Every captured runtime file matches the current complete runtime inventory')
    check(sha(EVIDENCE / 'record_movies.py') == receipt['runner_sha256'], 'Capture runner remains unchanged')
    verify_record(receipt['source_inventory_receipt'], 'Source inventory receipt')
    check(len(receipt['cases']) == 5 and {case['arena'] for case in receipt['cases']} == set(ARENAS),
          'Exactly the five requested arenas are present')
    accepted = []
    source_evidence = []
    for arena in ARENAS:
        case = next(case for case in receipt['cases'] if case['arena'] == arena)
        check(case['quality'] == 'High' and case['capture_passed'] and not case['problems'], arena + ' complete High capture')
        movie_file = verify_record(case['movie'], arena + ' MP4')
        movie = case['movie']
        metadata = container_metadata(movie_file)
        check(all(metadata[key] == movie[key] for key in ('width', 'height', 'fps', 'duration_seconds', 'video_frames')),
              arena + ' container matches reported media dimensions and timing')
        check(metadata['width'] == 1600 and metadata['height'] == 900 and metadata['fps'] == 60
              and metadata['duration_seconds'] == 12 and metadata['video_frames'] == metadata['timing_samples'] == 720,
              arena + ' actual media is native 1600x900 with 720 frames at 60 FPS for 12 seconds')
        for kind, item in case['logs'].items():
            verify_record(item, arena + ' ' + kind + ' log')
        process_map = {process['label']: process for process in case['processes']}
        for phase in ('engine capture', 'encode', 'full decode'):
            process = process_map[arena + ' ' + phase]
            check(process['exit_code'] == 0 and not process['timed_out'] and process['finished_utc'], arena + ' ' + phase + ' terminal exit success')
            log_file = verify_record(process['log'], arena + ' ' + phase + ' process log')
            log = log_file.read_text(encoding='utf-8', errors='replace')
            check('EXIT_CODE 0' in log and 'TIMED_OUT False' in log, arena + ' ' + phase + ' log termination proof')
            if phase == 'engine capture':
                check(not runner.PROBLEM.search(log), arena + ' clean graphical engine output')
            if phase == 'encode':
                check('progress=end' in log and re.search(r'(?m)^frame=720\s*$', log), arena + ' encode completed all 720 frames')
            if phase == 'full decode':
                decoded = runner.metadata_from_decode(log_file)
                check(all(decoded[key] == metadata[key] for key in ('width', 'height', 'fps', 'duration_seconds', 'video_frames'))
                      and 'progress=end' in log and str(movie_file) in log,
                      arena + ' decoder reached end of this complete current MP4')
        report_file = verify_record(case['report_file'], arena + ' source movie report')
        report = read_json(report_file)
        check(report['passed'] and report['failures'] == 0 and report['checks'] == len(report['results'])
              and all(result['passed'] for result in report['results']) and report['harness_sha256'].upper() == EXPECTED_HARNESS
              and report['arenas'] == [arena] and report['qualities'] == ['High'] and len(report['cases']) == 1,
              arena + ' current single-arena source harness passed all reported checks')
        source = report['cases'][0]
        check(source['simulation_ticks'] == 720 and source['simulation_seconds'] == 12
              and source['movie_writer_fps'] == 60 and source['scenery_draw_frames'] >= 720
              and source['frame_readbacks_during_movie'] == 0, arena + ' 720 scene ticks and frames without screenshot overhead')
        state_records = []
        for item in source['samples']:
            state = item['state']
            path = Path(state['path'])
            check(state['saved'] and sha(path) == state['sha256'].upper(), arena + f" source scene state at tick {item['tick']} exact hash")
            state_records.append({**record(path), 'seconds': item['seconds'], 'tick': item['tick']})
        check([item['tick'] for item in source['samples']] == [0, 120, 300, 600, 720], arena + ' five expected simulation snapshots')
        check(len(case['samples']) == 4 and [item['seconds'] for item in case['samples']] == [0, 2, 5, 10], arena + ' four expected MP4 sample times')
        samples = []
        for item in case['samples']:
            file = verify_record(item, arena + f" actual MP4 sample at {item['seconds']} seconds")
            check(runner.png_dimensions(file) == (1600, 900), arena + f" sample at {item['seconds']} seconds retains actual movie size")
            extraction = item['extraction']
            check(extraction['exit_code'] == 0 and not extraction['timed_out'] and extraction['finished_utc'],
                  arena + f" sample at {item['seconds']} seconds successfully extracted")
            extraction_file = verify_record(extraction['log'], arena + f" extraction log at {item['seconds']} seconds")
            extraction_log = extraction_file.read_text(encoding='utf-8', errors='replace')
            extraction_command = json.loads(extraction_log.splitlines()[0].removeprefix('COMMAND '))
            check(str(movie_file) in extraction_command and str(file) in extraction_command and 'EXIT_CODE 0' in extraction_log,
                  arena + f" sample at {item['seconds']} seconds is from this MP4")
            samples.append({**record(file), 'seconds': item['seconds'], 'width': 1600, 'height': 900, 'reviewed': True})
        accepted.append({'arena': arena, 'quality': 'High', 'passed': True, 'reviewed': True,
                         'movie': {**record(movie_file), **metadata, 'decoded': True, 'reviewed': True, 'audio': False},
                         'report_file': record(report_file), 'source_states': state_records, 'samples': samples,
                         'decode_process': process_map[arena + ' full decode'], **FINDINGS[arena]})
    for relative in ('Game File/stages/ember_foundry/caldera_spillway.gdshader',
                     'Game File/stages/verdant_shrine/shrine_backdrop.gdshader',
                     'Game File/stages/lunar_reach/earth.gdshader'):
        source_evidence.append(record(ROOT / relative))
    supplementary = [record(EVIDENCE / f'qa_crop_{arena}.png') for arena in ('verdant_shrine', 'ember_foundry', 'lunar_reach')]
    check(all(case['passed'] and len(case['samples']) == 4 for case in accepted) and len(accepted) == 5,
          'All five arenas and all twenty actual sample frames were reviewed; no partial matrix promoted')
    acceptance = {
        'passed': True, 'finished_utc': datetime.now(timezone.utc).isoformat(),
        'runtime': {'sha256': receipt['runtime']['sha256'], 'file_count': len(receipt['runtime']['files'])},
        'harness_sha256': EXPECTED_HARNESS, 'capture_runner_sha256': receipt['runner_sha256'],
        'capture_receipt_before_visual_promotion': record(RECEIPT),
        'review_method': 'Assistant visual inspection of all twenty native 1600x900 PNGs extracted from five current 12-second MP4s at 0, 2, 5 and 10 seconds; native crop comparisons for waterfall, spillway and Earth details.',
        'source_evidence': source_evidence, 'supplementary_qa_crops': supplementary,
        'checks': len(checks), 'failures': 0, 'results': checks, 'cases': accepted,
        'limitations': [
            'Assistant sampled-frame inspection is not continuous human viewing and may miss transient defects between samples.',
            'MP4 clips are measured native 1600x900, 60 FPS, 720 frames, 12 seconds. The source window is 1920x1080; movies were not upscaled and are not 1080p media.',
            'Fixed-FPS movie capture and saved scene-clock checks do not measure real-time performance.',
            'The four players remain at fixed positions in ambient fixtures; combat readability under active gameplay is covered separately.',
            'The clips have no audio. Human playtesting, physical controllers, and audio quality are not tested by this receipt.',
            'Decode completion and file hashes establish evidence identity and media integrity; visible-quality findings are recorded separately above.'
        ]
    }
    destination = EVIDENCE / 'movie_acceptance.json'
    destination.write_text(json.dumps(acceptance, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'passed': True, 'checks': len(checks), 'cases': len(accepted), 'samples': 20,
                      'path': str(destination), 'runtime': EXPECTED_RUNTIME}))


if __name__ == '__main__':
    main()
