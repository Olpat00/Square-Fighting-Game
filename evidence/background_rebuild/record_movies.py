"""Record five ambient scenery fixtures sequentially; leave visual acceptance pending.

Run only after the source is frozen and its current validation/preservation
inventory exists. No capture or encode job is launched when importing this file.
The receipt becomes a review candidate, never automatic aesthetic acceptance.

After a device-loss/reboot interruption:
1. Confirm GPU health and complete the graphical import/source gate.
2. Keep runtime/harness frozen; run this runner with --resume. Only exact-hash
   completed clips from the same source/harness are reused; failed logs remain.
3. Inspect all extracted sample frames, mark their reviewed state and each
   movie reviewed, then promote the full movie receipt only after all five pass.
4. Complete final arena views, scenery pause/reset checks, Windows validation,
   profiles and strict packaging; a candidate export alone is not acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / 'Game File'
MOTION = ROOT / 'evidence/background_rebuild/motion'
HARNESS = ROOT / 'tools/validation/living_background_review.gd'
ARENAS = ('rooftop_riot', 'lunar_reach', 'verdant_shrine', 'abyssal_observatory', 'ember_foundry')
GODOT = Path(r'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe')
FFMPEG = Path(r'C:\Users\dayw9\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe')
EXTENSIONS = {'.gd', '.gdshader', '.godot', '.tscn', '.tres', '.glb', '.png', '.jpg', '.jpeg',
              '.svg', '.wav', '.ogg', '.json', '.import', '.uid', '.cfg'}
PROBLEM = re.compile(r'SCRIPT ERROR:|ERROR:|Parse Error|WARNING:|VK_ERROR_DEVICE_LOST|GPU is lost|device (?:was )?lost|FATAL|CRASH', re.I)
NO_WINDOW = getattr(subprocess, 'CREATE_NO_WINDOW', 0)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def utc():
    return datetime.now(timezone.utc).isoformat()


def sha256(file):
    digest = hashlib.sha256()
    with Path(file).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest().upper()


def record(file):
    file = Path(file).resolve()
    return {'path': str(file), 'bytes': file.stat().st_size, 'sha256': sha256(file)}


def read_json(file):
    return json.loads(Path(file).read_text(encoding='utf-8-sig'))


def contained(file, parent):
    file, parent = Path(file).resolve(), Path(parent).resolve()
    require(file != parent and file.is_relative_to(parent), f'Path escapes owned directory: {file}')
    return file


def verify_runtime(runtime):
    records = runtime['files']
    expected = {}
    for item in records:
        relative = item['path'].replace('\\', '/')
        require(relative not in expected, 'Duplicate runtime record.')
        file = contained(PROJECT / relative, PROJECT)
        require(file.is_file() and file.stat().st_size == item['bytes'] and
                sha256(file) == item['sha256'].upper(), f'Runtime differs from accepted inventory: {relative}')
        expected[relative] = file
    current = {p.relative_to(PROJECT).as_posix() for p in PROJECT.rglob('*')
               if p.is_file() and '.godot' not in p.relative_to(PROJECT).parts and p.suffix in EXTENSIONS
               and not p.name.startswith('source_') and p.name not in {'validate_input.gd', 'engine.png'}}
    require(current == set(expected), 'Current runtime file set differs from accepted inventory.')
    require(re.fullmatch(r'[0-9a-fA-F]{64}', runtime['sha256']), 'Missing canonical runtime digest.')


def current_inventory():
    # Copy the canonical PowerShell-produced records and digest, rather than
    # inventing a different locale/JSON ordering for the same inventory.
    errors = []
    for relative in ('evidence/validation_all.json', 'evidence/background_rebuild/preservation.json'):
        file = ROOT / relative
        if not file.is_file():
            continue
        data = read_json(file)
        runtime = data.get('current_runtime', data.get('runtime'))
        if not data.get('passed') or not isinstance(runtime, dict) or 'files' not in runtime:
            continue
        try:
            verify_runtime(runtime)
            return runtime, record(file)
        except ValueError as error:
            errors.append(str(error))
    raise ValueError('A fresh passed source-gate or full preservation runtime inventory is required. ' + '; '.join(errors))


def checkpoint(receipt):
    verify_runtime(receipt['runtime'])
    require(sha256(HARNESS) == receipt['harness_sha256'], 'Movie harness changed during capture.')
    require(sha256(__file__) == receipt['runner_sha256'], 'Movie runner changed during capture.')
    source = receipt['source_inventory_receipt']
    require(sha256(source['path']) == source['sha256'], 'Source inventory receipt changed during capture.')


def write_receipt(receipt):
    destination = MOTION / 'movie_receipt.json'
    temporary = MOTION / 'movie_receipt.tmp.json'
    contained(destination, MOTION)
    contained(temporary, MOTION)
    temporary.write_text(json.dumps(receipt, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    temporary.replace(destination)


def archive_previous(folder, stamp):
    if not folder.exists():
        folder.mkdir(parents=True)
        return
    # Both absolute endpoints are checked before moving an owned arena folder.
    source = contained(folder, MOTION)
    destination = contained(MOTION / 'history' / stamp / folder.name, MOTION)
    require(folder.name in ARENAS and source == MOTION.resolve() / folder.name,
            'Unexpected archive source or redirected arena directory.')
    destination.parent.mkdir(parents=True, exist_ok=True)
    require(not destination.exists(), 'Archive destination already exists.')
    source.rename(destination)
    folder.mkdir(parents=True)


def run_owned(arguments, log, label, timeout=180):
    started = utc()
    log = contained(log, MOTION)
    command = [str(value) for value in arguments]
    with log.open('wb') as stream:
        stream.write(('COMMAND ' + json.dumps(command, ensure_ascii=False) + '\nSTARTED ' + started + '\n').encode())
        stream.flush()
        process = subprocess.Popen(command, cwd=str(ROOT), stdin=subprocess.DEVNULL,
                                   stdout=stream, stderr=subprocess.STDOUT, creationflags=NO_WINDOW)
        print(f'{label}: running PID {process.pid}, timeout {timeout}s', flush=True)
        timed_out = False
        try:
            exit_code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            # Terminate only this still-live owned process tree. No process-name
            # kill is used and unrelated editor/game windows are never touched.
            if process.poll() is None:
                if os.name == 'nt':
                    try:
                        cleanup = subprocess.run(['taskkill.exe', '/PID', str(process.pid), '/T', '/F'],
                                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                                 creationflags=NO_WINDOW, timeout=20)
                        stream.write(b'\nOWNED_TREE_TIMEOUT_CLEANUP\n' + cleanup.stdout)
                    except subprocess.TimeoutExpired:
                        stream.write(b'\nOwned tree cleanup timed out; terminating the owned parent handle.\n')
                        process.kill()
                else:
                    process.kill()
            try:
                exit_code = process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                exit_code = process.wait(timeout=10)
        stream.write(f'\nFINISHED {utc()}\nEXIT_CODE {exit_code}\nTIMED_OUT {timed_out}\n'.encode())
    result = {'label': label, 'pid': process.pid, 'started_utc': started, 'finished_utc': utc(),
              'exit_code': exit_code, 'timed_out': timed_out, 'timeout_seconds': timeout, 'log': record(log)}
    require(not timed_out and exit_code == 0, f'{label} failed (exit {exit_code}, timeout {timed_out}); see {log}')
    return result


def metadata_from_decode(log):
    text = Path(log).read_text(encoding='utf-8', errors='replace')
    input_block = text.split('Output #0', 1)[0]
    video_lines = [line for line in input_block.splitlines() if 'Video:' in line]
    require(len(video_lines) == 1, 'Expected one decoded video stream.')
    size = re.search(r'\b(\d{3,5})x(\d{3,5})\b', video_lines[0])
    fps = re.search(r'\b(\d+(?:\.\d+)?) fps\b', video_lines[0])
    duration = re.search(r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)', input_block)
    frames = re.findall(r'(?m)^frame=(\d+)\s*$', text)
    require(size and fps and duration and frames and 'progress=end' in text, 'Decoder metadata/progress is incomplete.')
    seconds = int(duration[1]) * 3600 + int(duration[2]) * 60 + float(duration[3])
    return {'width': int(size[1]), 'height': int(size[2]), 'fps': float(fps[1]),
            'duration_seconds': seconds, 'video_frames': int(frames[-1])}


def png_dimensions(file):
    with Path(file).open('rb') as stream:
        header = stream.read(24)
    require(header[:8] == b'\x89PNG\r\n\x1a\n' and header[12:16] == b'IHDR', f'Invalid PNG: {file}')
    return struct.unpack('>II', header[16:24])


def capture_arena(arena, receipt, args, stamp):
    folder = MOTION / arena
    archive_previous(folder, stamp)
    checkpoint(receipt)
    require(shutil.disk_usage(folder).free >= 7 * 1024 ** 3, 'At least 7 GiB free is needed for one temporary raw AVI.')
    avi, mp4 = folder / 'ambient.avi', folder / 'ambient.mp4'
    engine_log, native_log = folder / 'engine.log', folder / 'native.log'
    started = utc()
    case = {'arena': arena, 'quality': 'High', 'started_utc': started, 'capture_passed': False,
            'reviewed': False, 'movie': None, 'processes': [], 'problems': [], 'samples': []}
    receipt['cases'].append(case)
    write_receipt(receipt)
    try:
        case['processes'].append(run_owned([args.godot, '--path', PROJECT, '--resolution', '1920x1080',
            '--write-movie', avi, '--fixed-fps', '60', '--log-file', engine_log, '--script', HARNESS, '--',
            '--movie', f'--arena={arena}', '--quality=High', f'--output={folder}'], native_log, arena + ' engine capture'))
        require(avi.is_file() and avi.stat().st_size > 0 and engine_log.is_file(), 'Movie writer did not save outputs.')
        for log in (engine_log, native_log):
            require(not PROBLEM.search(log.read_text(encoding='utf-8', errors='replace')), f'Godot logged a problem: {log}')
        report_file = folder / 'living_background_review.json'
        report = read_json(report_file)
        require(report['passed'] and report['failures'] == 0 and report['movie']
                and all(check['passed'] for check in report['results']) and report['checks'] == len(report['results'])
                and report['harness_sha256'].upper() == receipt['harness_sha256']
                and report['arenas'] == [arena] and report['qualities'] == ['High'] and len(report['cases']) == 1,
                'Incomplete ambient source harness report.')
        capture = report['cases'][0]
        require(capture['arena'] == arena and capture['quality'] == 'High' and capture['simulation_ticks'] == 720
                and capture['simulation_seconds'] == 12.0 and capture['movie_writer_fps'] == 60
                and capture['scenery_draw_frames'] >= 720 and capture['frame_readbacks_during_movie'] == 0,
                'Ambient fixture did not advance exactly twelve scenery seconds.')
        start_frame = int(capture['bootstrap_draw_frames'])
        require(start_frame >= 0 and capture['draw_frames_at_completion'] >= start_frame + 720,
                'Invalid movie writer bootstrap/scenery frame counts.')
        case['report_file'] = record(report_file)
        case['source_viewport_resolution'] = capture['resolution']
        case['bootstrap_draw_frames'] = start_frame
        case['scenery_draw_frames'] = capture['scenery_draw_frames']
        encode_log, decode_log = folder / 'encode.log', folder / 'decode.log'
        video_filter = f'trim=start_frame={start_frame}:end_frame={start_frame + 720},setpts=PTS-STARTPTS'
        case['processes'].append(run_owned([args.ffmpeg, '-hide_banner', '-y', '-i', avi, '-an', '-vf', video_filter,
            '-c:v', 'libx264', '-preset', 'fast', '-crf', '20', '-pix_fmt', 'yuv420p', '-r', '60',
            '-movflags', '+faststart', '-progress', 'pipe:1', '-nostats', mp4], encode_log, arena + ' encode'))
        case['processes'].append(run_owned([args.ffmpeg, '-hide_banner', '-i', mp4, '-map', '0:v:0', '-an', '-sn', '-dn',
            '-progress', 'pipe:1', '-nostats', '-f', 'null', '-'], decode_log, arena + ' full decode'))
        metadata = metadata_from_decode(decode_log)
        require(metadata['width'] >= 1280 and metadata['height'] >= 720 and abs(metadata['fps'] - 60) < 0.001
                and abs(metadata['duration_seconds'] - 12.0) <= 0.03 and metadata['video_frames'] == 720,
                f'Encoded media dimensions/timing are incomplete: {metadata}')
        case['movie'] = {**record(mp4), **metadata, 'decoded': True, 'reviewed': False,
                         'review_method': 'Pending assistant sample-frame inspection.', 'audio': False}
        case['logs'] = {name: record(file) for name, file in [('engine', engine_log), ('native', native_log),
                        ('encode', encode_log), ('decode', decode_log)]}
        sample_folder = folder / 'review'
        sample_folder.mkdir()
        for seconds in (0, 2, 5, 10):
            sample = sample_folder / f't{seconds:02d}.png'
            sample_log = sample_folder / f't{seconds:02d}.log'
            result = run_owned([args.ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', '-ss', str(seconds),
                                '-i', mp4, '-frames:v', '1', sample], sample_log, arena + f' sample {seconds}s')
            width, height = png_dimensions(sample)
            require((width, height) == (metadata['width'], metadata['height']), 'Sample was resized relative to actual movie.')
            case['samples'].append({**record(sample), 'seconds': seconds, 'width': width, 'height': height,
                                    'reviewed': False, 'extraction': result})
        checkpoint(receipt)
        # Delete only the literal, resolved, owned raw AVI after the exact MP4
        # hash and a complete 720-frame decode have been verified. Never recurse.
        raw = contained(avi, folder)
        require(raw == folder.resolve() / 'ambient.avi' and raw.is_file(), 'Unexpected raw movie deletion target.')
        require(sha256(mp4) == case['movie']['sha256'], 'Encoded movie changed before raw cleanup.')
        case['raw_avi'] = {**record(raw), 'deleted_after_verified_decode': True}
        raw.unlink()
        case['capture_passed'] = True
        print(f'{arena}: recorded {metadata["width"]}x{metadata["height"]}, 720 frames/12s; review pending', flush=True)
    except Exception as error:
        case['problems'].append(str(error))
        raise
    finally:
        case.setdefault('logs', {})
        for name, file in (('engine', engine_log), ('native', native_log),
                           ('encode', folder / 'encode.log'), ('decode', folder / 'decode.log')):
            if file.is_file(): case['logs'][name] = record(file)
        case['finished_utc'] = utc()
        write_receipt(receipt)


def reusable_case(case, runtime, harness_hash, runner_hash, prior):
    if not (case.get('capture_passed') and case.get('movie') and case['movie'].get('decoded') and
            prior.get('harness_sha256') == harness_hash and prior.get('runner_sha256') == runner_hash
            and prior.get('runtime', {}).get('sha256') == runtime['sha256']
            and prior.get('runtime', {}).get('files') == runtime['files']):
        return False
    files = [case['movie'], case['report_file'], *case['logs'].values(), *case['samples']]
    try:
        for item in files:
            file = contained(item['path'], MOTION / case['arena'])
            require(file.is_file() and file.stat().st_size == item['bytes'] and
                    sha256(file) == item['sha256'], 'Resume media evidence changed.')
        require(len(case['samples']) == 4 and case['movie']['video_frames'] == 720
                and abs(case['movie']['fps'] - 60) < 0.001, 'Resume clip is incomplete.')
    except (ValueError, KeyError, OSError):
        return False
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, default=GODOT)
    parser.add_argument('--ffmpeg', type=Path, default=FFMPEG)
    parser.add_argument('--resume', action='store_true', help='Reuse only unchanged, fully captured and decoded current-source clips.')
    args = parser.parse_args()
    require(args.godot.is_file() and args.ffmpeg.is_file() and HARNESS.is_file(), 'Required engine/encoder/harness is missing.')
    runtime, source_receipt = current_inventory()
    MOTION.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    previous = MOTION / 'movie_receipt.json'
    prior = read_json(previous) if args.resume and previous.exists() else {}
    if previous.exists():
        archived = contained(MOTION / 'history' / stamp / 'movie_receipt.json', MOTION)
        archived.parent.mkdir(parents=True, exist_ok=True)
        contained(previous, MOTION).rename(archived)
    receipt = {'passed': False, 'capture_passed': False, 'started_utc': utc(), 'finished_utc': None,
               'runtime': runtime, 'source_inventory_receipt': source_receipt, 'harness_sha256': sha256(HARNESS),
               'runner_path': str(Path(__file__).resolve()), 'runner_sha256': sha256(__file__), 'resumed_cases': [],
               'resume_candidates': prior.get('cases', []) + prior.get('resume_candidates', []),
               'unchanged_during_recording': False, 'cases': [], 'problems': [], 'visual_review': 'pending',
               'limitations': ['Stationary-player ambient scenery fixtures, not human gameplay or performance measurements.',
                               'Actual encoded dimensions are measured; no upscaling is applied.',
                               'Full decode proves readable media, not animation quality; sample images require visual inspection.',
                               'MP4s contain visual presentation only; audio quality is not tested.']}
    write_receipt(receipt)
    try:
        nvidia_smi = shutil.which('nvidia-smi.exe') if os.name == 'nt' else shutil.which('nvidia-smi')
        if nvidia_smi:
            gpu_log = MOTION / 'gpu_preflight.log'
            receipt['gpu_preflight'] = run_owned([nvidia_smi, '--query-gpu=name,temperature.gpu,memory.used',
                                                   '--format=csv,noheader,nounits'], gpu_log, 'read-only GPU health', 20)
            require(not PROBLEM.search(gpu_log.read_text(encoding='utf-8', errors='replace')),
                    'GPU health check reports device loss; restart/driver recovery is required before capture.')
        for arena in ARENAS:
            old = next((c for c in receipt['resume_candidates'] if c.get('arena') == arena and
                        reusable_case(c, runtime, receipt['harness_sha256'], receipt['runner_sha256'], prior)), None)
            if old:
                receipt['cases'].append(old)
                receipt['resumed_cases'].append(arena)
                write_receipt(receipt)
                print(f'{arena}: reusing exact-hash completed current-source clip', flush=True)
                continue
            capture_arena(arena, receipt, args, stamp)
        checkpoint(receipt)
        require(len(receipt['cases']) == 5 and all(c['capture_passed'] for c in receipt['cases']), 'Movie matrix is incomplete.')
        receipt['capture_passed'] = True
        receipt['unchanged_during_recording'] = True
        receipt['resume_candidates'] = []
    except Exception as error:
        receipt['problems'].append(str(error))
        raise
    finally:
        receipt['finished_utc'] = utc()
        write_receipt(receipt)
    print('All five ambient captures/encodes/decodes passed. movie_receipt.json remains passed:false until visual review.', flush=True)


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'MOVIE_CAPTURE_FAILED: {error}', file=sys.stderr, flush=True)
        raise SystemExit(1)
