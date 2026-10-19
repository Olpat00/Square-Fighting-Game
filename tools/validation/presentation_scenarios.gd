extends SceneTree
## Real main-scene visual acceptance fixtures. No generated poses, substituted models,
## manually applied hits, synthetic effects, or alternate lighting are used.
## Run graphically with --path "Game File" --script ../tools/validation/presentation_scenarios.gd
## Optional user args: -- --case=substring --output=absolute_directory

const CONFIRMED: Array[String] = ["f01_clutch", "f02_sunstruck", "f03_heavy_duty", "f04_deadfall", "f05_fine_print"]
const SEED: int = 4261
var app: Node
var world: MatchWorld
var a: RiotFighter
var b: RiotFighter
var output: String
var filter: String = ""
var scenario: String = ""
var events: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var checks: Array[Dictionary] = []
var failures: int = 0
var input_trace: Array[Dictionary] = []
var camera_mode: String = "gameplay"
var initial_settings: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Presentation scenarios require a real graphical renderer; no visual pass recorded.")
		quit(2)
		return
	output = ProjectSettings.globalize_path("res://../evidence/presentation")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): filter = arg.trim_prefix("--case=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	# Own the real game's clock so a still is captured at the recorded combat tick.
	# Rendering continues; main's ordinary callbacks would otherwise advance twice.
	app.set_physics_process(false)
	app.set_process(false)
	initial_settings = app.settings.values.duplicate(true)
	app.settings.values.shake = 0.0
	app.settings.values.fullscreen = false
	app.settings.values.resolution = "1920x1080"
	app.settings.values.graphics = "High"
	app.apply_settings() # In-memory only. The user's settings file is never saved.
	world = app.world
	world.presentation_event.connect(_on_event)
	await _frames(5)
	for id: String in CONFIRMED:
		_check(ResourceLoader.exists(RosterRegistry.by_id(id).model_path), "Confirmed model exists: " + id)
	if _include("match_1v1_action"): await _action_case()
	if _include("high_damage_launch"): await _launch_case()
	for id: String in CONFIRMED:
		if _include(id + "_normal_light"): await _normal_light_case(id)
		for move_id: String in ["special_neutral", "special_side", "special_up", "special_down"]:
			if _include(id + "_" + move_id): await _special_case(id, move_id)
		if _include(id + "_ultimate"): await _ultimate_case(id)
	if _include("f03_heavy_duty_special_down_air"): await _air_drop_case()
	if _include("f03_heavy_duty_taunt1_chair"): await _chair_taunt_case()
	if _include("vfx_material_review"): await _vfx_material_cases()
	if _include("vfx_debris_dust"): await _vfx_debris_dust_case()
	_save_report()
	print("PRESENTATION_SCENARIOS captures=", captures.size(), " trigger_failures=", failures, " output=", output)
	await app.shutdown(1 if failures > 0 else 0)

func _include(name_value: String) -> bool:
	return filter.is_empty() or name_value.contains(filter)

func _frames(count: int) -> void:
	for i: int in count: await process_frame

func _check(condition: bool, name_value: String, detail: String = "") -> void:
	checks.append({"scenario": scenario, "name": name_value, "passed": condition, "detail": detail, "tick": world.tick if world != null else -1})
	if not condition:
		failures += 1
		print("PRESENTATION_TRIGGER_FAIL ", scenario, " / ", name_value, " ", detail)

func _fresh(id: String, other: String = "f04_deadfall", distance: float = 2.0, mode: String = "Fair Fight") -> void:
	var slots: Array[Dictionary] = [{"fighter": id, "device": "CPU", "difficulty": "Normal"}, {"fighter": other, "device": "CPU", "difficulty": "Normal"}]
	app.start_match(slots, mode, false)
	world.countdown = 0
	a = world.fighters[0]
	b = world.fighters[1]
	_fixture(a, Vector3(-distance * 0.5, 0, 0), 1)
	_fixture(b, Vector3(distance * 0.5, 0, 0), -1)
	app.effects.rng.seed = 8742
	events.clear()
	input_trace.clear()
	camera_mode = "gameplay"
	app.camera.size = 11.7
	app.camera.position = Vector3(0, 12.1, 32)
	app.camera.rotation_degrees = Vector3(-17.0, 0, 0)
	app.camera.h_offset = 0
	app.camera.v_offset = 0
	# Intro gets interrupted through ordinary state/animation presentation.
	_advance(8)
	await _frames(2)

func _fixture(fighter: RiotFighter, p: Vector3, facing: int) -> void:
	fighter.interrupt()
	fighter.position = p
	fighter.velocity = Vector3.ZERO
	fighter.grounded = is_zero_approx(p.y)
	fighter.support_id = 0 if fighter.grounded else -1
	fighter.stun = 0
	fighter.hitstop = 0
	fighter.invulnerability = 0
	fighter.damage = 0
	fighter.facing = facing
	fighter.helpless = false
	fighter.recovery_used = false
	fighter.change_state("idle" if fighter.grounded else "air")
	fighter.provider = ScriptedInputProvider.new()
	fighter.snapshot = InputSnapshot.new()

func _pulse(fighter: RiotFighter, action: String, direction: Vector2 = Vector2.ZERO, held: int = 1) -> void:
	fighter.provider = ScriptedInputProvider.new([{"from": 0, "to": held - 1, "move": direction, "actions": [action]}])
	input_trace.append({"tick": world.tick, "slot": fighter.slot, "action": action, "direction": [direction.x, direction.y], "held_ticks": held})

func _advance(count: int) -> void:
	for i: int in count:
		world.step()
		app.effects.update(CombatTuning.DT)
		app.ui.update_hud()
		app._update_camera(CombatTuning.DT)

func _until_damage(max_ticks: int = 100, prior: float = 0.0) -> bool:
	for i: int in max_ticks:
		_advance(1)
		if b.damage > prior: return true
	return false

func _until_contact_pose(move: MoveDefinition, offset: int = 0, max_ticks: int = 130) -> bool:
	for i: int in max_ticks:
		_advance(1)
		if a.move != null and a.move.id == move.id and a.move_tick >= move.startup + offset:
			return true
		if a.state == "ability_sequence" and b.damage > 0:
			return true
	return false

func _on_event(event: String, actor: int, at: Vector3, details: Dictionary) -> void:
	events.append({"event": event, "actor": actor, "tick": world.tick, "at": _v3(at), "details": details.duplicate(true)})

func _owned(type: String) -> Dictionary:
	for item: Dictionary in world.abilities.objects:
		if item.owner == a and item.type == type and not item.expired: return item
	return {}

func _detail_camera(single: bool = false) -> void:
	# The same Camera3D keeps its ordinary fixed viewing angle. Only framing changes.
	# Arena lights/materials, HUD, player transforms and simulation stay untouched.
	var low: Vector3 = a.position
	var high: Vector3 = a.position + Vector3(0, 2.5, 0)
	if not single:
		low.x = minf(low.x, b.position.x)
		low.y = minf(low.y, b.position.y)
		high.x = maxf(high.x, b.position.x)
		high.y = maxf(high.y, b.position.y + 2.5)
		for item: Dictionary in world.abilities.objects:
			if item.expired or not item.visual.visible: continue
			var p: Vector2 = item.position
			low.x = minf(low.x, p.x - 0.8)
			low.y = minf(low.y, p.y - 0.6)
			high.x = maxf(high.x, p.x + 0.8)
			high.y = maxf(high.y, p.y + 0.8)
	var center: Vector3 = (low + high) * 0.5
	var extent: Vector3 = high - low
	app.camera.size = clampf(maxf(extent.y + 3.0, (extent.x + 3.0) * 0.5625), 5.6, 13.5)
	app.camera.position = Vector3(center.x, center.y + 9.8, 32)
	app.camera.rotation_degrees = Vector3(-17.0, 0, 0)
	app.camera.h_offset = 0
	app.camera.v_offset = 0
	camera_mode = "same main camera, closer QA framing; unchanged angle and arena lighting"

func _capture(name_value: String, purpose: String) -> void:
	app.world.stage.frame_horizon(app.camera)
	app.ui.update_hud()
	await _frames(2)
	await RenderingServer.frame_post_draw
	var path: String = output.path_join(name_value + ".png")
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(path)
	_check(error == OK, "Screenshot written: " + name_value, error_string(error))
	var row: Dictionary = {"name": name_value, "scenario": scenario, "file": path, "purpose": purpose,
		"preset": world.stage.preset, "presentation_settings": {"blood": app.settings.values.blood, "flashes": app.settings.values.flashes},
		"captured": error == OK, "dimensions": [image.get_width(), image.get_height()], "world_tick": world.tick,
		"camera_mode": camera_mode, "camera_size": app.camera.size, "camera_position": _v3(app.camera.position),
		"fighters": [_fighter_record(a), _fighter_record(b)], "ability_objects": _object_records(),
		"sequences": _sequence_records(), "impact_particle_count": app.effects.particles.size(),
		"events": events.duplicate(true), "scripted_inputs": input_trace.duplicate(true),
		"visual_review": "Not automatically graded. Inspect the saved running-game frame."}
	captures.append(row)
	_save_report() # Retains completed captures if a later fixture fails.
	print("PRESENTATION_CAPTURE ", name_value, " tick=", world.tick, " clip=", a.visual.current_clip, " move_tick=", a.move_tick)

func _fighter_record(fighter: RiotFighter) -> Dictionary:
	var player: AnimationPlayer = fighter.visual.animation_player
	return {"id": fighter.definition.id, "slot": fighter.slot, "position": _v3(fighter.position), "velocity": _v3(fighter.velocity),
		"state": fighter.state, "move": fighter.move.id if fighter.move != null else "", "move_tick": fighter.move_tick,
		"damage": fighter.damage, "stocks": fighter.stocks, "ultimate_meter": fighter.ultimate_meter, "hitstop": fighter.hitstop,
		"clip": fighter.visual.current_clip, "clip_seconds": player.current_animation_position if player != null else -1,
		"model_loaded": fighter.visual.model != null, "grounded": fighter.grounded, "captured": fighter.captured_by != null}

func _object_records() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for item: Dictionary in world.abilities.objects:
		var active: bool = not item.expired
		if item.type in ["tree", "geometry", "spotlight"]: active = active and item.move.is_active(int(item.age))
		if item.type == "trap": active = active and item.age >= int(item.data.get("arming_ticks", 30)) and int(item.support) >= 0
		rows.append({"type": item.type, "owner": item.owner.slot, "age": item.age, "life": item.life,
			"position": [item.position.x, item.position.y], "visible": item.visual.visible, "active": active,
			"cosmetic": item.options.get("cosmetic", false), "expired": item.expired})
	return rows

func _sequence_records() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for sequence: Dictionary in world.abilities.sequences:
		rows.append({"move": sequence.move.id, "age": sequence.age, "duration": sequence.duration, "capture": sequence.capture, "cancelled": sequence.cancelled})
	return rows

func _v3(v: Vector3) -> Array[float]:
	return [v.x, v.y, v.z]

func _action_case() -> void:
	scenario = "match_1v1_action"
	await _fresh("f01_clutch", "f04_deadfall", 0.85)
	_pulse(a, "light")
	_check(_until_damage(50), "Jab produces a real resolved hit")
	await _capture(scenario, "Ordinary gameplay camera: hit pose, impact, HUD and stage together.")
	_detail_camera()
	await _capture(scenario + "_detail", "Same combat tick viewed closer for shoulder, hand and target contact inspection.")

func _launch_case() -> void:
	scenario = "high_damage_launch"
	await _fresh("f01_clutch", "f04_deadfall", 1.05)
	b.damage = 160.0
	_pulse(a, "heavy")
	_check(_until_damage(110, 160.0), "Heavy hits the 160 percent fixture")
	var launched: bool = false
	for i: int in 35:
		_advance(1)
		if b.position.y > 0.8 and b.hitstop == 0:
			launched = true
			break
	_check(launched, "Victim actually leaves ground after hitstop", str(b.position))
	await _capture(scenario, "Actual gameplay camera during a high-damage launched tumble, after hitstop.")
	_detail_camera()
	await _capture(scenario + "_detail", "Closer view of the same real launch pose and damage HUD.")

func _normal_light_case(id: String) -> void:
	scenario = id + "_normal_light"
	await _fresh(id, "f01_clutch" if id != "f01_clutch" else "f04_deadfall", 6.5)
	_advance(12)
	_detail_camera(true)
	await _capture(scenario, "Recognizable supplied model in ordinary arena lighting and real idle pose; opponent remains in the match outside this close framing.")

func _vfx_material_cases() -> void:
	var old_blood: bool = app.settings.values.blood
	var old_flashes: float = app.settings.values.flashes
	var signature_particle_count: int = -1
	for flags: Vector2i in [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, 0)]:
		scenario = "vfx_material_review_blood%d_flashes%d" % [flags.x, flags.y]
		app.settings.values.blood = flags.x == 1
		app.settings.values.flashes = float(flags.y)
		await _fresh("f01_clutch", "f04_deadfall", 1.05)
		_pulse(a, "heavy")
		_check(_until_damage(110), "Actual heavy impact resolves with this settings pair")
		var drops: int = 0
		for particle: Dictionary in app.effects.particles:
			if particle.shape == "drop": drops += 1
		var non_blood_particles: int = app.effects.particles.size() - drops
		if signature_particle_count < 0: signature_particle_count = non_blood_particles
		_check(drops == (4 if flags.x == 1 else 0) and non_blood_particles == signature_particle_count, "Blood switch changes only four drops; signature impact count remains stable")
		await _capture(scenario + "_impact", "Real heavy impact through the gameplay camera; blood/flash pair recorded in filename.")
		_advance(4)
		_detail_camera()
		await _capture(scenario + "_spread", "Four real ticks after impact, closer QA view of the pooled streak, ring, smoke and optional drops.")
	app.settings.values.blood = old_blood
	app.settings.values.flashes = old_flashes
	scenario = "vfx_material_review_shield"
	await _fresh("f03_heavy_duty", "f05_fine_print", 2.8)
	_pulse(a, "defend", Vector2.ZERO, 40)
	_pulse(b, "defend", Vector2.ZERO, 40)
	_advance(12)
	_check(a.state == "shield" and b.state == "shield" and a.visual.shield_mesh.visible and b.visual.shield_mesh.visible, "Both opposing facings enter shield through real held input")
	await _capture(scenario, "Opposite-facing fighters and their actual shields through the gameplay camera.")
	_detail_camera()
	await _capture(scenario + "_detail", "Closer same-angle shield inspection: edge contour, uncovered face and ground arcs.")

func _vfx_debris_dust_case() -> void:
	scenario = "vfx_debris_dust"
	await _fresh("f01_clutch", "f04_deadfall", 1.05, "Party")
	var chair: Node3D = world.stage.breakable_furniture[0]
	a.position.x = chair.position.x - 1.05
	b.position.x = chair.position.x
	_pulse(a, "heavy")
	_check(_until_damage(110), "Real heavy resolves near a breakable decorative chair")
	_check(not chair.visible and world.stage.broken_furniture.size() == 1, "Actual resolved heavy impact breaks the nearby chair")
	_advance(6)
	_detail_camera()
	await _capture(scenario + "_chair", "Six real ticks after a chair-breaking heavy; geometric wood fragments share the bounded impact pool.")
	await _fresh("f04_deadfall", "f01_clutch", 3.0)
	_pulse(a, "jump")
	_advance(7)
	_check(not a.grounded and a.position.y > 0.1, "Actual jump input lifts fighter above its takeoff dust")
	_detail_camera()
	await _capture(scenario + "_jump", "Real jump after seven ticks; soft takeoff dust remains separate from the moving fighter.")

func _special_case(id: String, move_id: String) -> void:
	scenario = id + "_" + move_id
	var direction: Vector2 = Vector2.ZERO
	var distance: float = 2.1 if id == "f05_fine_print" else 3.4
	if move_id == "special_side":
		direction = Vector2.RIGHT
		distance = 1.25 if id == "f05_fine_print" else 2.6
	elif move_id == "special_up":
		direction = Vector2(0, 1)
		distance = 6.0
	elif move_id == "special_down":
		direction = Vector2(0, -1)
		distance = 0.85 if id in ["f01_clutch", "f05_fine_print"] else 1.1 if id == "f03_heavy_duty" else 5.0
	await _fresh(id, "f01_clutch" if id != "f01_clutch" else "f04_deadfall", distance)
	var move: MoveDefinition = a.definition.get_move(move_id)
	_pulse(a, "special", direction)
	if move_id == "special_down" and id in ["f01_clutch", "f05_fine_print"]:
		_pulse(b, "light")
		_check(_until_damage(30), "A real incoming jab triggers the counter response")
		_check(a.damage == 0 and a.visual.current_clip.ends_with("counter_success"), "Counter blocks incoming damage and presents its response")
	else:
		_check(_until_contact_pose(move), "Requested special reaches its contact pose", move_id)
		if id == "f01_clutch" and move_id == "special_side" and b.damage <= 0:
			_check(_until_damage(45), "Shoulder rush closes to visible body contact before damage")
		if id == "f03_heavy_duty" and move_id == "special_side":
			for i: int in 20:
				if b.captured_by == a: break
				_advance(1)
	_detail_camera()
	await _capture(scenario, "Actual scripted directional special at contact/response, with any real spawned effect or prop.")
	if id == "f05_fine_print" and move_id == "special_neutral":
		_check(b.damage > 0 and a.hitstop > 0 and not _owned("precision_line").is_empty(), "Outer-range palm connects with visible trace and impact pause")
		_advance(1)
		_check(a.hitstop > 0 and not _owned("precision_line").is_empty(), "Palm trace persists through actual hitstop")
		await _capture(scenario + "_hitstop", "One real combat tick after the outer-range hit; attached trace and earned per-owner Citations ticket persist during impact pause.")
	if move_id == "special_down" and id in ["f01_clutch", "f05_fine_print"]:
		_advance(14)
		_detail_camera()
		await _capture(scenario + "_response", "Counter follow-through after real hitstop, without seeking the animation or moving the victim by hand.")
	if id == "f03_heavy_duty" and move_id == "special_side":
		_check(b.captured_by == a, "Heavy side establishes a real command grab")
		_advance(10)
		_detail_camera()
		await _capture(scenario + "_lift", "Heavy's authored lift with the victim following the real capture trajectory.")
		var released: bool = false
		for i: int in 100:
			_advance(1)
			if b.captured_by == null and world.abilities.sequences.is_empty():
				released = true
				break
		_check(released and b.damage > 0, "Heavy side slam damages and releases its target")
		_detail_camera()
		await _capture(scenario + "_slam", "Command-grab slam contact after the lift; source remains committed to recovery.")
	if id == "f04_deadfall" and move_id == "special_down":
		var armed: bool = false
		for i: int in 50:
			var trap: Dictionary = _owned("trap")
			if not trap.is_empty() and trap.age >= int(trap.data.get("arming_ticks", 30)):
				armed = true
				break
			_advance(1)
		_check(armed, "Deployable trap reaches its armed visual state")
		_detail_camera()
		await _capture(scenario + "_armed", "Real trap after its announced arming delay, not a manually spawned prop.")

func _ultimate_case(id: String) -> void:
	scenario = id + "_ultimate"
	var distance: float = {"f01_clutch": 2.0, "f02_sunstruck": 3.0, "f03_heavy_duty": 1.1, "f04_deadfall": 3.3, "f05_fine_print": 1.95}[id]
	await _fresh(id, "f01_clutch" if id != "f01_clutch" else "f04_deadfall", distance)
	a.ultimate_meter = 100.0
	var move: MoveDefinition = a.definition.get_move("ultimate")
	_pulse(a, "ultimate")
	_advance(maxi(1, move.startup - 4))
	_check(a.ultimate_meter == 0 and a.move != null and a.move.id == "ultimate", "Real ultimate request spends the meter and begins startup")
	_detail_camera()
	await _capture(scenario + "_warning", "Committed anticipation and any warning zone before the first ultimate hit.")
	var opened: bool = false
	for i: int in 60:
		_advance(1)
		if b.damage > 0 or b.captured_by == a:
			opened = true
			break
	_check(opened, "Ultimate produces its real opening hit or command grab")
	_detail_camera()
	await _capture(scenario + "_opener", "First resolved ultimate hit, real impact effect, and any active capture/zone.")
	if id == "f02_sunstruck":
		for index: int in range(1, 3):
			_check(_until_contact_pose(move, int(move.active_windows[index].x) - move.startup), "Solar zone reaches pulse %d" % (index + 1))
			var zone: Dictionary = _owned("spotlight")
			_check(not zone.is_empty() and move.is_active(int(zone.get("age", -1))), "Solar pulse has an active real zone")
			_detail_camera()
			await _capture(scenario + "_pulse_%d" % (index + 1), "Real bounded solar pulse %d; launched targets may escape subsequent impacts." % (index + 1))
	elif id != "f04_deadfall":
		if id == "f03_heavy_duty":
			_advance(13)
			_detail_camera()
			await _capture(scenario + "_lift", "Heavy ultimate's real captured-victim lift and temporary folding chair.")
		var released: bool = false
		for i: int in 160:
			_advance(1)
			if b.captured_by == null and world.abilities.sequences.is_empty():
				released = true
				break
		_check(released and b.damage > move.damage, "Ultimate followups finish and release the target")
		_detail_camera()
		await _capture(scenario + "_finisher", "Actual final combo contact and released victim, with authoritative accumulated damage.")

func _chair_taunt_case() -> void:
	scenario = "f03_heavy_duty_taunt1_chair"
	await _fresh("f03_heavy_duty", "f01_clutch", 5.0)
	_pulse(a, "taunt")
	_advance(34)
	_check(a.state == "taunt" and a.visual.current_clip.ends_with("taunt1"), "Heavy performs first taunt through real input")
	_check(not _owned("chair").is_empty(), "Seated taunt has its real temporary chair")
	_detail_camera()
	await _capture(scenario, "Authored opening gesture and seated phase over a real temporary chair, in ordinary arena lighting.")
	_advance(30)
	_check(_owned("chair").is_empty(), "Temporary taunt chair clears after standing")

func _air_drop_case() -> void:
	scenario = "f03_heavy_duty_special_down_air"
	await _fresh("f03_heavy_duty", "f01_clutch", 1.1)
	# Clear both upper platforms and allow the real down-input fast fall to
	# complete startup before the committed elbow descent reaches the deck.
	_fixture(a, Vector3(2.2, 6.5, 0), 1)
	_fixture(b, Vector3(3.1, 0, 0), -1)
	var move: MoveDefinition = a.definition.get_move("special_down")
	_pulse(a, "special", Vector2(0, -1))
	_check(_until_contact_pose(move), "Airborne down special activates before landing")
	_check(a.velocity.y < -10.0 and not a.grounded, "Committed elbow drop has real downward velocity")
	_detail_camera()
	await _capture(scenario, "Airborne elbow-drop clip, real descending movement, and ordinary arena lighting.")
	var landed: bool = false
	for i: int in 80:
		_advance(1)
		if a.grounded:
			landed = true
			break
	_check(landed and not _owned("ring").is_empty(), "Elbow drop lands and spawns its real ground wave")
	_detail_camera()
	await _capture(scenario + "_landing", "Landing-triggered shockwave from the same airborne move; no effect spawned by the harness.")

func _save_report() -> void:
	var report: Dictionary = {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(), "graphical": DisplayServer.get_name() != "headless", "tick_hz": 60,
		"seed": SEED, "preset": "Fair Fight except the explicitly labeled Party chair-break fixture; exact preset recorded per capture", "confirmed_ids_only": CONFIRMED, "case_filter": filter,
		"settings": app.settings.values.duplicate(true), "original_settings": initial_settings,
		"captures": captures, "trigger_checks": checks, "trigger_failures": failures,
		"scope": "Real main.tscn, MatchWorld, arena lighting, HUD, skins, clips, ability props and impact effects. Inputs use ScriptedInputProvider. Positions and starting resources are documented acceptance fixtures. Simulation advances manually at 60 Hz and pauses only for exact-tick screenshots; this is not a frame-time or live-play measurement.",
		"review_status": "Capture and trigger checks are machine evidence only; visual quality requires inspection of these images. All five canonical mappings are confirmed; Sunstruck=Will and Heavy Duty=Damion were explicitly confirmed by the user on 2026-09-22.",
		"reproduction": "Godot --path <Game File> --script ../tools/validation/presentation_scenarios.gd; optionally -- --case=<substring> --output=<absolute directory>"}
	var file: FileAccess = FileAccess.open(output.path_join("presentation_scenarios.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "  "))
