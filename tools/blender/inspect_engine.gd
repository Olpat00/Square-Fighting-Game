extends SceneTree
## Executed graphical GLB validation, outside shipped game content.

var roster: Array[String] = ["f01_clutch", "f02_sunstruck", "f03_heavy_duty", "f04_deadfall", "f05_fine_print"]
var models: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var report: Dictionary = {"engine": Engine.get_version_info(), "rendering_method": "", "fighters": [], "captures": []}
var output: String
var stage: Node3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/characters/engine")
	DirAccess.make_dir_recursive_absolute(output)
	report["rendering_method"] = RenderingServer.get_current_rendering_method()
	stage = Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.045, 0.065, 0.1)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.72, 0.81, 1)
	environment.environment.ambient_light_energy = 0.42
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.light_energy = 0.85
	light.shadow_enabled = true
	stage.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, 150, 0)
	fill.light_color = Color(0.42, 0.7, 1)
	fill.light_energy = 0.4
	stage.add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 0.08, 6)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.075, 0.10, 0.15)
	mat.roughness = 0.85
	floor_mesh.material_override = mat
	stage.add_child(floor_mesh)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.25
	camera.position = Vector3(0, 2.6, 9)
	stage.add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0))
	camera.current = true
	for i in range(roster.size()):
		var fid: String = roster[i]
		var scene := load("res://assets/characters/%s.glb" % fid) as PackedScene
		if scene == null:
			report["fighters"].append({"id": fid, "error": "missing import"})
			continue
		var model := scene.instantiate() as Node3D
		stage.add_child(model)
		model.position.x = float(i - 2) * 1.55
		models.append(model)
		var found := model.find_children("*", "AnimationPlayer", true, false)
		var skels := model.find_children("*", "Skeleton3D", true, false)
		var player := found[0] as AnimationPlayer if not found.is_empty() else null
		if player == null:
			report["fighters"].append({"id": fid, "error": "missing AnimationPlayer"})
			continue
		players.append(player)
		var entry: Dictionary = {"id": fid, "animation_count": player.get_animation_list().size(), "animation_names": Array(player.get_animation_list()), "invalid_bone_transforms": [], "bones": []}
		for sn in skels:
			var skel := sn as Skeleton3D
			for b in range(skel.get_bone_count()):
				entry["bones"].append(skel.get_bone_name(b))
		for name in player.get_animation_list():
			if name == "RESET":
				continue
			player.play(name)
			for phase: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
				player.seek(player.get_animation(name).length * phase, true)
				for sn in skels:
					var skel := sn as Skeleton3D
					for b in range(skel.get_bone_count()):
						if not skel.get_bone_global_pose(b).origin.is_finite():
							entry["invalid_bone_transforms"].append([name, phase, skel.get_bone_name(b)])
		player.pause()
		report["fighters"].append(entry)
		var label := Label3D.new()
		label.text = fid.trim_prefix("f01_").trim_prefix("f04_").trim_prefix("f05_")
		label.font_size = 23
		label.pixel_size = 0.006
		label.no_depth_test = true
		label.outline_size = 5
		label.position = Vector3(model.position.x, 0.02, 0.48)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stage.add_child(label)
	for action: String in ["idle", "run", "jump_rise", "jab1", "special_neutral", "special_side", "special_up", "special_down", "ultimate", "victim_grab", "victim_throw", "qa_shoulder_raise", "qa_knee_bend", "qa_deep_pose"]:
		for player in players:
			player.play(action)
			player.seek(player.get_animation(action).length * (0.5 if action.begins_with("qa_") else 0.34), true)
			player.pause()
		await _capture(action)
	for i in range(players.size()):
		players[i].play("ultimate")
		players[i].seek([66.0 / 60.0, 54.0 / 60.0, 76.0 / 60.0, 43.0 / 60.0, 67.0 / 60.0][i], true)
		players[i].pause()
	await _capture("ultimate_finisher")
	for model in models:
		model.rotation_degrees.y = 90 if model.position.x < 0 else -90
	for player in players:
		player.play("jab1")
		player.seek(0.1, true)
		player.pause()
	await _capture("facing_left_and_right")
	for model in models:
		model.rotation_degrees.y = 90
	for player in players:
		player.play("run")
		player.seek(player.get_animation("run").length * 0.2, true)
		player.pause()
	await _capture("run_side")
	if "--capture-motion" in OS.get_cmdline_user_args():
		for model in models:
			model.rotation.y = 0
		var frames_dir := output.path_join("motion_frames")
		DirAccess.make_dir_recursive_absolute(frames_dir)
		var frame_index: int = 0
		for action: String in ["idle", "run", "jab1", "special_up", "ultimate"]:
			for sample in range(24):
				for player in players:
					player.play(action)
					player.seek(player.get_animation(action).length * float(sample) / 23.0, true)
					player.pause()
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(frames_dir.path_join("frame_%03d.png" % frame_index))
				frame_index += 1
		report["motion_frame_count"] = frame_index
	var file := FileAccess.open(output.path_join("engine_validation.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("CHARACTER_ENGINE_VALIDATION_COMPLETE ", output)
	quit(0)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := output.path_join(label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	report["captures"].append({"label": label, "path": path, "error": error})
