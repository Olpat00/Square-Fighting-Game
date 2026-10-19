extends SceneTree
## Pure resource contract checks plus registration of an unshipped fixture.

var checks: int = 0
var failures := PackedStringArray()

func _initialize() -> void:
	var roster: Array[FighterDefinition] = RosterRegistry.discover()
	_check(roster.size() == 8, "Exactly eight selectable fighters")
	var ids: Dictionary = {}
	var mechanic_ids: Dictionary = {}
	var signatures: Dictionary = {}
	for fighter: FighterDefinition in roster:
		_check(not ids.has(fighter.id), "Fighter ID is unique: " + fighter.id)
		ids[fighter.id] = true
		mechanic_ids[fighter.mechanic] = true
		_check(fighter.moves.size() == 25, "Common 25-move vocabulary: " + fighter.id)
		_check(fighter.validate().is_empty(), "Definition validation: " + fighter.id)
		_check(fighter.beginner_combos.size() == 2, "Two beginner sequences: " + fighter.id)
		_check(fighter.taunts.size() == 2, "Two taunts: " + fighter.id)
		var signature: String = str(fighter.run_speed) + ":" + str(fighter.weight)
		for move_id: String in FighterDefinition.REQUIRED_MOVES:
			var move: MoveDefinition = fighter.get_move(move_id)
			_check(move != null, "Move exists: " + fighter.id + "/" + move_id)
			_check(move.animation_id == str(fighter.animation_profile[move_id]), "Animation mapping: " + fighter.id + "/" + move_id)
			_check(not move.is_active(move.startup - 1), "Startup cannot hit: " + move_id)
			_check(move.is_active(move.startup), "First active boundary: " + move_id)
			_check(not move.is_active(move.total_ticks() - 1), "Final recovery tick cannot hit: " + move_id)
			_check(not move.is_active(move.total_ticks()), "Completed move cannot hit: " + move_id)
			_check(move.ownership.get("clear_on_stock_loss", false), "Stock loss ownership cleanup: " + move_id)
			for window: Vector2i in move.active_windows:
				_check(move.is_active(window.x) and move.is_active(window.y), "Inclusive active endpoints: " + move_id)
			for window: Dictionary in move.cancel_windows:
				var next: String = str(window.into[0])
				_check(move.can_cancel(int(window.from), next, true), "Confirmed cancel begins at declared tick: " + move_id)
				_check(not move.can_cancel(int(window.from) - 1, next, true), "Cancel cannot begin early: " + move_id)
				_check(not move.can_cancel(int(window.to) + 1, next, true), "Cancel cannot extend late: " + move_id)
				if bool(window.on_hit):
					_check(not move.can_cancel(int(window.from), next, false), "Whiff cannot use hit-confirm cancel: " + move_id)
			if move_id.begins_with("special_") or move_id == "ultimate":
				_check(not move.ability.is_empty(), "Unique special has an ability key: " + move_id)
				signature += ":" + move.ability
		_check(not signatures.has(signature), "Distinct movement and abilities: " + fighter.id)
		signatures[signature] = true
		var other: FighterDefinition = RosterRegistry.by_id(fighter.id)
		_check(other != fighter and other.get_move("jab1") != fighter.get_move("jab1"), "Independent resource creation: " + fighter.id)
		var old_damage: float = fighter.get_move("jab1").damage
		other.get_move("jab1").damage = 999.0
		_check(fighter.get_move("jab1").damage == old_damage, "Mutation isolation across independently loaded definitions: " + fighter.id)
	_check(mechanic_ids.size() == roster.size(), "Every fighter has a distinct passive implementation")
	_test_extra_registration(roster.size())
	var result: Dictionary = {"engine": Engine.get_version_info().string, "checks": checks, "failures": failures, "shipped_fighters": roster.size(), "moves": roster.size() * 25, "extra_fighter_fixture": "Temporary user:// folder loaded using registry discovery; removed after test", "scope": "Definition and pure timing contracts; combat resolution and graphical animation validation run separately"}
	var report: FileAccess = FileAccess.open("res://../docs/moves/content-validation.json", FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _test_extra_registration(shipped_count: int) -> void:
	# Unique test directory avoids touching user content or the shipped roster.
	var probe_path: String = "user://roster_registration_probe_%d" % OS.get_process_id()
	var absolute_probe: String = ProjectSettings.globalize_path(probe_path)
	var absolute_user: String = ProjectSettings.globalize_path("user://")
	if not absolute_probe.begins_with(absolute_user) or not absolute_probe.get_file().begins_with("roster_registration_probe_"):
		_check(false, "Registration fixture path stays in the dedicated user test directory")
		return
	DirAccess.make_dir_recursive_absolute(absolute_probe)
	var definition_path: String = probe_path.path_join("development_probe.gd")
	var definition: FileAccess = FileAccess.open(definition_path, FileAccess.WRITE)
	if definition == null:
		_check(false, "Create registration fixture")
		return
	definition.store_string("extends RefCounted\n\nstatic func create() -> FighterDefinition:\n\tvar fighter: FighterDefinition = RosterRegistry.by_id(\"f01_clutch\")\n\tfighter.id = \"development_only_probe\"\n\tfighter.display_name = \"Unshipped Registration Probe\"\n\treturn fighter\n")
	definition.close()
	var probe_roster: Array[FighterDefinition] = RosterRegistry.discover(probe_path)
	_check(probe_roster.size() == 1, "Registry discovers a new content file without registry edits")
	_check(probe_roster.size() == 1 and probe_roster[0].id == "development_only_probe", "New stable ID is registered correctly")
	_check(RosterRegistry.discover().size() == shipped_count, "Development fixture never enters shipped selection")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(definition_path))
	DirAccess.remove_absolute(absolute_probe)
