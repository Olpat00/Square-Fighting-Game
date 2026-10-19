extends SceneTree
## Run: godot --headless --path "Game File" --script ../docs/moves/export_move_data.gd
## Export source-of-truth resources, never hand-maintain duplicate frame tables.

func _initialize() -> void:
	var roster: Array[FighterDefinition] = RosterRegistry.discover()
	var payload: Dictionary = {"tick_rate": 60, "tick_indexing": "zero-based inclusive windows", "fighters": {}}
	var output_dir: String = ProjectSettings.globalize_path("res://../docs/moves")
	var errors := PackedStringArray()
	for fighter: FighterDefinition in roster:
		errors.append_array(fighter.validate())
		var moves: Dictionary = {}
		var lines := PackedStringArray([
			"# %s — implemented move data" % fighter.display_name,
			"", fighter.archetype + ". " + fighter.description, "",
			"Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.", "",
			"Run %.1f m/s · Air %.1f m/s · Weight %.2f · Jump %.2f m/s · Gravity %.1f m/s²." % [fighter.run_speed, fighter.air_speed, fighter.weight, fighter.jump_velocity, fighter.gravity], "",
			"**Passive — %s:** %s" % [fighter.mechanic.capitalize(), fighter.passive_description], "",
			"| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |",
			"|---|---:|---|---:|---:|---:|---:|---:|---:|"
		])
		for move_id: String in FighterDefinition.REQUIRED_MOVES:
			var move: MoveDefinition = fighter.get_move(move_id)
			if move == null:
				continue
			var move_data: Dictionary = {}
			for property: Dictionary in move.get_property_list():
				if (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
					move_data[str(property.name)] = _json_safe(move.get(str(property.name)))
			move_data["total_ticks"] = move.total_ticks()
			move_data["duration_seconds"] = move.total_ticks() / 60.0
			moves[move_id] = move_data
			var windows := PackedStringArray()
			for window: Vector2i in move.active_windows:
				windows.append("%d–%d" % [window.x, window.y])
			lines.append("| `%s` / %s | %d | %s | %d | %.1f | %.2f | %.3f | %.0f° | %d |" % [move_id, move.display_name, move.startup, ", ".join(windows), move.recovery, move.damage, move.base_knockback, move.knockback_growth, move.angle, move.charge_max])
		lines.append_array(PackedStringArray(["", "Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.", "", "## Purpose, risk, and counterplay", ""]))
		for move_id: String in FighterDefinition.REQUIRED_MOVES:
			var move: MoveDefinition = fighter.get_move(move_id)
			lines.append("- **%s:** %s Counterplay: %s" % [move.display_name, move.purpose, move.counterplay])
		lines.append_array(PackedStringArray(["", "## Beginner sequences", "", "These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.", ""]))
		for combo: String in fighter.beginner_combos:
			lines.append("- " + combo)
		lines.append_array(PackedStringArray(["", "## Exact technical data", "", "`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.", ""]))
		payload.fighters[fighter.id] = {"display_name": fighter.display_name, "model_path": fighter.model_path, "animation_profile": fighter.animation_profile, "moves": moves}
		var sheet: FileAccess = FileAccess.open(output_dir.path_join(fighter.id + ".md"), FileAccess.WRITE)
		if sheet == null:
			errors.append("Cannot write move sheet for " + fighter.id)
		else:
			sheet.store_string("\n".join(lines))
	var output: FileAccess = FileAccess.open(output_dir.path_join("move_timing.json"), FileAccess.WRITE)
	if output != null:
		output.store_string(JSON.stringify(payload, "\t"))
	else:
		errors.append("Cannot write move_timing.json")
	if roster.size() != 8:
		errors.append("Expected exactly eight shipped fighters; discovered %d" % roster.size())
	print(JSON.stringify({"fighters": roster.size(), "moves": roster.size() * FighterDefinition.REQUIRED_MOVES.size(), "errors": errors, "output": output_dir}))
	quit(0 if errors.is_empty() else 1)

func _json_safe(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i:
		return [value.x, value.y]
	if value is Vector3 or value is Vector3i:
		return [value.x, value.y, value.z]
	if value is Color:
		return value.to_html()
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(_json_safe(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[str(key)] = _json_safe(value[key])
		return result
	return value
