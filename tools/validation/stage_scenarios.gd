extends SceneTree
## Stage-switching regression: collision, hazard rules and arena lifetime.

var failures: int = 0
var checks: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name": label, "passed": ok})
	if not ok:
		failures += 1
		print("STAGE_FAIL ", label)

func _run() -> void:
	var world := MatchWorld.new()
	root.add_child(world)
	if world.abilities == null or world.resolver == null:
		push_error("Stage suite aborted: combat runtime failed to initialize.")
		quit(1)
		return
	var slots: Array[Dictionary] = [{"fighter": "f06_rugged_explorer", "device": "CPU"}, {"fighter": "f07_urban_sentinel", "device": "CPU"}]
	var arenas: Array[String] = StageCatalog.IDS.duplicate()
	arenas.append("rooftop_riot") # Return to the original after every new stage.
	for id: String in arenas:
		world.start(slots, "Fair Fight", false, 4261, id)
		check(world.running and world.fighters.size() == 2, id + " starts both fighters")
		world.countdown = 0
		for fighter: RiotFighter in world.fighters: fighter.provider = ScriptedInputProvider.new()
		await process_frame
		check(world.stage_id == id, "Selected " + id)
		var environments: Array[Node] = world.find_children("*", "WorldEnvironment", true, false)
		check(environments.size() == 1, id + " has exactly one active environment after switching")
		for platform: Dictionary in world.stage.platforms:
			var center := Vector3(platform.x, platform.y, 0)
			var solved: Dictionary = world.stage.solve_motion(center + Vector3.UP, center - Vector3.UP, -12.0, -1, -1)
			check(solved.landed and solved.platform == platform.id and is_equal_approx(solved.position.y, platform.y), id + " top landing " + str(platform.id))
		for tick: int in 20: world.step()
		var rest_height: float = float(world.stage.platforms[3].get("base_y", 5.5))
		check(world.stage.hazard_phase == 0 and is_equal_approx(world.stage.platforms[3].y, rest_height), id + " Fair Fight remains fixed and hazard free")
		var deck_edges: Vector2 = world.stage.main_bounds()
		var deck: Dictionary = world.stage.support(0)
		var bottom: float = float(deck.y) - float(deck.get("thickness", 0.9))
		for side: float in [-1.0, 1.0]:
			var edge: float = deck_edges.x if side < 0 else deck_edges.y
			var beside: Dictionary = world.stage.solve_motion(Vector3(edge + side, -0.7, 0), Vector3(edge - side, -0.7, 0), 0, -1, -1)
			check(is_equal_approx(beside.position.x, edge + side * 0.25), id + " solid deck wall follows actual edge " + str(side))
			var recovering: RiotFighter = world.fighters[0]
			recovering.position = Vector3(edge + side * 0.35, float(deck.y) - 1.2, 0)
			recovering.velocity = Vector3(0, -1, 0)
			recovering.grounded = false
			recovering.support_id = -1
			recovering.ledge_lock = 0
			recovering.stun = 0
			recovering.change_state("air")
			recovering._move_body()
			check(recovering.state == "ledge" and is_equal_approx(recovering.position.x, edge + side * 0.3) and recovering.facing == -int(side), id + " actual fighter catches authored ledge facing inward " + str(side))
		var under: Dictionary = world.stage.solve_motion(Vector3(0, bottom - CombatTuning.HURT_HEIGHT - 1, 0), Vector3(0, bottom, 0), 10, -1, -1)
		check(is_equal_approx(under.position.y, bottom - CombatTuning.HURT_HEIGHT), id + " swept underside matches authored deck thickness")
		world.stage.preset = "Party"
		var fixed_planes: Array[Dictionary] = world.stage.platforms.duplicate(true)
		for frame: int in 90: world.stage.step()
		check(not is_equal_approx(world.stage.platforms[3].y, rest_height) and is_equal_approx(world.stage.center_visual.position.y, world.stage.platforms[3].y), id + " Party lift and rendered surface move together")
		check(world.stage.platforms[0] == fixed_planes[0] and world.stage.platforms[1] == fixed_planes[1] and world.stage.platforms[2] == fixed_planes[2], id + " decorative animation leaves fixed collision planes unchanged")
		world.stage.tick = world.stage.hazard_cycle - 97
		world.stage.step()
		check(world.stage.hazard_phase == 1, id + " Party warns before the vent")
		world.stage.tick = world.stage.hazard_cycle - 25
		world.stage.step()
		check(world.stage.hazard_phase == 2, id + " Party vent becomes active")
		world.start(slots, "Party", true, 4261, id)
		check(world.stage.preset == "Fair Fight" and world.training, id + " training disables hazards")
		check(world.stage.hazard_phase == 0 and not world.stage.hazard_flames[0].visible and not world.stage.hazard_flames[1].visible, id + " rematch clears active hazard visuals during countdown")
		check(is_equal_approx(world.stage.center_visual.position.y, rest_height) and is_equal_approx(world.stage.platforms[3].previous_y, rest_height), id + " rematch restores this map's authored lift height")
	world.clear()
	world.queue_free()
	await process_frame
	await process_frame
	var report := {"checks": checks, "failures": failures}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../evidence/lunar_upgrade"))
	FileAccess.open(ProjectSettings.globalize_path("res://../evidence/lunar_upgrade/stage_scenarios.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("STAGE_SCENARIOS checks=", checks.size(), " failures=", failures)
	quit(1 if failures else 0)
