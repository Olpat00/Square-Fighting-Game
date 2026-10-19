extends SceneTree
## Headless state tests. Synthetic connection signals do not register physical pads.

var app: Node
var checks: Array[Dictionary] = []
var failures: int = 0
var combat_events: Array[Dictionary] = []

class AudioProbe extends AudioDirector:
	var calls: Array[Dictionary] = []
	func play_sound(id: String, gain: float = 0.0) -> void:
		calls.append({"id": id, "gain": gain})

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String, detail: String = "") -> void:
	checks.append({"name": label, "passed": condition, "detail": detail})
	if not condition:
		failures += 1
		print("PRESENTATION_FAIL ", label, " ", detail)

func particle_ids(effects: EffectsDirector) -> Array[int]:
	var ids: Array[int] = []
	for node in effects.get_children():
		if node is MeshInstance3D: ids.append(node.get_instance_id())
	ids.sort()
	return ids

func all_particles_hidden(effects: EffectsDirector) -> bool:
	for node in effects.get_children():
		if node is MeshInstance3D and node.visible: return false
	return true

func all_signs_visible(stage: RooftopStage) -> bool:
	for sign in stage.breakable_signs:
		if not sign.visible: return false
	return true

func key_event(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event

func _run() -> void:
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	# The harness owns time advancement; loading the real app still executes _ready.
	app.set_process(false)
	app.set_physics_process(false)
	app.audio.stop_all()
	await process_frame
	check(app.ui.screen_name == "title" and app.ui.has_method("apply_scale"), "Actual main and current UI initialize headlessly")
	app.settings.values.blood = false # In-memory deterministic presentation fixture; never saved.
	_test_pool()
	_test_signs()
	_test_furniture()
	_test_launch_audio()
	_test_impact_locations()
	_test_results()
	_test_results_camera()
	await process_frame
	_test_connection_and_f3()
	_test_host_pause()
	_test_citation_overlay()
	_test_low_texture_tier()
	_test_camera_and_labels()
	_test_stage_quality()
	await process_frame
	var report := {
		"engine": Engine.get_version_info().string,
		"checks": checks.size(), "failures": failures, "results": checks,
		"headless": DisplayServer.get_name() == "headless",
		"limitation": "Actual main, effects, stage, providers, and UI state run headlessly. Connection signals and input events are synthetic; they do not prove physical controller operation, connected-device enumeration changes, rendered visuals, audio quality, or performance. User settings are not saved."
	}
	FileAccess.open(ProjectSettings.globalize_path("res://../evidence/presentation_state.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("PRESENTATION_STATE ", checks.size(), " checks; ", failures, " failures")
	app.audio.stop_all()
	app.world.clear()
	app.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func _test_low_texture_tier() -> void:
	var original_quality: String = str(app.settings.values.graphics)
	app.settings.values.graphics = "Low"
	app.apply_settings()
	for definition: FighterDefinition in RosterRegistry.discover():
		var slots: Array[Dictionary] = [{"fighter": definition.id, "device": "CPU"}, {"fighter": "f01_clutch", "device": "CPU"}]
		app.start_match(slots, "Fair Fight", false)
		var visual: FighterVisual = app.world.fighters[0].visual
		var dimensions := _model_texture_dimensions(visual.model)
		check(visual.loaded_model_path == definition.low_model_path and dimensions.size() >= 3 and dimensions.all(func(size: Vector2i) -> bool: return size.x <= 1024 and size.y <= 1024), definition.id + " Low match loads the real 1K albedo/normal/packed material textures", str(dimensions))
		var high_model: Node = load(definition.model_path).instantiate()
		var high_player: AnimationPlayer = visual._find_player(high_model)
		check(visual.animation_player.get_animation_list() == high_player.get_animation_list(), definition.id + " Low preserves every runtime animation")
		high_model.free()
	app.settings.values.graphics = "High"
	app.apply_settings()
	app.rematch()
	check(app.world.fighters.all(func(fighter: RiotFighter) -> bool: return fighter.visual.loaded_model_path == fighter.definition.model_path), "High restores original-resolution fighters on the next match")
	app.settings.values.graphics = original_quality
	app.apply_settings()

func _model_texture_dimensions(node: Node) -> Array[Vector2i]:
	var dimensions: Array[Vector2i] = []
	if node is MeshInstance3D:
		for surface: int in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(surface)
			if material is StandardMaterial3D:
				for kind: int in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL, BaseMaterial3D.TEXTURE_ROUGHNESS, BaseMaterial3D.TEXTURE_METALLIC]:
					var texture: Texture2D = material.get_texture(kind)
					if texture: dimensions.append(Vector2i(texture.get_width(), texture.get_height()))
	for child: Node in node.get_children(): dimensions.append_array(_model_texture_dimensions(child))
	return dimensions

func _test_pool() -> void:
	var effects: EffectsDirector = app.effects
	var original_quality: String = app.world.graphics_quality
	app.world.graphics_quality = "High"
	var origin := Vector3(2, 3, 0)
	var first_color := Color("e6aa66")
	effects.burst(origin, first_color, 200, 3)
	var original_ids := particle_ids(effects)
	check(effects.particles.size() == 144 and original_ids.size() == 144, "Oversized High burst respects the 144 active-node cap")
	effects.burst(origin, first_color, 300, 3)
	check(particle_ids(effects) == original_ids and effects.particles.size() == 144, "Additional bursts at capacity allocate no nodes")
	check(effects.mesh_cache.size() == 1, "Same-color bursts reuse a mesh/material resource")
	effects.update(0.1)
	check(effects.particles.size() == 144 and is_equal_approx(effects.particles[0].life, 0.35) and is_equal_approx(float(effects.particles[0].node.get_instance_shader_parameter("age")), 0.1 / 0.45) and effects.particles[0].node.scale == Vector3.ONE and effects.particles[2].node.scale.x < 1.0, "Pooled lifetime and shader age advance; pressure ring retains its expanding shader while sparks shrink")
	var smoke_size: float = effects.particles[1].node.scale.x
	effects.update(0.1)
	check(effects.particles[1].shape == "smoke" and effects.particles[1].node.scale.x > smoke_size and is_equal_approx(effects.particles[1].life, 0.25), "Smoke expands as its lifetime decays")
	effects.update(1.0)
	check(effects.particles.is_empty() and effects.spare_particles.size() == 144 and all_particles_hidden(effects), "Expired effects become hidden reusable nodes")
	var next_origin := Vector3(-4, 1, 0)
	effects.burst(next_origin, first_color, 72, 2)
	effects.burst(next_origin, Color("55bbdd"), 72, 2)
	var reset_fields: bool = true
	for particle in effects.particles:
		reset_fields = reset_fields and particle.node.position == next_origin and particle.node.scale == Vector3.ONE and particle.node.visible and is_equal_approx(particle.life, 0.45)
	check(particle_ids(effects) == original_ids and effects.spare_particles.is_empty() and reset_fields, "Reused particles restore position, scale, visibility, and lifetime")
	check(effects.mesh_cache.size() == 2, "A new color adds one shared resource without new particle nodes")
	for cycle in 20:
		effects.clear_effects()
		effects.burst(origin, first_color, 144, 2)
		effects.update(1)
	check(particle_ids(effects) == original_ids and effects.spare_particles.size() == 144, "Twenty pool reuse cycles preserve the original node set")
	app.world.graphics_quality = "Low"
	effects.burst(origin, first_color, 200, 3)
	check(effects.particles.size() == 64 and particle_ids(effects) == original_ids and effects.spare_particles.size() == 80, "Oversized Low burst caps active particles at 64 and reuses existing High-tier nodes")
	effects.burst(origin, first_color, 300, 3)
	check(effects.particles.size() == 64 and particle_ids(effects) == original_ids, "Additional Low bursts at capacity allocate no nodes")
	effects.clear_effects()
	app.world.graphics_quality = "High"
	effects.on_event("parry", -1, origin, {})
	check(effects.impulse > 0 and not effects.particles.is_empty(), "Real presentation event populates the pool and camera impulse")
	effects.clear_effects()
	effects.clear_effects()
	check(effects.impulse == 0 and effects.particles.is_empty() and effects.spare_particles.size() == 144 and all_particles_hidden(effects), "Repeated effect reset clears impulse and does not duplicate spare nodes")
	app.world.graphics_quality = original_quality

func _test_signs() -> void:
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f04_deadfall", "device": "CPU"}]
	app.start_match(slots, "Party", false)
	var stage: RooftopStage = app.world.stage
	var platforms_before: Array[Dictionary] = stage.platforms.duplicate(true)
	check(stage.breakable_signs.size() == 3 and all_signs_visible(stage), "Party starts with exactly three intact cosmetic signs")
	app.world.emit_event("hit", app.world.fighters[0], Vector3(-7.1, 0, 0), {"heavy": false})
	check(stage.broken_signs.is_empty(), "Light hit event does not break a sign")
	app.world.emit_event("hit", app.world.fighters[0], Vector3(-7.1, 0, 0), {"heavy": true})
	check(stage.broken_signs.size() == 1 and not stage.breakable_signs[0].visible, "Heavy hit presentation event breaks its nearby Party sign")
	check(not stage.break_nearby_sign(Vector3(-7.1, 0, 0)).is_finite() and stage.broken_signs.size() == 1, "A broken sign cannot trigger a second break")
	app.world.emit_event("hit", app.world.fighters[0], Vector3(0, 0, 0), {"heavy": true})
	app.world.emit_event("hit", app.world.fighters[0], Vector3(7.1, 0, 0), {"heavy": true})
	check(stage.broken_signs.size() == 3, "All three signs break independently")
	check(stage.platforms == platforms_before and app.world.fighters[0].damage == 0 and app.world.fighters[1].damage == 0, "Cosmetic break events leave authoritative surfaces and damage unchanged")
	app.rematch()
	check(stage.broken_signs.is_empty() and all_signs_visible(stage), "Real rematch restores all cosmetic signs")
	check(app.effects.particles.is_empty() and app.effects.impulse == 0, "Real rematch clears active effects and camera impulse")
	check(not stage.break_nearby_sign(Vector3(100, 0, 0)).is_finite() and not stage.break_nearby_sign(Vector3(0, 4, 0)).is_finite(), "Distant and high hits cannot break signs")
	app.start_match(slots, "Fair Fight", false)
	for x in [-7.1, 0.0, 7.1]:
		app.world.emit_event("hit", app.world.fighters[0], Vector3(x, 0, 0), {"heavy": true})
	check(stage.broken_signs.is_empty() and all_signs_visible(stage), "Fair Fight disables all three cosmetic break triggers")

func _test_furniture() -> void:
	var original_quality: String = app.world.graphics_quality
	app.world.graphics_quality = "High"
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f04_deadfall", "device": "CPU"}]
	app.start_match(slots, "Party", false)
	var stage: RooftopStage = app.world.stage
	var surfaces: Array[Dictionary] = stage.platforms.duplicate(true)
	var ids := particle_ids(app.effects)
	check(stage.breakable_furniture.size() == 2 and stage.breakable_furniture[0].visible and stage.breakable_furniture[1].visible, "Party installs exactly two intact authored cosmetic chairs")
	var first_at: Vector3 = stage.breakable_furniture[0].position
	first_at.z = 0
	app.world.emit_event("hit", app.world.fighters[0], first_at, {"heavy": false})
	check(stage.broken_furniture.is_empty(), "Ordinary light impact leaves decorative furniture intact")
	app.effects.clear_effects()
	app.world.emit_event("hit", app.world.fighters[0], first_at, {"heavy": true})
	check(stage.broken_furniture.size() == 1 and not stage.breakable_furniture[0].visible and stage.broken_signs.is_empty(), "Nearby heavy hit breaks its selected chair without breaking a distant sign")
	var furniture_fragments: int = 0
	for particle: Dictionary in app.effects.particles:
		if particle.shape in ["splinter", "chunk"]: furniture_fragments += 1
	check(furniture_fragments == 8 and app.effects.particles.size() > furniture_fragments and particle_ids(app.effects) == ids, "Chair breakup adds exactly eight debris fragments, separately from the signature impact, through the existing pool")
	check(not stage.break_nearby_decoration(first_at).is_finite() and stage.broken_furniture.size() == 1, "A broken chair cannot create a second breakup")
	app.world.emit_event("hit", app.world.fighters[0], Vector3(stage.breakable_furniture[1].position.x, 0, 0), {"heavy": true})
	check(stage.broken_furniture.size() == 2 and not stage.breakable_furniture[1].visible, "Second curated chair breaks independently")
	check(stage.platforms == surfaces and app.world.fighters[0].damage == 0 and app.world.fighters[1].damage == 0, "Furniture breakup adds no collision surface or combat damage")
	app.rematch()
	check(stage.broken_furniture.is_empty() and stage.breakable_furniture[0].visible and stage.breakable_furniture[1].visible and app.effects.particles.is_empty() and particle_ids(app.effects) == ids, "Rematch restores both chairs and clears their pooled fragments without allocations")
	check(not stage.break_nearby_decoration(first_at + Vector3.UP * 4).is_finite(), "Distant overhead impact cannot break floor furniture")
	app.start_match(slots, "Fair Fight", false)
	for chair: Node3D in stage.breakable_furniture:
		app.world.emit_event("hit", app.world.fighters[0], Vector3(chair.position.x, 0, 0), {"heavy": true})
	check(stage.broken_furniture.is_empty() and stage.breakable_furniture[0].visible and stage.breakable_furniture[1].visible, "Fair Fight disables furniture breakup")
	app.world.graphics_quality = original_quality

func _capture_combat_event(event: String, actor: int, at: Vector3, details: Dictionary) -> void:
	combat_events.append({"event": event, "actor": actor, "at": at, "details": details})

func _event_count(name_value: String) -> int:
	var count: int = 0
	for event: Dictionary in combat_events:
		if event.event == name_value: count += 1
	return count

func _launch_fixture(percent: float, move_id: String, shielded: bool = false) -> void:
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f01_clutch", "device": "CPU"}]
	app.start_match(slots, "Fair Fight", false)
	app.world.countdown = 0
	for fighter: RiotFighter in app.world.fighters:
		fighter.provider = ScriptedInputProvider.new()
		fighter.snapshot = InputSnapshot.new()
	var source: RiotFighter = app.world.fighters[0]
	var target: RiotFighter = app.world.fighters[1]
	source.position = Vector3.ZERO
	source.facing = 1
	target.position = Vector3(0.85, 0, 0)
	target.damage = percent
	if shielded:
		target.state = "shield"
		target.shield_start_tick = -100
		target.provider = ScriptedInputProvider.new([{"from": 0, "to": 20, "actions": ["defend"]}])
		target.provider._previous["defend"] = true # Already-held shield, not a fresh parry edge.
	source.start_move(move_id)
	source.state = "attack"
	source.move_tick = source.move.startup - 1
	combat_events.clear()
	app.world.step()

func _test_launch_audio() -> void:
	app.world.presentation_event.connect(_capture_combat_event)
	_launch_fixture(0, "jab1")
	check(_event_count("hit") == 1 and _event_count("launch") == 0 and app.world.fighters[1].velocity.length() < CombatResolver.LAUNCH_SOUND_MIN_SPEED, "Actual low-percent light hit has an impact cue without launch spam")
	_launch_fixture(300, "heavy_side")
	var launch_event: Dictionary = {}
	for event: Dictionary in combat_events:
		if event.event == "launch": launch_event = event
	check(_event_count("hit") == 1 and _event_count("launch") == 1 and launch_event.details.speed > CombatResolver.LAUNCH_SOUND_MIN_SPEED and launch_event.details.target == 1 and is_equal_approx(launch_event.details.speed, app.world.fighters[1].velocity.length()), "Actual high-knockback impact emits one launch event with resolved speed and target")
	for i in 3: app.world.step()
	check(_event_count("launch") == 1, "Hitstop and hit registry do not repeat a launch cue")
	_launch_fixture(300, "heavy_side", true)
	check(_event_count("shield") == 1 and _event_count("launch") == 0, "Shielded high-percent heavy contact does not emit a launch cue", str(combat_events))
	var probe := AudioProbe.new()
	probe.on_event("hit", 0, Vector3.ZERO, {"heavy": true})
	probe.on_event("launch", 0, Vector3.ZERO, {"speed": 25.0})
	check(probe.calls.size() == 2 and probe.calls[0].id == "hit_heavy_1" and probe.calls[1].id == "launch" and probe.calls[1].gain < 0 and ResourceLoader.exists("res://assets/audio/launch.wav"), "Audio event route layers the authored launch asset at reduced gain")
	probe.free()
	app.world.presentation_event.disconnect(_capture_combat_event)

func _test_impact_locations() -> void:
	app.world.presentation_event.connect(_capture_combat_event)
	_launch_fixture(0, "tilt_down")
	var low: Vector3 = Vector3.INF
	for event: Dictionary in combat_events:
		if event.event == "hit": low = event.at
	_launch_fixture(0, "tilt_up")
	var high: Vector3 = Vector3.INF
	for event: Dictionary in combat_events:
		if event.event == "hit": high = event.at
	check(low.is_finite() and high.is_finite() and low.y < 0.5 and high.y > 1.4 and high.y - low.y > 0.8, "Actual ankle and overhead contacts place their impact events at distinct visible body heights", str([low, high]))
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f04_deadfall", "device": "CPU"}]
	app.start_match(slots, "Fair Fight", false)
	app.world.countdown = 0
	var source: RiotFighter = app.world.fighters[0]
	var target: RiotFighter = app.world.fighters[1]
	for fighter: RiotFighter in app.world.fighters:
		fighter.provider = ScriptedInputProvider.new()
		fighter.snapshot = InputSnapshot.new()
	source.position = Vector3(-4, 0, 0)
	target.position = Vector3.ZERO
	app.world.abilities.spawn(source, "ring", Vector2(-0.7, 1.45), Vector2(9, 0), source.definition.get_move("special_neutral"), {"radius": 0.15, "life": 30})
	combat_events.clear()
	for i in 8: app.world.step()
	var projectile_at: Vector3 = Vector3.INF
	for event: Dictionary in combat_events:
		if event.event == "hit": projectile_at = event.at
	check(target.damage > 0 and projectile_at.is_finite() and absf(projectile_at.x) < 0.5 and projectile_at.y > 1.3 and source.position.x < -3.5, "A travelled projectile places its effect on the remote victim using its sweep, not its owner's stale move offset", str(projectile_at))
	app.world.presentation_event.disconnect(_capture_combat_event)

func _test_results() -> void:
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f03_heavy_duty", "device": "CPU"}]
	app.start_match(slots, "Fair Fight", false)
	app.world.countdown = 0
	var winner: RiotFighter = app.world.fighters[0]
	var loser: RiotFighter = app.world.fighters[1]
	winner.provider = ScriptedInputProvider.new()
	loser.provider = ScriptedInputProvider.new()
	winner.position = Vector3.ZERO
	loser.position = Vector3(19, 0, 0)
	loser.stocks = 1
	app.world.abilities.spawn(winner, "chair", Vector2.ZERO, Vector2.ZERO, winner.definition.get_move("ultimate"), {"life": 100, "cosmetic": true})
	app.world.step()
	check(not app.world.running and app.ui.screen_name == "results" and winner.stocks == 3 and loser.stocks == 0 and winner.position == Vector3.ZERO and loser.position == Vector3(19, 0, 0), "Actual final KO stages results without changing committed stocks or fighter positions")
	check(loser.visual.visible and loser.visual.current_clip.ends_with("lose") and not loser.visual.ring.visible and winner.visual.current_clip.ends_with("final_ko"), "Eliminated loser is visible in defeat while winner begins final-KO flourish")
	check(app.world.abilities.objects.is_empty() and app.world.abilities.sequences.is_empty(), "Results clear temporary ability props and captures")
	for i in 69: app._process(CombatTuning.DT)
	check(winner.visual.current_clip.ends_with("final_ko") and winner.visual.result_win_pending, "Winner's final-KO flourish remains active through tick 69")
	for i in 2: app._process(CombatTuning.DT)
	check(winner.visual.current_clip.ends_with("win") and not winner.visual.result_win_pending and loser.visual.current_clip.ends_with("lose"), "Actual main results update transitions final-KO flourish to looping victory")
	app.rematch()
	var clean: bool = true
	for fighter: RiotFighter in app.world.fighters:
		clean = clean and fighter.stocks == 3 and fighter.visual.position == Vector3.ZERO and not fighter.visual.result_win_pending
	check(clean and app.world.running and app.ui.screen_name == "match", "Rematch replaces staged result visuals with clean gameplay fighters")

func _test_results_camera() -> void:
	var slots: Array[Dictionary] = [
		{"fighter": "f01_clutch", "device": "CPU"},
		{"fighter": "f03_heavy_duty", "device": "CPU"},
		{"fighter": "f07_urban_sentinel", "device": "CPU"},
		{"fighter": "f08_midnight_gentleman", "device": "CPU"}
	]
	for arena: String in StageCatalog.IDS:
		for winner_at: Vector3 in [Vector3(-8.7, 10, 0), Vector3(8.7, -1.7, 0)]:
			app.start_match(slots, "Fair Fight", false, arena)
			app.world.countdown = 0
			for fighter: RiotFighter in app.world.fighters:
				fighter.provider = ScriptedInputProvider.new()
				fighter.position = winner_at if fighter.slot == 3 else Vector3(19 + fighter.slot, 0, 0)
				fighter.grounded = false
				fighter.support_id = -1
				fighter.stocks = 1
			# Reproduce a last stock loss while the eventual winner is high above
			# or recovering beside a ledge, rather than conveniently near center.
			app._update_camera(CombatTuning.DT)
			app.world.step()
			var committed: Array[Vector3] = []
			for fighter: RiotFighter in app.world.fighters: committed.append(fighter.position)
			app._update_camera(CombatTuning.DT)
			var in_frame: bool = true
			var beside_panel: bool = true
			var unchanged: bool = true
			var projected_corners: Array[Vector2] = []
			var viewport_size: Vector2 = app.camera.get_viewport().get_visible_rect().size
			for fighter: RiotFighter in app.world.fighters:
				unchanged = unchanged and fighter.position == committed[fighter.slot]
				for corner: Vector3 in [Vector3(-0.85, 0, 0), Vector3(0.85, 2.5, 0)]:
					var projected: Vector2 = app.camera.unproject_position(fighter.visual.global_position + corner) / viewport_size
					projected_corners.append(projected)
					in_frame = in_frame and Rect2(0.025, 0.025, 0.95, 0.95).has_point(projected)
					beside_panel = beside_panel and (projected.x < 0.30 if fighter.slot == 3 else projected.x > 0.70)
			var fixture: String = "%s final KO at %s" % [arena, winner_at]
			check(not app.world.running and app.world.result.get("winner", -1) == 3 and in_frame, fixture + " immediately frames every staged result actor", str(projected_corners))
			check(beside_panel, fixture + " keeps result actors beside the central results panel")
			check(unchanged, fixture + " result framing preserves committed combat roots")

func _test_connection_and_f3() -> void:
	# Pick a device absent from OS enumeration without altering actual hardware state.
	var device: int = 93
	while Input.get_connected_joypads().has(device): device += 1
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "Gamepad", "device_id": device}, {"fighter": "f04_deadfall", "device": "Keyboard", "device_id": -1}]
	app.start_match(slots, "Fair Fight", false)
	app.world.countdown = 0
	var pad: HumanInputProvider = app.world.fighters[0].provider
	var keyboard: HumanInputProvider = app.world.fighters[1].provider
	var press := InputEventJoypadButton.new()
	press.device = device
	press.button_index = JOY_BUTTON_X
	press.pressed = true
	app._input(press)
	app._input(key_event(int(HumanInputProvider.get_keyboard_bindings().light)))
	app.world.fighters[1].sample_input()
	app.world.fighters[0].buffered["light"] = CombatTuning.INPUT_BUFFER
	check(pad._held.get("light", false) and keyboard._held.get("light", false) and not app.world.fighters[1].buffered.is_empty(), "Actual main input route seeds independent pad and keyboard held/buffered state")
	Input.joy_connection_changed.emit(device + 1, false)
	check(not app.world.paused and pad._held.get("light", false), "Unassigned controller disconnect does not pause or reset active players")
	Input.joy_connection_changed.emit(device, false)
	check(app.world.paused and app.ui.screen_name == "pause", "Assigned controller disconnect signal pauses actual main and opens pause UI")
	var cleared: bool = true
	for fighter in app.world.fighters:
		var provider: HumanInputProvider = fighter.provider
		cleared = cleared and provider._held.is_empty() and provider._pressed.is_empty() and provider._released.is_empty() and fighter.buffered.is_empty()
	check(cleared, "Disconnect clears every player's held, edge, and buffered inputs")
	var tick_before: int = app.world.tick
	app.world.step()
	check(app.world.tick == tick_before, "Paused controller-loss match does not advance simulation")
	Input.joy_connection_changed.emit(device, true)
	check(app.world.paused and app.ui.screen_name == "pause", "Reconnect signal keeps a paused match paused until explicit resume")
	app.resume_match()
	app.world.step()
	check(not app.world.paused and app.world.tick == tick_before + 1 and app.ui.screen_name == "match", "Explicit resume continues simulation through the actual main handler")
	check(app.world.fighters[0].attack_instance == 0 and app.world.fighters[1].attack_instance == 0, "Inputs held before disconnect cannot become attacks after resume")
	app._input(key_event(KEY_F3))
	check(not app.world.training and app.world.fighters[1].provider == keyboard, "F3 is ignored in a normal match with a human second slot")
	var training_slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "Keyboard", "device_id": -1}, {"fighter": "f04_deadfall", "device": "CPU"}]
	app.start_match(training_slots, "Fair Fight", true)
	var dummy: CpuInputProvider = app.world.fighters[1].provider
	check(dummy.dummy_mode == "stationary", "Training starts with a stationary CPU fixture")
	app._input(key_event(KEY_F3))
	check(dummy.dummy_mode == "defending", "F3 positive control changes the live training dummy behavior")
	app.leave_match()
	app.ui.show_title()
	app._input(key_event(KEY_F3))
	check(not app.world.training and app.world.fighters.is_empty() and app.ui.screen_name == "title", "F3 after leaving Training safely ignores an empty roster")
	app.ui.slots[0].device = "Gamepad"
	app.ui.slots[0].device_id = device
	app.ui.show_setup(false)
	var old_screen_id: int = app.ui.screen.get_instance_id()
	Input.joy_connection_changed.emit(device, true)
	check(app.ui.screen_name == "setup" and app.ui.screen.get_instance_id() != old_screen_id, "Synthetic reconnect rebuilds the active selection UI")
	check(app.ui.slots[0].device == "Gamepad" and app.ui.slots[0].device_id == device, "Selection refresh preserves the assigned pad slot")
	var retained_disconnected_label: bool = false
	for control in app.ui.screen.find_children("*", "OptionButton", true, false):
		if control.get_item_text(control.selected) == "Pad %d · disconnected" % (device + 1): retained_disconnected_label = true
	check(retained_disconnected_label, "Synthetic signal does not falsely display a physically absent pad as connected")

func _test_host_pause() -> void:
	var old_bindings: Dictionary = HumanInputProvider.get_keyboard_bindings()
	HumanInputProvider.set_keyboard_binding("pause", KEY_P)
	var cpu_slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f04_deadfall", "device": "CPU"}]
	app.start_match(cpu_slots, "Fair Fight", false)
	app.world.countdown = 0
	app._input(key_event(KEY_ESCAPE))
	check(not app.world.paused, "Old pause key does not pause a CPU demo after remapping")
	app._input(key_event(KEY_P))
	var before: int = app.world.tick
	app.world.step()
	check(app.world.paused and app.ui.screen_name == "pause" and app.world.tick == before, "Remapped host pause freezes a CPU-only demo")
	var echo := key_event(KEY_P)
	echo.echo = true
	app._input(echo)
	check(app.world.paused, "Keyboard repeat cannot resume a paused CPU demo")
	app._input(key_event(KEY_P))
	app.world.step()
	check(not app.world.paused and app.ui.screen_name == "match" and app.world.tick == before + 1, "Remapped host key resumes a CPU demo without a second pause edge")
	app._input(echo)
	check(not app.world.paused, "Keyboard repeat cannot pause a running CPU demo")
	var keyboard_slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "Keyboard", "device_id": -1}, {"fighter": "f04_deadfall", "device": "CPU"}]
	app.start_match(keyboard_slots, "Fair Fight", false)
	app.world.countdown = 0
	app._input(key_event(KEY_P))
	check(not app.world.paused, "Keyboard-owned pause reaches the normal provider before simulation")
	app.world.step()
	check(app.world.paused and app.world.tick == 0, "Keyboard-owned pause toggles exactly once in the world step")
	app._input(echo)
	check(app.world.paused, "Keyboard-owned pause also ignores repeat while paused")
	app._input(key_event(KEY_P))
	app.world.step()
	check(not app.world.paused and app.world.tick == 1, "Keyboard-owned resume clears the queued pause edge")
	var device: int = 93
	while Input.get_connected_joypads().has(device): device += 1
	var pad_slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "Gamepad", "device_id": device}, {"fighter": "f04_deadfall", "device": "Gamepad", "device_id": device + 1}]
	app.start_match(pad_slots, "Fair Fight", false)
	app.world.countdown = 0
	app._input(key_event(KEY_P))
	check(app.world.paused, "Host can pause an all-gamepad match")
	var start := InputEventJoypadButton.new()
	start.device = device + 2
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	app._input(start)
	check(app.world.paused, "Unassigned controller Start cannot resume another match")
	start.device = device
	app._input(start)
	app.world.step()
	check(not app.world.paused and app.world.tick == 1 and app.ui.screen_name == "match", "Assigned controller Start resumes and clears pending pause state")
	HumanInputProvider.KEYBOARD_SETTINGS.bindings = old_bindings

func _test_citation_overlay() -> void:
	var overlay: CombatDebugOverlay
	for child: Node in app.ui.root.get_children():
		if child is CombatDebugOverlay: overlay = child
	check(overlay != null, "Actual main installs its normal HUD citation overlay")
	if overlay == null: return
	var slots: Array[Dictionary] = [{"fighter": "f05_fine_print", "device": "CPU"}, {"fighter": "f05_fine_print", "device": "CPU"}, {"fighter": "f01_clutch", "device": "CPU"}]
	app.start_match(slots, "Fair Fight", false)
	app.world.countdown = 0
	app.debug_hitboxes = false
	for fighter: RiotFighter in app.world.fighters: fighter.provider = ScriptedInputProvider.new()
	var first: RiotFighter = app.world.fighters[0]
	var second: RiotFighter = app.world.fighters[1]
	var target: RiotFighter = app.world.fighters[2]
	# Combat award semantics have separate scenarios; seed through the real mechanic
	# API here to test the HUD's live owner/color/count projection independently.
	first.mechanics.add_mark(target)
	first.mechanics.add_mark(target)
	second.mechanics.add_mark(target)
	var rows: Array[Dictionary] = overlay.marks_for_target(target)
	check(not app.debug_hitboxes and rows.size() == 2 and rows[0].source == first.slot and rows[0].count == 2 and rows[0].color == first.player_color and rows[1].source == second.slot and rows[1].count == 1 and rows[1].color == second.player_color, "Normal HUD exposes independent mirror-owned citation counts and colors with debug disabled")
	first.mechanics.consume_marks(target)
	rows = overlay.marks_for_target(target)
	check(rows.size() == 1 and rows[0].source == second.slot and rows[0].count == 1, "Consumption removes only the consuming owner's HUD citation row")
	second.mechanics.marks[target.slot].remaining = 1
	app.world.step()
	check(overlay.marks_for_target(target).is_empty(), "Citation expiry removes the displayed row on the next simulation tick")
	first.mechanics.add_mark(target)
	second.mechanics.add_mark(target)
	first.position.x = 19
	app.world.step()
	rows = overlay.marks_for_target(target)
	check(first.stocks == 2 and rows.size() == 1 and rows[0].source == second.slot, "Source KO clears only that source's displayed citation row")
	target.position.x = 19
	app.world.step()
	check(target.stocks == 2 and overlay.marks_for_target(target).is_empty(), "Target KO clears every source's displayed citation row")

func _test_camera_and_labels() -> void:
	var camera: Camera3D = app.camera
	var points: Array[Vector3] = [Vector3(-1, 0, 0), Vector3(1, 0, 0)]
	var offsets: Array[Vector2] = []
	for fps: int in [30, 60, 144]:
		var framing := MatchCamera.new()
		for frame: int in fps: framing.update(camera, points, 2, 1.0 / fps, false, 0.12, 1.0)
		offsets.append(Vector2(camera.h_offset, camera.v_offset))
		var paused_transform: Transform3D = camera.transform
		var paused_size: float = camera.size
		var paused_offset := Vector2(camera.h_offset, camera.v_offset)
		var recovery: Array[Vector3] = [Vector3(-16, -8.8, 0), Vector3(15.5, 11, 0)]
		framing.update(camera, recovery, 2, 1.0, true, 0.12, 1.0)
		check(camera.transform == paused_transform and camera.size == paused_size and Vector2(camera.h_offset, camera.v_offset) == paused_offset, "Pause freezes camera focus, zoom and shake at %d FPS" % fps)
		framing.update(camera, recovery, 2, 1.0 / fps, false, 0.0, 1.0)
		var visible_rect: Vector2 = camera.get_viewport().get_visible_rect().size
		var contained: bool = true
		for point: Vector3 in recovery:
			for corner: Vector3 in [Vector3(-0.85, -0.3, 0), Vector3(0.85, 2.5, 0)]:
				var normalized: Vector2 = camera.unproject_position(point + corner) / visible_rect
				contained = contained and normalized.x >= 0.02 and normalized.x <= 0.98 and normalized.y >= 0.015 and normalized.y <= 0.815
		check(contained, "Fast launch and low recovery remain in the safe frame at %d FPS" % fps)
	check(offsets[0].distance_to(offsets[1]) < 0.0001 and offsets[1].distance_to(offsets[2]) < 0.0001, "Shake phase depends on elapsed time rather than render-frame count")
	var framing := MatchCamera.new()
	framing.update(camera, points, 2, 0.0, false, 0, 0)
	var close_height: float = camera.size
	var wide: Array[Vector3] = [Vector3(-9, 0, 0), Vector3(9, 0, 0)]
	framing.update(camera, wide, 2, 0.1, false, 0, 0)
	var expanded_height: float = camera.size
	framing.update(camera, points, 2, 0.1, false, 0, 0)
	check(expanded_height - close_height > expanded_height - camera.size and close_height < 12, "Close exchanges frame larger fighters and zoom out faster than they zoom in")
	var bounds := Rect2(12, 50, 960, 600)
	for anchor: Vector2 in [bounds.position, bounds.end, bounds.position + Vector2(bounds.size.x, 0), bounds.position + Vector2(0, bounds.size.y), bounds.get_center()]:
		var occupied: Array[Rect2] = []
		var fits: bool = true
		for slot: int in 4:
			var rect: Rect2 = PlayerLabels.place_label(anchor, bounds, occupied)
			fits = fits and bounds.encloses(rect)
			for other: Rect2 in occupied: fits = fits and not rect.intersects(other)
			occupied.append(rect)
		check(fits, "Four overlapping player labels separate inside safe bounds at " + str(anchor))
	app.effects.clear_effects()
	app.effects.burst(Vector3.ZERO, Color.WHITE, 6, 3)
	var particle: Dictionary = app.effects.particles[1]
	var before: Transform3D = particle.node.transform
	app.effects.impulse = 0.12
	app.effects.update(0.0)
	check(particle.node.transform == before and particle.life == particle.initial and app.effects.impulse == 0.12, "Paused effects preserve even the first burst frame and impulse envelope")
	app.effects.clear_effects()
	app.effects.on_event("shield", -1, Vector3.ZERO, {})
	check(app.effects.particles.size() > 0 and app.effects.particles.all(func(p: Dictionary) -> bool: return p.shape != "smoke") and app.effects.impulse == 0.0, "Shield contact gets a compact smoke-free cue without camera impact")
	app.effects.clear_effects()

func _test_stage_quality() -> void:
	for stage: RooftopStage in [RooftopStage.new(), LunarStage.new()]:
		root.add_child(stage)
		var surfaces: Array[Dictionary] = stage.platforms.duplicate(true)
		stage.apply_quality("High")
		stage.apply_quality("Low")
		var reduced: bool = true
		var restored: bool = true
		for entry: Dictionary in stage.quality_nodes:
			if entry.has("optional"): reduced = reduced and not entry.node.visible
			if entry.has("shadow"): reduced = reduced and entry.node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if entry.has("instances"): reduced = reduced and entry.node.multimesh.visible_instance_count == int(entry.instances) / 4
		for material: ShaderMaterial in stage.quality_materials: reduced = reduced and material.get_shader_parameter("low_quality") == true
		check(reduced and not stage.environment.glow_enabled and not stage.environment.ssil_enabled and not stage.environment.ssao_enabled, stage.get_class() + " Low reduces scenery, shaders, shadow and postprocess costs")
		if stage is LunarStage:
			check(stage.terrain_node.mesh == stage.terrain_low and stage.terrain_low.surface_get_array_index_len(0) * 9 == stage.terrain_high.surface_get_array_index_len(0), "Lunar Low terrain draws one ninth of High triangles")
			var recovery_clear: bool = true
			for x: float in [-18.0, -10.0, 0.0, 10.0, 18.0]:
				for z: float in [0.0, 2.0, 8.0]: recovery_clear = recovery_clear and stage._height(x, z) < CombatTuning.BLAST_BOTTOM - 3.0
			check(recovery_clear, "Lunar foreground terrain stays below the recovery/blast plane")
		stage.apply_quality("High")
		for entry: Dictionary in stage.quality_nodes:
			if entry.has("optional"): restored = restored and entry.node.visible == entry.visible
			if entry.has("shadow"): restored = restored and entry.node.cast_shadow == entry.shadow
			if entry.has("instances"): restored = restored and entry.node.multimesh.visible_instance_count == -1
		for material: ShaderMaterial in stage.quality_materials: restored = restored and material.get_shader_parameter("low_quality") == false
		check(restored and stage.platforms == surfaces and stage.environment.glow_enabled, stage.get_class() + " High restores presentation without changing collision planes")
		stage.free()
	# Inspect the actual scene graph/materials of the new maps, independently of
	# each stage's private quality-node and animated-material bookkeeping.
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f03_heavy_duty", "device": "CPU"}]
	for arena: String in ["verdant_shrine", "abyssal_observatory", "ember_foundry"]:
		app.settings.values.graphics = "High"
		app.start_match(slots, "Party", false, arena)
		app.world.countdown = 0
		for fighter: RiotFighter in app.world.fighters: fighter.provider = ScriptedInputProvider.new()
		for simulation_tick in 450: app.world.step()
		app._process(1.0 / 60.0) # Settle the camera/backdrop before pause snapshots.
		var stage: RooftopStage = app.world.stage
		var surfaces: Array[Dictionary] = stage.platforms.duplicate(true)
		var geometry: Array[Node] = stage.find_children("*", "GeometryInstance3D", true, false)
		var lights: Array[Node] = stage.find_children("*", "Light3D", true, false)
		var scene_nodes: Array[Node] = stage.find_children("*", "Node3D", true, false)
		var shaders: Array[ShaderMaterial] = []
		var clocks: Array[Dictionary] = []
		var quality_shaders: Array[ShaderMaterial] = []
		var node_states: Array[Dictionary] = []
		var geometry_states: Array[Dictionary] = []
		var light_states: Array[Dictionary] = []
		var high_units: int = 0
		var high_casters: int = 0
		var high_lights: int = 0
		for node: Node3D in scene_nodes:
			node_states.append({"node": node, "visible": node.visible, "transform": node.transform})
		for node: GeometryInstance3D in geometry:
			var units: int = 1
			var state: Dictionary = {"node": node, "shadow": node.cast_shadow, "override": node.material_override}
			var materials: Array[Material] = []
			if node is MeshInstance3D:
				for surface in node.mesh.get_surface_count(): materials.append(node.get_active_material(surface))
			elif node is MultiMeshInstance3D:
				state["instances"] = node.multimesh.visible_instance_count
				units = node.multimesh.instance_count if node.multimesh.visible_instance_count < 0 else node.multimesh.visible_instance_count
				materials.append(node.material_override)
				for surface in node.multimesh.mesh.get_surface_count(): materials.append(node.multimesh.mesh.surface_get_material(surface))
			geometry_states.append(state)
			if node.is_visible_in_tree():
				high_units += units
				if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: high_casters += 1
			for material: Material in materials:
				if material is ShaderMaterial and not shaders.has(material): shaders.append(material)
		for light: Light3D in lights:
			light_states.append({"node": light, "visible": light.visible, "shadow": light.shadow_enabled})
			if light.is_visible_in_tree(): high_lights += 1
		for material: ShaderMaterial in shaders:
			for uniform: Dictionary in material.shader.get_shader_uniform_list():
				if uniform.name in ["scene_time", "simulation_time"]:
					clocks.append({"material": material, "uniform": uniform.name, "value": float(material.get_shader_parameter(uniform.name))})
				elif uniform.name == "low_quality": quality_shaders.append(material)
		var clocks_advanced: bool = not clocks.is_empty()
		for clock: Dictionary in clocks: clocks_advanced = clocks_advanced and is_equal_approx(clock.value, stage.tick / 60.0) and clock.value > 0.0
		check(clocks_advanced, arena + " live shader clocks advance with actual match simulation", "%d attached shader clocks at tick %d" % [clocks.size(), stage.tick])
		stage.apply_quality("Low")
		var low_units: int = 0
		var low_casters: int = 0
		var low_lights: int = 0
		for node: GeometryInstance3D in geometry:
			if not node.is_visible_in_tree(): continue
			low_units += (node.multimesh.instance_count if node.multimesh.visible_instance_count < 0 else node.multimesh.visible_instance_count) if node is MultiMeshInstance3D else 1
			if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: low_casters += 1
		for light: Light3D in lights:
			if light.is_visible_in_tree(): low_lights += 1
		check(low_units > 0 and low_units < high_units, arena + " Low reduces actual visible scenery and batch instances", "High %d, Low %d drawable instances" % [high_units, low_units])
		check(low_lights < high_lights and low_casters < high_casters, arena + " Low reduces actual scene lights and shadow casters", "Lights %d→%d; casters %d→%d" % [high_lights, low_lights, high_casters, low_casters])
		var shaders_reduced: bool = not quality_shaders.is_empty()
		for material: ShaderMaterial in quality_shaders: shaders_reduced = shaders_reduced and material.get_shader_parameter("low_quality") == true
		check(shaders_reduced and not stage.environment.glow_enabled and not stage.environment.ssao_enabled and not stage.environment.ssil_enabled, arena + " Low selects reduced attached shaders and disables expensive postprocess")
		check(stage.platforms == surfaces and stage.hazard_phase == 1 and stage.hazard_warnings.any(func(node: MeshInstance3D) -> bool: return node.visible), arena + " Low retains collision and the live Party warning")
		stage.apply_quality("High")
		var graph_restored: bool = true
		for state: Dictionary in node_states: graph_restored = graph_restored and state.node.visible == state.visible and state.node.transform == state.transform
		for state: Dictionary in geometry_states:
			graph_restored = graph_restored and state.node.cast_shadow == state.shadow and state.node.material_override == state.override
			if state.has("instances"): graph_restored = graph_restored and state.node.multimesh.visible_instance_count == state.instances
		for state: Dictionary in light_states: graph_restored = graph_restored and state.node.visible == state.visible and state.node.shadow_enabled == state.shadow
		for material: ShaderMaterial in quality_shaders: graph_restored = graph_restored and material.get_shader_parameter("low_quality") == false
		check(graph_restored and stage.platforms == surfaces and stage.environment.glow_enabled, arena + " High restores exact scene visibility, materials, shadows and instance counts without moving collision")
		var paused_tick: int = app.world.tick
		var paused_stage_tick: int = stage.tick
		var paused_phase: int = stage.hazard_phase
		app.world.paused = true
		for fps: int in [30, 60, 144]:
			for frame in 12:
				app._physics_process(1.0 / 60.0)
				app._process(1.0 / fps)
			var frozen: bool = app.world.tick == paused_tick and stage.tick == paused_stage_tick and stage.platforms == surfaces and stage.hazard_phase == paused_phase
			for clock: Dictionary in clocks: frozen = frozen and float(clock.material.get_shader_parameter(clock.uniform)) == clock.value
			for state: Dictionary in node_states: frozen = frozen and state.node.transform == state.transform
			check(frozen, arena + " paused shader clocks, scenery transforms, lift and warning remain fixed at %d render FPS" % fps)
		app.world.paused = false
		app.world.step()
		var resumed: bool = app.world.tick == paused_tick + 1 and stage.tick == paused_stage_tick + 1
		for clock: Dictionary in clocks: resumed = resumed and float(clock.material.get_shader_parameter(clock.uniform)) > clock.value
		check(resumed, arena + " resuming advances every attached shader clock with the next combat tick")
		app.rematch()
		var reset_clocks: bool = app.world.tick == 0 and app.world.stage.tick == 0 and app.world.countdown > 0
		for clock: Dictionary in clocks: reset_clocks = reset_clocks and is_zero_approx(float(clock.material.get_shader_parameter(clock.uniform)))
		check(reset_clocks, arena + " rematch resets live shader clocks during countdown")
