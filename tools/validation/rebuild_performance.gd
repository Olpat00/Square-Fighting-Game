extends SceneTree
## Real-time profiling without movie encoding/readback inside the sample window.
var arena: String = "rooftop_riot"
var quality: String = "High"
var participants: int = 4
var duration: float = 60.0
var render_cap: int = 0
var output: String

func _initialize() -> void: run.call_deferred()

func summary(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {"available": false}
	var sorted := values.duplicate()
	sorted.sort()
	var sum: float = 0.0
	var over: int = 0
	for value: float in values:
		sum += value
		if value > 16.667: over += 1
	return {"available": sorted[-1] > 0.0, "count": values.size(), "mean_ms": sum / values.size(), "p95_ms": sorted[int((sorted.size() - 1) * 0.95)], "p99_ms": sorted[int((sorted.size() - 1) * 0.99)], "max_ms": sorted[-1], "over_16_667": over}

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("GPU performance requires a graphical run")
		quit(2)
		return
	output = ProjectSettings.globalize_path("res://../evidence/rebuild/performance")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--arena="): arena = arg.trim_prefix("--arena=")
		if arg.begins_with("--quality="): quality = arg.trim_prefix("--quality=")
		if arg.begins_with("--players="): participants = clampi(int(arg.trim_prefix("--players=")), 2, 4)
		if arg.begins_with("--seconds="): duration = float(arg.trim_prefix("--seconds="))
		if arg.begins_with("--render-cap="): render_cap = clampi(int(arg.trim_prefix("--render-cap=")), 0, 240)
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	var app: Node = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.settings.values.fullscreen = false
	app.settings.values.resolution = "1920x1080"
	app.settings.values.graphics = quality
	app.settings.values.ui_scale = 1.0
	app.apply_settings()
	var slots: Array[Dictionary] = []
	var ids: Array[String] = ["f01_clutch", "f03_heavy_duty", "f07_urban_sentinel", "f08_midnight_gentleman"]
	for i: int in participants: slots.append({"fighter": ids[i], "device": "CPU", "difficulty": "Normal"})
	app.start_match(slots, "Party", false, arena)
	app.world.countdown = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = render_cap
	var viewport: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	var warmup_start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - warmup_start < 3000000: await process_frame
	var intervals: Array[float] = []
	var cpu: Array[float] = []
	var gpu: Array[float] = []
	var physics: Array[float] = []
	var process: Array[float] = []
	var draws: float = 0.0
	var primitives: float = 0.0
	var memory: float = 0.0
	var completed_matches: Array[Dictionary] = []
	var active_fighter_samples: Dictionary = {}
	var simulation_ticks: int = 0
	var last_tick: int = app.world.tick
	var begin: int = Time.get_ticks_usec()
	var previous: int = begin
	while Time.get_ticks_usec() - begin < int(duration * 1000000.0):
		await process_frame
		var now: int = Time.get_ticks_usec()
		intervals.append((now - previous) / 1000.0)
		previous = now
		var alive: int = 0
		for fighter: RiotFighter in app.world.fighters:
			if fighter.stocks > 0: alive += 1
		active_fighter_samples[str(alive)] = int(active_fighter_samples.get(str(alive), 0)) + 1
		simulation_ticks += maxi(0, app.world.tick - last_tick)
		last_tick = app.world.tick
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport))
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		draws = maxf(draws, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives = maxf(primitives, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		memory = maxf(memory, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
		if not app.world.running:
			completed_matches.append(app.world.result.duplicate(true))
			app.rematch()
			app.world.countdown = 0
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = render_cap
			last_tick = 0
	var report: Dictionary = {
		"arena": arena, "quality": quality, "players": participants,
		"duration_seconds": (previous - begin) / 1000000.0, "warmup_seconds": 3,
		"renderer": RenderingServer.get_current_rendering_method(), "gpu_name": RenderingServer.get_video_adapter_name(),
		"engine": Engine.get_version_info().string, "window_pixels": str(DisplayServer.window_get_size()),
		"logical_viewport": str(root.get_visible_rect().size), "vsync": "disabled", "render_cap": render_cap,
		"frame_intervals": summary(intervals), "viewport_render_cpu": summary(cpu), "viewport_render_gpu": summary(gpu),
		"physics_callback": summary(physics), "process_callback": summary(process),
		"peak_draws": draws, "peak_primitives": primitives, "peak_vram_bytes": memory,
		"tick": app.world.tick, "contacts": app.world.resolver.contacts_resolved,
		"simulation_ticks_in_sample_window": simulation_ticks,
		"active_fighter_samples": active_fighter_samples, "completed_matches": completed_matches,
		"readback_inside_sample_window": false,
		"measurement_note": "Frame intervals are monotonic process-frame intervals. Viewport CPU/GPU uses RenderingServer measured render time; process/physics are engine callback monitors. These are separate overlapping measurements, not additive."
	}
	# The single screenshot happens only after every timing sample has been collected.
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	report.captured_pixels = str(shot.get_size())
	var name_value: String = "%s_%s_%dp" % [arena, quality.to_lower(), participants]
	shot.save_png(output.path_join(name_value + ".png"))
	FileAccess.open(output.path_join(name_value + ".json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("REBUILD_PERFORMANCE ", JSON.stringify(report))
	RenderingServer.viewport_set_measure_render_time(viewport, false)
	await app.shutdown(0)
