extends SceneTree
## Genuine input-driven active-frame fixtures, with a labeled inspection camera.
## Hit regions remain authored combat data; joints are measured for review only.
var app: Node
var output: String
var records: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	output = ProjectSettings.globalize_path("res://../evidence/rebuild/contact")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_process(false)
	app.set_physics_process(false)
	app.settings.values.graphics = "High"
	app.settings.values.fullscreen = false
	app.settings.values.resolution = "1920x1080"
	app.settings.values.shake = 0.0
	app.debug_hitboxes = true
	var label := Label.new()
	label.position = Vector2(35, 25)
	label.add_theme_font_size_override("font_size", 24)
	app.ui.root.add_child(label)
	for definition: FighterDefinition in RosterRegistry.discover():
		for facing: int in [1, -1]:
			for input_action: String in ["light", "heavy"]:
				var slots: Array[Dictionary] = [{"fighter": definition.id, "device": "CPU"}, {"fighter": "f01_clutch", "device": "CPU"}]
				app.start_match(slots, "Fair Fight", false, "rooftop_riot")
				app.world.countdown = 0
				var actor: RiotFighter = app.world.fighters[0]
				var opponent: RiotFighter = app.world.fighters[1]
				actor.position = Vector3.ZERO
				actor.facing = facing
				opponent.position = Vector3(facing * 8, 0, 0)
				actor.provider = ScriptedInputProvider.new([{ "from": 30, "to": 30, "actions": [input_action]}])
				opponent.provider = ScriptedInputProvider.new()
				var active: bool = false
				for tick: int in 120:
					app.world.step()
					if actor.move != null and actor.state == "attack" and actor.move.is_active(actor.move_tick):
						active = true
						break
				if not active:
					failures += 1
					continue
				app.ui.hud.visible = false
				app.camera.position = Vector3(facing * 0.45, 4.3, 18)
				app.camera.rotation_degrees = Vector3(-10, 0, 0)
				app.camera.size = 4.8
				app._update_player_labels()
				label.text = "CONTACT QA · %s · %s · tick %d · facing %s\nInspection camera / cyan hurt region / orange authored hit region" % [definition.display_name, actor.move.id, actor.move_tick, "right" if facing > 0 else "left"]
				var joints: Dictionary = {}
				var rig: Skeleton3D = actor.visual.foot_plant.rig
				for semantic: String in ["hand.L", "hand.R", "foot.L", "foot.R"]:
					var bone: int = rig.find_bone(semantic)
					var at: Vector3 = rig.global_transform * rig.get_bone_global_pose(bone).origin
					joints[semantic] = [at.x, at.y, at.z]
				var file: String = "%s_%s_%s.png" % [definition.id, actor.move.id, "right" if facing > 0 else "left"]
				for frame: int in 3: await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join(file))
				records.append({"fighter": definition.id, "move": actor.move.id, "tick": actor.move_tick, "facing": facing, "joints": joints, "hit_center": str(actor.attack_center()), "hit_radius": actor.move.hit_radius, "capture": file})
	FileAccess.open(output.path_join("contact_review.json"), FileAccess.WRITE).store_string(JSON.stringify({"captures": records, "failures": failures, "scope": "First active frame of jab1 and uncharged heavy_side, both facings, all eight fighters. Inspection framing. Metrics do not drive collision or establish every move is aligned."}, "  "))
	print("CONTACT_REVIEW captures=", records.size(), " failures=", failures)
	await app.shutdown(1 if failures else 0)
