extends SceneTree
## Continuous genuine runtime input sequence; also usable against the preserved baseline.
var app: Node
var fighter_id: String = "f01_clutch"
var arena: String = "rooftop_riot"
var output: String
var frames: int = 720
var mirror: bool = false

func _initialize() -> void: run.call_deferred()

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/rebuild/motion")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--fighter="): fighter_id = arg.trim_prefix("--fighter=")
		if arg.begins_with("--arena="): arena = arg.trim_prefix("--arena=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg == "--mirror": mirror = true
	DirAccess.make_dir_recursive_absolute(output)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_physics_process(false)
	app.set_process(false)
	app.settings.values.fullscreen = false
	app.settings.values.resolution = "1920x1080"
	app.settings.values.graphics = "High"
	app.settings.values.shake = 0.25
	app.apply_settings()
	var slots: Array[Dictionary] = [{"fighter": fighter_id, "device": "CPU"}, {"fighter": "f03_heavy_duty" if fighter_id != "f03_heavy_duty" else "f01_clutch", "device": "CPU"}]
	app.start_match(slots, "Fair Fight", false, arena)
	var world: MatchWorld = app.world
	world.countdown = 0
	var actor: RiotFighter = world.fighters[0]
	var target: RiotFighter = world.fighters[1]
	actor.position.x = -4.5
	target.position.x = 2.2
	actor.ultimate_meter = 100
	var sequence: Array[Dictionary] = [
		{"from": 35, "to": 59, "move": Vector2.RIGHT},
		{"from": 65, "to": 88, "move": Vector2.LEFT},
		{"from": 100, "to": 127, "move": Vector2.RIGHT},
		{"from": 132, "to": 138, "actions": ["jump"]},
		{"from": 143, "to": 156, "move": Vector2.RIGHT},
		{"from": 230, "to": 230, "actions": ["light"]},
		{"from": 237, "to": 237, "actions": ["light"]},
		{"from": 247, "to": 247, "actions": ["light"]},
		{"from": 295, "to": 312, "actions": ["heavy"]},
		{"from": 380, "to": 380, "actions": ["special"]},
		{"from": 445, "to": 450, "actions": ["defend"]},
		{"from": 475, "to": 475, "actions": ["grab"]},
		{"from": 486, "to": 486, "move": Vector2.UP},
		{"from": 550, "to": 550, "actions": ["ultimate"]}
	]
	if mirror:
		actor.position.x *= -1
		target.position.x *= -1
		actor.facing = -1
		target.facing = 1
		for input: Dictionary in sequence:
			if input.has("move"): input.move.x *= -1
	actor.provider = ScriptedInputProvider.new(sequence)
	target.provider = ScriptedInputProvider.new()
	var trace: Array[Dictionary] = []
	for tick: int in frames:
		# Reset only between separate review phrases; each action uses ordinary input.
		if tick in [215, 285, 370, 465, 540]:
			for f: RiotFighter in world.fighters:
				f.interrupt()
				f.position = Vector3(-0.7 if f.slot == 0 else 0.7, 0, 0)
				if mirror: f.position.x *= -1
				f.velocity = Vector3.ZERO
				f.grounded = true
				f.support_id = 0
				f.stun = 0
				f.hitstop = 0
				f.invulnerability = 0
				f.change_state("idle")
				f.facing = 1 if f.slot == 0 else -1
				if mirror: f.facing *= -1
			actor.ultimate_meter = 100
		world.step()
		app._process(1.0 / 60.0)
		if tick % 10 == 0: trace.append({"tick": tick, "state": actor.state, "position": str(actor.position), "move": actor.move.id if actor.move != null else "", "move_tick": actor.move_tick})
		await process_frame
		if tick in [30, 120, 240, 321, 390, 570]:
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png(output.path_join("%s_%03d.png" % [fighter_id, tick]))
	FileAccess.open(output.path_join(fighter_id + "_trace.json"), FileAccess.WRITE).store_string(JSON.stringify({"fighter": fighter_id, "arena": arena, "mirrored": mirror, "ticks": frames, "fixture_resets": [215,285,370,465,540], "trace": trace}, "  "))
	await app.shutdown(0)
