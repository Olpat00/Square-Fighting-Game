extends SceneTree
## Actual 1080p arena/identity fixtures. Writes no user settings. Capture work is
## deliberately separate from tools/validation/rebuild_performance.gd timings.

var app: Node3D
var output: String
var captures: Array[Dictionary] = []
var arenas: Array[String] = StageCatalog.IDS.duplicate()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	output = ProjectSettings.globalize_path("res://../evidence/rebuild/stages")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		if argument.begins_with("--arenas="): arenas.assign(argument.trim_prefix("--arenas=").split(","))
	DirAccess.make_dir_recursive_absolute(output)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_process(false)
	app.set_physics_process(false)
	app.settings.values.resolution = "1920x1080"
	app.settings.values.fullscreen = false
	app.settings.values.ui_scale = 1.0
	app.settings.values.shake = 0.0
	var slots: Array[Dictionary] = [
		{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f03_heavy_duty", "device": "CPU"},
		{"fighter": "f06_rugged_explorer", "device": "CPU"}, {"fighter": "f08_midnight_gentleman", "device": "CPU"}]
	for arena: String in arenas:
		for quality: String in ["High", "Low"]:
			app.settings.values.graphics = quality
			app.start_match(slots, "Fair Fight", false, arena)
			app.world.countdown = 0
			for fighter: RiotFighter in app.world.fighters: fighter.provider = ScriptedInputProvider.new()
			for tick: int in 30: app.world.step()
			for i: int in 4: app.world.fighters[i].position = Vector3(-5.4 + i * 3.6, 0, 0)
			app.match_camera.reset()
			await _capture(arena + "_" + quality.to_lower(), "Four-player neutral exchange, current shared camera and live HUD")
			if quality == "High":
				for i: int in 4: app.world.fighters[i].position = Vector3(i * 0.05, 3.6, 0)
				app.match_camera.reset()
				await _capture(arena + "_overlap", "Four simultaneous nearby identities; labels separate deterministically")
				app.world.fighters[0].position = Vector3(-15, -7, 0)
				app.world.fighters[1].position = Vector3(14, 10, 0)
				await _capture(arena + "_recovery", "Low recovery and high launch share the camera without HUD clipping")
				var deck_edges: Vector2 = app.world.stage.main_bounds()
				app.world.fighters[0].position = Vector3(deck_edges.x - 1, -4.5, 0)
				app.world.fighters[1].position = Vector3(deck_edges.y + 1, -4.5, 0)
				app.match_camera.reset()
				await _capture(arena + "_near_ledge", "Both low recoveries remain readable adjacent to the stage side walls")
	var file := FileAccess.open(output.path_join("stage_review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": captures, "limitations": "Deterministic presentation fixtures, not frame-time measurements or human playtesting."}, "  "))
	print("REBUILD_STAGE_REVIEW ", captures.size(), " captures")
	await app.shutdown()

func _capture(name_value: String, purpose: String) -> void:
	app._update_camera(1.0 / 60.0)
	app._update_player_labels()
	app.ui.update_hud()
	for frame: int in 8: await process_frame
	await RenderingServer.frame_post_draw
	var path: String = output.path_join(name_value + ".png")
	var result: Error = root.get_texture().get_image().save_png(path)
	captures.append({"file": path, "purpose": purpose, "saved": result == OK, "camera_height": app.camera.size, "arena": app.world.stage_id, "quality": app.world.graphics_quality})
	print("STAGE_CAPTURE ", name_value, " result=", result)
