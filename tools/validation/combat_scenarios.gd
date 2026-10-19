extends SceneTree

var world: MatchWorld
var checks: Array[Dictionary] = []
var failures: int = 0
var a: RiotFighter
var b: RiotFighter

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, name_value: String, detail: String = "") -> void:
	checks.append({"name": name_value, "passed": condition, "detail": detail})
	if not condition:
		failures += 1
		print("FAIL ", name_value, " ", detail)

func reset_pair(id_a: String = "f01_clutch", id_b: String = "f01_clutch") -> void:
	var slots: Array[Dictionary] = [{"fighter": id_a, "device": "CPU"}, {"fighter": id_b, "device": "CPU"}]
	world.start(slots, "Fair Fight")
	world.countdown = 0
	a = world.fighters[0]
	b = world.fighters[1]
	a.provider = ScriptedInputProvider.new()
	b.provider = ScriptedInputProvider.new()
	a.position = Vector3(-0.6, 0, 0)
	b.position = Vector3(0.6, 0, 0)
	a.facing = 1
	b.facing = -1
	a.snapshot = InputSnapshot.new()
	b.snapshot = InputSnapshot.new()

func advance(ticks: int) -> void:
	for i in ticks: world.step()

func ready_attack(f: RiotFighter, id: String) -> void:
	f.start_move(id)
	f.state = "attack"
	f.move_tick = f.move.startup

func _run() -> void:
	world = MatchWorld.new()
	root.add_child(world)
	await process_frame
	reset_pair()
	check(Engine.physics_ticks_per_second == 60, "60 Hz simulation")
	check(not CombatTuning.beyond_blast(Vector3(17.9, 0, 0)) and CombatTuning.beyond_blast(Vector3(18.1, 0, 0)), "Fixed horizontal blast boundary")
	check(CombatTuning.knockback(5, 0.1, 120, 1) > CombatTuning.knockback(5, 0.1, 0, 1), "Damage raises knockback")
	check(CombatTuning.knockback(5, 0.1, 80, 1.2) < CombatTuning.knockback(5, 0.1, 80, 0.8), "Weight lowers knockback")
	var solved := world.stage.solve_motion(Vector3(-5, 4, 0), Vector3(-5, 3, 0), -8, -1, -1)
	check(solved.landed and solved.platform == 1 and is_equal_approx(solved.position.y, 3.6), "One-way platform descending crossing")
	solved = world.stage.solve_motion(Vector3(-5, 3, 0), Vector3(-5, 4, 0), 8, -1, -1)
	check(not solved.landed and is_equal_approx(solved.position.y, 4), "One-way platform upward pass")
	solved = world.stage.solve_motion(Vector3(-5, 3.6, 0), Vector3(-5, -0.2, 0), -20, 1, -1)
	check(solved.landed and solved.platform == 0, "Drop-through ignores selected platform only")
	solved = world.stage.solve_motion(Vector3(-10, -0.5, 0), Vector3(1, -0.5, 0), 0, -1, -1)
	check(solved.position.x <= -9.2, "Swept dash cannot tunnel deck wall")
	world.stage.preset = "Party"
	world.stage.tick = 500
	world.stage.step()
	solved = world.stage.solve_motion(Vector3(0, world.stage.platforms[3].previous_y, 0), Vector3(0, 4, 0), 0, -1, 3)
	check(solved.landed and is_equal_approx(solved.position.y, world.stage.platforms[3].y), "Moving support carries fighter")
	world.stage.preset = "Fair Fight"
	for i in 600:
		world.stage.step()
		if not world.stage.hazard_contacts(world.fighters).is_empty(): failures += 1
	check(world.stage.hazard_phase == 0 and is_equal_approx(world.stage.platforms[3].y, 5.5), "Fair Fight disables damaging hazards and lift motion")
	ready_attack(a, "jab1")
	a.move_tick = a.move.startup - 1
	check(world.resolver.collect(world.fighters).is_empty(), "No hit during startup")
	a.move_tick = a.move.startup
	var contacts := world.resolver.collect(world.fighters)
	check(contacts.size() == 1, "First active frame collects contact")
	world.resolver.resolve(contacts)
	var first_damage: float = b.damage
	world.resolver.resolve(world.resolver.collect(world.fighters))
	check(first_damage > 0 and is_equal_approx(b.damage, first_damage), "One hit per attack instance and target")
	check(a.ultimate_meter > 0 and a.mechanics.pips == 1, "Legitimate hit awards capped meter and momentum")
	await process_frame
	reset_pair()
	ready_attack(a, "jab1")
	ready_attack(b, "jab1")
	contacts = world.resolver.collect(world.fighters)
	world.resolver.resolve(contacts)
	check(a.damage > 0 and b.damage > 0, "Simultaneous active attacks trade")
	await process_frame
	reset_pair()
	b.state = "shield"
	b.shield_start_tick = -100
	ready_attack(a, "jab1")
	world.resolver.resolve(world.resolver.collect(world.fighters))
	check(b.damage == 0 and b.shield < 100 and a.mechanics.pips == 0 and a.ultimate_meter == 0, "Shield absorbs damage without meter/passive farming")
	await process_frame
	reset_pair()
	b.state = "shield"
	b.shield_start_tick = world.tick
	ready_attack(a, "jab1")
	world.resolver.resolve(world.resolver.collect(world.fighters))
	check(b.damage == 0 and a.stun > 0, "Parry window interrupts striker")
	await process_frame
	reset_pair()
	b.state = "dodge"
	b.state_ticks = 5
	ready_attack(a, "jab1")
	world.resolver.resolve(world.resolver.collect(world.fighters))
	check(b.damage == 0, "Dodge active invulnerability")
	b.state_ticks = 20
	world.resolver.resolve(world.resolver.collect(world.fighters))
	check(b.damage > 0, "Dodge recovery is vulnerable")
	await process_frame
	reset_pair()
	ready_attack(a, "grab")
	b.state = "shield"
	world.resolver.resolve(world.resolver.collect(world.fighters))
	check(a.capture_target == b and b.captured_by == a, "Grab beats shield and creates paired capture")
	a.interrupt()
	check(a.capture_target == null and b.captured_by == null, "Interruption releases captured target")
	await process_frame
	reset_pair()
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 18, "actions": ["jump"]}])
	var full_apex: float = 0
	for i in 80:
		world.step()
		full_apex = maxf(full_apex, a.position.y)
	check(full_apex > 3.4 and full_apex < 4.1, "Full jump reaches intended apex", str(full_apex))
	await process_frame
	reset_pair()
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 2, "actions": ["jump"]}])
	var short_apex: float = 0
	for i in 70:
		world.step()
		short_apex = maxf(short_apex, a.position.y)
	check(short_apex < full_apex * 0.7, "Jump release produces short hop", str(short_apex))
	await process_frame
	reset_pair()
	a.position = Vector3(12, 1, 0)
	a.grounded = false
	a.support_id = -1
	a.air_jumps = 0
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 1, "move": Vector2(0, 1), "actions": ["special"]}, {"from": 65, "to": 67, "move": Vector2(0, 1), "actions": ["special"]}])
	advance(62)
	check(a.recovery_used and a.helpless, "Recovery spends airborne resource and ends helpless")
	var attack_before: int = a.attack_instance
	advance(7)
	check(a.attack_instance == attack_before, "Second recovery rejected without landing")
	await process_frame
	reset_pair()
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 1, "move": Vector2(0, 1), "actions": ["special"]}])
	advance(15)
	check(a.recovery_used and a.position.y > 0.1, "Grounded recovery startup cannot reset air resource")
	await process_frame
	reset_pair()
	a.ultimate_meter = 100
	a.position = Vector3(-8, 0, 0)
	b.position = Vector3(8, 0, 0)
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 1, "actions": ["ultimate"]}])
	advance(75)
	check(a.ultimate_meter == 0 and b.damage == 0, "Whiffed ultimate costs meter and can miss")
	check(a.mechanics.pips == 0 and a.ultimate_meter == 0, "Idle/whiff actions cannot farm passive or meter")
	await process_frame
	reset_pair()
	a.damage = 350
	advance(2)
	check(a.stocks == 3, "High damage never removes a stock by itself")
	a.position.x = 19
	advance(1)
	check(a.stocks == 2 and a.state == "ko", "Blast crossing loses exactly one stock")
	advance(110)
	check(a.damage == 0 and a.stocks == 2 and a.invulnerability > 0, "Respawn resets damage and grants temporary protection")
	await process_frame
	reset_pair()
	a.stocks = 1
	b.stocks = 1
	a.position.x = -19
	b.position.x = 19
	advance(1)
	check(world.sudden_death and a.stocks == 1 and b.stocks == 1, "Simultaneous last-stock KO enters announced sudden death")
	await process_frame
	reset_pair()
	a.damage = 50
	b.damage = 80
	world.time_left = 1
	advance(1)
	check(not world.running and world.result.winner == a.slot, "Timeout ranks equal stocks by lower damage")
	await process_frame
	reset_pair()
	world.time_left = 1
	advance(1)
	check(world.sudden_death and a.damage == 200 and b.damage == 200, "Exact timeout tie creates tied-only sudden death")
	await process_frame
	reset_pair()
	a.mechanics.pips = 3
	a.damage = 60
	check(b.mechanics.pips == 0 and b.damage == 0, "Mirror fighters have independent state")
	world.paused = true
	var tick_before: int = world.tick
	advance(30)
	check(world.tick == tick_before, "Pause freezes authoritative simulation")
	world.paused = false
	advance(1)
	check(world.tick == tick_before + 1, "Resume advances simulation")
	await process_frame
	reset_pair()
	a.grounded = false
	check(not a.can_start("grab"), "Ground-only grab cannot start in the air")
	await process_frame
	reset_pair()
	ready_attack(a, "grab")
	ready_attack(b, "jab1")
	contacts = world.resolver.collect(world.fighters)
	contacts.reverse()
	world.resolver.resolve(contacts)
	check(a.damage > 0 and a.capture_target == null and b.captured_by == null, "Strike defeats simultaneous grab regardless of contact order")
	await process_frame
	reset_pair()
	ready_attack(a, "jab1")
	var projectile: Dictionary = world.resolver.from_move(a, b, a.definition.get_move("special_neutral"))
	projectile.instance = world.next_attack_id()
	projectile.kind = "projectile"
	world.resolver.resolve([projectile])
	check(not a.confirmed_hit and not a.hit_registry.has(b.slot), "Independent projectile cannot confirm or suppress current melee")
	await process_frame
	reset_pair()
	b.provider = ScriptedInputProvider.new([{"from": 0, "to": 100, "actions": ["defend"]}])
	b.state = "shield_stun"
	b.shield_start_tick = -100
	b.stun = 1
	advance(1)
	check(b.state == "shield", "Held shield resumes after shield stun")
	await process_frame
	reset_pair()
	ready_attack(a, "special_up")
	a.move_tick = a.move.total_ticks() - 1
	a.grounded = true
	a.support_id = 1
	a.position = Vector3(-5, 3.6, 0)
	advance(1)
	check(not a.helpless and a.can_start("jab1"), "Recovery ending after platform landing does not lock actions")
	await locomotion_and_getup_scenarios()
	await movement_resource_scenarios()
	await attribution_and_influence_scenarios()
	await hazard_warning_scenarios()
	var report := {"engine": Engine.get_version_info().string, "checks": checks.size(), "failures": failures, "results": checks}
	var path := ProjectSettings.globalize_path("res://../evidence/combat_scenarios.json")
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("COMBAT_SCENARIOS ", checks.size(), " checks; ", failures, " failures")
	world.clear()
	world.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)

func locomotion_and_getup_scenarios() -> void:
	await process_frame
	reset_pair()
	b.position.x = 7
	advance(1)
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 40, "move": Vector2.RIGHT}])
	var before_x: float = a.position.x
	advance(1)
	check(a.position.x > before_x and a.velocity.x > 0 and a.visual.current_clip.ends_with("move_start"), "Move-start animation begins with immediate authoritative movement")
	advance(a.visual.presentation_profile.transition_duration("move_start", 10))
	check(a.visual.current_clip.ends_with("run") or a.visual.current_clip.ends_with("walk"), "Move-start presentation yields to normal locomotion")
	var before_velocity: float = a.velocity.x
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 40, "move": Vector2.LEFT}])
	advance(1)
	check(a.facing == -1 and a.velocity.x < before_velocity and a.visual.current_clip.ends_with("turnaround"), "Turnaround changes facing and acceleration immediately")
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["light"]}])
	advance(1)
	check(a.state == "attack" and a.move.id == "jab1" and a.attack_instance > 0, "Attack input interrupts turnaround presentation without extra delay")
	await process_frame
	reset_pair()
	b.position.x = 7
	advance(1)
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 18, "move": Vector2.RIGHT}])
	advance(19)
	var stop_seen: bool = false
	for tick in 30:
		advance(1)
		if a.visual.current_clip.ends_with("move_stop"):
			stop_seen = true
			break
	check(stop_seen and a.state == "idle", "Deceleration selects the authored move-stop presentation")
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["jump"]}])
	var before_y: float = a.position.y
	advance(1)
	check(not a.grounded and a.velocity.y > 0 and a.position.y > before_y, "Jump input starts immediately during move-stop presentation")
	for cause in ["ground_impact", "shield_break"]:
		await process_frame
		reset_pair()
		b.position.x = 7
		if cause == "ground_impact":
			a.position = Vector3(0, 0.01, 0)
			a.grounded = false
			a.support_id = -1
			a.velocity.y = -3
			a.stun = 3
			a.change_state("hitstun")
			advance(1)
			check(a.grounded and a.knocked_down and a.visual.current_clip.ends_with("knockdown"), "Descending hitstun creates a grounded knockdown")
			advance(2)
		else:
			a.break_shield()
			advance(120)
		check(a.state == "getup" and a.visual.current_clip.ends_with("getup") and a.vulnerable(), "%s ends in vulnerable authored getup" % cause)
		advance(11)
		check(a.state == "getup", "%s getup does not end before twelve ticks" % cause)
		advance(1)
		check(a.state == "idle" and not a.knocked_down, "%s getup ends at twelve ticks" % cause)
		a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["light"]}])
		advance(1)
		check(a.state == "attack" and a.move.id == "jab1", "%s permits normal attacks after getup" % cause)
	await process_frame
	reset_pair()
	a.break_shield()
	advance(120)
	ready_attack(b, "jab1")
	advance(1)
	check(a.damage > 0 and a.state == "hitstun", "A real melee contact can punish getup recovery")
	for speed in [-2.0, -12.0]:
		await process_frame
		reset_pair()
		a.position = Vector3(0, 0.01, 0)
		a.grounded = false
		a.support_id = -1
		a.velocity.y = speed
		a.change_state("air")
		advance(1)
		var duration: int = CombatTuning.HARD_LANDING_TICKS if speed < -9 else CombatTuning.SOFT_LANDING_TICKS
		var clip: String = "land_hard" if speed < -9 else "land_soft"
		check(a.state == "landing" and a.landing_ticks == duration and a.visual.current_clip.ends_with(clip), "%s chooses its authored landing duration" % clip)
		advance(duration - 1)
		check(a.state == "landing", "%s remains committed until its final recovery tick" % clip)
		advance(1)
		check(a.state == "idle", "%s ends at the declared recovery boundary" % clip)

func movement_resource_scenarios() -> void:
	# Exercise the actual fixed-step/input route, including both outer ledges.
	for side in [-1, 1]:
		await process_frame
		reset_pair()
		b.position.x = 0
		a.position = Vector3(side * 9.5, -0.5, 0)
		a.grounded = false
		a.support_id = -1
		a.velocity = Vector3(0, -1, 0)
		a.change_state("air")
		advance(1)
		check(a.state == "ledge" and a.facing == -side and a.visual.current_clip.ends_with("ledge_catch"), "Ledge %d catches a descending fighter with the inward-facing authored pose" % side)
		var held_position: Vector3 = a.position
		advance(12)
		check(a.state == "ledge" and a.position.is_equal_approx(held_position), "Ledge %d holds a stable position without edge jitter" % side)
		a.provider = ScriptedInputProvider.new([{"from": 0, "to": 1, "actions": ["jump"]}, {"from": 0, "to": 65, "move": Vector2(-side, 0)}])
		advance(1)
		check(a.state == "air" and a.velocity.y > 0 and a.ledge_lock > 0 and a.visual.current_clip.ends_with("ledge_release"), "Ledge %d jump input releases upward with recatch lockout" % side)
		var landed: bool = false
		for tick in 70:
			advance(1)
			if a.grounded:
				landed = true
				break
		check(landed and a.support_id == 0 and a.stocks == 3, "Ledge %d release returns to the main deck through ordinary movement" % side)
	await process_frame
	reset_pair()
	b.position.x = 7
	a.position.x = 0
	a.provider = ScriptedInputProvider.new([
		{"from": 0, "to": 3, "actions": ["jump"]},
		{"from": 16, "to": 18, "actions": ["jump"]},
		{"from": 30, "to": 32, "actions": ["jump"]}])
	advance(1)
	check(not a.grounded and a.air_jumps == 1, "Ground jump preserves the one aerial jump")
	advance(15)
	var before_double: float = a.velocity.y
	advance(1)
	check(a.air_jumps == 0 and a.velocity.y > before_double + 3 and a.visual.current_clip.ends_with("double_jump"), "Second distinct jump input performs and spends the aerial jump")
	advance(13)
	var before_third: float = a.velocity.y
	advance(1)
	check(not a.grounded and a.air_jumps == 0 and a.velocity.y <= before_third, "Third jump input cannot refresh or repeat the aerial jump")
	await process_frame
	reset_pair()
	b.position.x = 7
	a.position = Vector3(0, 9, 0)
	a.grounded = false
	a.support_id = -1
	a.change_state("air")
	a.provider = ScriptedInputProvider.new([
		{"from": 0, "to": 1, "move": Vector2(0, 1), "actions": ["defend"]},
		{"from": 39, "to": 40, "move": Vector2(0, 1), "actions": ["defend"]}])
	advance(1)
	check(a.state == "dodge" and a.air_dodge_used, "Aerial defend starts and spends the one aerial dodge")
	advance(38)
	check(not a.grounded and a.state == "air" and a.vulnerable(), "Aerial dodge returns to vulnerable airborne movement")
	var before_redodge: float = a.velocity.y
	advance(1)
	check(a.state == "air" and a.air_dodge_used and a.velocity.y <= before_redodge, "Second aerial dodge input is rejected before landing")
	var reached_support: bool = false
	for tick in 100:
		advance(1)
		if a.grounded:
			reached_support = true
			break
	check(reached_support and not a.air_dodge_used, "Legitimate platform landing refreshes aerial dodge")
	advance(12)
	a.provider = ScriptedInputProvider.new([
		{"from": 0, "to": 0, "actions": ["jump"]},
		{"from": 2, "to": 3, "actions": ["defend"]}])
	advance(3)
	check(a.state == "dodge" and a.air_dodge_used, "A new airtime can use its refreshed aerial dodge through input")

func attribution_and_influence_scenarios() -> void:
	var launches: Array[Vector3] = []
	for axis in [-1.0, 0.0, 1.0]:
		await process_frame
		reset_pair()
		a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["light"]}])
		b.provider = ScriptedInputProvider.new([{"from": 0, "to": 30, "move": Vector2(0, axis)}])
		for tick in 20:
			advance(1)
			if b.damage > 0: break
		check(b.damage > 0 and b.velocity.is_finite(), "Directional-influence fixture %s receives a real resolved hit" % axis)
		launches.append(b.velocity)
	var neutral_angle: float = atan2(launches[1].y, launches[1].x)
	var low_angle: float = atan2(launches[0].y, launches[0].x)
	var high_angle: float = atan2(launches[2].y, launches[2].x)
	check(low_angle < neutral_angle and high_angle > neutral_angle and absf(low_angle - neutral_angle) < deg_to_rad(7) and absf(high_angle - neutral_angle) < deg_to_rad(7), "Full directional influence changes launch angle in the expected direction by less than seven degrees")
	check(is_equal_approx(launches[0].length(), launches[1].length()) and is_equal_approx(launches[2].length(), launches[1].length()) and launches[1].length() <= 42, "Directional influence preserves the bounded launch magnitude")
	await process_frame
	var slots: Array[Dictionary] = [
		{"fighter": "f01_clutch", "device": "CPU"},
		{"fighter": "f01_clutch", "device": "CPU"},
		{"fighter": "f04_deadfall", "device": "CPU"}]
	world.start(slots, "Fair Fight")
	world.countdown = 0
	a = world.fighters[0]
	b = world.fighters[1]
	var c: RiotFighter = world.fighters[2]
	for fighter in world.fighters: fighter.provider = ScriptedInputProvider.new()
	a.position = Vector3(-0.6, 0, 0)
	b.position = Vector3(0.6, 0, 0)
	c.position = Vector3(-7, 0, 0)
	a.facing = 1
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["light"]}])
	advance(50)
	var first_damage: float = b.damage
	check(first_damage > 0 and b.last_attacker == a.slot, "Actual first attacker is recorded for KO attribution")
	a.position.x = -7
	c.position = b.position - Vector3(1.1, 0, 0)
	c.facing = 1
	c.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["light"]}])
	advance(20)
	check(b.damage > first_damage and b.last_attacker == c.slot, "A later actual hit transfers last-hit KO credit")
	b.position.x = 19
	advance(1)
	var entry: Dictionary = world.ko_log.back() if not world.ko_log.is_empty() else {}
	check(entry.get("victim", -1) == b.slot and entry.get("credited", -1) == c.slot, "Boundary KO credits the most recent legitimate attacker")
	var contributors: Array = entry.get("assists", [])
	check(contributors.has(a.slot) and contributors.has(c.slot) and contributors.size() == 2, "KO history retains each actual stock contributor once")
	advance(105)
	check(b.last_attacker == -1 and b.assists.is_empty(), "Respawn clears previous-stock KO and assist attribution")
	await process_frame
	reset_pair()
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["light"]}])
	advance(620)
	check(b.damage > 0, "Expired-credit fixture preserves an earlier real hit")
	b.position.x = 19
	advance(1)
	entry = world.ko_log.back() if not world.ko_log.is_empty() else {}
	check(entry.get("credited", -2) == -1, "A ring-out over ten seconds after the last hit has no credited attacker")

func hazard_warning_scenarios() -> void:
	await process_frame
	reset_pair()
	world.stage.preset = "Party"
	a.position.x = -8
	b.position.x = 8
	var events: Array[Dictionary] = []
	var listener: Callable = func(event: String, _actor: int, at: Vector3, _details: Dictionary) -> void:
		if event in ["hazard_warning", "hazard_fire"]:
			events.append({"name": event, "tick": world.tick, "x": at.x})
	world.presentation_event.connect(listener)
	var first_visible: int = -1
	var first_damage: int = -1
	var warning_damage: bool = false
	for tick in 600:
		advance(1)
		for marker in world.stage.hazard_warnings:
			if marker.visible and first_visible < 0: first_visible = world.tick
		if world.stage.hazard_phase == 1 and (a.damage > 0 or b.damage > 0): warning_damage = true
		if (a.damage > 0 or b.damage > 0) and first_damage < 0:
			first_damage = world.tick
	world.presentation_event.disconnect(listener)
	var warning_tick: int = -1
	var fire_tick: int = -1
	var warning_x: float = 0
	var fire_x: float = 0
	for event in events:
		if event.name == "hazard_warning" and warning_tick < 0:
			warning_tick = event.tick
			warning_x = event.x
		if event.name == "hazard_fire" and fire_tick < 0:
			fire_tick = event.tick
			fire_x = event.x
	check(warning_tick > 0 and first_visible == warning_tick, "Party emits its audible warning event when the actual vent marker first appears")
	check(fire_tick > warning_tick and fire_tick - warning_tick >= 60 and warning_x == fire_x, "Party warns the same vent for at least one second before its fire event", str(fire_tick - warning_tick) + " simulation ticks")
	check(not warning_damage and first_damage == fire_tick, "Party vent cannot damage during warning and begins damage only at announced fire")
