"""Promote platform notes only after current, hash-bound acceptance receipts pass.

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
ARCHIVE = 'builds/RooftopRiot-Platform-Upgrade-Windows.zip'
DELIVERY = 'evidence/platform_refinement/delivery.json'
BEGIN = '<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->'
END = '<!-- PLATFORM_REFINEMENT_CURRENT_END -->'
HISTORY = '<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->'
LIMITS = ('Human playtesting, physical multi-controller testing, continuous motion/audio '
          'acceptance, weaker-PC performance and current Mobile-renderer performance '
          'remain unverified. Assistant still review and automated CPU matches do not '
          'establish competitive balance or zero clipping in every pose.')
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


def assertion_count(suite):
    value = suite.get('checks')
    return len(value) if isinstance(value, list) else int(value or 0)


def load_profile_reports(directory, provenance):
    require(provenance.get('passed') is True and provenance['unchanged_during_profiling']
            and len(provenance['cases']) > 0, f'Incomplete profile provenance: {directory}')
    reports = []
    for case in provenance['cases']:
        require(case['arena'] in ARENAS and case['quality'].lower() in {'high', 'low'} and
                case['file'] == f'{case["arena"]}_{case["quality"].lower()}_4p.json',
                f'Unexpected profile case: {directory}')
        file = directory / case['file']
        check_hash(file, case['sha256'])
        report = read_json(file)
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


def performance_table(reports):
    table = ('| Arena | Tier | Samples | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |\n'
             '|---|---|---:|---:|---:|---:|---:|---:|\n')
    for report in reports:
        f = report['frame_intervals']
        table += (f'| {ARENAS[report["arena"]]} | {report["quality"]} | {f["count"]:,} | '
                  f'{f["p95_ms"]:.3f} / {f["p99_ms"]:.3f} | {f["max_ms"]:.3f} | {f["over_16_667"]} | '
                  f'{report["viewport_render_cpu"]["p95_ms"]:.3f} | {report["viewport_render_gpu"]["p95_ms"]:.3f} |\n')
    return table


def promote(document, section, relative):
    """Own one marked current section and retain every earlier record verbatim."""
    document = re.sub(re.escape(BEGIN) + r'\n.*?' + re.escape(END) + r'\n*',
                      '', document, flags=re.S)
    first, separator, remainder = document.partition('\n')
    require(separator and first.startswith('# '), f'Expected document title: {relative}')
    remainder = remainder.lstrip('\n')
    if HISTORY not in remainder:
        # These markers previously described the latest map expansion. Rename
        # them as history without discarding its failures or recorded metrics.
        remainder = remainder.replace('MAP_EXPANSION_CURRENT_', 'MAP_EXPANSION_HISTORICAL_')
        remainder = re.sub(r'^## Five-arena expansion[^\n]*$',
                           lambda match: match[0].replace('Five-arena expansion',
                               'Historical five-arena expansion before platform refinement', 1)
                               .replace('current', 'recorded'), remainder, flags=re.M)
        if relative == 'docs/KNOWN_ISSUES.md':
            remainder = remainder.replace('## Current limits\n',
                                          '## Historical limits before platform refinement\n', 1)
        if relative == 'docs/MAP_EXPANSION.md':
            remainder = remainder.replace('## Validation status\n',
                                          '## Historical pre-platform validation status\n', 1)
        historical = ('\n\n' + HISTORY + '\n## Historical records before the platform refinement\n\n'
                      'The retained notes below describe earlier build snapshots. Their '
                      'screenshots, movies, runtime counts, metrics and package names are '
                      'historical; current platform acceptance is above. The pre-platform '
                      'runtime, docs, tools, Windows build and map evidence are preserved '
                      'under `evidence/platform_refinement/baseline/`. Earlier failure '
                      'histories remain retained.\n'
                      '<!-- PLATFORM_REFINEMENT_HISTORY_END -->\n\n')
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
    visual = read_json('evidence/platform_refinement/visualreview.json')
    provenance = read_json(profiles_dir / 'profile_provenance.json')
    baseline = read_json('evidence/platform_refinement/baseline.json')
    for name, receipt in (('source gate', gate), ('Windows validation', package),
                          ('map EXE validation', release), ('visual review', visual),
                          ('profiles', provenance)):
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
    captures = visual['captures']
    require(len(captures) == 25 and {(c['arena'], c['purpose']) for c in captures} ==
            {(arena, view) for arena in ARENAS for view in VIEWS}, 'Expected five current views on each arena.')
    require(not visual.get('blocking_findings'), 'Platform visual review has blocking findings.')
    for capture in captures:
        require(capture['reviewed'] and capture['quality'].lower() ==
                ('low' if capture['purpose'] == 'low' else 'high'), 'A current platform view is unreviewed or has wrong quality.')
        png_record(capture)
    check_hash('tools/validation/rebuild_performance.gd', provenance['harness_sha256'])
    require(provenance['art']['present'], 'Profile fighter-art report is missing.')
    check_hash('evidence/characters/hero_rebuild/release_assets.json', provenance['art']['sha256'])
    require(len(provenance['cases']) == 10, 'Expected ten current High/Low profiles.')
    profiles = load_profile_reports(profiles_dir, provenance)
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
                and receipt['harness_sha256'].upper() == provenance['harness_sha256'].upper(),
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
                         if missed else f'All {samples:,} measured render intervals stayed below 16.667 ms.')
    ticks = ', '.join(f'{ARENAS[p["arena"]]} {p["quality"]}: {p["simulation_ticks_in_sample_window"]:,}' for p in profiles)
    table = performance_table(profiles)
    repeat_section = ''
    repeat_summary = ''
    if repeats:
        repeat_count = sum(len(reports) for _, reports in repeats)
        repeat_summary = (f'An additional {repeat_count} unchanged-source repeat case(s) are recorded separately '
                          'in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers.')
        repeat_section = ('### Additional isolated repeats\n\nThe following completed one-minute repeats use the same '
                          'runtime inventory, accepted fighter-art report and measurement harness. They are '
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
    art_table = '''| Arena | Platform finish |
|---|---|
| The Last Resort | Timber decks, stone faces and brass edge details |
| Lunar Reach | Service panels and vent housings with a clear landing edge |
| Verdant Shrine | Jointed weathered stone with carved edge construction |
| Abyssal Observatory | Marble and brass around recessed cobalt panels |
| Ember Foundry | Steel treads, support ribs and inset vents |
'''
    scope = ('Main decks and raised platforms on all five arenas have rebuilt surface construction. '
             'Flat face normals and chamfered geometry give the slabs distinct top, edge and underside planes. '
             'The authored landing planes, arena layouts and lift behavior are retained. '
             'Materials and detail follow each arena\'s setting; High and Low retain readable platform edges.')
    identity = (f'Exported **{build["build_timestamp_utc"]}** with Godot 4.7.2; **{count} runtime files** match '
                f'the current source, build, visual-review and performance inventories (`{runtime_hash}`).')
    counts = (f'{checks:,} source assertions; 25 current 1080p platform views; five completed CPU '
              'matches/35 lifecycle checks; 108 exported-PCK UI checks/40 captures; actual Windows '
              'EXE smoke on each of the three added arenas; ten isolated 60-second four-player profiles.')
    reproduction = '''```powershell
$godot = 'D:\\Game Engines\\Godot\\Godot_v4.7.2-stable_win64_console.exe'
$project = Join-Path $PWD 'Game File'
$allArenas = @('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')
$review = Join-Path $PWD 'evidence/platform_refinement/review_reproduced'
$profiles = Join-Path $PWD ('evidence/platform_refinement/performance/local-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& ./tools/validation/validate_all.ps1 -Godot $godot
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_stage_review.gd') -- "--output=$review"
# Inspect all 25 captures and record exact hashes/current runtime in visualreview.json.
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_match_flow.gd') -- "--evidence-root=$(Join-Path $PWD 'evidence/rebuild')"
& ./tools/validation/export_windows.ps1 -Godot $godot
& ./tools/validation/validate_windows_build.ps1 -Godot $godot
& ./tools/validation/validate_map_release.ps1
& ./tools/validation/profile_rebuild.ps1 -Arenas $allArenas -Qualities High,Low -Players 4 -Seconds 60 -Output $profiles
python ./evidence/platform_refinement/update_delivery_notes.py $profiles
# Add any completed unchanged-source repeats as further directory arguments:
# python ./evidence/platform_refinement/update_delivery_notes.py $profiles $repeatObservatory $repeatFoundry
& ./tools/validation/package_map_expansion.ps1 -PerformanceDirectory $profiles `
  -ArchivePath (Join-Path $PWD 'builds/RooftopRiot-Platform-Upgrade-Windows.zip') `
  -DeliveryReceiptPath (Join-Path $PWD 'evidence/platform_refinement/delivery.json')
```
'''
    sections = {
        'README.md': f'''## Platform refinement — validated Windows build

{scope}

{art_table}
Play the matching `builds/windows/RooftopRiot.exe` and `.pck`. The dedicated archive target is `{ARCHIVE}`; successful packaging writes `{DELIVERY}` and verifies every decoded ZIP entry. The preceding Five-Arenas archive remains unchanged.

{counts} {identity}

[Platform guide and reproduction](docs/MAP_EXPANSION.md) · [validation](docs/VALIDATION.md) · [current performance](docs/PERFORMANCE.md). {LIMITS}
''',
        'STATUS.md': f'''## Platform refinement — validated source and Windows build

{scope}

{counts} {identity}

{performance_claim} {repeat_summary} Current data are in `{profile_rel}/`; still review is `evidence/platform_refinement/visualreview.json`. Earlier map and fighter movies describe the pre-platform presentation.

Package target: `{ARCHIVE}`. The receipt `{DELIVERY}` establishes completion of archive packaging; this documentation generator does not certify an archive. Pre-platform backups and the prior Five-Arenas ZIP are retained. {LIMITS}
''',
        'docs/VALIDATION.md': f'''## Platform refinement — current acceptance

{identity}

| Check | Current result | Evidence |
|---|---|---|
| Source and preservation | Import plus all {len(gate['suites']) - 1} suites pass; {checks:,} assertions; eight supplied originals preserved | `evidence/validation_all.json` |
| Stage/presentation/motion regression | {suite_counts['stages']} stage, {suite_counts['presentation_state']} presentation and {suite_counts['rebuild_animation']} animation assertions | Source gate suite records |
| Platform review | 25 exact, reviewed 1080p stills: High, Low, overlap, recovery and near-ledge on every arena | `evidence/platform_refinement/visualreview.json` |
| Full lifecycle | Five natural CPU matches through results and rematch; 35 checks | `evidence/rebuild/match_flow.json` |
| Exported UI | 108 checks and 40 current 1080p images; matching editor loads the explicit exported PCK | `evidence/windows_release_flow/validation.json` |
| Actual executable | Default 600-tick/four-CPU run plus each added arena at 600 ticks with explicit CPU providers and contacts; clean exits | Windows receipt and `evidence/map_expansion/release_validation.json` |
| Performance | Ten current source/art/harness-bound 60-second High/Low cases, five arenas, four CPU fighters, 1080p | `{profile_rel}/profile_provenance.json` |

Current platform stills establish assistant visual review of those exact images, including face shading and landing-edge readability. They do not establish temporal shimmer, continuous motion or human acceptance. Earlier map movies and before/after fighter comparisons remain historical. Screenshot readback is excluded from the profile window.

{performance_claim} {repeat_summary}

The dedicated ZIP target is `{ARCHIVE}`. Packaging separately verifies source/build/UI/EXE/lifecycle/profile receipts and every archive entry, writing `{DELIVERY}`. {LIMITS}
''',
        'docs/PERFORMANCE.md': f'''## Platform refinement — current four-player measurements

Ten isolated 60-second source-project cases cover all five arenas at 1920×1080 on High and Low, with four CPU fighters and authoritative 60 Hz combat. {performance_claim} Measurements apply to the Ryzen 7700X / RTX 4080 SUPER workstation; they do not certify weaker PCs, the exported build or the separate Mobile renderer.

CPU rendering work, GPU rendering work and frame intervals are separate measures; their percentiles must not be added. Screenshot readback occurs after measurement. The provenance receipt binds every report to unchanged current runtime, accepted fighter art and the measurement harness. Summary JSON reports, engine/native logs and companion captures are in `{profile_rel}/`; the harness does not save the raw interval series.

Combat ticks by case: {ticks}.

### Original full matrix

[Bound ten-case receipt](../{profile_rel}/profile_provenance.json). These original results remain intact, including every recorded outlier.

{table}
{repeat_section}
Earlier map and two-arena matrices below are historical workloads. The earlier Vulkan lost-device failure and reboot history remain retained; its cause was not established, and this platform pass does not claim a driver fix.
''',
        'docs/WINDOWS_BUILD_README.md': f'''## Platform refinement — validated Windows build

Main and raised platforms have finished stone, marble, timber or steel construction across all five arenas. {identity}

Double-click **RooftopRiot.exe** beside its matching **RooftopRiot.pck**. Start a Fight, choose fighters and arena, assign keyboard/controllers/CPUs, then Ready. Party/Fair Fight and rematch remain available. Default rendering uses Forward+; `Launch-Mobile.cmd` chooses the separate Mobile renderer after restart. Godot and Blender are not required to play.

The packaged archive target is `RooftopRiot-Platform-Upgrade-Windows.zip`; workspace receipt `{DELIVERY}` records successful archive verification. The exported UI passes 108 checks and actual Windows EXE runs cover the three added arenas. Ten 1080p High/Low four-player cases are listed in `PERFORMANCE.md`. {performance_claim} {repeat_summary}

{LIMITS}
''',
        'docs/MAP_EXPANSION.md': f'''## Platform refinement — all five arenas

{scope}

{art_table}
The shared editable slab builder is `Game File/stages/platform_geometry.gd`; per-arena construction lives under `Game File/stages/`. Platform material shaders remain editable source files in those arena folders. No new generated bitmap artwork or character rebuild is part of this pass. Distant illustrated vistas retain their original map-expansion provenance.

{identity} {counts}

Current still hashes and findings: `evidence/platform_refinement/visualreview.json`. Pre-platform runtime, docs, tools, build and evidence: `evidence/platform_refinement/baseline/`; preservation receipt: `evidence/platform_refinement/baseline.json`. The prior `builds/RooftopRiot-Five-Arenas-Windows.zip` retains SHA-256 `{baseline['previous_archive_sha256']}`. Prior map movies remain historical evidence of that earlier build.

### Reproduction

Run graphical review, lifecycle, export, Windows validation and profiling sequentially. Freeze runtime sources before final captures/receipts. The notes generator requires current 25-view acceptance and matching source/build/profile hashes before it writes docs; the strict packager then creates `{ARCHIVE}` and `{DELIVERY}`.

{reproduction}
{LIMITS}
''',
        'docs/KNOWN_ISSUES.md': f'''## Platform refinement — current validation limits

The rebuilt platform surfaces on all five arenas pass the current 25-view assistant review, source gate, five-match lifecycle and exported Windows checks. {performance_claim} {repeat_summary} Exact frame maxima and CPU/GPU percentiles are in [PERFORMANCE.md](PERFORMANCE.md); no outlier cause is inferred from aggregate samples.

- Still-image review covers High/Low, overlap, recovery and near-ledge fixtures. It cannot establish temporal shimmer or every combat pose and moving-platform transition.
- Human gameplay, continuous motion/audio judgment and physical multi-controller operation remain unverified.
- The performance matrix covers this workstation at 1080p with four CPU fighters. Weaker-PC, current Mobile-renderer and exported-build performance remain unverified.
- Prior map movies and historical fighter comparisons predate the platform finishes; they are not current platform-motion acceptance.
- Archive completion is recorded separately in `{DELIVERY}` after strict packaging; documentation promotion alone does not certify the ZIP.

Original-asset permission records and earlier engine/device failure histories below remain retained. No new permission or driver-resolution claim is made by this visual pass.
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
    print(json.dumps({'source_assertions': checks, 'runtime_files': count, 'platform_views': 25,
                      'performance_samples': samples, 'over_budget': missed, 'updated_documents': len(documents),
                      'repeat_directories': [relative for relative, _ in repeats],
                      'repeat_cases': sum(len(reports) for _, reports in repeats),
                      'archive_target': ARCHIVE, 'archive_packaging_still_separate': True}))


if __name__ == '__main__':
    main()
