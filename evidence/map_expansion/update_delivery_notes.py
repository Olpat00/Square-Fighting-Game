"""Generate the expansion's final notes only from completed local receipts."""
import json
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILES = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / 'evidence/map_expansion/performance/after_reboot_20261003'
PROFILE_REL = PROFILES.relative_to(ROOT).as_posix()

def read_json(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))

def text(path):
	value = (ROOT / path).read_text(encoding='utf-8-sig')
	return re.sub(r'<!-- MAP_EXPANSION_PENDING_BEGIN -->.*?<!-- MAP_EXPANSION_PENDING_END -->\n*', '', value, flags=re.S)

def save(path, value):
    (ROOT / path).write_text(value, encoding='utf-8')

def prepend_current(document, title, section):
    # Own only the generated section; retain the historical suffix verbatim.
    begin = '<!-- MAP_EXPANSION_CURRENT_BEGIN -->'
    end = '<!-- MAP_EXPANSION_CURRENT_END -->'
    document = re.sub(re.escape(begin) + r'\n.*?' + re.escape(end) + r'\n\n', '', document, flags=re.S)
    # Accept a first promotion made by the older, unmarked updater as well.
    section_heading = section.splitlines()[0]
    document = re.sub(r'^' + re.escape(section_heading) + r'\n.*?(?=^## |\Z)', '', document, flags=re.S | re.M)
    anchor = title + '\n\n'
    require(document.count(anchor) == 1, f'Expected one document title: {title}')
    return document.replace(anchor, anchor + begin + '\n' + section.rstrip() + '\n' + end + '\n\n', 1)

def require(condition, message):
    if not condition:
        raise ValueError(message)

def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest().upper()

def inventory(records):
    result = {r['path'].replace('\\', '/'): (r['bytes'], r['sha256'].upper()) for r in records}
    require(len(result) == len(records), 'Duplicate runtime inventory entries.')
    return result

gate = read_json('evidence/validation_all.json')
package = read_json('evidence/windows_release_flow/validation.json')
release = read_json('evidence/map_expansion/release_validation.json')
build = read_json('builds/windows/build_manifest.json')
flow = read_json('evidence/rebuild/match_flow.json')
provenance = json.loads((PROFILES / 'profile_provenance.json').read_text(encoding='utf-8-sig'))
assert gate['passed'] and package['passed'] and release['passed'] and provenance['passed']
assert flow['checks'] == 35 and flow['failures'] == 0
assert len(provenance['cases']) == 10
checks = sum(len(s['checks']) if isinstance(s.get('checks'), list) else (s.get('checks') or 0) for s in gate['suites'])
count = len(build['runtime_source_files'])
# A passing historical receipt must never promote the current candidate's notes.
expected_inventory = inventory(build['runtime_source_files'])
require(inventory(gate['runtime']['files']) == expected_inventory == inventory(provenance['runtime']['files']), 'Source gate, profiles and exported build describe different runtime files.')
runtime_hash = gate['runtime']['sha256'].upper()
require(provenance['runtime']['sha256'].upper() == runtime_hash and provenance['unchanged_during_profiling'], 'Profile source binding is stale or changed during measurement.')
project = ROOT / 'Game File'
runtime_extensions = {'.gd', '.gdshader', '.godot', '.tscn', '.tres', '.glb', '.png', '.jpg', '.jpeg', '.svg', '.wav', '.ogg', '.json', '.import', '.uid', '.cfg'}
runtime_paths = {p.relative_to(project).as_posix(): p for p in project.rglob('*') if p.is_file() and '.godot' not in p.relative_to(project).parts and p.suffix in runtime_extensions and not p.name.startswith('source_') and p.name not in {'validate_input.gd', 'engine.png'}}
require(runtime_paths.keys() == expected_inventory.keys(), 'Current runtime file set differs from the exported build.')
for relative, path in runtime_paths.items():
    require((path.stat().st_size, sha256(path)) == expected_inventory[relative], f'Runtime file changed after validation: {relative}')
build_hashes = {'executable': build['exe_sha256'].upper(), 'pck': build['pck_sha256'].upper(), 'manifest': sha256(ROOT / 'builds/windows/build_manifest.json')}
for key, filename in (('executable', 'RooftopRiot.exe'), ('pck', 'RooftopRiot.pck')):
    require(sha256(ROOT / 'builds/windows' / filename) == build_hashes[key], f'Current {filename} differs from its build manifest.')
require(package['build_unchanged_during_validation'] and release['build_unchanged_during_validation'], 'Release build changed during validation.')
for key, field in (('executable', 'executable_sha256'), ('pck', 'pck_sha256'), ('manifest', 'build_manifest_sha256')):
    require(package[field].upper() == build_hashes[key], f'Windows UI receipt belongs to another {key}.')
    for moment in ('before', 'after'):
        require(release[f'build_hashes_{moment}'][key]['sha256'].upper() == build_hashes[key], f'Map release receipt belongs to another {key}.')
for moment in ('before', 'after'):
    require(package[f'runtime_source_hashes_verified_{moment}'] == count, 'Windows UI receipt has another runtime file count.')
    release_runtime = release[f'runtime_inventory_{moment}']
    require(release_runtime['files'] == count and release_runtime['sha256'].upper() == runtime_hash and release_runtime['manifest_inventory_sha256'].upper() == runtime_hash, 'Map release receipt belongs to another runtime inventory.')
require(package['pck_ui_harness']['checks'] == 108 and len(package['pck_ui_harness']['captured_images']) == 40, 'Current exported UI acceptance is incomplete.')
require(provenance['harness_sha256'].upper() == sha256(ROOT / 'tools/validation/rebuild_performance.gd'), 'Profile harness changed after measurement.')
require(provenance['art']['sha256'].upper() == sha256(ROOT / 'evidence/characters/hero_rebuild/release_assets.json'), 'Profile fighter art binding is stale.')
titles = dict(rooftop_riot='The Last Resort', lunar_reach='Lunar Reach', verdant_shrine='Verdant Shrine', abyssal_observatory='Abyssal Observatory', ember_foundry='Ember Foundry')
profiles = []
for case in provenance['cases']:
    path = PROFILES / case['file']
    require(sha256(path) == case['sha256'].upper(), f'Profile changed after measurement: {case["file"]}')
    profiles.append(json.loads(path.read_text(encoding='utf-8-sig')))
require({(p['arena'], p['quality'].lower(), p['players']) for p in profiles} == {(arena, quality, 4) for arena in titles for quality in ('high', 'low')}, 'Profiles do not cover all five arenas at High/Low with four players.')
missed = sum(p['frame_intervals']['over_16_667'] for p in profiles)
samples = sum(p['frame_intervals']['count'] for p in profiles)
ticks = [p['simulation_ticks_in_sample_window'] for p in profiles]
tick_claim = (f'Every case advances {ticks[0]:,} combat ticks.' if len(set(ticks)) == 1 else 'Combat ticks by case: ' + '; '.join(f'{titles[p["arena"]]} {p["quality"]}: {p["simulation_ticks_in_sample_window"]:,}' for p in profiles) + '.')
performance_claim = ('All ten cases stayed below the 16.667 ms frame budget in every measured sample.' if missed == 0 else f'The ten cases contain {missed} intervals above 16.667 ms out of {samples:,} samples; the full table retains those outliers.')
table = '| Arena | Tier | Frame P95 / P99 ms | Max ms | >16.667 ms | Render CPU P95 ms | GPU P95 ms |\n|---|---|---:|---:|---:|---:|---:|\n'
for p in profiles:
    f = p['frame_intervals']
    table += f"| {titles[p['arena']]} | {p['quality']} | {f['p95_ms']:.3f} / {f['p99_ms']:.3f} | {f['max_ms']:.3f} | {f['over_16_667']} | {p['viewport_render_cpu']['p95_ms']:.3f} | {p['viewport_render_gpu']['p95_ms']:.3f} |\n"
performance_section = f'''## Five-arena expansion: current four-player measurements

Ten isolated 60-second cases cover all five arenas at 1920×1080 on High and Low, using four CPU fighters and the fixed 60 Hz combat loop. {performance_claim} These measurements apply to the Ryzen 7700X / RTX 4080 SUPER workstation; weaker-PC and current Mobile-renderer performance remain unverified.

The matrix contains {samples:,} render-interval samples. {tick_claim} Screenshot readback occurs after the measurement window; movie, export, Blender and other Godot work were stopped during profiling. Render CPU and GPU time are reported separately from frame pacing. Full reports, sample counts, callback statistics, draw counts and memory are in `{PROFILE_REL}/`; `profile_provenance.json` binds all ten cases to unchanged current source, fighter art and harness.

An earlier uncapped matrix aborted on Lunar High with Vulkan lost-device errors; NVIDIA then reported a lost GPU requiring a system reboot. That failed run is preserved in `evidence/map_expansion/performance/final_20261003/failure.json`. Its root cause was not established. The table below describes the subsequent complete run, not a demonstrated fix for that driver/device failure.

{table}
The table measures four-player matches. Earlier two-player figures below belong to the previous two-arena rebuild and are retained as history.

'''
old = text('docs/PERFORMANCE.md').replace('## October 3 rebuild: measured 1080p results', '## Prior two-arena rebuild: historical 1080p results', 1)
save('docs/PERFORMANCE.md', prepend_current(old, '# Measured Windows performance', performance_section))

validation_section = f'''## Five-arena expansion: current acceptance

The three new arenas are Verdant Shrine, Abyssal Observatory and Ember Foundry. The Last Resort and Lunar Reach remain available. The current build was exported at **{build['build_timestamp_utc']}** with Godot 4.7.2, and its **{count} runtime files** match the validated source inventory.

| Check | Result | Evidence |
|---|---|---|
| Source and preservation | Import + all 11 suites pass; {checks:,} assertions, four settings scenarios, 36 pairings and 20 rematches. All eight supplied originals preserved. | `evidence/validation_all.json` |
| New arena behavior | 120 stage checks; 181 presentation checks; 86 animation checks, including complete lift cycles. Low reductions/restoration and paused clocks are covered on all five maps. | Stage, presentation and animation reports referenced by the source gate |
| Full match lifecycle | Five complete CPU matches; 35 checks; results, stock losses and clean rematches. | `evidence/rebuild/match_flow.json` |
| Graphical review | 15 current High/Low, overlap, wide recovery and near-ledge captures reviewed; no blocking still-image findings. | `evidence/map_expansion/visual_review.json` |
| Continuous footage | Three 900-tick CPU movies; 29 / 43 / 41 contacts for Shrine / Observatory / Foundry. Normal and half-speed MP4s fully decode. Native movies are 1600×900; PNGs are 1920×1080. | `evidence/map_expansion/brawl/<arena>/capture_validation.json` |
| Exported package UI | 108 checks and 40 fresh captures using the matching engine on the exported PCK; clean exit. | `evidence/windows_release_flow/validation.json` |
| Actual Windows EXE | Each new arena completes 600 ticks with four explicit CPU providers and combat contacts; clean exit, fresh 1080p capture, source/build hashes unchanged. | `evidence/map_expansion/release_validation.json` |
| Performance | Ten source-bound, isolated 60-second cases, all five arenas at High/Low with four CPU fighters. | [Measured results](PERFORMANCE.md) |

The full source gate initially exposed an outdated mock stage interface and a six-second lift test that did not cover the slower ocean lift. The mock now implements the arena-bounds interface and the animation test samples each complete cycle, including ascent/descent and foot anchors. These fixture repairs did not change gameplay rules. The initial failed report is retained in `evidence/map_expansion/initial_source_gate_failure.json`.

The first three-map EXE validator rejected the texture-size metadata even though the window, actual image readback and saved PNG were all 1920×1080. The same metadata discrepancy exists in the prior accepted build. The runner now checks window, image and PNG dimensions and retains texture metadata separately; all three fresh reruns pass. This validation-only correction changes no runtime files. The failed receipt is retained in `evidence/map_expansion/release_size_metadata_failure.json`, with original case outputs under `release/history/`.

Human playtesting, physical controllers, subjective audio/continuous-motion acceptance and weaker-PC performance remain unverified. Automated matches and assistant still review do not establish competitive balance. Current delivery is `builds/RooftopRiot-Five-Arenas-Windows.zip`; its final receipt is `evidence/map_expansion/delivery.json`.

'''
old = text('docs/VALIDATION.md').replace('## October 3, 2026: eight-fighter animation, art and gameplay rebuild', '## Prior eight-fighter rebuild: historical acceptance before the map expansion', 1)
save('docs/VALIDATION.md', prepend_current(old, '# Validation record', validation_section))

old = text('README.md').replace('eight fighters, two arenas', 'eight fighters, five arenas', 1)
lines = old.splitlines()
lines[4] = f'**The five-arena Windows build is ready to play.** Verdant Shrine, Abyssal Observatory and Ember Foundry join The Last Resort and Lunar Reach, with distinct scenery, platform arrangements and Party effects. The current source passes {checks:,} assertions; exported UI passes 108 checks, and the actual release EXE runs all three new maps. [Map guide and editable sources](docs/MAP_EXPANSION.md) · [measured performance](docs/PERFORMANCE.md).'
old = '\n'.join(lines) + '\n'
old = old.replace('Select **The Last Resort** or **Lunar Reach** beneath the fighter cards', 'Select **The Last Resort**, **Lunar Reach**, **Verdant Shrine**, **Abyssal Observatory** or **Ember Foundry** beneath the fighter cards')
map_intro = 'The new maps use a waterfall sanctuary, an underwater brass gallery, and a suspended volcanic forge. Distant illustrated vistas sit behind animated 3D scenery and authored play surfaces. '
old = old.replace(map_intro, '')
old = old.replace('The Last Resort uses warm sunset/cool pool contrast.', map_intro + 'The Last Resort uses warm sunset/cool pool contrast.', 1)
reproduction = f'''## Reproduction and evidence

The current source gate passes {checks:,} assertions, four settings scenarios, 36 roster pairings and 20 rematches. The exported PCK passes 108 UI checks with 40 fresh captures; the actual Windows executable completes 600 ticks with four CPU fighters and combat contacts on each new arena. Five full matches pass 35 lifecycle checks. Ten isolated 60-second profiles cover all five arenas at High/Low with four players, measuring CPU/GPU work and frame pacing at 1080p. The build and current receipts bind to the same {count}-file runtime inventory. Current map evidence is in `evidence/map_expansion/`; [validation](docs/VALIDATION.md) and [performance](docs/PERFORMANCE.md) retain exact results and limits. Human playtesting, physical-controller testing, subjective audio/continuous-motion acceptance and weaker-PC performance remain unverified.

New-map normal/half-speed recordings are available for [Verdant Shrine](evidence/map_expansion/brawl/verdant_shrine/brawl.mp4), [Abyssal Observatory](evidence/map_expansion/brawl/abyssal_observatory/brawl.mp4) and [Ember Foundry](evidence/map_expansion/brawl/ember_foundry/brawl.mp4), with half-speed versions beside them. These 900-tick CPU movies use ordinary match play; their recording cost is excluded from performance measurements.

The prior fighter rebuild's historical before/after comparisons remain available for [Clutch](evidence/rebuild/comparison/f01_clutch.mp4) ([half speed](evidence/rebuild/comparison/f01_clutch_half_speed.mp4)) and [Heavy Duty](evidence/rebuild/comparison/f03_heavy_duty.mp4) ([half speed](evidence/rebuild/comparison/f03_heavy_duty_half_speed.mp4)). Both use the same scripted movement/combat phrases in the preserved baseline and rebuilt project. The [portrait roster](evidence/characters/hero_rebuild/final_portrait_roster.jpg) shows the eight updated model portraits. Historical four-CPU recordings for [The Last Resort](evidence/rebuild/brawl/rooftop_riot/brawl.mp4) and [Lunar Reach](evidence/rebuild/brawl/lunar_reach/brawl.mp4) remain beside their half-speed versions. September evidence and the prior two-arena performance matrix are historical.

Run graphical validation, profiling and capture sequentially so measurement windows stay isolated:

```powershell
$allArenas = @('rooftop_riot', 'lunar_reach', 'verdant_shrine', 'abyssal_observatory', 'ember_foundry')
$profiles = Join-Path $PWD ('evidence/map_expansion/performance/local-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& ./tools/validation/validate_all.ps1
& ./tools/validation/export_windows.ps1
& ./tools/validation/validate_windows_build.ps1
& ./tools/validation/validate_map_release.ps1
& ./tools/validation/profile_rebuild.ps1 -Arenas $allArenas -Qualities High,Low -Players 4 -Seconds 60 -Output $profiles
python ./evidence/map_expansion/update_delivery_notes.py $profiles
& ./tools/validation/package_map_expansion.ps1 -PerformanceDirectory $profiles
```

If runtime edits invalidate the saved lifecycle or visual evidence, rerun the affected review fixtures before packaging. The profile's `profile_provenance.json` binds all ten cases to the current {count}-file runtime inventory, accepted art and measurement harness. Packaging checks these bindings against the exported build, writes `builds/RooftopRiot-Five-Arenas-Windows.zip`, verifies every archive entry by SHA-256 and records `evidence/map_expansion/delivery.json`. The prior `builds/RooftopRiot-Rebuild-Windows.zip` remains preserved.

'''
reproduction_start = old.index('## Reproduction and evidence')
reproduction_end = old.index('The new stage and continuous-motion review fixtures', reproduction_start)
old = old[:reproduction_start] + reproduction + old[reproduction_end:]
save('README.md', old)

status = text('STATUS.md').replace('## October 3 rebuild — verified Windows build', '## Prior eight-fighter rebuild — historical state before arena expansion', 1)
section = f'''## Five-arena expansion — verified Windows build

Three new maps are integrated: **Verdant Shrine**, **Abyssal Observatory**, and **Ember Foundry**. Each has a distinct layout, generated distant scenery, locally editable 3D geometry/materials, animated details and Party hazards. Existing fighters, move timing, the original two collision layouts, inputs and 60 Hz combat remain intact. Shared recovery/CPU logic now reads actual arena dimensions.

Current validation: {checks:,} source assertions, 108 packaged UI checks/40 captures, five full matches/35 lifecycle checks, three actual Windows EXE arena smokes and ten isolated 1080p four-player performance cases. {performance_claim}

Play `builds/windows/RooftopRiot.exe` or extract `builds/RooftopRiot-Five-Arenas-Windows.zip`. Exact export time is {build['build_timestamp_utc']}; all {count} runtime file hashes are checked. Prior archive `builds/RooftopRiot-Rebuild-Windows.zip` and `Fighting Game Map Expansion Backup 20261003-174209` remain preserved.

[Map sources and reproduction](docs/MAP_EXPANSION.md) · [validation](docs/VALIDATION.md) · [performance](docs/PERFORMANCE.md). Human/physical-controller playtesting and weaker-PC performance remain open. The following section records the earlier rebuild, not the current package manifest.

'''
save('STATUS.md', prepend_current(status, '# UNSUPERVISED: ROOFTOP RIOT — production status', section))

win = text('docs/WINDOWS_BUILD_README.md')
win_lines = win.splitlines()
win_lines[2] = f'**Five-arena Windows build — October 3.** Exported {build["build_timestamp_utc"]} with Godot 4.7.2 and verified against {count} runtime source files. The exported PCK passes 108 UI checks; the actual Windows EXE completes four-fighter smoke runs on all three new arenas. Exact hashes are in `build_manifest.json`.'
win = '\n'.join(win_lines) + '\n'
win = win.replace('select **The Last Resort** or **Lunar Reach** beneath the fighter cards', 'select **The Last Resort**, **Lunar Reach**, **Verdant Shrine**, **Abyssal Observatory** or **Ember Foundry** beneath the fighter cards')
win = win.replace('on either arena.', 'on any arena.').replace('announced rooftop pyro/lunar vent hazards', 'announced arena-themed vent hazards')
start = win.index('The default renderer is Forward+')
end = win.index('\n\n', start)
win = win[:start] + f'The default renderer is Forward+ on Vulkan. Launch-Mobile.cmd selects the separate Mobile renderer and requires a restart. Ten 60-second 1080p four-player High/Low cases cover all five arenas. {performance_claim} See `PERFORMANCE.md` for CPU/GPU/frame-pacing results and `MAP_EXPANSION.md` for map sources. Weaker-PC and current Mobile performance remain unverified.' + win[end:]
save('docs/WINDOWS_BUILD_README.md', win)

guide = text('docs/MAP_EXPANSION.md')
guide = guide[:guide.index('## Validation status')] + f'''## Validation status

The current full-source gate passes {checks:,} assertions, including 120 stage, 181 presentation and 86 animation checks. All five complete matches pass 35 lifecycle checks. Exported-PCK UI passes 108 checks; the actual EXE passes three new-arena smoke runs. Fifteen final stills were reviewed, and normal/half-speed four-player movies were captured and fully decoded. Ten isolated one-minute 1080p High/Low four-player cases bind to the same unchanged source and assets.

See [VALIDATION.md](VALIDATION.md) and [PERFORMANCE.md](PERFORMANCE.md) for current evidence, exact metrics and limits. The verified playable package is `builds/RooftopRiot-Five-Arenas-Windows.zip`; editable arena code and original matte PNGs remain in this workspace. The prior build/archive are preserved. Human playtesting, physical controllers and weaker-PC performance remain unverified.
'''
save('docs/MAP_EXPANSION.md', guide)
print(json.dumps({'source_assertions': checks, 'runtime_files': count, 'performance_samples': samples, 'over_budget': missed, 'updated_documents': 6}))
