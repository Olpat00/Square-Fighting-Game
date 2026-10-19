extends SceneTree
## Rig/runtime tests complement (never replace) continuous visual review.
var world: MatchWorld
var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name": label, "passed": ok})
	if not ok:
		failures += 1
		print("ANIMATION_FAIL ", label)

func run() -> void:
	world = MatchWorld.new()
	root.add_child(world)
	await process_frame
	var profile := FighterPresentationProfile.new()
	check(profile.blend_for("idle", "hit_heavy") < profile.blend_for("run", "idle"), "Impacts blend faster than rest")
	check(profile.transition_duration("turnaround") == 10, "Turn receives authored visual duration")
	profile.effect_sockets = {"left_hand": "grip.L", "right_hand": "grip.R", "left_foot": "toe.L", "right_foot": "toe.R"}
	check(profile.socket("hand.L") == "grip.L" and profile.socket("hand.R") == "grip.R" and profile.socket("foot.L") == "toe.L" and profile.socket("foot.R") == "toe.R", "Exported semantic effect socket overrides reach hand and foot attachments")
	profile.effect_sockets["hand.L"] = "explicit_grip.L"
	check(profile.socket("hand.L") == "explicit_grip.L" and profile.socket("chest") == "chest", "Explicit bone socket overrides take precedence and unconfigured bones retain their names")
	for definition: FighterDefinition in RosterRegistry.discover():
		world.start([{"fighter": definition.id, "device": "CPU"}, {"fighter": "f01_clutch", "device": "CPU"}], "Fair Fight")
		world.countdown = 0
		var actor: RiotFighter = world.fighters[0]
		var other: RiotFighter = world.fighters[1]
		other.provider = ScriptedInputProvider.new()
		other.position.x = 8.5
		actor.provider = ScriptedInputProvider.new([
			{"from": 0, "to": 38, "move": Vector2.RIGHT},
			{"from": 40, "to": 88, "move": Vector2.LEFT},
			{"from": 95, "to": 100, "actions": ["jump"]},
			{"from": 115, "to": 145, "move": Vector2.RIGHT},
			{"from": 124, "to": 124, "actions": ["light"]},
			{"from": 220, "to": 227, "actions": ["defend"]}
		])
		var finite_poses: bool = true
		var bounded_ik: bool = true
		var improved_contact: bool = true
		for tick: int in 250:
			world.step()
			if actor.visual.foot_plant:
				var plant: FighterFootPlant = actor.visual.foot_plant
				bounded_ik = bounded_ik and plant.last_correction <= actor.visual.presentation_profile.max_foot_correction + 0.001
				improved_contact = improved_contact and plant.contact_error_after <= plant.contact_error_before + 0.003
				for side: String in plant.legs:
					for part: String in ["upper", "lower", "foot"]:
						var transform: Transform3D = plant.rig.get_bone_global_pose(plant.legs[side][part])
						finite_poses = finite_poses and transform.origin.is_finite() and transform.basis.is_finite() and transform.origin.length() < 4.0
		check(finite_poses, definition.id + " finite leg poses through movement/turn/jump/landing")
		check(bounded_ik, definition.id + " footplant correction is bounded")
		check(improved_contact, definition.id + " IK improves measured stance target error")
		check(actor.visual.foot_plant != null, definition.id + " live skeleton footplant configured")
		actor.hitstop = 3
		actor.facing *= -1
		var yaw: float = actor.visual.model.rotation.y
		var time: float = actor.visual.animation_player.current_animation_position
		var position: Vector3 = actor.position
		for tick: int in 3: world.step()
		check(is_equal_approx(actor.visual.model.rotation.y, yaw) and is_equal_approx(actor.visual.animation_player.current_animation_position, time), definition.id + " hitstop freezes facing and animation")
		check(actor.position.is_equal_approx(position), definition.id + " visual correction cannot move combat root")
		actor.visual.play("walk", 0, true)
		actor.visual.animation_player.seek(actor.visual.animation_player.current_animation_length * 0.3, true)
		actor.visual.play("run", 0, true)
		var phase: float = actor.visual.animation_player.current_animation_position / actor.visual.animation_player.current_animation_length
		check(absf(phase - 0.3) < 0.002, definition.id + " walk/run preserve contact phase")
		check(actor.visual.presentation_profile != other.visual.presentation_profile, definition.id + " runtime profile is instance-local")
		actor.visual.play("heavy_side", actor.definition.get_move("heavy_side").total_ticks())
		actor.visual.animation_player.seek(0.15, true)
		actor.visual.play("heavy_side", actor.definition.get_move("heavy_side").total_ticks())
		check(is_zero_approx(actor.visual.animation_player.current_animation_position), definition.id + " repeated move/charge release restarts visual clock")
		await process_frame
	var output: String = ProjectSettings.globalize_path("res://../evidence/rebuild")
	DirAccess.make_dir_recursive_absolute(output)
	FileAccess.open(output.path_join("animation_scenarios.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures}, "  "))
	print("REBUILD_ANIMATION checks=", checks.size(), " failures=", failures)
	# Let queued fighter/skeleton/body disposal settle before freeing their
	# world and shutting down the engine, even in an uncapped headless run.
	print("DIAGNOSTIC before clear"); world.clear(); print("DIAGNOSTIC after clear")
	await process_frame
	await physics_frame
	print("DIAGNOSTIC before world free"); world.queue_free(); print("DIAGNOSTIC after world free queued")
	await process_frame
	await process_frame
	await process_frame
	print("DIAGNOSTIC request quit"); quit(1 if failures else 0)

