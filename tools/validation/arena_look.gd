extends SceneTree
## Quick visual review of the real title and ordinary two/four-player cameras.
## Does not save settings or change authoritative stage geometry.

var app: Node
var output: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	output = ProjectSettings.globalize_path("res://../evidence/visual_overhaul/arena")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.settings.values.graphics = "High"
	app.settings.values.resolution = "1920x1080"
	app.settings.values.fullscreen = false
	app.settings.values.ui_scale = 1.0
	app.settings.values.shake = 0.0
	app.apply_settings()
	await create_timer(0.5).timeout
	await app.capture(output.path_join("title.png"))
	var slots: Array[Dictionary] = [{"fighter": "f02_sunstruck", "device": "Keyboard", "device_id": -1}, {"fighter": "f03_heavy_duty", "device": "CPU", "difficulty": "Normal"}]
	app.start_match(slots, "Fair Fight", false)
	app.world.countdown = 0
	app.world.paused = true
	await create_timer(2).timeout
	await app.capture(output.path_join("match_1v1.png"))
	slots = [{"fighter": "f01_clutch", "device": "CPU", "difficulty": "Normal"}, {"fighter": "f02_sunstruck", "device": "CPU", "difficulty": "Normal"}, {"fighter": "f03_heavy_duty", "device": "CPU", "difficulty": "Normal"}, {"fighter": "f04_deadfall", "device": "CPU", "difficulty": "Normal"}]
	app.start_match(slots, "Party", false)
	app.world.countdown = 0
	await create_timer(7).timeout
	await app.capture(output.path_join("match_4players.png"))
	print("ARENA_LOOK_COMPLETE ", output)
	await app.shutdown()
