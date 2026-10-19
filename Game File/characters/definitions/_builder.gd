class_name FighterContentBuilder
extends RefCounted
## Content authoring helper; the registry excludes files beginning with '_'.
## Rows: id, name, startup, active length, recovery, damage, base KB, growth,
## angle degrees, local x, local y, radius, optional overrides.

static func build(profile: Dictionary, rows: Array) -> FighterDefinition:
	var fighter := FighterDefinition.new()
	for key: String in profile:
		match key:
			"taunts": fighter.taunts.assign(profile[key])
			"beginner_combos": fighter.beginner_combos.assign(profile[key])
			_: fighter.set(key, profile[key])
	fighter.model_path = "res://assets/characters/%s.glb" % fighter.id
	fighter.low_model_path = "res://assets/characters/%s_low.glb" % fighter.id
	fighter.portrait_path = "res://assets/portraits/%s.png" % fighter.id
	for animation: String in FighterDefinition.REQUIRED_ANIMATIONS:
		fighter.animation_profile[animation] = animation
	for row: Array in rows:
		var move: MoveDefinition = _make_move(row)
		fighter.moves[move.id] = move
		fighter.animation_profile[move.id] = move.animation_id
	return fighter

static func _make_move(row: Array) -> MoveDefinition:
	var move := MoveDefinition.new()
	move.id = str(row[0])
	move.display_name = str(row[1])
	move.animation_id = move.id
	move.startup = int(row[2])
	move.active_windows = [Vector2i(move.startup, move.startup + int(row[3]) - 1)]
	move.recovery = int(row[4])
	move.damage = float(row[5])
	move.base_knockback = float(row[6])
	move.knockback_growth = float(row[7])
	move.angle = float(row[8])
	move.hit_offset = Vector2(float(row[9]), float(row[10]))
	move.hit_radius = float(row[11])
	# Authored move roles establish impact rhythm independently of damage.
	# Per-fighter overrides below remain the final authority.
	move.hitstun = 18
	move.hitstop = 5
	if move.id in ["jab1", "jab2"]:
		move.hitstun = 16
		move.hitstop = 4
	elif move.id == "jab3":
		move.hitstun = 21
		move.hitstop = 7
	elif move.id.begins_with("heavy_"):
		move.hitstun = 25
		move.hitstop = 10
	elif move.id == "dash":
		move.hitstun = 20
		move.hitstop = 7
	elif move.id.begins_with("throw_"):
		move.hitstun = 21
		move.hitstop = 7
	elif move.id.begins_with("special_"):
		move.hitstun = 22
		move.hitstop = 7
	elif move.id == "ultimate":
		move.hitstun = 26
		move.hitstop = 10
	move.shield_damage = move.damage * 1.15
	move.shield_stun = int(roundf(4.0 + move.damage * 0.6))
	move.effects = ["impact_ring"]
	move.purpose = "Close-range pressure and a readable launch."
	move.counterplay = "Space outside the contact arc and punish recovery."
	if move.id.begins_with("air_"):
		move.context = "air"
		move.direction = move.id.trim_prefix("air_")
		move.air_control = 0.45
		match move.direction:
			"neutral", "up":
				move.landing_lag = 8
				move.hitstun = 18
				move.hitstop = 5
			"forward":
				move.landing_lag = 11
				move.hitstun = 21
				move.hitstop = 7
			"back":
				move.landing_lag = 13
				move.hitstun = 22
				move.hitstop = 8
			"down":
				move.air_control = 0.35
				move.landing_lag = 16
				move.hitstun = 24
				move.hitstop = 9
	elif move.id.begins_with("special_"):
		move.context = "any"
		move.input_action = "special"
		move.direction = move.id.trim_prefix("special_")
		move.air_control = 0.20 if move.id != "special_down" else 0.0
	elif move.id.begins_with("throw_"):
		move.context = "grab_hold"
		move.input_action = "grab"
		move.direction = move.id.trim_prefix("throw_")
		move.ability = "throw"
		move.ownership["max_targets"] = 1
	elif move.id == "grab":
		move.context = "ground"
		move.input_action = "grab"
		move.ability = "grab"
		move.ownership["max_targets"] = 1
		move.purpose = "Catch a grounded shield; choose a directional throw."
		move.counterplay = "Jump, attack first, or dodge the short grab window."
	elif move.id == "ultimate":
		move.context = "any"
		move.input_action = "ultimate"
		move.ability_data = {"meter_cost": 100.0}
	else:
		move.context = "ground"
		if move.id.begins_with("heavy_"):
			move.input_action = "heavy"
			move.direction = move.id.trim_prefix("heavy_")
			move.charge_max = 60
		elif move.id.begins_with("tilt_"):
			move.direction = move.id.trim_prefix("tilt_")
	if move.id in ["jab1", "jab2"]:
		move.cancel_windows = [{"from": move.startup + 2, "to": move.total_ticks() - 2, "into": ["jab2" if move.id == "jab1" else "jab3"], "on_hit": true}]
		move.purpose = "Confirmed jab-chain starter." if move.id == "jab1" else "Confirmed jab-chain link."
		move.counterplay = "Block the first strike, then punish the string's commitment."
	if row.size() > 12:
		var overrides: Dictionary = row[12]
		for key: String in overrides:
			match key:
				"active_windows": move.active_windows.assign(overrides[key])
				"cancel_windows": move.cancel_windows.assign(overrides[key])
				"armor_windows": move.armor_windows.assign(overrides[key])
				"invulnerable_windows": move.invulnerable_windows.assign(overrides[key])
				"movement": move.movement.assign(overrides[key])
				"effects": move.effects.assign(overrides[key])
				_: move.set(key, overrides[key])
	return move
