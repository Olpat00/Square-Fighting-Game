extends Node3D

var settings := SettingsStore.new()
var world: MatchWorld
var ui: GameUI
var audio: AudioDirector
var effects: EffectsDirector
var camera: Camera3D
var match_camera := MatchCamera.new()
var player_labels: PlayerLabels
var debug_hitboxes: bool = false
var smoke_mode: bool = false
var smoke_limit: int = 900
var render_frames: int = 0
var frame_times: Array[float] = []
var screenshot_path: String = ""
var smoke_started: bool = false
var screenshot_frame: int = 240
var evidence_root: String = ""
var peak_draw_calls: float = 0
var peak_primitives: float = 0
var peak_video_memory: float = 0
var smoke_wall_start: int = 0
var screenshot_tick: int = -1
var screenshot_taken: bool = false
var profile_mode: bool = false
var frame_spikes: Array[Dictionary] = []
var last_capture_render_frame: int = -100
var last_process_usec: int = 0
var sample_start_usec: int = 0
var sample_end_usec: int = 0
var closing: bool = false

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	get_tree().auto_accept_quit = false
	settings.load_settings()
	HumanInputProvider.load_keyboard_bindings()
	world = MatchWorld.new()
	add_child(world)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.0
	camera.position = Vector3(0, 10, 32)
	add_child(camera)
	camera.look_at(Vector3(0, 2.5, -2))
	camera.far = 1000
	audio = AudioDirector.new()
	add_child(audio)
	audio.configure(settings)
	effects = EffectsDirector.new()
	add_child(effects)
	effects.configure(settings, world)
	world.presentation_event.connect(audio.on_event)
	world.presentation_event.connect(effects.on_event)
	world.presentation_event.connect(_on_event)
	world.match_finished.connect(_on_finished)
	ui = GameUI.new()
	add_child(ui)
	ui.configure(self)
	player_labels = PlayerLabels.new()
	ui.root.add_child(player_labels)
	ui.root.move_child(player_labels, 0)
	ui.show_title()
	var debug_overlay: Control = preload("res://presentation/debug_overlay.gd").new()
	debug_overlay.app = self
	ui.root.add_child(debug_overlay)
	Input.joy_connection_changed.connect(_on_joy_connection)
	apply_settings()
	evidence_root = ProjectSettings.globalize_path("res://../evidence")
	var args := OS.get_cmdline_user_args()
	var requested_arena: String = ""
	for arg in args:
		if arg == "--smoke": smoke_mode = true
		elif arg == "--profile": profile_mode = true
		elif arg.begins_with("--frames="): smoke_limit = int(arg.get_slice("=", 1))
		elif arg.begins_with("--screenshot="): screenshot_path = arg.trim_prefix("--screenshot=")
		elif arg.begins_with("--capture-frame="): screenshot_frame = int(arg.get_slice("=", 1))
		elif arg.begins_with("--capture-tick="): screenshot_tick = int(arg.get_slice("=", 1))
		elif arg.begins_with("--evidence-root="): evidence_root = arg.trim_prefix("--evidence-root=")
		elif arg.begins_with("--arena="): requested_arena = arg.trim_prefix("--arena=")
	if StageCatalog.IDS.has(requested_arena):
		preview_arena(requested_arena)
		ui.selected_stage_id = requested_arena
		ui.show_title()
	if profile_mode:
		settings.values.graphics = "High"
		settings.values.resolution = "1920x1080"
		settings.values.fullscreen = false
		settings.values.ui_scale = 1.0
		apply_settings() # Reproducible in-memory profile; never overwrites user settings.
	if smoke_mode:
		smoke_wall_start = Time.get_ticks_msec()
		var slots: Array[Dictionary] = []
		var roster := RosterRegistry.discover()
		roster = roster.filter(func(f: FighterDefinition) -> bool: return ResourceLoader.exists(f.model_path))
		var selected: Dictionary = {}
		for id: String in ["f06_rugged_explorer", "f07_urban_sentinel", "f08_midnight_gentleman", "f01_clutch"]:
			for definition: FighterDefinition in roster:
				if definition.id == id and not selected.has(id):
					slots.append({"fighter": id, "device": "CPU", "difficulty": "Normal"})
					selected[id] = true
		for definition: FighterDefinition in roster:
			if slots.size() >= 4: break
			if not selected.has(definition.id):
				slots.append({"fighter": definition.id, "device": "CPU", "difficulty": "Normal"})
				selected[definition.id] = true
		start_match(slots, "Party", false)
		world.countdown = 0
	print("ROOFTOP_READY renderer=", RenderingServer.get_current_rendering_method(), " GPU=", RenderingServer.get_video_adapter_name())

func preview_arena(arena_id: String) -> void:
	if world.running or not world.fighters.is_empty(): return
	world.select_stage(arena_id)
	apply_settings()

func start_match(slots: Array[Dictionary], preset: String, training_mode: bool, arena_id: String = "") -> void:
	effects.clear_effects()
	world.start(slots, preset, training_mode, 4261, arena_id)
	apply_settings()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0, 12.1, 32)
	camera.rotation_degrees = Vector3(-17, 0, 0)
	camera.size = 23.5
	match_camera.reset()
	ui.show_hud()

func rematch() -> void:
	var slots: Array[Dictionary] = world.config.duplicate(true)
	start_match(slots, world.stage.preset, world.training, world.stage_id)

func resume_match() -> void:
	world.reset_inputs()
	world.paused = false
	ui.clear_screen("match")
	ui.screen.mouse_filter = Control.MOUSE_FILTER_IGNORE

func leave_match() -> void:
	effects.clear_effects()
	world.clear()
	if ui.hud: ui.hud.visible = false

func apply_settings() -> void:
	if DisplayServer.get_name() != "headless": settings.apply_display()
	world.graphics_quality = str(settings.values.graphics)
	get_window().content_scale_factor = 1.0
	ui.apply_scale()
	audio.apply_volume()
	world.stage.apply_quality(str(settings.values.graphics))

func _physics_process(_delta: float) -> void:
	world.step()
	if smoke_mode and world.tick >= smoke_limit:
		_save_smoke_report()
		smoke_mode = false
		_finish_smoke.call_deferred()

func _process(delta: float) -> void:
	var process_usec := Time.get_ticks_usec()
	var wall_frame_ms := (process_usec - last_process_usec) / 1000.0 if last_process_usec > 0 else 0.0
	var previous_process_usec := last_process_usec
	last_process_usec = process_usec
	render_frames += 1
	if smoke_mode and previous_process_usec > 0 and Time.get_ticks_msec() - smoke_wall_start >= 2000 and frame_times.size() < 250000:
		if frame_times.is_empty(): sample_start_usec = previous_process_usec
		sample_end_usec = process_usec
		# Engine delta can be smoothed/corrected for simulation. Profile elapsed
		# monotonic time between callbacks without altering presentation delta.
		frame_times.append(wall_frame_ms)
		if wall_frame_ms > 16.667 and frame_spikes.size() < 100:
			frame_spikes.append({"tick": world.tick, "render_frame": render_frames, "ms": wall_frame_ms, "capture_on_previous_frame": render_frames - last_capture_render_frame <= 1})
		peak_draw_calls = maxf(peak_draw_calls, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		peak_primitives = maxf(peak_primitives, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		peak_video_memory = maxf(peak_video_memory, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	effects.update(delta if not world.paused else 0)
	audio.update_mix(delta, world.paused)
	ui.update_hud()
	_update_camera(delta)
	_update_player_labels()
	if not screenshot_taken and not screenshot_path.is_empty() and (world.tick >= screenshot_tick if screenshot_tick >= 0 else render_frames == screenshot_frame):
		screenshot_taken = true
		capture.call_deferred(screenshot_path)
	if not world.running and not world.fighters.is_empty():
		for fighter in world.fighters:
			fighter.visual.step_result(delta)

func _update_camera(delta: float) -> void:
	if world.fighters.is_empty():
		# A fixed architectural view for menus. Ordinary combat immediately uses
		# the stable side-on orthographic camera below, never this angled view.
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 38
		var arena_view := StageCatalog.info(world.stage_id)
		camera.position = arena_view.camera
		camera.look_at(arena_view.focus)
		camera.h_offset = -4.0
		camera.v_offset = 0
		world.stage.frame_horizon(camera)
		match_camera.reset()
		return
	if not world.running and not world.result.is_empty():
		match_camera.present_results(camera)
		world.stage.frame_horizon(camera)
		return
	var points: Array[Vector3] = []
	for fighter in world.fighters:
		if fighter.stocks <= 0 or fighter.state in ["ko", "eliminated"]: continue
		var point: Vector3 = fighter.position
		# A small look-ahead helps launches/recoveries stay in view without making
		# neutral footwork drag the camera in every input direction.
		if absf(fighter.velocity.x) > 7.0: point.x += clampf(fighter.velocity.x * 0.08, -0.8, 0.8)
		points.append(point)
	# Tall arenas keep their upper route visible during a wide multiplayer
	# exchange. Duels still use close fighter framing and track jumps normally.
	if world.fighters.size() >= 3 and StageCatalog.info(world.stage_id).get("frame_crown", false):
		var crown: Dictionary = world.stage.support(3)
		points.append(Vector3(float(crown.x), float(crown.y) - 1.5, 0))
	match_camera.update(camera, points, world.fighters.size(), delta, world.paused, effects.impulse, float(settings.values.shake))
	world.stage.frame_horizon(camera)

func _update_player_labels() -> void:
	if player_labels:
		player_labels.update_labels(world.fighters, camera, world.running and ui.screen_name in ["match", "pause"])

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var absolute := path if path.is_absolute_path() else evidence_root.path_join(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := get_viewport().get_texture().get_image().save_png(absolute)
	last_capture_render_frame = render_frames
	print("CAPTURE ", absolute, " result=", error)

func _input(event: InputEvent) -> void:
	if ui and ui.capture_remap(event): return
	if world:
		world.route_input(event)
		var host_pause: bool = event is InputEventKey and event.pressed and not event.echo and HumanInputProvider.event_keycode(event) == int(HumanInputProvider.get_keyboard_bindings().pause)
		var assigned_pad_pause: bool = false
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
			for fighter in world.fighters:
				if fighter.provider is HumanInputProvider and fighter.provider.device_id == event.device: assigned_pad_pause = true
		if world.running and world.paused and (host_pause or assigned_pad_pause):
			resume_match()
		elif world.running and host_pause:
			var keyboard_owned: bool = false
			for fighter in world.fighters:
				if fighter.provider is HumanInputProvider and fighter.provider.device_id < 0: keyboard_owned = true
			if not keyboard_owned:
				world.paused = true
				world.reset_inputs()
				ui.show_pause()
		elif world.running and world.training and not world.paused and world.fighters.size() >= 2 and event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_F1: world.training_reset()
				KEY_F2:
					for fighter in world.fighters: fighter.damage = 0
				KEY_F3:
					world.training_cycle_dummy()
				KEY_F4: debug_hitboxes = not debug_hitboxes
				KEY_F5:
					for fighter in world.fighters: fighter.ultimate_meter = 100
				KEY_F6: world.training_toggle_recording()
				KEY_F7: world.training_toggle_playback()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(world):
		world.reset_inputs()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST and not closing:
		shutdown.call_deferred()

func _on_event(event: String, actor: int, _at: Vector3, details: Dictionary) -> void:
	if event == "pause": ui.show_pause()
	if event == "ko":
		world.stage.react(1.0)
		ui.feedback("P%d %s%s" % [actor + 1, StageCatalog.info(world.stage_id).ko, " · OH, SHIT." if settings.values.profanity else ""])
	elif event == "taunt" and actor >= 0:
		var fighter: RiotFighter = world.fighters[actor]
		var line: String = fighter.definition.taunts[0 if fighter.taunt_alternate else 1] if fighter.definition.taunts.size() >= 2 else "No supervision. No refunds."
		ui.feedback("%s: %s" % [fighter.definition.display_name, line])
	elif event == "meter_ready":
		ui.feedback("P%d · ULTIMATE READY" % (actor + 1))
	elif event == "sudden_death":
		ui.feedback(str(details.get("text", "SUDDEN DEATH")), 2600)
	elif event == "parry": ui.feedback("PERFECT PARRY", 600)
	if event == "hit" and actor >= 0 and settings.values.rumble > 0:
		var provider: InputProvider = world.fighters[actor].provider
		if provider is HumanInputProvider and provider.device_id >= 0:
			Input.start_joy_vibration(provider.device_id, 0.15 * settings.values.rumble, 0.3 * settings.values.rumble, 0.10)
	if event == "hit" and details.get("heavy", false):
		world.stage.react(0.5)

func _on_finished(result: Dictionary) -> void:
	audio.play_sound("victory", -3)
	ui.show_results(result)
	if smoke_mode:
		_save_smoke_report()
		smoke_mode = false
		_finish_smoke.call_deferred()

func _finish_smoke() -> void:
	await shutdown()

func shutdown(exit_code: int = 0) -> void:
	if closing: return
	closing = true
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	world.clear()
	audio.stop_all()
	ui.queue_free()
	world.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(exit_code)

func _on_joy_connection(device: int, connected: bool) -> void:
	if closing: return
	if ui.screen_name == "setup": ui.show_setup(ui.setup_training)
	if not connected and world.running:
		for fighter in world.fighters:
			if fighter.provider is HumanInputProvider and fighter.provider.device_id == device:
				world.paused = true
				world.reset_inputs()
				ui.show_pause("CONTROLLER DISCONNECTED")

func _save_smoke_report() -> void:
	DirAccess.make_dir_recursive_absolute(evidence_root)
	var average: float = 0
	for ms in frame_times: average += ms
	average /= maxf(1, frame_times.size())
	frame_times.sort()
	var path := evidence_root.path_join("smoke_runtime.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	var rows: Array[Dictionary] = []
	for fighter in world.fighters: rows.append({"id": fighter.definition.id, "input_provider": fighter.provider.get_script().resource_path, "damage": fighter.damage, "stocks": fighter.stocks, "state": fighter.state, "position": str(fighter.position)})
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(), "logical_viewport": str(get_viewport().get_visible_rect().size), "window_pixels": str(DisplayServer.window_get_size()), "render_texture_pixels": str(get_viewport().get_texture().get_size()), "ticks": world.tick, "render_frames": render_frames, "mean_frame_ms": average, "p95_frame_ms": frame_times[int(frame_times.size() * 0.95)] if not frame_times.is_empty() else 0, "contacts": world.resolver.contacts_resolved, "kos": world.ko_log, "fighters": rows, "objects": world.abilities.objects.size(), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "memory_static": Performance.get_monitor(Performance.MEMORY_STATIC)}
	report["arena"] = world.stage_id
	if DisplayServer.get_name() != "headless":
		report["captured_pixel_size"] = str(get_viewport().get_texture().get_image().get_size())
	report["sample_count"] = frame_times.size()
	report["sample_clock"] = "Time.get_ticks_usec between process callbacks; unsmoothed wall time"
	report["sample_window_ms"] = (sample_end_usec - sample_start_usec) / 1000.0
	report["sample_sum_ms"] = average * frame_times.size()
	report["frame_spikes"] = frame_spikes
	report["warmup_seconds"] = 2
	report["profile_mode"] = profile_mode
	report["settings"] = settings.values.duplicate(true)
	report["p99_frame_ms"] = frame_times[int(frame_times.size() * 0.99)] if not frame_times.is_empty() else 0
	report["worst_frame_ms"] = frame_times[-1] if not frame_times.is_empty() else 0
	var missed_budget: int = 0
	for ms in frame_times:
		if ms > 16.667: missed_budget += 1
	report["frames_over_16_667ms"] = missed_budget
	report["wall_seconds"] = (Time.get_ticks_msec() - smoke_wall_start) / 1000.0
	report["peak_draw_calls"] = peak_draw_calls
	report["peak_primitives"] = peak_primitives
	report["peak_video_memory_bytes"] = peak_video_memory
	report["connected_controllers"] = Array(Input.get_connected_joypads())
	file.store_string(JSON.stringify(report, "  "))
	print("SMOKE_REPORT ", JSON.stringify(report))
