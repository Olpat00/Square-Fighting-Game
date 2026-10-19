"""Independent read-only release audit. Run after profiling and packaging finish.

Only final_audit.json is written; no receipt, runtime, build or documentation is
modified. Standard-library-only, with streamed hashing and ZIP decompression.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "Game File"
BUILD = ROOT / "builds/windows"
RUNTIME_SHA = ""
RUNTIME_COUNT = 0
EXPECTED_RUNTIME = {}
OLD_ZIP_SHA = ""
OLD_ZIP = ROOT / "builds/RooftopRiot-Platform-Upgrade-Windows.zip"
NEW_ZIP = ROOT / "builds/RooftopRiot-Living-Arenas-Windows.zip"
UNCAPPED_FAILURE = 'evidence/background_rebuild/performance/aborted_uncapped_20261004/failure.json'
ARENAS = {"rooftop_riot", "lunar_reach", "verdant_shrine", "abyssal_observatory", "ember_foundry"}
NEW_ARENAS = ARENAS - {"rooftop_riot", "lunar_reach"}
VIEWS = {"high", "low", "overlap", "recovery", "near_ledge"}
EXTENSIONS = {".gd", ".gdshader", ".godot", ".tscn", ".tres", ".glb", ".png", ".jpg", ".jpeg", ".svg", ".wav", ".ogg", ".json", ".import", ".uid", ".cfg"}
TRACKED: dict[Path, str] = {}
CHECKS: list[str] = []


def require(condition, message):
    if not condition:
        raise ValueError(message)


def path(value, base=ROOT):
    result = Path(value)
    return (result if result.is_absolute() else base / result).resolve()


def stream_hash(stream):
    digest = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(chunk)
    return digest.hexdigest().upper()


def file_hash(value):
    with path(value).open("rb") as stream:
        return stream_hash(stream)


def check_hash(value, expected, size=None):
    file = path(value)
    require(re.fullmatch(r"[0-9A-Fa-f]{64}", str(expected)) is not None, f"Invalid SHA-256: {file}")
    actual = file_hash(file)
    require(actual == expected.upper(), f"SHA-256 differs: {file}")
    require(size is None or file.stat().st_size == size, f"Size differs: {file}")
    TRACKED[file] = actual
    return file


def read_json(value):
    file = path(value)
    TRACKED[file] = file_hash(file)
    return json.loads(file.read_text(encoding="utf-8-sig"))


def check_record(record, base=ROOT):
    return check_hash(path(record["path"], base), record["sha256"], record.get("bytes"))


def check_png(record, base=ROOT):
    file = check_record(record, base)
    with file.open("rb") as stream:
        header = stream.read(24)
    require(header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR", f"Invalid PNG: {file}")
    require(struct.unpack(">II", header[16:24]) == (1920, 1080), f"PNG dimensions differ: {file}")
    require((record["width"], record["height"]) == (1920, 1080), f"PNG receipt dimensions differ: {file}")


def inventory_hash(records):
    # Receipt order is the canonical PowerShell Sort-Object path order. Python
    # ordinal sorting would order punctuation differently on this Windows host.
    normalized = [{"path": r["path"].replace("\\", "/"), "bytes": int(r["bytes"]), "sha256": r["sha256"].upper()} for r in records]
    return hashlib.sha256(json.dumps(normalized, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest().upper()


def check_inventory(inventory):
    records = inventory["files"]
    normalized = {r["path"].replace("\\", "/"): (int(r["bytes"]), r["sha256"].upper()) for r in records}
    require(len(records) == len(normalized) == RUNTIME_COUNT, "Runtime inventory file count differs from the accepted source gate.")
    require(normalized == EXPECTED_RUNTIME, "Runtime inventory entries differ from the accepted source gate.")
    require(inventory["sha256"].upper() == RUNTIME_SHA and inventory_hash(records) == RUNTIME_SHA, "Runtime inventory canonical SHA-256 differs from the accepted source gate.")


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
    acceptance = read_json(check_record(binding))
    require(acceptance.get('passed') is True and acceptance.get('motion_reviewed') is True
            and acceptance.get('visual_aesthetic_passed') is True and acceptance.get('capture_checks_passed') is True
            and not acceptance.get('interim') and not acceptance.get('blocking_findings')
            and acceptance.get('limitations'), 'Current temporal visual acceptance is incomplete or interim.')
    review_runtime_binding(acceptance['runtime'], expected_inventory, runtime_hash)
    require(acceptance['harness_sha256'].upper() == motion['harness_sha256'].upper(),
            'Temporal visual acceptance belongs to another harness.')
    reviewed_report = check_record(acceptance['report_file'])
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
    acceptance = read_json(check_record(binding))
    require(acceptance.get('passed') is True and acceptance.get('failures') == 0
            and acceptance['checks'] == len(acceptance['results']) and acceptance['checks'] > 0
            and all(result['passed'] for result in acceptance['results'])
            and not acceptance.get('blocking_findings') and acceptance.get('review_method')
            and acceptance.get('limitations'), 'Bound movie visual acceptance is incomplete.')
    review_runtime_binding(acceptance['runtime'], expected_inventory, runtime_hash)
    require(acceptance['harness_sha256'].upper() == receipt['harness_sha256'].upper()
            and acceptance['capture_runner_sha256'].upper() == receipt['runner_sha256'].upper(),
            'Bound movie acceptance belongs to another harness or capture runner.')
    historical_capture = read_json(check_record(acceptance['capture_receipt_before_visual_promotion']))
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
        report = read_json(check_record(case['report_file']))
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
        file = check_record(artifact).resolve()
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
    check_png({'path': str(file), 'bytes': file.stat().st_size, 'sha256': record['sha256'],
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
    require(len(report['captures']) == 70 and report['checks'] == 378, 'Expected seventy captures and all 378 scenery checks.')
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
        require(paused_a == paused_b == states[-1] and pause['before']['sha256'].upper() == pause['after']['sha256'].upper(), 'Scenery state or paused rendered image changed while paused.')
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


def check_movie_process(process):
    require(process["exit_code"] == 0 and process["timed_out"] is False, "Movie subprocess failed or timed out: " + process["label"])
    log = check_record(process["log"])
    content = log.read_text(encoding="utf-8", errors="replace")
    require(re.search(r"(?m)^EXIT_CODE 0$", content) and re.search(r"(?m)^TIMED_OUT False$", content), "Movie subprocess log does not confirm clean completion.")
    first = content.splitlines()[0]
    require(first.startswith("COMMAND "), "Movie subprocess log lacks its command.")
    command = json.loads(first.removeprefix("COMMAND "))
    require(isinstance(command, list) and command, "Movie subprocess command is invalid.")
    return log, command


def audit_movie_processes(case, movie, latest_runtime):
    require(set(case["logs"]) == {"engine", "native", "encode", "decode"}, "Movie process log coverage is incomplete.")
    logs = {key: check_record(record) for key, record in case["logs"].items()}
    for log in logs.values(): fresh_record(log, latest_runtime, "Ambient subprocess log")
    require(len(case["processes"]) == 3, "Movie must have engine, encode and full-decode process receipts.")
    expected = [("native", "engine capture"), ("encode", "encode"), ("decode", "full decode")]
    commands = {}
    for process, (key, label) in zip(case["processes"], expected):
        require(process["label"] == case["arena"] + " " + label, "Movie subprocess identity differs.")
        log, command = check_movie_process(process)
        require(log == logs[key], "Movie subprocess log binding differs.")
        commands[key] = command
    for key in ("engine", "native"):
        content = logs[key].read_text(encoding="utf-8", errors="replace")
        require(not re.search(r"(?im)^.*(?:SCRIPT ERROR|Parse Error|ERROR:|WARNING:).*$", content), "Godot movie capture logged a problem.")
    encode = commands["encode"]
    require("-vf" in encode and encode[encode.index("-vf")+1].startswith("trim=start_frame=") and
            re.fullmatch(r"trim=start_frame=\d+:end_frame=\d+,setpts=PTS-STARTPTS", encode[encode.index("-vf")+1]),
            "Movie encode must trim editorial frames without resizing or upscaling.")
    require(path(encode[-1]) == path(movie["path"]), "Movie encoder names a different output.")
    decode = commands["decode"]
    require("-i" in decode and path(decode[decode.index("-i")+1]) == path(movie["path"]) and
            "-f" in decode and decode[decode.index("-f")+1] == "null", "Movie decode is not a full null-output decode of the accepted MP4.")
    content = logs["decode"].read_text(encoding="utf-8", errors="replace")
    input_block = content.split("Output #0", 1)[0]
    video_lines = [line for line in input_block.splitlines() if "Video:" in line]
    require(len(video_lines) == 1, "Decoded movie has unexpected video streams.")
    size = re.search(r"\b(\d{3,5})x(\d{3,5})\b", video_lines[0])
    fps = re.search(r"\b(\d+(?:\.\d+)?) fps\b", video_lines[0])
    duration = re.search(r"Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)", input_block)
    frames = re.findall(r"(?m)^frame=(\d+)\s*$", content)
    require(size and fps and duration and frames and "progress=end" in content, "Movie full-decode metadata/progress is incomplete.")
    seconds = int(duration[1])*3600+int(duration[2])*60+float(duration[3])
    require((int(size[1]), int(size[2])) == (movie["width"], movie["height"]) and
            abs(float(fps[1])-movie["fps"]) < 0.001 and abs(seconds-movie["duration_seconds"]) < 0.01 and
            int(frames[-1]) == movie["video_frames"] == 720, "Movie metadata differs from actual full-decode evidence.")


def validate_movies(value, expected_inventory, runtime_hash, latest_runtime):
    receipt = read_json(value)
    require(receipt.get('passed') is True and not receipt.get('blocking_findings'),
            'Current motion media has not passed review.')
    require(receipt.get('capture_passed') is True and receipt.get('unchanged_during_recording') is True
            and not receipt.get('problems'), 'Current motion capture or source preservation is incomplete.')
    require({r["path"].replace("\\", "/"): (int(r["bytes"]), r["sha256"].upper()) for r in receipt['runtime']['files']} == expected_inventory and
            receipt['runtime']['sha256'].upper() == runtime_hash, 'Motion media source binding is stale.')
    check_hash('tools/validation/living_background_review.gd', receipt['harness_sha256'])
    check_hash(receipt['runner_path'], receipt['runner_sha256'])
    require(len(receipt['cases']) == 5 and {c['arena'] for c in receipt['cases']} == set(ARENAS),
            'Expected five current ambient movies, one per arena.')
    for case in receipt['cases']:
        require(case['quality'] == 'High' and case['capture_passed'] is True and case['reviewed'] is True and not case['problems'], 'Ambient clip has wrong tier or incomplete capture/review.')
        movie = case['movie']
        file = check_record(movie)
        require(file == ROOT / 'evidence/background_rebuild/motion' / case['arena'] / 'ambient.mp4',
                'Unexpected current ambient movie destination.')
        require(movie['width'] >= 1280 and movie['height'] >= 720 and movie['fps'] == 60
                and 11.99 <= movie['duration_seconds'] <= 12.10 and movie['decoded'] is True
                and movie['reviewed'] is True and movie['video_frames'] == 720,
                'Ambient clip is incomplete, undecoded or unreviewed.')
        audit_movie_processes(case, movie, latest_runtime)
        require(len(case['samples']) == 4 and [s['seconds'] for s in case['samples']] == [0, 2, 5, 10],
                'Ambient clip has incomplete visual samples.')
        for sample in case['samples']:
            require(sample['width'] == movie['width'] and sample['height'] == movie['height']
                    and sample['reviewed'] is True, 'Ambient sample is resized or unreviewed.')
            sample_file = check_record(sample)
            fresh_record(sample_file, latest_runtime, 'Ambient review sample')
            _, extraction = check_movie_process(sample['extraction'])
            require(sample['extraction']['label'] == case['arena'] + f" sample {sample['seconds']}s"
                    and '-ss' in extraction and float(extraction[extraction.index('-ss')+1]) == sample['seconds']
                    and '-i' in extraction and path(extraction[extraction.index('-i')+1]) == file
                    and '-vf' not in extraction and path(extraction[-1]) == sample_file,
                    'Ambient review frame extraction time, media, or output differs.')
            with sample_file.open('rb') as stream: header = stream.read(24)
            require(header[:8] == b'\x89PNG\r\n\x1a\n' and header[12:16] == b'IHDR'
                    and struct.unpack('>II', header[16:24]) == (movie['width'], movie['height']),
                    'Ambient sample dimensions differ from measured video.')
        with file.open('rb') as stream:
            require(stream.read(12)[4:8] == b'ftyp', 'Ambient media is not an MP4 container.')
        fresh_record(file, latest_runtime, 'Ambient movie')
        report_file = check_record(case['report_file'])
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


def audit_preservation(baseline):
    receipt = read_json("evidence/background_rebuild/preservation.json")
    require(receipt["passed"] is True and len(receipt["checks"]) == 72 and all(c["passed"] is True for c in receipt["checks"]), "Preservation invariants are incomplete.")
    check_inventory(receipt["runtime"])
    check_hash(receipt["baseline_path"], receipt["baseline_sha256"])
    require(receipt["baseline_runtime_sha256"].upper() == baseline["runtime"]["sha256"].upper(), "Preservation baseline differs.")
    baseline_bitmaps = {r["path"]: r for r in baseline["runtime"]["files"] if Path(r["path"]).suffix.lower() in {".png", ".jpg", ".jpeg"}}
    bitmaps = receipt["preserved_existing_bitmaps"]
    require(len(bitmaps) == len(baseline_bitmaps) and {r["path"] for r in bitmaps} == set(baseline_bitmaps), "Existing bitmap preservation coverage differs.")
    for bitmap in bitmaps:
        expected = baseline_bitmaps[bitmap["path"]]
        require(bitmap["preserved"] is True and bitmap["bytes"] == expected["bytes"] and bitmap["sha256"].upper() == expected["sha256"].upper(), "Existing bitmap preservation record differs.")
        check_record(bitmap, PROJECT)
    require(len(receipt["arenas"]) == 5 and {a["arena"] for a in receipt["arenas"]} == ARENAS, "Preservation lacks a stage.")
    for stage in receipt["arenas"]:
        require(stage["collision_dictionary_unchanged"] is True and all(f["unchanged"] is True and f["baseline_sha256"] == f["current_sha256"] for f in stage["visual_platform_and_hazard_builders"]), "Stage layout/platform/hazard preservation failed.")
        check_hash(PROJECT / stage["path"], stage["current_file_sha256"])
        check_hash(ROOT / "evidence/background_rebuild/baseline/Game File" / stage["path"], stage["baseline_file_sha256"])
    for label, key in [("Supplied originals", "supplied_originals"), ("Curated sources", "curated_character_sources")]:
        records = receipt[key]
        require(len(records) == 8 and all(r["preserved"] is True and r["expected_sha256"] == r["actual_sha256"] for r in records), label + " preservation incomplete.")
        for record in records: check_hash(record["path"], record["expected_sha256"])
    prior = receipt["prior_archive"]
    require(prior["preserved"] is True and path(prior["path"]) == OLD_ZIP and prior["sha256"].upper() == OLD_ZIP_SHA, "Prior archive preservation receipt differs.")
    check_record(prior)
    CHECKS.append("All 72 source preservation checks, current runtime and stage hashes, eight originals, eight curated sources and prior platform archive")


def audit(delivery_path, repeat_directories=()):
    global RUNTIME_SHA, RUNTIME_COUNT, EXPECTED_RUNTIME, OLD_ZIP_SHA
    gate = read_json("evidence/validation_all.json")
    RUNTIME_SHA = gate["runtime"]["sha256"].upper()
    RUNTIME_COUNT = len(gate["runtime"]["files"])
    require(RUNTIME_COUNT > 0, "Accepted source inventory is empty.")
    EXPECTED_RUNTIME = {r["path"].replace("\\", "/"): (int(r["bytes"]), r["sha256"].upper()) for r in gate["runtime"]["files"]}
    baseline = read_json("evidence/background_rebuild/baseline.json")
    require(path(baseline["previous_archive"]) == OLD_ZIP, "Baseline names a different previous platform package.")
    OLD_ZIP_SHA = baseline["previous_archive_sha256"].upper()
    delivery = read_json(delivery_path)
    require(delivery["passed"] is True and delivery["runtime_source_sha256"].upper() == RUNTIME_SHA, "Delivery receipt is not the accepted living-arena build.")
    require(path(delivery["archive"]) == NEW_ZIP and NEW_ZIP != OLD_ZIP, "Delivery must use the dedicated living-arena ZIP.")
    check_hash(OLD_ZIP, OLD_ZIP_SHA)
    check_hash(NEW_ZIP, delivery["archive_sha256"], delivery["archive_bytes"])
    CHECKS.append("Dedicated living-arena archive and unchanged prior platform ZIP")

    gate = read_json("evidence/validation_all.json")
    require(gate["passed"] is True and gate["runtime_unchanged_during_validation"] is True and gate["failed_suites"] == 0, "Source gate failed.")
    require(gate["completed_suites"] == gate["expected_suites"] == len(gate["suites"]) and len(gate["suites"]) >= 12, "Source suites incomplete.")
    check_inventory(gate["runtime"])
    expected = {r["path"] for r in gate["runtime"]["files"]}
    actual = {p.relative_to(PROJECT).as_posix() for p in PROJECT.rglob("*") if p.is_file() and ".godot" not in p.relative_to(PROJECT).parts and p.suffix.lower() in EXTENSIONS and not p.name.lower().startswith("source_") and p.name.lower() not in {"validate_input.gd", "engine.png"}}
    require(actual == expected, "Current runtime file set differs from the accepted source inventory.")
    for record in gate["runtime"]["files"]:
        check_record(record, PROJECT)
    for suite in gate["suites"]:
        require(suite["passed"] is True and suite["exit_code"] == 0 and not suite["problems"] and not suite["unexpected_error_lines"] and not suite["unexpected_warning_lines"], f"Source suite failed: {suite['name']}")
        if suite.get("script_sha256"):
            match = re.search(r'--script\s+"([^"]+)"', suite["command"])
            require(match is not None, f"Missing suite harness: {suite['name']}")
            check_hash(match.group(1), suite["script_sha256"])
    require(gate["roster_preflight"]["originals_preserved"] is True, "Original preservation gate failed.")
    originals = gate["roster_preflight"]["original_sources"]
    require(len(originals) == 8, "Eight supplied originals are required.")
    for original in originals:
        require(original["preserved"] is True and original["actual_sha256"] == original["expected_sha256"], "Original preservation receipt differs.")
        check_hash(original["path"], original["expected_sha256"])
    CHECKS.append("Current source inventory, canonical SHA-256 and all required source suites")

    visual = read_json("evidence/background_rebuild/visualreview.json")
    require(visual["passed"] is True, "Visual review has not passed.")
    check_inventory(visual["runtime"])
    check_hash("tools/validation/rebuild_stage_review.gd", visual["harness_sha256"])
    stage_report_file = check_record(visual["capture_report_file"])
    if "report_path" in visual:
        require(path(visual["report_path"]) == stage_report_file, "Arena review report aliases name different files.")
    if "report_sha256" in visual:
        require(visual["report_sha256"].upper() == visual["capture_report_file"]["sha256"].upper(), "Arena review report aliases have different hashes.")
    stage_report = read_json(stage_report_file)
    captures = visual["captures"]
    require(len(captures) == 25 and {(c["arena"], c["purpose"]) for c in captures} == {(a, v) for a in ARENAS for v in VIEWS}, "Visual views incomplete or duplicated.")
    require(len(stage_report["captures"]) == 25 and all(c["saved"] is True for c in stage_report["captures"]), "Stage capture report incomplete.")
    require({path(c["path"]) for c in captures} == {path(c["file"]) for c in stage_report["captures"]}, "Review and capture report name different images.")
    for capture in captures:
        require(capture["reviewed"] is True and capture["quality"] == ("Low" if capture["purpose"] == "low" else "High"), "Unreviewed capture or incorrect quality.")
        check_png(capture)
    require(not visual.get("blocking_findings"), "Visual review contains blocking findings.")
    latest_runtime_write = max((PROJECT / r["path"]).stat().st_mtime_ns for r in gate["runtime"]["files"])
    for capture in captures:
        require(path(capture["path"]).stat().st_mtime_ns >= latest_runtime_write, "Reviewed capture predates current runtime.")
    CHECKS.append("Twenty-five exact reviewed PNG hashes, 1080p headers and current review harness")
    audit_preservation(baseline)
    motion_path = visual.get("motion_report_path")
    require(motion_path and visual.get("motion_report_sha256"), "Visual review lacks an exact temporal report binding.")
    check_hash(motion_path, visual["motion_report_sha256"])
    motion = validate_living_report(motion_path, latest_runtime_write)
    validate_bound_temporal_acceptance(visual, motion, motion_path, EXPECTED_RUNTIME, RUNTIME_SHA)
    require(motion["checks"] == 378, "Expected all 378 living-scenery assertions.")
    CHECKS.append("Seventy exact temporal PNG/state records, 378 scenery checks, pause/reset/quality restoration and explicit bound assistant motion acceptance")
    movies = validate_movies("evidence/background_rebuild/motion/movie_receipt.json", EXPECTED_RUNTIME, RUNTIME_SHA, latest_runtime_write)
    CHECKS.append("Five current High-tier 60 FPS twelve-second ambient MP4s at their measured resolution, all 720 frames decoded, explicit sample-frame review and exact runner/source/media/log/report/state bindings; no upscaling")

    manifest_path = ROOT / "builds/windows/build_manifest.json"
    manifest = read_json(manifest_path)
    require(inventory_hash(manifest["runtime_source_files"]) == RUNTIME_SHA and len(manifest["runtime_source_files"]) == RUNTIME_COUNT, "Exported inventory differs.")
    current_build = {"executable": check_hash(BUILD / "RooftopRiot.exe", manifest["exe_sha256"]), "pck": check_hash(BUILD / "RooftopRiot.pck", manifest["pck_sha256"]), "manifest": manifest_path}
    windows = read_json("evidence/windows_release_flow/validation.json")
    require(windows["passed"] is True and windows["build_unchanged_during_validation"] is True and not windows["problems"] and windows["runtime_source_hashes_verified_before"] == windows["runtime_source_hashes_verified_after"] == RUNTIME_COUNT, "Windows gate failed or is stale.")
    for key, field in [("executable", "executable_sha256"), ("pck", "pck_sha256"), ("manifest", "build_manifest_sha256")]:
        check_hash(current_build[key], windows[field])
    ui = windows["pck_ui_harness"]
    require(ui["passed"] is True and ui["exit_code"] == 0 and not ui["timed_out"] and not ui["errors"] and not ui["warnings"] and ui["checks"] == ui["expected_checks"] == 108 and len(ui["captured_images"]) == 40, "Exported-PCK UI coverage incomplete.")
    check_hash(ui["harness"], ui["harness_sha256"])
    for capture in ui["captured_images"]:
        check_png(capture, ROOT / "evidence/windows_release_flow")
    smoke = windows["release_executable_smoke"]
    require(smoke["passed"] is True and smoke["exit_code"] == 0 and smoke["ticks"] == 600 and smoke["fighters"] == 4 and smoke["contacts"] > 0 and not smoke["errors"] and not smoke["warnings"], "Actual Windows smoke failed.")
    check_png(smoke["capture"], ROOT / "evidence/windows_release_flow")
    release = read_json("evidence/map_expansion/release_validation.json")
    require(release["passed"] is True and release["build_unchanged_during_validation"] is True and not release["problems"] and len(release["cases"]) == 3, "Three-arena EXE gate incomplete.")
    check_hash(release["harness"], release["harness_sha256"])
    for moment in ["before", "after"]:
        require(release["runtime_inventory_" + moment]["sha256"].upper() == RUNTIME_SHA and release["runtime_inventory_" + moment]["files"] == RUNTIME_COUNT and release["runtime_inventory_" + moment]["manifest_inventory_sha256"].upper() == RUNTIME_SHA, "EXE runtime binding differs.")
        require(set(release["build_hashes_" + moment]) == set(current_build), "EXE validation lacks a before/after build component.")
        for key, record in release["build_hashes_" + moment].items():
            require(check_record(record) == current_build[key], "EXE validation names a different build component.")
    require({c["requested_arena"] for c in release["cases"]} == NEW_ARENAS, "EXE arenas differ.")
    for case in release["cases"]:
        require(case["passed"] is True and case["exit_code"] == 0 and not case["timed_out"] and case["ticks"] == 600 and case["contacts"] > 0 and not case["errors"] and not case["warnings"] and not case["problems"], "An actual arena EXE case failed.")
        require(case["reported_arena"] == case["requested_arena"] and case["reported_input_providers"] == ["res://input/cpu_input_provider.gd"] * 4, "EXE arena/CPU identity differs.")
        check_png(case["capture"])
        check_record(case["runtime_report_file"])
        for record in case["log_files"].values():
            check_record(record)
    flow = read_json("evidence/rebuild/match_flow.json")
    require(flow["checks"] == 35 and flow["failures"] == 0 and flow["graphical"] is True and len(flow["results"]) == 35 and all(r["passed"] is True for r in flow["results"]), "Match lifecycle gate failed.")
    reasons = {"LAST ONE STANDING", "TIME Ã‚Â· STOCKS THEN DAMAGE", "SUDDEN DEATH DECISION", "EXACT TIE Ã‚Â· DRAW", "SIMULTANEOUS FINAL KO Ã‚Â· DRAW"}
    require(len(flow["matches"]) == 5 and {m["arena"] for m in flow["matches"]} == ARENAS and all(m["contacts"] > 0 and m["kos"] > 0 and "winner" in m["result"] and m["result"]["reason"] in reasons for m in flow["matches"]), "Five natural full matches incomplete.")
    latest_runtime_write = max((PROJECT / r["path"]).stat().st_mtime_ns for r in gate["runtime"]["files"])
    require(path("evidence/rebuild/match_flow.json").stat().st_mtime_ns >= max(latest_runtime_write, path("tools/validation/rebuild_match_flow.gd").stat().st_mtime_ns), "Full matches predate current source or lifecycle harness.")
    CHECKS.append("Current exported build, 108 UI checks, actual EXE smokes and five full matches")

    profile_record = delivery["evidence"]["profile_provenance"]
    profile_path = check_record(profile_record)
    provenance = read_json(profile_path)
    require(provenance["passed"] is True and provenance["unchanged_during_profiling"] is True and len(provenance["cases"]) == 10, "Profile provenance incomplete.")
    render_cap = provenance.get("render_cap")
    require(type(render_cap) is int and 0 <= render_cap <= 240 and provenance.get("vsync") == "disabled",
            "Profile provenance lacks the actual render cap and disabled VSync.")
    check_inventory(provenance["runtime"])
    check_hash("tools/validation/rebuild_performance.gd", provenance["harness_sha256"])
    require(provenance["art"]["present"] is True, "Profile art binding absent.")
    check_record(provenance["art"])
    cases = {c["case"]: c for c in provenance["cases"]}
    expected_cases = {f"{a}_{q}_4p" for a in ARENAS for q in ["high", "low"]}
    require(set(cases) == expected_cases and len(delivery["performance"]) == 10 and {c["case"] for c in delivery["performance"]} == expected_cases, "Ten High/Low four-player profiles incomplete.")
    profiles = []
    for case_name, case in cases.items():
        file = check_hash(profile_path.parent / case["file"], case["sha256"])
        report = read_json(file)
        require(case.get("render_cap") == report.get("render_cap") == render_cap and
                case.get("vsync") == report.get("vsync") == provenance["vsync"] and report.get("renderer") == "forward_plus",
                f"Profile render cap, VSync or renderer differs from provenance: {case_name}")
        require(report["arena"] == case["arena"] and report["quality"].lower() == case["quality"].lower() and report["players"] == case["players"] == 4 and case["requested_seconds"] >= 60, f"Profile case identity differs: {case_name}")
        require(report["duration_seconds"] >= 59 and report["simulation_ticks_in_sample_window"] >= 3300 and report["frame_intervals"]["count"] >= 100 and report["readback_inside_sample_window"] is False and report["captured_pixels"] == "(1920, 1080)" and report["viewport_render_cpu"]["available"] is True and report["viewport_render_gpu"]["available"] is True, f"Profile measurement incomplete: {case_name}")
        delivery_case = next(c for c in delivery["performance"] if c["case"] == case_name)
        require(path(delivery_case["file"]) == file and delivery_case["sha256"].upper() == case["sha256"].upper(), "Delivery profile binding differs.")
        profiles.append({"case": case_name, "sha256": case["sha256"], "render_cap": render_cap, "vsync": report["vsync"], "frame_p99_ms": report["frame_intervals"]["p99_ms"], "frame_max_ms": report["frame_intervals"]["max_ms"], "over_16_667": report["frame_intervals"]["over_16_667"]})
    CHECKS.append("Ten current 60-second CPU/GPU profiles with consistent actual render cap/VSync, runtime/art/harness and delivery hash bindings; this does not establish uncapped stability")
    repeat_profiles = []
    repeat_paths = [path(directory) for directory in repeat_directories]
    require(len(set(repeat_paths)) == len(repeat_paths) and profile_path.parent not in repeat_paths,
            "Repeat profile directories must be distinct from each other and the original full matrix.")
    for directory in repeat_paths:
        require(directory.is_relative_to(ROOT), "Repeat profile directory must be within this workspace.")
        repeat_path = directory / "profile_provenance.json"
        repeat = read_json(repeat_path)
        require(repeat.get("passed") is True and repeat["unchanged_during_profiling"] is True
                and repeat.get("render_cap") == render_cap and repeat.get("vsync") == provenance["vsync"]
                and repeat["harness_sha256"].upper() == provenance["harness_sha256"].upper()
                and repeat["art"]["present"] is True and repeat["art"]["sha256"].upper() == provenance["art"]["sha256"].upper()
                and repeat["cases"], "Repeat profile provenance, render cap, VSync, harness or fighter art differs.")
        check_inventory(repeat["runtime"])
        check_record(repeat["art"])
        repeat_names = [case["case"] for case in repeat["cases"]]
        require(len(set(repeat_names)) == len(repeat_names) and set(repeat_names) <= expected_cases,
                "Repeat profile cases are duplicated or outside the full matrix.")
        for case in repeat["cases"]:
            repeat_file = check_hash(directory / case["file"], case["sha256"])
            report = read_json(repeat_file)
            require(case["file"] == case["case"] + ".json" and report["arena"] == case["arena"]
                    and report["quality"].lower() == case["quality"].lower() and case["players"] == report["players"] == 4
                    and case["requested_seconds"] >= 60 and case.get("render_cap") == report.get("render_cap") == render_cap
                    and case.get("vsync") == report.get("vsync") == provenance["vsync"] and report.get("renderer") == "forward_plus",
                    "Repeat report identity, render cap, VSync or renderer differs.")
            require(report["duration_seconds"] >= 59 and report["simulation_ticks_in_sample_window"] >= 3300
                    and report["frame_intervals"]["count"] >= 100 and report["readback_inside_sample_window"] is False
                    and report["captured_pixels"] == "(1920, 1080)" and report["viewport_render_cpu"]["available"] is True
                    and report["viewport_render_gpu"]["available"] is True, "Repeat profile measurement is incomplete.")
            repeat_profiles.append({"directory": str(directory), "provenance_sha256": TRACKED[repeat_path],
                                    "case": case["case"], "sha256": case["sha256"], "render_cap": render_cap,
                                    "vsync": report["vsync"], "frame_p99_ms": report["frame_intervals"]["p99_ms"],
                                    "frame_max_ms": report["frame_intervals"]["max_ms"], "over_16_667": report["frame_intervals"]["over_16_667"]})
    if repeat_paths:
        CHECKS.append("Optional unchanged-source repeats preserve the full matrix and match its actual render cap/VSync, harness, art and 1080p four-CPU measurement scope")
    validate_uncapped_failure()
    CHECKS.append("Preserved aborted uncapped Lunar Reach High stress failure, intact lost-device/signal-11 engine log and NUL-native-receipt limitation; no root cause or driver fix established")

    required_evidence = {
        "source_gate": ROOT / "evidence/validation_all.json",
        "windows_package_validation": ROOT / "evidence/windows_release_flow/validation.json",
        "map_release_validation": ROOT / "evidence/map_expansion/release_validation.json",
        "match_lifecycle": ROOT / "evidence/rebuild/match_flow.json",
        "accepted_fighter_art": ROOT / "evidence/characters/hero_rebuild/release_assets.json",
        "arena_artwork": ROOT / "source_art/environment/arena_artwork_manifest.json",
        "profile_provenance": profile_path,
    }
    require(set(delivery["evidence"]) == set(required_evidence), "Delivery receipt evidence set is incomplete or differs from the strict package contract.")
    for key, record in delivery["evidence"].items():
        require(path(record["path"]) == required_evidence[key], "Delivery receipt names different acceptance evidence: " + key)
        check_record(record)
    with zipfile.ZipFile(NEW_ZIP) as archive:
        names = archive.namelist()
        receipt_files = {r["file"]: r for r in delivery["files"]}
        require(len(names) == len(set(names)) == len(receipt_files) == 22 and set(names) == set(receipt_files), "ZIP exact entry set differs.")
        package_bytes = archive.read("package_manifest.json")
        require(hashlib.sha256(package_bytes).hexdigest().upper() == delivery["package_manifest_sha256"].upper(), "Decoded package manifest differs.")
        package = json.loads(package_bytes.decode("utf-8-sig"))
        require(package["runtime_source_sha256"].upper() == RUNTIME_SHA and set(package["expected_archive_entries"]) == set(names) and len(package["files"]) == 21, "Packaged inventory differs.")
        require(package["evidence"] == delivery["evidence"], "Packaged evidence differs from external receipt.")
        package_files = {r["file"]: r for r in package["files"]}
        require(set(package_files) == set(names) - {"package_manifest.json"}, "Package manifest payload set differs.")
        for name in names:
            record = receipt_files[name]
            with archive.open(name) as stream:
                decoded_sha = stream_hash(stream)
            require(decoded_sha == record["sha256"].upper() and archive.getinfo(name).file_size == record["bytes"], f"Decoded ZIP payload differs: {name}")
            check_hash(BUILD / name, record["sha256"], record["bytes"])
            if name != "package_manifest.json":
                require(package_files[name] == record, f"Package and delivery payload records differ: {name}")
            if name.endswith(".md"):
                source = ROOT / "docs" / name
                if name == "README.md": source = ROOT / "docs/WINDOWS_BUILD_README.md"
                elif name == "MOTION_CREDITS.md": source = ROOT / "source_art/motion/README.md"
                elif name == "LUNAR_ASSET_CREDITS.md": source = PROJECT / "assets/lunar_reach/CREDITS.md"
                elif name.startswith("maps/") and name.endswith("_CREDITS.md"): source = PROJECT / "assets/arenas" / name.removeprefix("maps/").removesuffix("_CREDITS.md") / "CREDITS.md"
                check_hash(source, record["sha256"], record["bytes"])
        require(file_hash(manifest_path) == delivery["build_manifest_sha256"].upper() == package["build_manifest_sha256"].upper(), "Build manifest binding differs.")
    CHECKS.append("All 22 ZIP entries decoded; package, receipt, build copies and current documentation match")
    for file, expected_hash in TRACKED.items():
        require(file_hash(file) == expected_hash, f"File changed during independent audit: {file}")
    CHECKS.append("All audited files remained unchanged through the audit")
    presentation = {"visual_review": "evidence/background_rebuild/visualreview.json", "temporal_report": motion_path, "movie_review": "evidence/background_rebuild/motion/movie_receipt.json", "preservation": "evidence/background_rebuild/preservation.json", "preserved_uncapped_failure": UNCAPPED_FAILURE}
    presentation_records = {key: {"path": str(path(value)), "sha256": TRACKED[path(value)]} for key, value in presentation.items()}
    return {"archive": str(NEW_ZIP), "archive_sha256": delivery["archive_sha256"], "runtime_source_sha256": RUNTIME_SHA, "runtime_files": RUNTIME_COUNT, "reviewed_captures": 25, "temporal_captures": 70, "temporal_checks": motion["checks"], "ambient_movies": len(movies["cases"]), "ambient_movie_dimensions": sorted({(c["movie"]["width"], c["movie"]["height"]) for c in movies["cases"]}), "ambient_movie_review": "Assistant inspection of four extracted frames per clip; continuous human acceptance unverified", "preservation_checks": 72, "presentation_evidence": presentation_records, "zip_entries": 22, "profile_render_cap": render_cap, "profile_vsync": provenance["vsync"], "performance_scope": "Measured current source workload at the recorded render cap with VSync disabled; not ordinary synchronized presentation, uncapped stability, or a device/driver fix.", "profiles": profiles, "repeat_profiles": repeat_profiles, "previous_platform_zip_sha256": OLD_ZIP_SHA}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--delivery", default="evidence/background_rebuild/delivery.json")
    parser.add_argument("--repeat-profile-directory", action="append", default=[], help="Completed unchanged-source repeat directory; may be supplied multiple times.")
    args = parser.parse_args()
    report = {"generated_at_utc": datetime.now(timezone.utc).isoformat(), "passed": False, "checks": CHECKS, "problems": [], "scope": "Independent hashes, full ZIP decoding, bound still/state receipts and explicit assistant sample-frame acceptance. Video frame count, dimensions and full-decode completion are checked against bound FFmpeg logs; audit does not re-decode video. No engines, performance reruns or human playtesting."}
    try:
        report.update(audit(path(args.delivery), args.repeat_profile_directory))
        report["passed"] = True
    except Exception as error:
        report["problems"].append(f"{type(error).__name__}: {error}")
    report["audit_script_sha256"] = file_hash(__file__)
    output = ROOT / "evidence/background_rebuild/final_audit.json"
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"LIVING ARENAS DELIVERY AUDIT {'PASS' if report['passed'] else 'FAIL'}: {output}")
    for problem in report["problems"]:
        print(problem, file=sys.stderr)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
