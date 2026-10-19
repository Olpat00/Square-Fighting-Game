"""Run the fresh scenery harness and full matches sequentially, with bounds."""
from pathlib import Path
import importlib.util
import json
from datetime import datetime, timezone

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
spec = importlib.util.spec_from_file_location('ambient_runner', HERE / 'record_movies.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
before, source = runner.current_inventory()
old = HERE / 'review_motion'
archive = HERE / 'review_motion_before_movie_api'
assert old.resolve().is_relative_to(HERE.resolve()) and archive.resolve().is_relative_to(HERE.resolve())
if old.is_dir():
    assert not archive.exists()
    old.rename(archive)
else:
    assert archive.is_dir(), 'Neither current nor archived scenery fixture exists'
logs = HERE / 'motion/scene_checks'
logs.mkdir(parents=True, exist_ok=True)
cases = []
for label, harness, extra, report in (
    ('motion final', 'living_background_review.gd', ['--output=' + str(HERE / 'review_motion')], HERE / 'review_motion/living_background_review.json'),
    ('full matches', 'rebuild_match_flow.gd', ['--evidence-root=' + str(ROOT / 'evidence/rebuild')], ROOT / 'evidence/rebuild/match_flow.json'),
):
    started = datetime.now(timezone.utc).timestamp()
    log = logs / (harness.removesuffix('.gd') + '_final_native.log')
    engine = logs / (harness.removesuffix('.gd') + '_final_engine.log')
    case = runner.run_owned([runner.GODOT, '--path', runner.PROJECT, '--script', ROOT / 'tools/validation' / harness,
                             '--log-file', engine, '--', *extra], log, label, 180)
    for file in (log, engine):
        assert file.is_file() and not runner.PROBLEM.search(file.read_text(encoding='utf-8', errors='replace')), file
    assert report.stat().st_mtime >= started
    value = runner.read_json(report)
    if label == 'motion final':
        assert value['passed'] and value['failures'] == 0 and value['checks'] == 378 and len(value['captures']) == 70
        assert value['harness_sha256'].upper() == runner.sha256(ROOT / 'tools/validation' / harness)
    else:
        assert value['failures'] == 0 and value['checks'] == 35 and value['graphical'] and len(value['matches']) == 5
        assert all(m['contacts'] > 0 and m['kos'] > 0 and 'winner' in m['result'] for m in value['matches'])
    cases.append({'case': label, 'process': case, 'engine': runner.record(engine), 'report': runner.record(report)})
    print(label + ': passed', flush=True)
after, _ = runner.current_inventory()
assert after == before
(HERE / 'scene_checks.json').write_text(json.dumps({'passed': True, 'finished_utc': datetime.now(timezone.utc).isoformat(),
    'runtime': after, 'source_gate': source, 'unchanged_during_checks': True, 'cases': cases}, indent=2) + '\n', encoding='utf-8')
