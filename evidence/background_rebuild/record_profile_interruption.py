"""Preserve the interrupted uncapped matrix and observed reboot evidence."""
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'evidence/background_rebuild'
source = (BASE / 'performance/final').resolve()
target = (BASE / 'performance/aborted_uncapped_20261004').resolve()
assert source.parent == target.parent == (BASE / 'performance').resolve()
assert source.is_relative_to(ROOT) and target.is_relative_to(ROOT)
assert source.is_dir() and not target.exists()
source.rename(target)
shutil.copy2(BASE / 'performance_runner.log', target / 'runner.log')

def record(p):
    b = p.read_bytes()
    return {'path': str(p), 'bytes': len(b), 'sha256': hashlib.sha256(b).hexdigest().upper(),
            'nul_bytes': b.count(b'\x00')}

engine_log = target / 'lunar_reach_high_4p.log'
text = engine_log.read_text(encoding='utf-8-sig')
assert 'print_lost_device_info' in text and 'Program crashed with signal 11' in text
records = [record(p) for p in sorted(target.iterdir()) if p.is_file()]
completed = [p.name for p in target.glob('*_4p.json')]
assert set(completed) == {'rooftop_riot_high_4p.json', 'rooftop_riot_low_4p.json'}
receipt = {
    'passed': False, 'recorded_utc': datetime.now(timezone.utc).isoformat(),
    'status': 'uncapped_matrix_aborted_during_lunar_reach_high',
    'render_cap': 0, 'vsync': 'disabled', 'completed_partial_reports': completed,
    'failed_case': 'lunar_reach_high_4p', 'native_exit_code': None,
    'engine_evidence': 'Vulkan lost-device breadcrumbs followed by native signal 11; BLIT_PASS/UI_PASS breadcrumbs and nvoglv64.dll in backtrace.',
    'observation': 'Session 34622 no longer exists and no matching Godot/profile runner is alive. Windows LastBootUpTime is 2026-10-04T19:55:53.5Z; System event 41 reports an unclean restart.',
    'gpu_after_restart': 'nvidia-smi exit 0: RTX 4080 SUPER, driver 610.88, 30 degrees C, utilization 3 percent.',
    'native_receipt_limitation': 'Failed native log and process_failure.json retain their original lengths but consist entirely of NUL bytes after the unclean reboot; they are preserved as observed and cannot establish exit status.',
    'retry_scope': 'Full unchanged-runtime ten-case 60-second 1080p/four-CPU matrix with explicit 120 FPS render cap. This measures a controlled-rate workload and does not prove uncapped stability or a device/driver fix.',
    'cause': 'Unknown; no arena, shader, driver, or hardware root cause established.',
    'artifacts': records,
}
(target / 'failure.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
print('Preserved aborted uncapped matrix and original partial results in', target)
