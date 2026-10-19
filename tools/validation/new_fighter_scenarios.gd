extends SceneTree
## Focused authoritative match-step checks for the three newly imported fighters.
## Fixtures place actors and reset transient state; actions use ScriptedInputProvider.

const NEW_IDS: Array[String] = ["f06_rugged_explorer", "f07_urban_sentinel", "f08_midnight_gentleman"]

var world: MatchWorld
var a: RiotFighter
var b: RiotFighter
var scenario: String = ""
var checks: Array[Dictionary] = []
var events: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String, detail: String = "") -> void:
	checks.append({"scenario": scenario, "name": label, "passed": ok, "tick": world.tick, "detail": detail})
	if not ok:
		failures += 1
		print("FAIL ", scenario, " / ", label, " ", detail)

func on_event(event: String, actor: int, _at: Vector3, details: Dictionary) -> void:
	events.append({"event": event, "actor": actor, "details": details.duplicate(true), "tick": world.tick})

func fresh(id_a: String, id_b: String = "f01_clutch") -> void:
	world.clear()
	await process_frame
	world.start([{"fighter": id_a, "device": "CPU"}, {"fighter": id_b, "device": "CPU"}], "Fair Fight")
	world.countdown = 0
	a = world.fighters[0]
	b = world.fighters[1]
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(0.85, 0, 0), -1)
	events.clear()

func fixture(f: RiotFighter, at: Vector3, direction: int) -> void:
	f.interrupt()
	f.position = at
	f.velocity = Vector3.ZERO
	f.grounded = is_zero_approx(at.y)
	f.support_id = 0 if f.grounded else -1
	f.stun = 0
	f.hitstop = 0
	f.invulnerability = 0
	f.damage = 0
	f.facing = direction
	f.helpless = false
	f.recovery_used = false
	f.change_state("idle" if f.grounded else "air")
	f.provider = ScriptedInputProvider.new()
	f.snapshot = InputSnapshot.new()

func pulse(f: RiotFighter, action: String, direction: Vector2 = Vector2.ZERO, held: int = 1) -> void:
	f.provider = ScriptedInputProvider.new([{"from": 0, "to": held - 1, "move": direction, "actions": [action]}])

func advance(ticks: int) -> void:
	for i: int in ticks:
		world.step()

func first_owned(fighter: RiotFighter, type: String) -> Dictionary:
	for item: Dictionary in world.abilities.objects:
		if item.owner == fighter and item.type == type and not item.expired:
			return item
	return {}

func hit_count(actor: int = 0) -> int:
	var count: int = 0
	for event: Dictionary in events:
		if event.event == "hit" and event.actor == actor:
			count += 1
	return count

func event_count(event_name: String, actor: int) -> int:
	var count: int = 0
	for event: Dictionary in events:
		if event.event == event_name and event.actor == actor:
			count += 1
	return count

func wait_damage(target: RiotFighter, limit: int = 100) -> bool:
	for i: int in limit:
		world.step()
		if target.damage > 0:
			return true
	return false

func _run() -> void:
	world = MatchWorld.new()
	root.add_child(world)
	world.presentation_event.connect(on_event)
	await process_frame
	var registered: bool = true
	for id: String in NEW_IDS:
		var definition: FighterDefinition = RosterRegistry.by_id(id)
		scenario = id + " registration"
		check(definition != null, "Fighter definition registers through the roster")
		registered = registered and definition != null
	if registered:
		await media_scenarios()
		await explorer_scenarios()
		await sentinel_scenarios()
		await gentleman_scenarios()
		await ultimate_and_cleanup_scenarios()
	var report: Dictionary = {"engine": Engine.get_version_info().string, "tick_hz": Engine.physics_ticks_per_second,
		"checks": checks.size(), "failures": failures, "results": checks,
		"limitation": "Headless imported-asset and authoritative combat checks. This does not judge rendered likeness, animation quality, audio, or physical controllers."}
	FileAccess.open(ProjectSettings.globalize_path("res://../evidence/new_fighter_scenarios.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("NEW_FIGHTER_SCENARIOS ", checks.size(), " checks; ", failures, " failures")
	world.clear()
	world.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)

func media_scenarios() -> void:
	for id: String in NEW_IDS:
		scenario = id + " imported media"
		var definition: FighterDefinition = RosterRegistry.by_id(id)
		var paths: Array[String] = [definition.model_path, definition.low_model_path, definition.portrait_path]
		for path: String in paths:
			check(ResourceLoader.exists(path), "Imported resource exists: " + path)
		if not ResourceLoader.exists(definition.model_path):
			continue
		await fresh(id)
		check(a.visual.model != null and a.visual.animation_player != null, "Canonical model instantiates with an AnimationPlayer")
		var portrait: Texture2D = load(definition.portrait_path) as Texture2D if ResourceLoader.exists(definition.portrait_path) else null
		check(portrait != null and portrait.get_width() > 0 and portrait.get_height() > 0, "Portrait loads as a nonempty texture")
		var absent: Array[String] = missing_clips(definition, a.visual)
		check(absent.is_empty(), "Required state and move animations resolve in the canonical model", ", ".join(absent))
		if ResourceLoader.exists(definition.low_model_path):
			world.graphics_quality = "Low"
			await fresh(id)
			check(a.visual.loaded_model_path == definition.low_model_path and a.visual.animation_player != null, "Low quality mode instantiates its own animated model")
			absent = missing_clips(definition, a.visual)
			check(absent.is_empty(), "Required state and move animations resolve in the low quality model", ", ".join(absent))
			world.graphics_quality = "High"

func missing_clips(definition: FighterDefinition, visual: FighterVisual) -> Array[String]:
	var absent: Array[String] = []
	for animation: String in FighterDefinition.REQUIRED_ANIMATIONS:
		var clip: String = str(definition.animation_profile.get(animation, ""))
		if clip.is_empty() or not visual.imported_clips.has(clip): absent.append(animation)
	for move_id: String in FighterDefinition.REQUIRED_MOVES:
		var clip: String = str(definition.animation_profile.get(move_id, ""))
		if clip.is_empty() or not visual.imported_clips.has(clip): absent.append(move_id)
	return absent

func explorer_scenarios() -> void:
	scenario = "Explorer hook contact and Route travel"
	await fresh("f06_rugged_explorer")
	fixture(b, Vector3(2.3, 0, 0), -1)
	pulse(a, "special")
	var hooked: bool = wait_damage(b, 60)
	check(hooked and hit_count() == 1 and a.mechanics.pips == 1, "A real hook hit deals once and grants one Route charge", "damage=%s hits=%d route=%d" % [b.damage, hit_count(), a.mechanics.pips])
	check(hooked and b.velocity.x < -1.0 and b.stun >= 28 and event_count("ability", 0) >= 2, "Hook draws the damaged rival toward its owner", "velocity=%s stun=%d" % [b.velocity.x, b.stun])
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(-8, 0, 0), 1)
	pulse(a, "special", Vector2.RIGHT)
	advance(1)
	check(a.mechanics.pips == 0 and a.mechanics.empowered, "The next side special spends Route")
	advance(17)
	var route_distance: float = a.position.x
	await fresh("f06_rugged_explorer")
	fixture(b, Vector3(-8, 0, 0), 1)
	pulse(a, "special", Vector2.RIGHT)
	advance(18)
	check(route_distance > a.position.x + 0.10, "Earned Route extends actual side-special travel", "charged=%s ordinary=%s" % [route_distance, a.position.x])

	scenario = "Explorer hook shielding, lifetime, and resource expiry"
	await fresh("f06_rugged_explorer")
	fixture(b, Vector3(2.3, 0, 0), -1)
	pulse(b, "defend", Vector2.ZERO, 100)
	advance(2)
	pulse(a, "special")
	advance(55)
	check(b.damage == 0 and a.mechanics.pips == 0 and event_count("shield", 1) > 0, "A held shield stops hook damage, pull, and Route charge", "damage=%s route=%d shield_events=%d" % [b.damage, a.mechanics.pips, event_count("shield", 1)])
	await fresh("f06_rugged_explorer")
	fixture(b, Vector3(-8, 0, 0), 1)
	pulse(a, "special")
	advance(16)
	var hook: Dictionary = first_owned(a, "hook")
	check(not hook.is_empty() and is_instance_valid(hook.get("visual")), "Neutral special owns one visible hook after startup")
	advance(45)
	check(first_owned(a, "hook").is_empty(), "Missed hook expires after finite lifetime")
	await fresh("f06_rugged_explorer")
	fixture(b, Vector3(2.3, 0, 0), -1)
	pulse(a, "special")
	var earned: bool = wait_damage(b, 60)
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(-8, 0, 0), 1)
	advance(245)
	check(earned and a.mechanics.pips == 0, "Unused Route expires through match ticks")

func sentinel_scenarios() -> void:
	scenario = "Sentinel parry powers a close pulse"
	await fresh("f07_urban_sentinel")
	pulse(b, "light")
	advance(4)
	pulse(a, "defend", Vector2.ZERO, 10)
	advance(4)
	check(event_count("parry", 0) == 1 and a.mechanics.pips == 1 and a.damage == 0, "Timed parry earns one Guard charge", "parries=%d guard=%d damage=%s" % [event_count("parry", 0), a.mechanics.pips, a.damage])
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(1.95, 0, 0), -1)
	pulse(a, "special", Vector2(0, -1))
	advance(1)
	check(a.mechanics.pips == 0 and a.mechanics.empowered, "Fortify Pulse consumes the earned Guard charge")
	advance(18)
	var pulse_object: Dictionary = first_owned(a, "ring")
	check(not pulse_object.is_empty() and float(pulse_object.get("radius", 0)) > 1.5 and float(pulse_object.get("options", {}).get("damage_scale", 0)) > 1.2, "Guard visibly enlarges and strengthens its authored pulse")
	advance(8)
	var empowered_damage: float = b.damage
	check(empowered_damage > 0 and hit_count() == 1, "Empowered close pulse reaches and damages the rival once", "damage=%s hits=%d" % [empowered_damage, hit_count()])
	await fresh("f07_urban_sentinel")
	fixture(b, Vector3(1.95, 0, 0), -1)
	pulse(a, "special", Vector2(0, -1))
	advance(30)
	check(b.damage == 0, "Opponent can back outside an uncharged pulse", "damage=%s" % b.damage)

	scenario = "Sentinel armor and grab counterplay"
	await fresh("f07_urban_sentinel")
	fixture(b, Vector3(-0.85, 0, 0), 1)
	pulse(a, "special", Vector2(0, -1))
	advance(6)
	pulse(b, "light")
	advance(7)
	check(a.damage > 0 and a.armor_spent and a.state == "attack", "One light strike damages but does not interrupt Fortify windup", "damage=%s state=%s" % [a.damage, a.state])
	await fresh("f07_urban_sentinel")
	pulse(a, "special", Vector2(0, -1))
	pulse(b, "grab")
	advance(12)
	check(a.captured_by == b and b.capture_target == a, "A grab beats the armored Fortify windup")

	scenario = "Sentinel Lockdown warning and interruption"
	await fresh("f07_urban_sentinel")
	fixture(b, Vector3(2.0, 0, 0), -1)
	a.ultimate_meter = 100
	pulse(a, "ultimate")
	advance(1)
	check(not first_owned(a, "geometry").is_empty(), "Lockdown places its warning zone at move start")
	advance(39)
	check(b.damage == 0, "Lockdown warning cannot deal early damage")
	advance(12)
	check(b.damage > 0, "Lockdown damages a rival who stays in the telegraphed area", "damage=%s" % b.damage)
	await fresh("f07_urban_sentinel")
	fixture(b, Vector3(7.0, 0, 0), -1)
	a.ultimate_meter = 100
	pulse(a, "ultimate")
	advance(5)
	var warning: Dictionary = first_owned(a, "geometry")
	check(not warning.is_empty(), "Interrupt fixture owns a live Lockdown warning")
	var warning_visual: Node3D = warning.get("visual")
	a.interrupt()
	a.change_state("hitstun")
	a.stun = 15
	advance(1)
	await process_frame
	check(first_owned(a, "geometry").is_empty() and not is_instance_valid(warning_visual), "Interruption clears the zone and frees its warning visual")

func gentleman_scenarios() -> void:
	scenario = "Gentleman aerial confirmation extends Shadow Step"
	await fresh("f08_midnight_gentleman")
	fixture(a, Vector3(0, 1.2, 0), 1)
	fixture(b, Vector3(1.2, 0, 0), -1)
	pulse(a, "light", Vector2.RIGHT)
	var aerial_hit: bool = wait_damage(b, 45)
	check(aerial_hit and a.mechanics.pips == 1, "A damaging aerial move earns one Veil charge", "damage=%s veil=%d" % [b.damage, a.mechanics.pips])
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(8.0, 0, 0), -1)
	pulse(a, "special", Vector2.RIGHT)
	advance(1)
	check(a.mechanics.pips == 0 and a.mechanics.empowered, "Shadow Step spends Veil when the move begins")
	advance(15)
	check(absf(a.position.x) < 0.10, "Shadow Step remains in place through visible startup", str(a.position.x))
	advance(1)
	var extended_x: float = a.position.x
	check(extended_x > 3.35 and extended_x < 3.65, "Empowered step covers its authored extended distance", str(extended_x))
	await fresh("f08_midnight_gentleman")
	fixture(b, Vector3(8.0, 0, 0), -1)
	pulse(a, "special", Vector2.RIGHT)
	advance(17)
	check(a.position.x > 2.55 and a.position.x < 2.85 and extended_x > a.position.x + 0.6, "Uncharged step covers a shorter real distance", "ordinary=%s extended=%s" % [a.position.x, extended_x])
	await fresh("f08_midnight_gentleman")
	fixture(b, Vector3(3.5, 0, 0), -1)
	pulse(a, "special", Vector2.RIGHT)
	advance(16)
	check(b.damage == 0 and absf(a.position.x) < 0.10, "Distant rival is outside the pre-step hit arc during startup")
	advance(5)
	check(b.damage > 0 and hit_count() == 1 and a.position.x > 2.5, "Shadow Step strikes from its post-step destination", "damage=%s hits=%d x=%s" % [b.damage, hit_count(), a.position.x])
	await fresh("f08_midnight_gentleman")
	fixture(a, Vector3(7.8, 0, 0), 1)
	fixture(b, Vector3(-8, 0, 0), 1)
	pulse(a, "special", Vector2.RIGHT)
	advance(17)
	check(a.position.x <= 8.25 and a.stocks == 3, "Ground Shadow Step clamps safely at the arena edge", str(a.position.x))

	scenario = "Gentleman step startup and retreat counterplay"
	await fresh("f08_midnight_gentleman")
	pulse(a, "special", Vector2.RIGHT)
	pulse(b, "light")
	advance(20)
	check(a.damage > 0 and a.position.x < 1.0 and a.state == "hitstun", "Opponent can punish Shadow Step before relocation", "damage=%s x=%s state=%s" % [a.damage, a.position.x, a.state])
	await fresh("f08_midnight_gentleman")
	fixture(b, Vector3(-8, 0, 0), 1)
	pulse(a, "special", Vector2(0, -1))
	advance(10)
	check(absf(a.position.x) < 0.10, "Retreat has a visible startup before repositioning")
	advance(1)
	check(a.position.x < -1.85 and b.damage == 0 and not a.vulnerable(), "Retreat shifts backward with a brief protected transition and no damage", "x=%s damage=%s" % [a.position.x, b.damage])
	advance(6)
	check(a.vulnerable(), "Retreat becomes punishable after its authored protection ends")

func ultimate_and_cleanup_scenarios() -> void:
	for id: String in ["f06_rugged_explorer", "f08_midnight_gentleman"]:
		scenario = id + " ultimate confirm and miss"
		await fresh(id)
		fixture(a, Vector3(-8, 0, 0), 1)
		fixture(b, Vector3(8, 0, 0), -1)
		a.ultimate_meter = 100
		pulse(a, "ultimate")
		advance(150)
		check(a.ultimate_meter == 0 and b.damage == 0 and world.abilities.sequences.is_empty(), "Whiffed opener spends meter and starts no capture sequence")
		await fresh(id)
		fixture(b, Vector3(1.1, 0, 0), -1)
		a.ultimate_meter = 100
		pulse(a, "ultimate")
		var saw_sequence: bool = false
		var max_damage: float = 0.0
		for tick: int in 155:
			world.step()
			saw_sequence = saw_sequence or not world.abilities.sequences.is_empty()
			max_damage = maxf(max_damage, b.damage)
		check(saw_sequence and max_damage >= 20.0, "Connected opener resolves its real follow-up sequence", "sequence=%s damage=%s" % [saw_sequence, max_damage])
		check(world.abilities.sequences.is_empty() and a.capture_target == null and b.captured_by == null, "Completed sequence releases both fighters")

	scenario = "new fighter resource and object reset"
	await fresh("f06_rugged_explorer")
	fixture(b, Vector3(-8, 0, 0), 1)
	pulse(a, "special")
	advance(16)
	check(not first_owned(a, "hook").is_empty(), "Reset fixture creates a live owned hook")
	world.training_reset()
	advance(1)
	check(world.abilities.objects.is_empty() and world.abilities.sequences.is_empty() and a.mechanics.pips == 0 and b.captured_by == null, "Training reset removes new fighter objects and resources")
