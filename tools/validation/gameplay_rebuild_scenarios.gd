extends SceneTree
## Behavior checks for the rebuild: combat input remains authoritative and tapes
## are ordinary inputs, not recorded transforms or privileged attack commands.

var world: MatchWorld
var a: RiotFighter
var b: RiotFighter
var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String, detail: String = "") -> void:
	checks.append({"name": label, "passed": condition, "detail": detail})
	if not condition:
		failures += 1
		print("FAIL ", label, " ", detail)

func pair(id: String = "f01_clutch", training: bool = false) -> void:
	var slots: Array[Dictionary] = [{"fighter": id, "device": "CPU"}, {"fighter": "f01_clutch", "device": "CPU"}]
	world.start(slots, "Fair Fight", training)
	world.countdown = 0
	a = world.fighters[0]
	b = world.fighters[1]
	a.provider = ScriptedInputProvider.new()
	if not training: b.provider = ScriptedInputProvider.new()
	a.snapshot = InputSnapshot.new()
	b.snapshot = InputSnapshot.new()
	a.position = Vector3(-3.5, 0, 0)
	b.position = Vector3(3.5, 0, 0)

func advance(ticks: int) -> void:
	for index in ticks: world.step()

func prepare_air(facing: int = 1) -> void:
	a.interrupt()
	a.position = Vector3(0, 7, 0)
	a.velocity = Vector3.ZERO
	a.grounded = false
	a.support_id = -1
	a.facing = facing
	a.snapshot = InputSnapshot.new()
	a.change_state("air")

func _run() -> void:
	world = MatchWorld.new()
	root.add_child(world)
	await process_frame
	await aerial_scenarios()
	await multihit_scenarios()
	await heavy_contact_scenarios()
	await transition_scenarios()
	await training_scenarios()
	await combo_scenarios()
	await cpu_scenarios()
	world.clear()
	await process_frame
	var report := {"checks": checks.size(), "failures": failures, "results": checks, "limitation": "Headless behavior validation; human feel, animation appearance and physical controls require separate review."}
	FileAccess.open(ProjectSettings.globalize_path("res://../evidence/gameplay_rebuild_scenarios.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("GAMEPLAY_REBUILD checks=", checks.size(), " failures=", failures)
	quit(0 if failures == 0 else 1)

func aerial_scenarios() -> void:
	for definition: FighterDefinition in RosterRegistry.discover():
		pair(definition.id)
		var steering_passed := true
		var authored_passed := true
		for facing: int in [-1, 1]:
			prepare_air(facing)
			a.start_move("air_neutral")
			a.snapshot.move.x = -facing
			a.tick()
			steering_passed = steering_passed and a.velocity.x * -facing > 0 and a.facing == facing and a.velocity.x < definition.air_speed
			prepare_air(facing)
			a.start_move("special_up")
			var segment: Dictionary = a.move.movement[0]
			a.move_tick = int(segment.from) - 1
			a.snapshot.move.x = -facing
			var expected: Dictionary = world.abilities.movement_for(a, a.move, a.move_tick + 1)
			a.tick()
			authored_passed = authored_passed and a.authored_motion_this_tick and is_equal_approx(a.velocity.x, float(expected.velocity.x) * facing)
			check(a.recovery_used and not a.can_start("special_up"), definition.id + " recovery remains finite facing " + str(facing))
		check(steering_passed, definition.id + " aerial input steers without reversing committed attack")
		check(authored_passed, definition.id + " mirrored recovery velocity wins over opposite air input")
		prepare_air()
		a.position = Vector3(0, 0.02, 0)
		a.velocity.y = -6
		a.start_move("air_neutral")
		var expected_lag: int = a.move.landing_lag
		a.tick()
		var elapsed: int = 0
		while a.state == "landing" and elapsed < 30:
			a.tick()
			elapsed += 1
		check(elapsed == expected_lag and a.move == null, definition.id + " landing retains authored aerial punish window", str(elapsed))
		prepare_air()
		a.position = Vector3(0, 0.02, 0)
		a.velocity.y = -6
		a.start_move("special_neutral")
		a.state = "attack" # Released charge, where applicable, before landing.
		a.tick()
		check(a.grounded and a.state == "attack" and a.visual.semantic_clip == "special_neutral", definition.id + " landing during special startup preserves its strike animation")
		check(definition.get_move("heavy_side").hitstop > definition.get_move("jab1").hitstop and definition.get_move("heavy_side").recovery > definition.get_move("jab1").recovery, definition.id + " heavy impact and recovery preserve commitment")
		world.clear()
		await process_frame
	pair("f08_midnight_gentleman")
	prepare_air()
	a.start_move("special_side")
	a.move_tick = a.move.startup - 1
	a.snapshot.move.x = 1
	a.tick()
	check(a.position.x > 0 and is_zero_approx(a.velocity.x), "Shadowstep teleport retains its authored stop on activation")
	await process_frame
	pair("f03_heavy_duty")
	prepare_air()
	a.position = Vector3(0, 0.02, 0)
	a.velocity.y = -6
	a.start_move("special_down")
	a.move_tick = a.move.startup - 1
	a.tick()
	check(a.grounded and a.visual.semantic_clip == "land_hard" and world.abilities.owned_count(a, "ring") > 0, "Heavy stomp preserves its explicit landing reaction and shockwave")
	await process_frame

func multihit_scenarios() -> void:
	for facing: int in [-1, 1]:
		for fixture_data: Dictionary in [{"shielding": false, "tracking": false}, {"shielding": true, "tracking": false}, {"shielding": false, "tracking": true}]:
			var shielding: bool = fixture_data.shielding
			pair("f05_fine_print")
			a.position = Vector3(-0.4 * facing, 0, 0)
			b.position = Vector3(0.2 * facing, 0, 0)
			a.facing = facing
			a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "move": Vector2(0, 1), "actions": ["special"]}])
			if shielding: b.provider = ScriptedInputProvider.new([{"from": 0, "to": 200, "actions": ["defend"]}])
			var contacts: Array[int] = []
			var on_contact := func(event: String, actor: int, _at: Vector3, _details: Dictionary) -> void:
				if (event == "shield" and actor == 1) or (event == "hit" and actor == 0): contacts.append(a.move_tick)
			world.presentation_event.connect(on_contact)
			for tick: int in 90:
				if fixture_data.tracking:
					# Keep a target in range to isolate rehit timing from the natural
					# launch; the real actor clock, contacts and hitstop still run.
					b.position = a.position + Vector3(0.6 * facing, 0.55, 0)
					b.grounded = false
					b.support_id = -1
				world.step()
			world.presentation_event.disconnect(on_contact)
			var unique_ticks: Dictionary = {}
			for contact_tick: int in contacts: unique_ticks[contact_tick] = true
			var fixture: String = "Corporate Ladder %s facing %d" % ["tracked target" if fixture_data.tracking else "shield" if shielding else "damage", facing]
			check(not contacts.is_empty() and contacts.size() <= 3 and contacts.size() == unique_ticks.size(), fixture + " never repeats a frozen active frame", str(contacts))
			check(a.move_tick >= 24, fixture + " exits its active windows despite seven-tick hitstop", str(a.move_tick))
			if fixture_data.tracking:
				check(contacts == [8, 14, 20], fixture + " retains one hit in each authored kick window", str(contacts))
			world.clear()
			await process_frame

func heavy_contact_scenarios() -> void:
	for facing: int in [-1, 1]:
		pair("f05_fine_print")
		a.position = Vector3.ZERO
		a.facing = facing
		b.position = Vector3(8 * facing, 0, 0)
		a.provider = ScriptedInputProvider.new([{"from": 30, "to": 30, "actions": ["heavy"]}])
		var active := false
		for tick: int in 120:
			world.step()
			if a.move != null and a.state == "attack" and a.move.is_active(a.move_tick):
				active = true
				break
		var fixture: String = "Final Ruling facing %d" % facing
		check(active and a.move.id == "heavy_side", fixture + " reaches first contact through a normal heavy press and release")
		if active:
			# Compare the authored circle with the imported striking wrist in
			# gameplay's XY plane. Bones remain inspection evidence, not collision.
			var rig: Skeleton3D = a.visual.foot_plant.rig
			var hand: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone("hand.L")).origin
			var hand_distance: float = a.attack_center().distance_to(Vector2(hand.x, hand.y))
			check(hand_distance <= a.move.hit_radius, fixture + " authored contact covers the striking hand", "distance=%.3f radius=%.3f" % [hand_distance, a.move.hit_radius])
			b.position = Vector3(hand.x, 0, 0)
			check(world.resolver.collect(world.fighters).size() == 1, fixture + " reaches an opponent at its visible fist")
			# The previous center could hit this standing target despite the
			# short punch. Moving the center inward must remove that phantom reach.
			b.position = Vector3(2.2 * facing, 0, 0)
			check(world.resolver.collect(world.fighters).is_empty() and a.move.hit_offset.x + a.move.hit_radius < 1.99, fixture + " no longer reaches the old distant contact region")
		world.clear()
		await process_frame

func transition_scenarios() -> void:
	pair()
	a.locomotion_clip = "idle"
	a.snapshot.move.x = 1
	a.tick()
	check(a.visual.semantic_clip == "move_start" and a.locomotion_transition == 9, "Locomotion start uses the ten-tick presentation profile")
	a.buffered.light = 6
	a.tick()
	check(a.state == "attack" and a.locomotion_transition == 0, "Attack immediately interrupts visual movement start")
	world.training_reset()
	a.locomotion_clip = "idle"
	a.snapshot.move.x = 1
	a.tick()
	a.snapshot.move.x = -1
	a.tick()
	a.tick()
	check(a.visual.semantic_clip == "turnaround" and a.facing == -1, "A fast reversal interrupts the start transition")
	for hard: bool in [false, true]:
		prepare_air()
		a.position = Vector3(0, 0.02, 0)
		a.velocity.y = -11 if hard else -3
		a.tick()
		var duration: int = 0
		while a.state == "landing" and duration < 20:
			a.tick()
			duration += 1
		check(duration == (5 if hard else 3), "Free landing ends after %s ticks" % (5 if hard else 3), str(duration))
	await process_frame

func training_scenarios() -> void:
	pair("f01_clutch", true)
	var dummy: TrainingInputProvider = world.training_dummy()
	a.provider = ScriptedInputProvider.new([
		{"from": 0, "to": 8, "move": Vector2(-1, 0)},
		{"from": 2, "to": 3, "actions": ["light"]},
		{"from": 15, "to": 18, "actions": ["jump"]}])
	world.training_toggle_recording()
	var recorded: Array[Dictionary] = []
	var one_neutral := true
	for index in 32:
		world.step()
		recorded.append(_snapshot_data(b.snapshot))
		one_neutral = one_neutral and a.position.is_equal_approx(Vector3(-3.5, 0, 0)) and a.state == "idle"
	world.training_toggle_recording()
	check(one_neutral and dummy.tape.size() == 32 and b.position.x < 3.5, "F6 sends live controls to P2 while keeping P1 neutral")
	a.provider = ScriptedInputProvider.new()
	world.training_toggle_playback()
	var replayed: Array[Dictionary] = []
	var first_positions: Array[Vector3] = []
	for index in 32:
		world.step()
		replayed.append(_snapshot_data(b.snapshot))
		first_positions.append(b.position)
	check(recorded == replayed, "Replay reproduces movement, held buttons and press/release edges")
	var before_cursor: int = dummy.cursor
	world.paused = true
	world.reset_inputs()
	advance(20)
	world.paused = false
	check(dummy.cursor == before_cursor, "Pause freezes tape without rewinding its playhead")
	advance(45)
	check(dummy.loop_ready, "Replay has a 45-tick neutral gap")
	var loop_positions: Array[Vector3] = []
	for index in 32:
		world.step()
		loop_positions.append(b.position)
	check(loop_positions == first_positions and world.tick == 32, "Loop resets simulation state before replaying the same positions")
	var stock_cursor: int = dummy.cursor
	b.lose_stock()
	check(dummy.cursor == stock_cursor and dummy.tape_mode == "playing", "Stock loss does not rewind or discard the playing tape")
	b.recent_moves.assign(["jab1", "jab1"])
	b.ledge_lock = 90
	b.shield_delay = 90
	world.training_reset()
	check(b.recent_moves.is_empty() and b.ledge_lock == 0 and b.shield_delay == 0 and dummy.cursor == 0, "Explicit reset removes stale damage and transient stock state")
	world.training_toggle_playback()
	dummy.begin_recording()
	a.snapshot = InputSnapshot.new()
	for index in 605: dummy.sample(b, world)
	check(dummy.tape.size() == 600 and dummy.tape_mode == "idle", "Recording stops at ten seconds without growing its tape")
	dummy.begin_playback()
	world.training_cycle_dummy()
	check(dummy.tape_mode == "idle" and dummy.dummy_mode == "defending" and dummy.tape.size() == 600, "Dummy mode changes stop replay while preserving the saved tape")
	a.provider = HumanInputProvider.new(-1)
	world.training_toggle_recording()
	var key := InputEventKey.new()
	key.physical_keycode = int(HumanInputProvider.get_keyboard_bindings().light)
	key.pressed = true
	world.route_input(key)
	key.pressed = false
	world.route_input(key)
	world.step()
	check(b.snapshot.was_pressed("light") and b.snapshot.was_released("light") and not b.snapshot.is_down("light") and b.state == "attack", "Recording preserves a complete native tap between simulation ticks")
	world.training_toggle_recording()
	world.training_toggle_playback()
	world.step()
	check(b.snapshot.was_pressed("light") and b.snapshot.was_released("light") and b.state == "attack", "Playback preserves same-tick tap edges through normal action buffering")
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 8, "move": Vector2.RIGHT}])
	world.training_toggle_recording()
	advance(9)
	a.provider = ScriptedInputProvider.new([
		{"from": 0, "to": 6, "move": Vector2.LEFT},
		{"from": 2, "to": 3, "actions": ["light"]}])
	world.training_reset() # The F1 path while a recording is active.
	check(dummy.tape_mode == "recording" and dummy.tape.is_empty() and dummy.cursor == 0 and b.position == Vector3(3.5, 0, 0), "F1 during recording starts a fresh take at the reset positions")
	var fresh_inputs: Array[Dictionary] = []
	var fresh_positions: Array[Vector3] = []
	for index in 12:
		world.step()
		fresh_inputs.append(_snapshot_data(b.snapshot))
		fresh_positions.append(b.position)
	a.provider = ScriptedInputProvider.new()
	world.training_toggle_playback() # F7 directly from recording, without F6.
	check(dummy.tape_mode == "playing" and dummy.tape.size() == 12 and dummy.cursor == 0, "F7 saves a live recording before the playback reset")
	var fresh_replay_inputs: Array[Dictionary] = []
	var fresh_replay_positions: Array[Vector3] = []
	for index in 12:
		world.step()
		fresh_replay_inputs.append(_snapshot_data(b.snapshot))
		fresh_replay_positions.append(b.position)
	check(fresh_inputs == fresh_replay_inputs and fresh_positions == fresh_replay_positions, "An F1-restarted take replays exact input edges and positions without the discarded pre-reset frames")
	world.training_reset()
	check(dummy.tape_mode == "playing" and dummy.tape.size() == 12 and dummy.cursor == 0, "F1 during playback rewinds and preserves the saved tape")
	await process_frame

func _snapshot_data(snapshot: InputSnapshot) -> Dictionary:
	return {"move": snapshot.move, "held": snapshot.held.duplicate(), "pressed": snapshot.pressed.duplicate(), "released": snapshot.released.duplicate()}

func hit(move_id: String = "jab1") -> void:
	a.position = Vector3(-0.6, 0, 0)
	b.position = Vector3(0.6, 0, 0)
	a.grounded = true
	b.grounded = true
	a.facing = 1
	a.start_move(move_id)
	a.state = "attack"
	a.move_tick = a.move.startup
	world.resolver.resolve(world.resolver.collect(world.fighters))

func combo_scenarios() -> void:
	pair("f01_clutch", true)
	hit()
	advance(a.hitstop)
	hit("jab2")
	check(world.training_combo_hits == 2 and is_equal_approx(world.training_combo_damage, b.damage), "Combo damage comes from actual resolved contacts")
	a.hitstop = 0
	b.hitstop = 0
	b.stun = 0
	a.interrupt()
	a.change_state("idle")
	b.change_state("idle")
	a.position.x = -6
	world.step()
	hit()
	check(world.training_combo_hits == 1 and world.training_combo_damage < a.move.damage, "An actionable gap starts a new combo and reports stale damage")
	world.training_reset()
	hit()
	var fresh_damage: float = b.damage
	world.training_reset()
	hit()
	check(is_equal_approx(fresh_damage, b.damage), "Repeated training reset restores the same unstaled damage")
	world.training_reset()
	b.state = "shield"
	b.shield_start_tick = -100
	hit()
	check(world.training_combo_hits == 0, "Blocked contacts never count as a damage combo")
	await process_frame

func cpu_scenarios() -> void:
	for definition: FighterDefinition in RosterRegistry.discover():
		pair(definition.id)
		var cpu := CpuInputProvider.new("Hard", 81)
		var decisive := {"mistake": 0.0, "defend": 1.0, "special": 0.0}
		a.position = Vector3(-0.5, 0, 0)
		b.position = Vector3(0.6, 0, 0)
		b.start_move("heavy_side")
		b.state = "attack"
		b.move_tick = b.move.total_ticks() - 5
		cpu._decide(a, world, decisive)
		check(cpu.intent == "punish" and cpu._presses.has("light") and not cpu._hold_ticks.has("defend"), definition.id + " CPU punishes visible recovery")
		cpu.reset()
		a.start_move("jab1")
		a.confirmed_hit = true
		cpu._decide(a, world, decisive)
		check(cpu.intent == "confirm" and cpu._presses.has("light"), definition.id + " CPU follows up a confirmed jab")
		cpu.reset()
		a.confirmed_hit = false
		b.position.x = 6
		b.change_state("idle")
		cpu._decide(a, world, decisive)
		check(cpu.intent != "confirm", definition.id + " CPU never treats a whiff as a confirmed jab")
		cpu.reset()
		a.position = Vector3(11, -1.5, 0)
		a.grounded = false
		a.air_jumps = 0
		a.recovery_used = false
		a.velocity.y = -4
		cpu._decide(a, world, decisive)
		check(cpu.intent == "recover" and cpu._move.x < 0 and cpu._move.y > 0 and cpu._presses.has("special"), definition.id + " CPU prioritizes finite offstage recovery")
		world.clear()
		await process_frame
