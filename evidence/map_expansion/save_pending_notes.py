"""Record the actual saved candidate and the external GPU validation blocker."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
def load(name): return json.loads((ROOT / name).read_text(encoding='utf-8-sig'))
def read(name): return (ROOT / name).read_text(encoding='utf-8-sig')
def save(name, value): (ROOT / name).write_text(value, encoding='utf-8')
build = load('builds/windows/build_manifest.json')
gate = load('evidence/validation_all.json')
assert gate['passed']
stamp = build['build_timestamp_utc']
count = len(build['runtime_source_files'])
status = f'''## Five-arena expansion — implemented; GPU validation blocked

Verdant Shrine, Abyssal Observatory and Ember Foundry are implemented alongside The Last Resort and Lunar Reach. The current Windows candidate was exported at **{stamp}**. Its EXE/PCK hashes and all **{count} runtime source files** match the passing source gate.

Completed: import and all 11 source suites (**5,097 assertions**), five full CPU matches through results/rematch (**35 checks**), source-project UI (**108 checks / 40 captures**), **15 reviewed High/Low/recovery stills**, and three **900-tick normal/half-speed gameplay recordings** with complete MP4 decoding. New arena quality restoration and paused clocks pass direct checks.

Outstanding: final exported-PCK UI validation, actual release-EXE runs on all three new maps, and the complete ten-case 1080p performance matrix. Two rooftop profiles completed within budget, but the Lunar High case crashed with Vulkan lost-device errors. Subsequent attempts cannot initialize graphics; NVIDIA's own diagnostic says **“GPU is lost. Reboot the system to recover this GPU.”** These partial profiles are not acceptance for the expansion. Evidence is preserved in `evidence/map_expansion/performance/final_20261003/failure.json` and `evidence/map_expansion/gpu_diagnostic.txt`.

The saved candidate is `builds/windows/RooftopRiot.exe` with its adjacent PCK. The previous verified archive `builds/RooftopRiot-Rebuild-Windows.zip` remains unchanged. A final five-arena ZIP has **not** been certified or created. Restart Windows, then continue this task to run the outstanding checks. Human/physical-controller playtesting and weaker-PC performance remain unverified.

'''
marked = '<!-- MAP_EXPANSION_PENDING_BEGIN -->\n' + status + '<!-- MAP_EXPANSION_PENDING_END -->\n\n'
for path, old_heading, new_heading in [
    ('STATUS.md','## October 3 rebuild — verified Windows build','## Prior eight-fighter rebuild — historical state before arena expansion'),
    ('docs/VALIDATION.md','## October 3, 2026: eight-fighter animation, art and gameplay rebuild','## Prior eight-fighter rebuild: historical acceptance before map expansion'),
    ('docs/PERFORMANCE.md','## October 3 rebuild: measured 1080p results','## Prior two-arena rebuild: historical 1080p results')]:
    value = read(path).replace(old_heading, new_heading, 1)
    header, rest = value.split('\n\n', 1)
    save(path, header + '\n\n' + marked + rest)
value = read('README.md').replace('eight fighters, two arenas','eight fighters, five arenas',1)
lines = value.splitlines()
lines[4] = '**Three new arenas are implemented:** Verdant Shrine, Abyssal Observatory and Ember Foundry. Source, gameplay lifecycle and visual checks pass. The updated Windows candidate is exported, but a GPU device-loss failure now requires a Windows restart before final performance and packaged-build validation. The prior verified ZIP is preserved. See [current status](STATUS.md) and [map guide](docs/MAP_EXPANSION.md).'
value = '\n'.join(lines) + '\n'
value = value.replace('Select **The Last Resort** or **Lunar Reach** beneath the fighter cards','Select **The Last Resort**, **Lunar Reach**, **Verdant Shrine**, **Abyssal Observatory** or **Ember Foundry** beneath the fighter cards')
save('README.md', value)
win = read('docs/WINDOWS_BUILD_README.md')
lines = win.splitlines()
lines[2] = f'**Five-arena Windows candidate — validation pending.** Exported {stamp} with Godot 4.7.2; EXE/PCK and {count} runtime source files match the passing source gate. A GPU device-loss failure requires restarting Windows before the final exported-package and performance checks. The previous verified two-arena ZIP remains preserved in the source workspace.'
win = '\n'.join(lines) + '\n'
win = win.replace('select **The Last Resort** or **Lunar Reach** beneath the fighter cards','select **The Last Resort**, **Lunar Reach**, **Verdant Shrine**, **Abyssal Observatory** or **Ember Foundry** beneath the fighter cards').replace('on either arena.','on any arena.').replace('announced rooftop pyro/lunar vent hazards','announced arena-themed vent hazards')
start = win.index('The default renderer is Forward+')
end = win.index('\n\n', start)
win = win[:start] + 'The default renderer is Forward+ on Vulkan. Launch-Mobile.cmd selects the separate Mobile renderer after restart. Current five-arena performance acceptance is pending: the first matrix stopped on a Vulkan device-loss crash, and NVIDIA now requests a system reboot. Earlier two-arena results in PERFORMANCE.md are historical; they do not validate this candidate. No weaker-PC or current Mobile performance claim is made.' + win[end:]
save('docs/WINDOWS_BUILD_README.md', win)
save('builds/windows/README.md', win)
receipt = dict(complete=False, implementation_complete=True, windows_export_complete=True,
    build_timestamp_utc=stamp, runtime_files=count, source_assertions=5097,
    source_gate='evidence/validation_all.json', source_gate_passed=True,
    source_ui_checks=108, full_match_checks=35, visual_review_count=15, new_arena_movies=3,
    blocker='NVIDIA GPU lost; nvidia-smi explicitly requires system reboot. Graphical initialization fails.',
    next_steps=['Restart Windows','Run a fresh isolated ten-case profile matrix','Validate exported PCK UI and actual EXE on all three new maps','Update current delivery notes from receipts','Run strict package_map_expansion.ps1'],
    preserved_old_archive='builds/RooftopRiot-Rebuild-Windows.zip', final_archive_created=False)
save('evidence/map_expansion/status.json',json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
