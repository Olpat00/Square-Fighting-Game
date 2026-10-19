extends SceneTree
## Deterministic gameplay-view evidence for living scenery, separate from profiling.
## Stills: all five arenas, both tiers, 0/2/5/10 seconds, pause and reset.
## Movie: one --arena/--quality, --movie, engine --write-movie <name.avi>
## and --fixed-fps 60. The engine writes frames; this script never reads back
## individual movie frames. Inspect clips/stills before judging visual quality.

const SAMPLE_TICKS: Array[int] = [0, 120, 300, 600]
const MOVIE_TICKS: int = 720
const SEED: int = 4261

var app: Node3D
var output: String
var arenas: Array[String] = StageCatalog.IDS.duplicate()
var qualities: Array[String] = ["High", "Low"]
var movie: bool = false
var movie_path: String = ""
var movie_fps: int = 0
var rendered_frames: int = 0
var checks: Array[Dictionary] = []
var cases: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var failures: int = 0
var requested_arena: bool = false
var requested_quality: bool = false
var camera_transform: Transform3D
var camera_size: float
var shader_time_usage: Dictionary = {}

func _initialize() -> void:
	RenderingServer.frame_post_draw.connect(_on_draw)
	_run.call_deferred()

func _on_draw() -> void:
	rendered_frames += 1

func _check(condition: bool, label: String, details: Dictionary = {}) -> void:
	checks.append({"name": label, "passed": condition, "details": details})
	if not condition:
		failures += 1
		print("LIVING_BACKGROUND_FAIL ", label)

func _run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/background_rebuild/review")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		elif argument.begins_with("--arena="):
			arenas.assign([argument.trim_prefix("--arena=")])
			requested_arena = true
		elif argument.begins_with("--quality="):
			qualities.assign([argument.trim_prefix("--quality=")])
			requested_quality = true
		elif argument == "--movie": movie = true
	# Movie options are consumed by startup and are absent from OS arguments.
	# Query the writer itself; the runner also checks the actual encoded FPS.
	movie_path = Engine.get_write_movie_path()
	movie_fps = int(ProjectSettings.get_setting("editor/movie_writer/fps", 60))
	DirAccess.make_dir_recursive_absolute(output)
	_check(DisplayServer.get_name() != "headless", "A graphical renderer is required")
	for arena: String in arenas: _check(StageCatalog.IDS.has(arena), "Known arena " + arena)
	for quality: String in qualities: _check(quality in ["High", "Low"], "Known graphics tier " + quality)
	if movie:
		_check(requested_arena and requested_quality and arenas.size() == 1 and qualities.size() == 1, "Movie selects exactly one arena and tier")
		_check(movie_path.to_lower().ends_with(".avi") and movie_fps == 60, "Movie uses engine AVI writer at fixed 60 FPS", {"path": movie_path, "fixed_fps": movie_fps})
	if failures:
		_write_report()
		quit(2)
		return
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	# All simulation is explicitly scheduled by this harness. The ordinary main
	# callbacks cannot inject extra physics ticks or camera/effect updates.
	app.set_process(false)
	app.set_physics_process(false)
	app.set_process_input(false)
	app.settings.values.resolution = "1920x1080"
	app.settings.values.fullscreen = false
	app.settings.values.ui_scale = 1.0
	app.settings.values.shake = 0.0
	app.evidence_root = output
	var slots: Array[Dictionary] = [
		{"fighter": "f01_clutch", "device": "CPU"}, {"fighter": "f03_heavy_duty", "device": "CPU"},
		{"fighter": "f06_rugged_explorer", "device": "CPU"}, {"fighter": "f08_midnight_gentleman", "device": "CPU"}]
	for arena: String in arenas:
		for quality: String in qualities:
			app.settings.values.graphics = quality
			app.start_match(slots, "Fair Fight", false, arena)
			app.world.countdown = 0
			for fighter: RiotFighter in app.world.fighters: fighter.provider = ScriptedInputProvider.new()
			_stationary_fighters()
			app.match_camera.reset()
			app._update_camera(1.0 / 60.0)
			camera_transform = app.camera.transform
			camera_size = app.camera.size
			_update_presentation()
			if movie:
				await _movie_case(arena, quality)
			else:
				await _still_case(arena, quality)
	_write_report()
	print("LIVING_BACKGROUND_REVIEW checks=", checks.size(), " failures=", failures, " captures=", captures.size(), " movie=", movie)
	await app.shutdown(1 if failures else 0)

func _stationary_fighters() -> void:
	for i: int in app.world.fighters.size():
		var fighter: RiotFighter = app.world.fighters[i]
		fighter.position = Vector3(-5.4 + i * 3.6, 0.0, 0.0)
		fighter.velocity = Vector3.ZERO
		fighter.grounded = true
		fighter.support_id = 0

func _update_presentation() -> void:
	# Use the normal gameplay framing once, then hold it for comparable views.
	app.camera.transform = camera_transform
	app.camera.size = camera_size
	app.camera.h_offset = 0.0
	app.camera.v_offset = 0.0
	app.world.stage.frame_horizon(app.camera)
	app._update_player_labels()
	app.ui.update_hud()

func _advance(ticks: int) -> void:
	for i: int in ticks: app.world.step()
	_stationary_fighters()
	_update_presentation()

func _still_case(arena: String, quality: String) -> void:
	var prefix: String = arena + "_" + quality.to_lower()
	var initial: Dictionary = _snapshot()
	var initial_platforms: Array = app.world.stage.platforms.duplicate(true)
	var bounds: Vector2 = app.world.stage.main_bounds()
	var row: Dictionary = {"arena": arena, "quality": quality, "samples": [], "motion": []}
	_check(app.world.fighters.size() == 4 and app.world.stage.preset == "Fair Fight", prefix + " has four idle fighters under Fair Fight")
	_check(not initial.clocks.is_empty(), prefix + " exposes stage-owned scenery clocks")
	var previous: Dictionary = initial
	for tick: int in SAMPLE_TICKS:
		_advance(tick - app.world.tick)
		await _frames(5)
		var state: Dictionary = _snapshot()
		_check(app.world.tick == tick and app.world.stage.tick == tick, prefix + " clocks reach tick " + str(tick))
		_check(_clocks_follow_time(state, tick / 60.0), prefix + " material clocks follow simulation at tick " + str(tick))
		_check(app.world.stage.platforms == initial_platforms and app.world.stage.main_bounds() == bounds and app.world.stage.hazard_phase == 0, prefix + " collision/layout and disabled hazards stay fixed at tick " + str(tick))
		_check(state.collision_probes == initial.collision_probes, prefix + " support, drop-through and swept-side responses remain stable at tick " + str(tick))
		_check(state.engine_time_shaders.is_empty(), prefix + " visible scenery avoids unpaused engine TIME at tick " + str(tick), {"shaders": state.engine_time_shaders})
		var sample: Dictionary = await _capture(prefix + "_t%04d" % tick, arena, quality, "motion_sample", state)
		row.samples.append(sample)
		if tick > 0:
			var motion: Dictionary = _motion(previous, state)
			_check(motion.visible_pose_changes > 0 or motion.visible_clock_changes > 0, prefix + " retains visible motion sources through tick " + str(tick), motion)
			row.motion.append(motion)
		previous = state
	var current: Dictionary = _snapshot()
	app.world.paused = true
	var pause_tick: int = app.world.tick
	var pause_before: Dictionary = await _capture(prefix + "_paused_a", arena, quality, "paused_before", current)
	# This interval renders ten frames with no world.step calls. No pixels are
	# compared automatically: unrelated render noise is not a motion verdict.
	await _frames(10)
	var paused: Dictionary = _snapshot()
	var pause_after: Dictionary = await _capture(prefix + "_paused_b", arena, quality, "paused_after_ten_render_frames", paused)
	_check(paused == current and app.world.tick == pause_tick and app.world.stage.tick == pause_tick, prefix + " pause freezes tracked scenery through ten render frames")
	# Verify the authoritative pause guard independently from the no-step view.
	for i: int in 60: app.world.step()
	_check(_snapshot() == current and app.world.tick == pause_tick, prefix + " paused world rejects sixty requested simulation steps")
	app.world.paused = false
	app.world.stage.apply_quality("Low" if quality == "High" else "High")
	var other_quality: Dictionary = _snapshot()
	app.world.stage.apply_quality(quality)
	var restored: Dictionary = _snapshot()
	_check(restored == current, prefix + " graphics roundtrip restores poses, uniforms, visibility and detail counts")
	_check(other_quality.platforms == current.platforms, prefix + " quality changes preserve collision data")
	app.world.stage.reset_match(SEED)
	app.world.tick = 0
	_stationary_fighters()
	_update_presentation()
	await _frames(5)
	var reset_state: Dictionary = _snapshot()
	_check(reset_state == initial, prefix + " match reset restores initial scenery poses, clocks and quality")
	var reset_capture: Dictionary = await _capture(prefix + "_reset", arena, quality, "reset_to_original_seed", reset_state)
	row["pause"] = {"before": pause_before, "after": pause_after, "render_frames_without_steps": 10}
	row["reset"] = reset_capture
	row["initial_state"] = _write_state(prefix + "_initial", initial)
	row["final_state"] = _write_state(prefix + "_final", current)
	cases.append(row)

func _movie_case(arena: String, quality: String) -> void:
	var prefix: String = arena + "_" + quality.to_lower()
	var initial: Dictionary = _snapshot()
	var before_frames: int = rendered_frames
	var initial_platforms: Array = app.world.stage.platforms.duplicate(true)
	var samples: Array[Dictionary] = [{"tick": 0, "seconds": 0.0, "state": _write_state(prefix + "_movie_t0000", initial)}]
	_check(_clocks_follow_time(initial, 0.0), prefix + " movie starts from reset scenery clock")
	for tick: int in MOVIE_TICKS:
		app.world.step()
		_stationary_fighters()
		_update_presentation()
		await process_frame
		if app.world.tick in [120, 300, 600, 720]:
			var state: Dictionary = _snapshot()
			_check(_clocks_follow_time(state, app.world.tick / 60.0), prefix + " movie clocks follow tick " + str(app.world.tick))
			samples.append({"tick": app.world.tick, "seconds": app.world.tick / 60.0, "state": _write_state(prefix + "_movie_t%04d" % app.world.tick, state)})
	await RenderingServer.frame_post_draw
	var final_state: Dictionary = _snapshot()
	_check(app.world.tick == MOVIE_TICKS and app.world.stage.tick == MOVIE_TICKS, prefix + " movie advances exactly 720 combat ticks")
	_check(final_state.platforms == initial_platforms and final_state.engine_time_shaders.is_empty(), prefix + " movie preserves Fair Fight geometry and clock-owned background")
	var motion: Dictionary = _motion(initial, final_state)
	_check(motion.visible_pose_changes > 0 or motion.visible_clock_changes > 0, prefix + " movie has visible motion sources", motion)
	cases.append({"arena": arena, "quality": quality, "movie_path": movie_path, "movie_writer_fps": movie_fps, "simulation_ticks": MOVIE_TICKS, "simulation_seconds": MOVIE_TICKS / 60.0, "bootstrap_draw_frames": before_frames, "scenery_draw_frames": rendered_frames - before_frames, "draw_frames_at_completion": rendered_frames, "samples": samples, "motion": motion, "resolution": _vector2i(root.size), "frame_readbacks_during_movie": 0})

func _frames(count: int) -> void:
	for i: int in count: await process_frame

func _capture(name_value: String, arena: String, quality: String, purpose: String, state: Dictionary) -> Dictionary:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output.path_join(name_value + ".png")
	var result: Error = image.save_png(path)
	var row: Dictionary = {"file": path, "arena": arena, "quality": quality, "purpose": purpose, "tick": app.world.tick, "stage_tick": app.world.stage.tick, "seconds": app.world.stage.tick / 60.0, "width": image.get_width(), "height": image.get_height(), "window_size": _vector2i(DisplayServer.window_get_size()), "saved": result == OK, "sha256": FileAccess.get_sha256(path) if result == OK else "", "state": _write_state(name_value, state), "camera_height": camera_size, "render_frame": rendered_frames, "visual_review": "pending_human_or_image_inspection"}
	_check(result == OK and image.get_width() == 1920 and image.get_height() == 1080 and DisplayServer.window_get_size() == Vector2i(1920, 1080), name_value + " saves a 1920x1080 gameplay view")
	captures.append(row)
	print("LIVING_BACKGROUND_CAPTURE ", name_value, " tick=", app.world.stage.tick, " result=", result)
	return row

func _snapshot() -> Dictionary:
	var state: Dictionary = {"stage_tick": app.world.stage.tick, "quality": app.world.stage.graphics_quality, "platforms": app.world.stage.platforms.duplicate(true), "collision_probes": _collision_probes(), "nodes": {}, "materials": {}, "clocks": {}, "engine_time_shaders": []}
	_collect(app.world.stage, state)
	# Stage-owned material registries include temporarily inactive Low/High
	# alternatives. Inspect their clocks too, without counting them as visible.
	for property: Dictionary in app.world.stage.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_collect_owned_materials(app.world.stage.get(str(property.name)), "owned/" + str(property.name), state, 0)
	if app.world.stage.environment:
		var env: Environment = app.world.stage.environment
		state["environment"] = {"ssao": env.ssao_enabled, "ssil": env.ssil_enabled, "ssr": env.ssr_enabled, "glow": env.glow_enabled, "fog": env.fog_enabled, "fog_density": env.fog_density}
	return state

func _collision_probes() -> Array[Dictionary]:
	# Exercise the stage's public pure collision interface at its authored planes.
	# Compare responses across animation/quality changes; existing combat suites
	# separately establish collision correctness and moving-platform behavior.
	var samples: Array[Dictionary] = []
	for platform: Dictionary in app.world.stage.platforms:
		var at := Vector3(float(platform.x), float(platform.y), 0.0)
		var id: int = int(platform.id)
		samples.append(_probe("fall_%d" % id, at + Vector3.UP * 0.35, at + Vector3.DOWN * 0.35, -12.0, -1, -1))
		samples.append(_probe("support_%d" % id, at, at + Vector3(0.10, -0.10, 0.0), -6.0, -1, id))
		samples.append(_probe("ignore_%d" % id, at + Vector3.UP * 0.35, at + Vector3.DOWN * 0.35, -12.0, id, -1))
	var edges: Vector2 = app.world.stage.main_bounds()
	for side: int in [-1, 1]:
		var edge: float = edges.x if side < 0 else edges.y
		var previous := Vector3(edge + side * 1.3, -0.4, 0.0)
		var desired := Vector3(edge - side * 1.3, -0.4, 0.0)
		samples.append(_probe("swept_side_%d" % side, previous, desired, 0.0, -1, -1))
	return samples

func _probe(label: String, previous: Vector3, desired: Vector3, speed: float, ignore: int, supported: int) -> Dictionary:
	var result: Dictionary = app.world.stage.solve_motion(previous, desired, speed, ignore, supported)
	var position: Vector3 = result.position
	return {"name": label, "position": [position.x, position.y, position.z], "landed": result.landed, "platform": result.platform}

func _collect(node: Node, state: Dictionary) -> void:
	var path: String = str(app.world.stage.get_path_to(node))
	if node is Node3D:
		var row: Dictionary = {"transform": _transform(node.transform), "visible": node.visible, "visible_in_tree": node.is_visible_in_tree()}
		if node is GeometryInstance3D: row["shadow"] = node.cast_shadow
		if node is Light3D:
			row["light"] = {"energy": node.light_energy, "color": str(node.light_color), "shadow": node.shadow_enabled}
		if node is MultiMeshInstance3D and node.multimesh:
			var multimesh: MultiMesh = node.multimesh
			var poses: Array = []
			var visible_count: int = multimesh.instance_count if multimesh.visible_instance_count < 0 else multimesh.visible_instance_count
			if bool(row.visible_in_tree):
				for i: int in visible_count: poses.append(_transform(multimesh.get_instance_transform(i)))
			row["instances"] = multimesh.instance_count
			row["visible_instances"] = multimesh.visible_instance_count
			row["instance_transforms"] = poses
			_collect_material(node.material_override, path + "/material", bool(row.visible_in_tree), state)
		elif node is MeshInstance3D and node.mesh:
			row["surfaces"] = node.mesh.get_surface_count()
			for i: int in node.mesh.get_surface_count(): _collect_material(node.get_active_material(i), path + "/surface%d" % i, bool(row.visible_in_tree), state)
		state.nodes[path] = row
	for child: Node in node.get_children(): _collect(child, state)

func _collect_owned_materials(value: Variant, path: String, state: Dictionary, depth: int) -> void:
	if depth > 4: return
	if value is Material:
		_collect_material(value, path, false, state)
	elif value is Array:
		for i: int in value.size(): _collect_owned_materials(value[i], path + "/" + str(i), state, depth + 1)
	elif value is Dictionary:
		for key: Variant in value: _collect_owned_materials(value[key], path + "/" + str(key), state, depth + 1)

func _collect_material(material: Material, path: String, visible: bool, state: Dictionary) -> void:
	if material == null: return
	var row: Dictionary = {"class": material.get_class(), "visible": visible}
	if material is ShaderMaterial and material.shader:
		row["shader"] = material.shader.resource_path
		var uniforms: Dictionary = {}
		for uniform: Dictionary in material.shader.get_shader_uniform_list():
			var uniform_name: String = str(uniform.name)
			if uniform_name.ends_with("_time") or uniform_name in ["blue_hour", "low_quality"]:
				var value: Variant = material.get_shader_parameter(uniform_name)
				if value == null: value = RenderingServer.shader_get_parameter_default(material.shader.get_rid(), uniform_name)
				uniforms[uniform_name] = value
				if uniform_name.ends_with("_time") or uniform_name == "blue_hour": state.clocks[path + "/" + uniform_name] = {"value": value, "name": uniform_name, "visible": visible, "shader": material.shader.resource_path}
		row["uniforms"] = uniforms
		if visible and _uses_engine_time(material.shader.code) and not state.engine_time_shaders.has(material.shader.resource_path): state.engine_time_shaders.append(material.shader.resource_path)
	elif material is StandardMaterial3D:
		row["emission"] = str(material.emission)
		row["emission_energy"] = material.emission_energy_multiplier
	state.materials[path] = row

func _uses_engine_time(source: String) -> bool:
	if shader_time_usage.has(source): return bool(shader_time_usage[source])
	var expression := RegEx.new()
	expression.compile("\\bTIME\\b")
	var block_comment := RegEx.new()
	block_comment.compile("(?s)/\\*.*?\\*/")
	var code: String = block_comment.sub(source, "", true)
	for line: String in code.split("\n"):
		if expression.search(line.split("//")[0]) != null:
			shader_time_usage[source] = true
			return true
	shader_time_usage[source] = false
	return false

func _clocks_follow_time(state: Dictionary, seconds: float) -> bool:
	var count: int = 0
	for clock: Dictionary in state.clocks.values():
		if clock.name == "blue_hour": continue
		if not clock.value is float and not clock.value is int: return false
		if not is_equal_approx(float(clock.value), seconds): return false
		count += 1
	return count > 0

func _motion(before: Dictionary, after: Dictionary) -> Dictionary:
	var changed_poses: Array[String] = []
	var changed_clocks: Array[String] = []
	for path: String in after.nodes:
		if not before.nodes.has(path): continue
		var old: Dictionary = before.nodes[path]
		var current: Dictionary = after.nodes[path]
		if not bool(current.visible_in_tree): continue
		if current.transform != old.transform or current.get("instance_transforms", []) != old.get("instance_transforms", []) or current.get("light", {}) != old.get("light", {}): changed_poses.append(path)
	for path: String in after.clocks:
		if not before.clocks.has(path): continue
		var current: Dictionary = after.clocks[path]
		if bool(current.visible) and current.value != before.clocks[path].value: changed_clocks.append(path)
	return {"from_tick": before.stage_tick, "to_tick": after.stage_tick, "visible_pose_changes": changed_poses.size(), "visible_clock_changes": changed_clocks.size(), "changed_pose_paths": changed_poses, "changed_clock_paths": changed_clocks, "visual_judgement": "Not inferred from state or image hashes; inspect captured motion."}

func _write_state(name_value: String, state: Dictionary) -> Dictionary:
	var path: String = output.path_join(name_value + "_state.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "Writes scenery state " + name_value)
		return {"path": path, "saved": false}
	file.store_string(JSON.stringify(state, "  "))
	file.close()
	return {"path": path, "saved": true, "sha256": FileAccess.get_sha256(path)}

func _transform(value: Transform3D) -> Array[float]:
	return [value.basis.x.x, value.basis.x.y, value.basis.x.z, value.basis.y.x, value.basis.y.y, value.basis.y.z, value.basis.z.x, value.basis.z.y, value.basis.z.z, value.origin.x, value.origin.y, value.origin.z]

func _vector2i(value: Vector2i) -> Array[int]:
	return [value.x, value.y]

func _write_report() -> void:
	var path: String = output.path_join("living_background_review.json")
	var source_path: String = get_script().resource_path
	var report: Dictionary = {"passed": failures == 0, "checks": checks.size(), "failures": failures, "results": checks, "cases": cases, "captures": captures, "movie": movie, "arenas": arenas, "qualities": qualities, "harness_sha256": FileAccess.get_sha256(source_path), "renderer": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(), "settings_saved": false, "visual_review": "pending_human_or_image_inspection", "limitations": ["Deterministic stationary-player presentation fixtures, not performance measurements or human gameplay/controller testing.", "State checks prove scene clock ownership, pause/reset and graphics restoration, not aesthetic quality or visibility at gameplay distance.", "Pause image equality is reviewed separately; image hashes are identities, not a visual-motion verdict.", "Movie writer may include setup/shutdown frames; bootstrap and captured draw-frame counts are recorded for editorial trimming."]}
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
