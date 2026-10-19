extends SceneTree
## Full match simulation through the actual main scene and match-finished UI.
## Accelerated ticks prove lifecycle integration, not real-time performance.

var app: Node
var checks: Array[Dictionary] = []
var matches: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks.append({"name": label, "passed": condition})
	if not condition:
		failures += 1
		print("MATCH_FLOW_FAIL ", label)

func frames(count: int) -> void:
	for index in count: await process_frame

func _run() -> void:
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await frames(5)
	app.set_physics_process(false)
	var original_settings: Dictionary = app.settings.values.duplicate(true)
	app.settings.values.graphics = "High"
	app.settings.values.ui_scale = 1.0
	app.apply_settings() # Select the High model tier before fighter construction.
	var groups: Array = [
		["f01_clutch", "f02_sunstruck", "f03_heavy_duty", "f04_deadfall"],
		["f05_fine_print", "f06_rugged_explorer", "f07_urban_sentinel", "f08_midnight_gentleman"]]
	for arena_index: int in StageCatalog.IDS.size():
		var arena: String = StageCatalog.IDS[arena_index]
		var slots: Array[Dictionary] = []
		for id: String in groups[arena_index % groups.size()]:
			slots.append({"fighter": id, "device": "CPU", "difficulty": "Hard"})
		var preset: String = "Party" if arena_index % 2 == 0 else "Fair Fight"
		app.start_match(slots, preset, false, arena)
		check(app.world.stage_id == arena and app.ui.screen_name == "match" and app.world.fighters.size() == 4, arena + " starts four selected fighters through main")
		for index in 180: app.world.step()
		check(app.world.countdown == 0 and app.world.tick == 0, arena + " completes the full ready countdown before combat")
		var contacts_before: int = app.world.resolver.contacts_resolved
		var match_ticks: int = 0
		for index in 25000:
			app.world.step()
			app.effects.update(CombatTuning.DT)
			match_ticks += 1
			if index % 120 == 0: await process_frame
			if not app.world.running: break
		await frames(8)
		var result: Dictionary = app.world.result.duplicate(true)
		check(not app.world.running and result.has("winner") and not str(result.get("reason", "")).is_empty(), arena + " finishes through stock or clock rules without forced result")
		check(app.world.resolver.contacts_resolved > contacts_before and app.world.ko_log.size() > 0, arena + " full match contains real contacts and ring-outs")
		check(app.ui.screen_name == "results" and not app.ui.hud.visible, arena + " finish signal displays results and hides match HUD")
		await app.capture("match_flow/%s_results.png" % arena)
		matches.append({"arena": arena, "preset": preset, "ticks": match_ticks, "contacts": app.world.resolver.contacts_resolved - contacts_before, "kos": app.world.ko_log.size(), "result": result})
		app.rematch()
		await frames(4)
		var clean: bool = app.world.running and app.world.stage_id == arena and app.world.stage.preset == preset and app.world.config == slots and app.world.countdown == 180
		for fighter: RiotFighter in app.world.fighters:
			clean = clean and fighter.stocks == 3 and fighter.damage == 0 and fighter.ultimate_meter == 0
		check(clean and app.world.abilities.objects.is_empty() and app.world.abilities.sequences.is_empty(), arena + " rematch preserves selections and rules with clean resources")
		await app.capture("match_flow/%s_rematch.png" % arena)
		app.leave_match()
		await frames(3)
		check(not app.world.running and app.world.fighters.is_empty() and app.world.abilities.objects.is_empty(), arena + " leaving rematch clears combat ownership")
	app.settings.values = original_settings
	app.apply_settings()
	var report := {"checks": checks.size(), "failures": failures, "results": checks, "matches": matches, "graphical": DisplayServer.get_name() != "headless", "limitation": "Accelerated full-match lifecycle coverage; not a real-time performance measurement or human playtest."}
	FileAccess.open(app.evidence_root.path_join("match_flow.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("REBUILD_MATCH_FLOW checks=", checks.size(), " failures=", failures)
	await app.shutdown(1 if failures else 0)
