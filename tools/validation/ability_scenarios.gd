extends SceneTree
## Actual match-tick scenarios. Positions/resources are seeded as test fixtures;
## attacks are normally requested through ScriptedInputProvider, not resolved by hand.
## Missing roster models are reported as visual limitations, never replaced/mapped.

const IDS: Array[String] = ["f01_clutch", "f02_sunstruck", "f03_heavy_duty", "f04_deadfall", "f05_fine_print"]
var world: MatchWorld
var a: RiotFighter
var b: RiotFighter
var checks: Array[Dictionary] = []
var events: Array[Dictionary] = []
var missing_visuals: Array[String] = []
var failures: int = 0
var scenario: String = ""

func _initialize() -> void:
	_run.call_deferred()

func check(passed: bool, name_value: String, detail: String = "") -> void:
	checks.append({"name": name_value, "scenario": scenario, "passed": passed, "tick": world.tick, "detail": detail})
	if not passed:
		failures += 1
		print("FAIL ", scenario, " / ", name_value, " ", detail)

func fresh(id_a: String = "f01_clutch", id_b: String = "f01_clutch") -> void:
	world.clear()
	await process_frame
	var slots: Array[Dictionary] = [{"fighter": id_a, "device": "CPU"}, {"fighter": id_b, "device": "CPU"}]
	world.start(slots, "Fair Fight")
	world.countdown = 0
	a = world.fighters[0]
	b = world.fighters[1]
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(0.85, 0, 0), -1)
	events.clear()

func fixture(f: RiotFighter, p: Vector3, direction: int) -> void:
	# Reset pose/state between independent attempts while retaining earned passive resources.
	f.interrupt()
	f.position = p
	f.velocity = Vector3.ZERO
	f.grounded = is_zero_approx(p.y)
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

func first_owned(type: String, fighter: RiotFighter = a) -> Dictionary:
	for item: Dictionary in world.abilities.objects:
		if item.owner == fighter and item.type == type and not item.expired:
			return item
	return {}

func count_hits(slot: int = 0) -> int:
	var count: int = 0
	for event: Dictionary in events:
		if event.event == "hit" and event.actor == slot: count += 1
	return count

func wait_damage(target: RiotFighter, max_ticks: int = 100) -> bool:
	for i: int in max_ticks:
		world.step()
		if target.damage > 0: return true
	return false

func on_event(event: String, actor: int, _at: Vector3, details: Dictionary) -> void:
	events.append({"event": event, "actor": actor, "tick": world.tick, "details": details.duplicate(true)})

func _run() -> void:
	world = MatchWorld.new()
	root.add_child(world)
	world.presentation_event.connect(on_event)
	await process_frame
	for id: String in IDS:
		var definition: FighterDefinition = RosterRegistry.by_id(id)
		if not ResourceLoader.exists(definition.model_path): missing_visuals.append(id)
	await momentum_scenarios()
	await encore_scenarios()
	await commitment_scenarios()
	await fieldcraft_scenarios()
	await citation_scenarios()
	await counter_scenarios()
	await ultimate_scenarios()
	await snapshot_and_zone_scenarios()
	await throw_scenarios()
	await recovery_and_cleanup_scenarios()
	await cosmetic_power_scenarios()
	await prop_alignment_scenarios()
	await taunt_and_fastfall_scenarios()
	var report: Dictionary = {"engine": Engine.get_version_info().string, "tick_hz": Engine.physics_ticks_per_second,
		"checks": checks.size(), "failures": failures, "results": checks,
		"missing_visual_assets": missing_visuals,
		"limitation": "Headless combat-logic scenarios. No identity inference, model substitution, animation quality, visual attack alignment, or listening claim. All simulation advances use MatchWorld.step()."}
	var path: String = ProjectSettings.globalize_path("res://../evidence/ability_scenarios.json")
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("ABILITY_SCENARIOS ", checks.size(), " checks; ", failures, " failures; missing visual assets=", missing_visuals)
	world.clear()
	world.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)

func owned_objects(type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in world.abilities.objects:
		if item.owner == a and item.type == type and not item.expired: result.append(item)
	return result

func wait_object(type: String, limit: int = 80) -> Dictionary:
	for tick in limit:
		advance(1)
		var item := first_owned(type)
		if not item.is_empty(): return item
	return {}

func visual_bounds(visual: Node3D) -> AABB:
	var result := AABB()
	var initialized: bool = false
	for child: Node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = child
		if mesh_node.mesh == null: continue
		var bounds: AABB = mesh_node.global_transform * mesh_node.mesh.get_aabb()
		result = result.merge(bounds) if initialized else bounds
		initialized = true
	return result

func cosmetic_power_scenarios() -> void:
	var cases: Array[Dictionary] = [
		{"id": "f05_fine_print", "type": "precision_line", "direction": Vector2.ZERO, "target_x": 2.1},
		{"id": "f02_sunstruck", "type": "ribbon", "direction": Vector2.RIGHT, "target_x": 1.28},
		{"id": "f03_heavy_duty", "type": "ring", "direction": Vector2.ZERO, "target_x": 1.15}]
	for test: Dictionary in cases:
		scenario = "cosmetic " + str(test.type)
		await fresh(test.id, "f01_clutch")
		fixture(b, Vector3(float(test.target_x), 0, 0), -1)
		var contacts_before: int = world.resolver.contacts_resolved
		pulse(a, "special", test.direction)
		var item := wait_object(test.type)
		check(not item.is_empty(), "Real special input creates its authored cosmetic effect")
		if item.is_empty(): continue
		if test.type == "ring":
			# The wave is a composition now: inspect its real descendant meshes
			# instead of assuming the first child is a single contour quad.
			var filament_count: int = 0
			var physical_count: int = 0
			var restrained: bool = true
			for child: Node in item.visual.find_children("*", "MeshInstance3D", true, false):
				var mesh_node: MeshInstance3D = child
				if mesh_node.mesh == null: continue
				for surface: int in range(mesh_node.mesh.get_surface_count()):
					var material: Material = mesh_node.get_active_material(surface)
					if not material is ShaderMaterial: continue
					if material.shader.resource_path.ends_with("ability_filament.gdshader"):
						filament_count += 1
						restrained = restrained and float(material.get_shader_parameter("brightness")) <= 1.75
					elif material.shader.resource_path.ends_with("ability_surface.gdshader"):
						physical_count += 1
			var bounds: AABB = visual_bounds(item.visual)
			var visible_radius: float = maxf(bounds.size.x, bounds.size.y) * 0.5
			var authored_scale_radius: float = float(item.visual.scale.x) * 0.45
			check(filament_count > 0 and physical_count > 0 and restrained and visible_radius > float(item.radius) * 0.40 and visible_radius <= float(item.radius) * 1.10 and absf(authored_scale_radius - float(item.radius)) <= float(item.radius) * 0.06, "Clap wave combines soft filaments and lit fragments within its authored radius", "filaments=%d physical=%d visible_radius=%s hit_radius=%s" % [filament_count, physical_count, visible_radius, item.radius])
		if test.type == "precision_line":
			var frozen_age: int = int(item.age)
			var freeze_ticks: int = a.hitstop
			check(freeze_ticks > 1 and item.visual.visible, "Confirmed thrust enters real hitstop with its precision trace visible")
			var retained: bool = true
			for tick in maxi(0, freeze_ticks - 1):
				advance(1)
				retained = retained and a.hitstop > 0 and not item.expired and int(item.age) == frozen_age and is_instance_valid(item.visual) and item.visual.visible
			check(retained and freeze_ticks > 1, "Attached precision trace keeps its age and visibility throughout source hitstop", "frozen_age=%d hitstop_ticks=%d" % [frozen_age, freeze_ticks])
		advance(70)
		check(b.damage > 0 and count_hits() == 1 and world.resolver.contacts_resolved - contacts_before == 1, "Cosmetic overlap adds no contact or damage beyond the authored melee hit", "hits=%d damage=%s contacts=%d" % [count_hits(), b.damage, world.resolver.contacts_resolved - contacts_before])
		check(owned_objects(test.type).is_empty(), "Cosmetic effect expires after its finite lifetime")
		await fresh(test.id, "f01_clutch")
		fixture(b, Vector3(-7, 0, 0), -1)
		pulse(a, "special", test.direction)
		item = wait_object(test.type)
		if item.is_empty():
			check(false, "Interrupt fixture creates a live cosmetic object")
			continue
		var old_visual: Node3D = item.visual
		a.interrupt()
		a.change_state("hitstun")
		a.stun = 10
		advance(1)
		await process_frame
		check(owned_objects(test.type).is_empty() and not is_instance_valid(old_visual), "Interruption removes the cosmetic object and frees its visual")
	scenario = "independent projectile during source hitstop"
	await fresh("f01_clutch", "f04_deadfall")
	fixture(b, Vector3(-7, 0, 0), -1)
	pulse(a, "special")
	var projectile := wait_object("ring")
	check(not projectile.is_empty(), "Projectile fixture spawns an actual palm wave")
	if not projectile.is_empty():
		var before_age: int = int(projectile.age)
		var before_position: Vector2 = projectile.position
		a.hitstop = 6
		advance(2)
		check(a.hitstop > 0 and int(projectile.age) == before_age + 2 and Vector2(projectile.position).x > before_position.x, "Independent projectile age and travel continue while its source is in hitstop")
	scenario = "three noncolliding recovery steps"
	await fresh("f05_fine_print", "f01_clutch")
	fixture(b, Vector3(-7, 0, 0), -1)
	var platforms_before: Array[Dictionary] = world.stage.platforms.duplicate(true)
	var contacts_before: int = world.resolver.contacts_resolved
	pulse(a, "special", Vector2(0, 1))
	var first := wait_object("step")
	var steps := owned_objects("step")
	check(steps.size() == 3, "Recovery creates exactly three temporary steps")
	if steps.size() == 3:
		check(steps[0].visual.visible and not steps[1].visual.visible and not steps[2].visual.visible, "Only the first recovery step is initially visible")
		var shown_ticks: Array[int] = [-1, -1, -1]
		var anchors: Array[Vector2] = [Vector2.INF, Vector2.INF, Vector2.INF]
		var stable: bool = true
		var anchors_at_feet: bool = true
		for elapsed in 15:
			for index in 3:
				var step: Dictionary = steps[index]
				if step.visual.visible:
					if shown_ticks[index] < 0:
						shown_ticks[index] = world.tick
						anchors[index] = step.position
						anchors_at_feet = anchors_at_feet and anchors[index].distance_to(Vector2(a.position.x, a.position.y - 0.04)) < 0.0001
					else:
						stable = stable and Vector2(step.position).distance_to(anchors[index]) < 0.0001
			advance(1)
		check(shown_ticks[1] - shown_ticks[0] == 6 and shown_ticks[2] - shown_ticks[1] == 6, "The three recovery steps become visible six simulation ticks apart", str(shown_ticks))
		check(anchors_at_feet and stable and anchors[0].y < anchors[1].y and anchors[1].y < anchors[2].y, "Each step anchors at the current foot position then remains fixed while the fighter rises")
		check(world.stage.platforms == platforms_before, "Recovery steps never add or alter authoritative platforms")
		# Cross the final visible step with an ordinary falling fighter; move its owner
		# away so an authored recovery kick cannot contaminate this collision probe.
		a.position = Vector3(6, 6, 0)
		var step_top: float = visual_bounds(steps[2].visual).end.y
		fixture(b, Vector3(anchors[2].x, step_top + 0.015, 0), -1)
		b.velocity.y = -3.0
		advance(1)
		check(not b.grounded and b.support_id == -1 and b.position.y < step_top, "A descending fighter passes through a visible step without landing")
		check(b.damage == 0 and world.resolver.contacts_resolved == contacts_before, "Overlapping recovery steps produce no gameplay contacts")
		advance(25)
		check(owned_objects("step").is_empty(), "All staggered recovery steps expire")
	await fresh("f05_fine_print", "f01_clutch")
	fixture(b, Vector3(-7, 0, 0), -1)
	pulse(a, "special", Vector2(0, 1))
	first = wait_object("step")
	steps = owned_objects("step")
	var step_visuals: Array[Node3D] = []
	for step: Dictionary in steps: step_visuals.append(step.visual)
	a.interrupt()
	a.change_state("hitstun")
	a.stun = 24
	advance(20)
	await process_frame
	var visuals_freed: bool = true
	for visual: Node3D in step_visuals: visuals_freed = visuals_freed and not is_instance_valid(visual)
	check(steps.size() == 3 and owned_objects("step").is_empty() and visuals_freed, "Interruption clears both visible and delayed steps before they can reappear")

func prop_alignment_scenarios() -> void:
	for direction in [1, -1]:
		scenario = "loaded GLB surface alignment facing %d" % direction
		await fresh("f04_deadfall", "f01_clutch")
		fixture(a, Vector3.ZERO, direction)
		fixture(b, Vector3(-7 * direction, 0, 0), -direction)
		pulse(a, "special", Vector2(direction, 0))
		var plank := wait_object("plank")
		check(not plank.is_empty(), "Real slide creates the plank visual")
		if not plank.is_empty():
			var bounds := visual_bounds(plank.visual)
			# The authored slide pose raises the shoes above the actor's gameplay origin;
			# the board top sits 0.09 m above that origin, clear of the solid deck.
			check(absf(bounds.size.x - 1.8) < 0.001 and absf(bounds.size.y - 0.157) < 0.001 and absf(bounds.end.y - a.position.y - 0.09) < 0.001, "Actual plank GLB top preserves authored 0.09 m foot clearance in either facing", "bottom=%s top=%s actor_origin=%s" % [bounds.position.y, bounds.end.y, a.position.y])
			check(absf(float(plank.position.y) - a.position.y - 0.04) < 0.001, "Plank visual alignment preserves the authoritative object offset")
		await fresh("f02_sunstruck", "f01_clutch")
		fixture(a, Vector3.ZERO, direction)
		fixture(b, Vector3(-7 * direction, 0, 0), -direction)
		pulse(a, "special", Vector2(0, -1))
		var reflector := wait_object("reflector")
		check(not reflector.is_empty(), "Real down special creates the reflector visual")
		if not reflector.is_empty():
			var bounds := visual_bounds(reflector.visual)
			var support: Dictionary = world.stage.support(int(reflector.support))
			check(not support.is_empty() and absf(bounds.size.y - 0.50074321) < 0.001 and absf(bounds.position.y - float(support.y)) < 0.001, "Actual reflector GLB bottom rests on its support surface in either facing", "bottom=%s top=%s support=%s" % [bounds.position.y, bounds.end.y, support])
			check(not support.is_empty() and absf(float(reflector.position.y) - float(support.y) - 0.20) < 0.001, "Reflector visual alignment preserves its authoritative terrain height")

func momentum_scenarios() -> void:
	scenario = "momentum distinct hits, cap, decay and spending"
	await fresh()
	var axes: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2(0, 1), Vector2(0, -1), Vector2.RIGHT]
	var expected: Array[int] = [1, 1, 2, 3, 3]
	for i: int in axes.size():
		fixture(a, Vector3.ZERO, 1)
		fixture(b, Vector3(0.85, 0, 0), -1)
		pulse(a, "light", axes[i])
		advance(55)
		check(b.damage > 0 and a.mechanics.pips == expected[i], "Distinct-hit accumulation attempt %d" % i, "damage=%s pips=%s" % [b.damage, a.mechanics.pips])
	check(b.mechanics.pips == 0, "Mirror opponent does not inherit Momentum")
	fixture(a, Vector3(-6, 0, 0), 1)
	fixture(b, Vector3(8, 0, 0), -1)
	pulse(a, "special")
	advance(1)
	check(a.mechanics.pips == 2 and a.mechanics.empowered, "Starting a special consumes exactly one pip")
	advance(16)
	check(world.abilities.owned_count(a, "ring") == 2, "Empowered Overtime produces two owned rings")
	advance(280)
	check(a.mechanics.pips == 0, "Unused Momentum expires through simulation ticks")
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(0.85, 0, 0), -1)
	a.ultimate_meter = 99.9
	pulse(a, "light", Vector2(0, 1))
	advance(20)
	check(b.damage > 0 and is_equal_approx(a.ultimate_meter, 100.0), "A real hit near full meter clamps it to 100", str(a.ultimate_meter))

func encore_scenarios() -> void:
	scenario = "encore returns, ownership and empowerment"
	await fresh("f02_sunstruck", "f02_sunstruck")
	fixture(b, Vector3(-8, 0, 0), -1)
	for expected: int in range(1, 4):
		pulse(a, "special")
		advance(130)
		check(a.mechanics.pips == expected, "Catch %d awards one Encore pip" % expected, str(a.mechanics.pips))
	check(b.mechanics.pips == 0 and b.damage == 0, "Mirror Encore and damage remain independent")
	pulse(a, "special")
	advance(13)
	var disc: Dictionary = first_owned("disc")
	check(a.mechanics.pips == 0 and a.mechanics.empowered and not disc.is_empty(), "Three catches empower and spend on next disc")
	if not disc.is_empty():
		check(float(disc.radius) > a.definition.get_move("special_neutral").hit_radius, "Empowered disc has authored larger radius")
	advance(130)
	check(a.mechanics.pips == 1, "Empowered disc catch begins the next Encore cycle")
	scenario = "reflector redirects and survives one attack instance"
	await fresh("f02_sunstruck")
	fixture(b, Vector3(-8, 0, 0), 1)
	pulse(a, "special", Vector2(0, -1))
	advance(48)
	check(world.abilities.owned_count(a, "reflector") == 1, "Down special creates one reflector")
	pulse(a, "special")
	var reflected: bool = false
	var angle: float = -999
	for i: int in 75:
		world.step()
		disc = first_owned("disc")
		if not disc.is_empty() and bool(disc.reflected):
			reflected = true
			var velocity: Vector2 = disc.velocity
			angle = rad_to_deg(velocity.angle())
			break
	check(reflected and absf(angle - 30.0) < 1.0, "Own disc follows the modeled 30-degree reflector route", str(angle))
	# Isolate destructible tool from the remaining disc, without changing the tool's HP.
	for item: Dictionary in world.abilities.objects:
		if item.type == "disc": item.expired = true
	fixture(a, Vector3(-5, 0, 0), 1)
	fixture(b, Vector3(1.65, 0, 0), -1)
	pulse(b, "light")
	advance(13)
	var puck: Dictionary = first_owned("reflector")
	check(not puck.is_empty() and float(puck.hp) > 0 and float(puck.hp) < 9.0, "One jab damages reflector once across its active frames", str(puck.get("hp", -1)))
	advance(20)
	pulse(b, "light", Vector2(0, -1))
	advance(30)
	check(world.abilities.owned_count(a, "reflector") == 0, "A second attack can destroy the weakened reflector")
	scenario = "disc ownership cap and stock cleanup"
	await fresh("f02_sunstruck")
	fixture(b, Vector3(-8, 0, 0), 1)
	a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "actions": ["special"]}, {"from": 37, "to": 37, "actions": ["special"]}])
	var maximum: int = 0
	for i: int in 60:
		world.step()
		maximum = maxi(maximum, world.abilities.owned_count(a, "disc"))
	check(maximum == 1, "Only one disc is live per owner")
	a.position.x = 19
	advance(2)
	check(a.state == "ko" and world.abilities.owned_count(a, "disc") == 0 and a.mechanics.pips == 0, "Stock loss removes owned disc and Encore")

func commitment_scenarios() -> void:
	scenario = "commitment absorbs one light strike"
	await fresh("f03_heavy_duty")
	fixture(b, Vector3(-0.8, 0, 0), 1)
	pulse(a, "heavy")
	advance(15)
	pulse(b, "light")
	advance(6)
	check(a.damage > 0 and a.armor_spent and a.state == "attack", "Armor takes damage without interrupting its first light hit", "damage=%s state=%s tick=%s" % [a.damage, a.state, a.move_tick])
	fixture(b, Vector3(-0.8, 0, 0), 1)
	pulse(b, "light")
	advance(7)
	check(a.state == "hitstun", "Armor cannot absorb a second attack instance")
	scenario = "command grab and grounded stomp"
	await fresh("f03_heavy_duty")
	fixture(b, Vector3(1.7, 0, 0), -1)
	pulse(b, "defend", Vector2.ZERO, 160)
	pulse(a, "special", Vector2.RIGHT)
	var captured: bool = false
	var max_lift: float = 0
	for i: int in 85:
		world.step()
		captured = captured or b.captured_by == a
		max_lift = maxf(max_lift, b.position.y)
	check(captured and b.damage > 0, "Command grab beats shield and delivers slam damage", "captured=%s damage=%s" % [captured, b.damage])
	# Measured hands hold the victim's waist: side-grab root lift peaks at 0.85m,
	# rather than lifting the victim's feet above the attacker's hands.
	check(max_lift >= 0.75 and max_lift <= 0.9 and b.captured_by == null and a.capture_target == null, "Authored waist-height lift-and-slam releases both capture links", str(max_lift))
	await fresh("f03_heavy_duty")
	fixture(b, Vector3(1.1, 0, 0), -1)
	pulse(a, "special", Vector2(0, -1))
	advance(25)
	check(b.damage > 0 and count_hits() == 1, "Ground stomp creates one damage event, not melee plus wave", "damage=%s hits=%s" % [b.damage, count_hits()])
	await fresh("f03_heavy_duty")
	fixture(a, Vector3(12, 1.5, 0), 1)
	fixture(b, Vector3(-6, 0, 0), 1)
	pulse(a, "special", Vector2(0, -1))
	advance(60)
	check(a.stocks == 2 and a.state == "ko", "Offstage elbow drop remains a genuine ring-out risk")

func fieldcraft_scenarios() -> void:
	scenario = "trap warning, single trigger and Quick Fix"
	await fresh("f04_deadfall")
	fixture(b, Vector3(1.2, 0, 0), -1)
	pulse(a, "special", Vector2(0, -1))
	advance(46)
	check(b.damage == 0 and world.abilities.owned_count(a, "trap") == 1, "Tripline cannot damage before its 30-tick arming period")
	advance(8)
	check(b.damage > 0 and a.mechanics.pips == 1, "Armed tripline hit grants one Quick Fix")
	check(world.abilities.owned_count(a, "trap") == 0 and count_hits() == 1, "Tripline triggers only once")
	fixture(a, Vector3(-5, 0, 0), 1)
	fixture(b, Vector3(8, 0, 0), -1)
	pulse(a, "special", Vector2.RIGHT)
	advance(1)
	check(a.mechanics.pips == 0 and a.mechanics.empowered, "Shortcut consumes earned Quick Fix")
	scenario = "trap cap, lifetime, and damage-once durability"
	await fresh("f04_deadfall")
	fixture(b, Vector3(8, 0, 0), -1)
	var first_instance: int = -1
	for attempt: int in 3:
		pulse(a, "special", Vector2(0, -1))
		advance(55)
		if attempt == 0: first_instance = int(first_owned("trap").get("instance", -1))
	check(world.abilities.owned_count(a, "trap") == 2, "Third tripline replaces oldest at the two-tool cap")
	var old_survived: bool = false
	for item: Dictionary in world.abilities.objects:
		old_survived = old_survived or int(item.instance) == first_instance
	check(not old_survived, "Replacement specifically removes the oldest tripline")
	advance(560)
	check(world.abilities.owned_count(a, "trap") == 0, "Untriggered triplines expire at finite lifetime")
	await fresh("f04_deadfall")
	fixture(b, Vector3(3, 0, 0), -1)
	pulse(a, "special", Vector2(0, -1))
	advance(20)
	fixture(b, Vector3(1.5, 0, 0), -1)
	pulse(b, "light")
	advance(9)
	var trap: Dictionary = first_owned("trap")
	check(not trap.is_empty() and float(trap.hp) > 0 and float(trap.hp) < 7, "One attack cannot repeatedly damage an arming tool", str(trap.get("hp", -1)))
	scenario = "log follows terrain then falls at edge"
	await fresh("f04_deadfall")
	fixture(a, Vector3(7.3, 0, 0), 1)
	fixture(b, Vector3(-7, 0, 0), 1)
	pulse(a, "special")
	var crossed: bool = false
	var fell: bool = false
	for i: int in 65:
		world.step()
		var log_item: Dictionary = first_owned("log")
		if not log_item.is_empty() and float(log_item.position.x) > 9.3:
			crossed = true
			fell = fell or float(log_item.velocity.y) < 0
	check(crossed and fell, "Rolling log falls after leaving the main deck")
	check(b.damage == 0, "Ground-route log cannot damage across the whole arena")

func citation_scenarios() -> void:
	scenario = "citations precision, target scope, cap and consumption"
	await fresh("f05_fine_print", "f05_fine_print")
	for attempt: int in 4:
		fixture(a, Vector3.ZERO, 1)
		fixture(b, Vector3(2.1, 0, 0), -1)
		pulse(a, "special")
		advance(55)
		check(b.damage > 0 and int(a.mechanics.marks.get(b.slot, {}).get("count", 0)) == mini(3, attempt + 1), "Precise thrust citation attempt %d" % attempt, str(a.mechanics.marks))
	check(b.mechanics.marks.is_empty(), "Mirror opponent does not share target citations")
	fixture(a, Vector3.ZERO, 1)
	fixture(b, Vector3(1.55, 0, 0), -1)
	pulse(a, "heavy")
	advance(32)
	check(b.damage > 16 and not a.mechanics.marks.has(b.slot), "Final Ruling consumes marks for a bounded bonus", str(b.damage))
	await fresh("f05_fine_print")
	fixture(b, Vector3(1.35, 0, 0), -1)
	pulse(a, "special")
	advance(35)
	check(b.damage > 0 and a.mechanics.marks.is_empty(), "Inner thrust contact causes damage without a precise citation")
	await fresh("f05_fine_print")
	fixture(b, Vector3(2.1, 0, 0), -1)
	pulse(a, "special")
	advance(35)
	check(a.mechanics.marks.has(b.slot), "Precision fixture actually earns a mark")
	advance(450)
	check(a.mechanics.marks.is_empty(), "Citations expire through live fighter ticks")

func counter_scenarios() -> void:
	for id: String in ["f01_clutch", "f05_fine_print"]:
		scenario = id + " counter timing and counterplay"
		await fresh(id)
		pulse(a, "special", Vector2(0, -1))
		pulse(b, "light")
		advance(10)
		check(a.damage == 0 and b.damage > 0, "Strike inside counter window triggers real reprisal", "defender=%s attacker=%s" % [a.damage, b.damage])
		check(world.abilities.spent_counters.has(a.attack_instance) and not world.abilities.counter_open(a), "Successful counter is spent for the attack instance")
		await fresh(id)
		pulse(a, "special", Vector2(0, -1))
		advance(int(a.definition.get_move("special_down").ability_data.counter_to) + 3)
		pulse(b, "light")
		advance(8)
		check(a.damage > 0 and b.damage == 0, "Counter recovery can be punished after its window")
		await fresh(id)
		pulse(a, "special", Vector2(0, -1))
		pulse(b, "grab")
		advance(12)
		check(a.captured_by == b and b.capture_target == a, "Grab beats a counter stance")

func ultimate_scenarios() -> void:
	for id: String in IDS:
		scenario = id + " ultimate miss and telegraph"
		await fresh(id)
		fixture(a, Vector3(-8, 0, 0), 1)
		fixture(b, Vector3(8, 0, 0), -1)
		a.ultimate_meter = 100
		pulse(a, "ultimate")
		advance(160)
		check(b.damage == 0 and a.ultimate_meter == 0 and world.abilities.sequences.is_empty(), "Missed ultimate spends meter and never auto-confirms")
		check(a.capture_target == null and b.captured_by == null, "Miss leaves no dangling capture")
		scenario = id + " ultimate connects and cleans up"
		await fresh(id)
		var distance: float = 2.0 if id == "f01_clutch" else 3.0 if id == "f02_sunstruck" else 1.1 if id == "f03_heavy_duty" else 3.3 if id == "f04_deadfall" else 1.95
		fixture(b, Vector3(distance, 0, 0), -1)
		a.ultimate_meter = 100
		pulse(a, "ultimate")
		advance(a.definition.get_move("ultimate").startup)
		check(b.damage == 0, "Startup/warning never deals early damage")
		var max_damage: float = 0
		var saw_sequence: bool = false
		for i: int in 170:
			world.step()
			max_damage = maxf(max_damage, b.damage)
			saw_sequence = saw_sequence or not world.abilities.sequences.is_empty()
		check(max_damage > 0 and count_hits() > 0, "Ultimate delivers authored damage through resolver", "maximum damage=%s hits=%s" % [max_damage, count_hits()])
		if id in ["f01_clutch", "f03_heavy_duty", "f05_fine_print"]:
			check(saw_sequence and max_damage >= 20, "Confirmed opener resolves its actual follow-up sequence", "sequence=%s maximum damage=%s" % [saw_sequence, max_damage])
		check(world.abilities.sequences.is_empty() and a.capture_target == null and b.captured_by == null, "Completed ultimate releases sequence and capture state")

func snapshot_and_zone_scenarios() -> void:
	scenario = "projectile keeps its launch-time charge and facing"
	await fresh()
	fixture(b, Vector3(8, 0, 0), -1)
	pulse(a, "special", Vector2.ZERO, 60)
	var next_attack_started: bool = false
	var damage_at_contact: float = 0
	var launch_x: float = 0
	for i: int in 140:
		world.step()
		if not next_attack_started and a.state == "idle" and not first_owned("ring").is_empty():
			pulse(a, "light", Vector2.LEFT)
			next_attack_started = true
		if b.damage > 0:
			damage_at_contact = b.damage
			launch_x = b.velocity.x
			break
	check(next_attack_started and a.facing == -1 and a.charge_ticks == 0, "Fixture begins a different facing/uncharged move before projectile contact")
	check(damage_at_contact > 14.0 and launch_x > 0, "Old charged blast retains damage and forward launch after owner turns", "damage=%s velocity_x=%s" % [damage_at_contact, launch_x])
	scenario = "foreign reflector cannot redirect a mirror fighter's disc"
	await fresh("f02_sunstruck", "f02_sunstruck")
	fixture(b, Vector3(2, 0, 0), -1)
	pulse(b, "special", Vector2(0, -1))
	advance(48)
	pulse(a, "special")
	advance(16)
	var disc: Dictionary = first_owned("disc")
	check(not disc.is_empty() and not bool(disc.reflected) and absf(float(disc.velocity.y)) < 0.01, "Opponent reflector does not alter disc ownership or trajectory")
	scenario = "spotlight has exactly three telegraphed pulses"
	await fresh("f02_sunstruck")
	fixture(b, Vector3(3, 0, 0), -1)
	pulse(b, "defend", Vector2.ZERO, 180)
	a.ultimate_meter = 100
	pulse(a, "ultimate")
	advance(130)
	var shield_contacts: int = 0
	for event: Dictionary in events:
		if event.event == "shield" and event.actor == b.slot: shield_contacts += 1
	check(shield_contacts == 3 and b.damage == 0, "Spotlight resolves three distinct shieldable pulses", "shield contacts=%s damage=%s" % [shield_contacts, b.damage])
	scenario = "falling tree uses diagonal capsule rather than filled rectangle"
	await fresh("f04_deadfall")
	fixture(b, Vector3(8, 0, 0), -1)
	a.ultimate_meter = 100
	pulse(a, "ultimate")
	advance(a.definition.get_move("ultimate").startup)
	# This airborne point lies inside the broad horizontal rectangle but clearly
	# outside the diagonal trunk capsule. Only position/velocity are a fixture.
	b.position = Vector3(0.5, 0.5, 0)
	b.velocity = Vector3.ZERO
	b.grounded = false
	b.support_id = -1
	advance(4)
	check(b.damage == 0, "Space beside the warned diagonal remains safe")
	scenario = "cosmetic plank cannot deal independent contact damage"
	await fresh("f04_deadfall")
	fixture(b, Vector3(-7, 0, 0), 1)
	pulse(a, "special", Vector2.RIGHT)
	advance(14)
	check(not first_owned("plank").is_empty(), "Slide actually creates its authored cosmetic prop")
	fixture(b, a.position + Vector3(-0.7, 0, 0), 1)
	advance(1)
	check(b.damage == 0, "Overlapping cosmetic plank behind the strike does not hit")

func throw_scenarios() -> void:
	for axis: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2(0, 1), Vector2(0, -1)]:
		scenario = "ordinary directional throw " + str(axis)
		await fresh()
		pulse(a, "grab")
		advance(9)
		check(a.capture_target == b and b.captured_by == a, "Grab establishes paired capture")
		a.provider = ScriptedInputProvider.new([{"from": 0, "to": 0, "move": axis, "actions": ["light"]}])
		var hit: bool = wait_damage(b, 25)
		var direction_ok: bool = (b.velocity.x > 0 if axis == Vector2.RIGHT else b.velocity.x < 0 if axis == Vector2.LEFT else b.velocity.y > absf(b.velocity.x) if axis == Vector2(0, 1) else b.velocity.y > 0)
		check(hit and direction_ok, "Selected throw delivers its declared launch direction", str(b.velocity))
		check(a.capture_target == null and b.captured_by == null, "Throw releases both capture links")
	scenario = "confirmed sequence cancels when its owner loses stock"
	await fresh("f03_heavy_duty")
	# The rush travels from tick 12 before its narrow grab opens on tick 17.
	# An initially overlapping target is passed before the active contact window.
	fixture(b, Vector3(2.2, 0, 0), -1)
	pulse(a, "special", Vector2.RIGHT)
	for i: int in 30:
		world.step()
		if not world.abilities.sequences.is_empty(): break
	check(not world.abilities.sequences.is_empty(), "Cleanup fixture reaches a real command-grab sequence")
	a.position.x = 19
	advance(3)
	check(a.stocks == 2 and a.capture_target == null and b.captured_by == null and world.abilities.sequences.is_empty(), "KO cancels active capture and owned sequence")

func taunt_and_fastfall_scenarios() -> void:
	scenario = "Heavy Duty chair taunt is cosmetic and bounded"
	await fresh("f03_heavy_duty")
	fixture(b, Vector3.ZERO, -1)
	var surfaces: Array[Dictionary] = world.stage.platforms.duplicate(true)
	pulse(a, "taunt")
	advance(1)
	var chair: Dictionary = first_owned("chair")
	check(a.state == "taunt" and not chair.is_empty() and not chair.visual.visible and int(chair.options.delay) == 12, "First taunt creates one delayed authored chair")
	advance(10)
	check(not chair.is_empty() and not chair.visual.visible and world.abilities.owned_count(a, "chair") == 1, "Chair remains hidden before the unfold beat")
	advance(3)
	check(not chair.is_empty() and chair.visual.visible and chair.visual.scale.x < 1.0, "Chair unfolds visibly on the delayed taunt beat")
	advance(8)
	check(is_equal_approx(chair.visual.scale.x, 1.0) and b.damage == 0 and count_hits() == 0 and world.stage.platforms == surfaces, "Unfolded chair remains cosmetic despite overlapping a target")
	advance(36)
	check(a.state == "idle" and first_owned("chair").is_empty(), "Chair expires at the end of its 55-tick taunt")
	pulse(a, "taunt")
	advance(15)
	check(a.state == "taunt" and first_owned("chair").is_empty(), "Second alternating taunt does not borrow the chair")
	scenario = "Chair taunt interruption clears hidden and unfolded props"
	for delay_ticks: int in [2, 17]:
		await fresh("f03_heavy_duty")
		fixture(b, Vector3(-6, 0, 0), 1)
		pulse(a, "taunt")
		advance(delay_ticks)
		check(not first_owned("chair").is_empty(), "Interruption fixture has a chair at tick %d" % delay_ticks)
		a.interrupt()
		a.stun = 10
		a.change_state("hitstun")
		advance(1)
		check(first_owned("chair").is_empty(), "Hit interruption removes the chair at tick %d" % delay_ticks)
	scenario = "Down-aerial startup owns descent rather than manual fast-fall"
	for id: String in IDS:
		await fresh(id)
		fixture(a, Vector3(10, 7, 0), 1)
		fixture(b, Vector3(-6, 0, 0), 1)
		a.velocity.y = -1
		# Input vectors use positive Y for up, unlike canvas Vector2.UP/DOWN.
		a.provider = ScriptedInputProvider.new([{"from": 0, "to": 4, "move": Vector2(0, -1), "actions": ["light"]}])
		advance(1)
		check(a.state == "attack" and a.move.id == "air_down" and a.velocity.y > -a.definition.fast_fall_speed, id + " down-air startup does not trigger manual fast-fall")
		fixture(a, Vector3(10, 7, 0), 1)
		a.velocity.y = -1
		a.provider = ScriptedInputProvider.new([{"from": 0, "to": 4, "move": Vector2(0, -1)}])
		advance(1)
		check(a.state == "air" and a.velocity.y <= -a.definition.fast_fall_speed, id + " descending free movement still permits manual fast-fall")

func recovery_and_cleanup_scenarios() -> void:
	for id: String in IDS:
		scenario = id + " airborne resource and mirror isolation"
		await fresh(id, id)
		fixture(a, Vector3(11, 1.0, 0), 1)
		fixture(b, Vector3(-6, 0, 0), 1)
		a.air_jumps = 0
		pulse(a, "special", Vector2(0, 1))
		advance(a.definition.get_move("special_up").total_ticks() + 2)
		check(a.stocks == 3 and a.recovery_used and a.helpless, "Recovery spends once and ends in airborne helpless state", "state=%s pos=%s" % [a.state, a.position])
		var instance: int = a.attack_instance
		pulse(a, "special", Vector2(0, 1))
		advance(2)
		check(a.attack_instance == instance, "Second recovery input is rejected without a landing")
		check(not b.recovery_used and b.attack_instance == 0 and b.mechanics.pips == 0, "Mirror fighter retains independent resources")
		# Seed a descending foot crossing; the actual stage solve must refresh resources.
		a.position = Vector3(0, 0.02, 0)
		a.velocity = Vector3(0, -3, 0)
		a.grounded = false
		a.support_id = -1
		a.provider = ScriptedInputProvider.new()
		advance(1)
		check(a.grounded and not a.recovery_used and not a.helpless, "Legitimate landing refreshes recovery")
		# Recovery availability is distinct from the seven-tick landing lockout.
		advance(8)
		pulse(a, "special", Vector2(0, 1))
		advance(1)
		check(a.recovery_used and a.attack_instance != instance, "A new recovery becomes available after landing")
		world.training_reset()
		advance(1)
		check(world.abilities.objects.is_empty() and world.abilities.sequences.is_empty() and a.capture_target == null and b.captured_by == null, "Reset clears ability objects and capture state")
