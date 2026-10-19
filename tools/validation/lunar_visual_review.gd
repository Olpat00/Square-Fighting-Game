extends "presentation_scenarios.gd"
## Brief deterministic still review. No CPU play session or saved-settings changes.
## -- --case=arena|attacks|fighter-id --output=absolute_path --quality=Low

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	output = ProjectSettings.globalize_path("res://../evidence/lunar_upgrade")
	var quality := "High"
	var review_arena := "lunar_reach"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): filter = arg.trim_prefix("--case=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--quality="): quality = arg.trim_prefix("--quality=")
		if arg.begins_with("--arena="): review_arena = arg.trim_prefix("--arena=")
	DirAccess.make_dir_recursive_absolute(output)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_physics_process(false)
	app.set_process(false)
	initial_settings = app.settings.values.duplicate(true)
	app.settings.values.shake = 0.0
	app.settings.values.fullscreen = false
	app.settings.values.resolution = "1920x1080"
	app.settings.values.graphics = quality
	app.settings.values.flashes = 0.45
	app.apply_settings()
	world = app.world
	world.presentation_event.connect(_on_event)
	app.preview_arena(review_arena)
	await _frames(4)
	if filter.is_empty() or filter == "arena": await _arena_review()
	if filter != "arena":
		for definition: FighterDefinition in RosterRegistry.discover():
			if not filter.is_empty() and filter != "attacks" and not definition.id.contains(filter): continue
			await _attack_review(definition.id)
	_save_report()
	print("LUNAR_VISUAL_REVIEW captures=", captures.size(), " failures=", failures)
	await app.shutdown(1 if failures > 0 else 0)

func _arena_review() -> void:
	scenario = "lunar_arena"
	app.ui.show_title()
	app._update_camera(1.0)
	await _stage_still("lunar_title")
	app.ui.show_setup(false)
	var chooser: OptionButton = app.ui.screen.find_child("ArenaChoice", true, false)
	_check(chooser != null and chooser.item_count == 2, "Both arenas are selectable")
	await _stage_still("lunar_selection")
	app.ui.screen.visible = false
	await _stage_still("lunar_architecture")
	app.ui.screen.visible = true
	await _fresh("f06_rugged_explorer", "f07_urban_sentinel", 11.0)
	app.camera.size = 18.5
	app.camera.position = Vector3(0, 12.1, 32)
	app.camera.rotation_degrees = Vector3(-17, 0, 0)
	await _capture("lunar_gameplay_wide", "Actual playable arena at the initial wide framing; no simulation beyond idle fixture.")
	app._update_camera(3.0)
	await _capture("lunar_gameplay", "Ordinary gameplay camera settled on the starting pair; unchanged arena lighting and models.")
	app.rematch()
	_check(world.stage_id == "lunar_reach", "Rematch retains the selected Moon arena")
	app.leave_match()
	await _frames(2)
	app.preview_arena("rooftop_riot")
	_check(world.stage_id == "rooftop_riot", "Can return to the original rooftop")
	app.ui.show_title()
	app._update_camera(1.0)
	await _stage_still("rooftop_preserved")
	app.preview_arena("lunar_reach")
	app.ui.selected_stage_id = "lunar_reach"
	app._update_camera(1.0)

func _stage_still(file_name: String) -> void:
	world.stage.frame_horizon(app.camera)
	await _frames(4)
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(output.path_join(file_name + ".png"))
	_check(result == OK, "Stage still saved: " + file_name)

func _attack_review(id: String) -> void:
	var other: String = "f03_heavy_duty" if id != "f03_heavy_duty" else "f07_urban_sentinel"
	scenario = id + "_heavy"
	await _fresh(id, other, 1.5)
	var heavy: MoveDefinition = a.definition.get_move("heavy_side")
	_pulse(a, "heavy", Vector2.RIGHT)
	_check(_until_contact_pose(heavy, 1), "Heavy reaches its active pose")
	_advance(2)
	_detail_camera()
	await _capture(scenario, "Real directional heavy: skeletal attack trail, signature material and impact in lunar lighting.")
	scenario = id + "_special"
	await _fresh(id, other, 4.0 if id != "f05_fine_print" else 2.2)
	var move: MoveDefinition = a.definition.get_move("special_neutral")
	_pulse(a, "special")
	_check(_until_contact_pose(move), "Signature special activates")
	_advance(5)
	_detail_camera()
	await _capture(scenario, "Actual signature special and its authored dimensional effect; close QA camera only.")
	scenario = id + "_ultimate"
	await _fresh(id, other, 1.15 if id in ["f03_heavy_duty", "f06_rugged_explorer", "f08_midnight_gentleman"] else 2.0)
	a.ultimate_meter = 100
	_pulse(a, "ultimate")
	_check(_until_damage(110), "Ultimate produces a real hit")
	_advance(3)
	_detail_camera()
	await _capture(scenario, "Real ultimate opening impact, without spawning synthetic effect props.")

func _save_report() -> void:
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(), "settings": app.settings.values.duplicate(true),
		"case_filter": filter, "checks": checks, "failures": failures, "captures": captures,
		"scope": "Short scripted real-input fixtures with still screenshots; no free-play session or performance certification. Closer attack framing is labeled. User settings are not saved."}
	FileAccess.open(output.path_join("review.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
