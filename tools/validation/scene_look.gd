extends SceneTree
## Brief art-only preview: frozen fighters in the real scene, no match playthrough.
## Gameplay-angle and hazard stills precede an explicitly labeled architectural
## detail. No user settings are saved.

var app: Node
var output: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	output = ProjectSettings.globalize_path("res://../evidence/visual_overhaul/scene_revision3")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	AudioServer.set_bus_mute(0, true)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_process(false)
	app.set_physics_process(false)
	app.settings.values.graphics = "High"
	app.settings.values.resolution = "1920x1080"
	app.settings.values.fullscreen = false
	app.apply_settings()
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f03_heavy_duty", "device": "CPU"}]
	app.start_match(slots, "Fair Fight", false)
	app.world.paused = true
	app.ui.root.hide()
	for i: int in app.world.fighters.size():
		var fighter: Node = app.world.fighters[i]
		fighter.interrupt()
		fighter.position = Vector3(-2.0 if i == 0 else 2.0, 0.0, 0.0)
		fighter.facing = 1 if i == 0 else -1
		fighter.change_state("idle")
		fighter.visual.model.rotation.y = fighter.facing * PI * 0.5
		fighter.visual.play("idle", 60, true)
		fighter.visual.animation_player.advance(0.4)
	app.camera.size = 11.7
	app.world.stage.frame_horizon(app.camera)
	await create_timer(1.2).timeout
	await app.capture(output.path_join("gameplay_angle.png"))
	app.world.stage.preset = "Party"
	app.world.stage.tick = 530
	app.world.stage.step()
	await create_timer(0.3).timeout
	await app.capture(output.path_join("pyro_detail.png"))
	app.world.stage.preset = "Fair Fight"
	app.world.stage.step()
	app.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	app.camera.position = Vector3(12.7, 6.8, 9.5)
	app.camera.look_at(Vector3(0.5, 0.2, -5.0))
	app.camera.fov = 61
	app.world.stage.frame_horizon(app.camera)
	await create_timer(0.8).timeout
	await app.capture(output.path_join("architecture_detail.png"))
	print("SCENE_LOOK_COMPLETE three graphics-only stills; no match simulated: ", output)
	await app.shutdown()
