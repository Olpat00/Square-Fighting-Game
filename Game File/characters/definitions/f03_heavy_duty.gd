extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f03_heavy_duty", "display_name": "Heavy Duty", "archetype": "Heavyweight grappler",
		"final_ko_caption": "PLEASE RETURN THE FURNITURE",
		"description": "Broad grabs, armored commitments, and enormous punish windows on both sides.",
		"palette": Color("ea5c64"), "accent": Color("cbd8e4"), "run_speed": 6.8, "air_speed": 5.4, "weight": 1.24,
		"acceleration": 43.0, "air_acceleration": 19.0, "jump_velocity": 12.3, "gravity": 22.0, "fast_fall_speed": 19.0,
		"mechanic": "commitment", "passive_description": "The specified heavy windup windows absorb one hit of at most 8 damage without interruption. Damage still applies. Grabs and stronger hits beat the armor.",
		"taunts": ["This chair was rated for that.", "I'm going to need you to leave."],
		"beginner_combos": ["Jab 1 → Jab 2 → Jab 3 for a close-range low-damage check.", "Down throw → up tilt against limited DI at low damage; jump away to avoid retaliation."]
	}, [
		["jab1", "Complaint Intake", 7, 4, 13, 4.5, 2.7, 0.033, 14, 0.72, 1.04, 0.51],
		["jab2", "Follow-up Call", 8, 4, 14, 5.0, 3.0, 0.037, 18, 0.87, 1.05, 0.55],
		["jab3", "Case Closed", 10, 5, 23, 8.0, 5.3, 0.079, 36, 1.0, 0.90, 0.68],
		["tilt_side", "Personal Space", 11, 5, 20, 10.0, 4.9, 0.087, 33, 1.12, 1.06, 0.65],
		["tilt_up", "Overhead Cost", 10, 6, 22, 9.0, 4.8, 0.080, 83, 0.30, 1.84, 0.78],
		["tilt_down", "Heel Inspection", 10, 5, 20, 9.0, 4.4, 0.068, 61, 0.89, 0.22, 0.66],
		["dash", "Express Delivery", 13, 7, 28, 13.0, 5.7, 0.091, 38, 0.95, 0.98, 0.78, {"movement": [{"from": 10, "to": 19, "velocity": Vector2(9.2, 0), "mode": "set"}]}],
		["heavy_side", "Final Notice", 24, 6, 35, 21.0, 7.2, 0.130, 30, 1.13, 1.00, 0.83, {"armor_windows": [Vector2i(13, 24)], "armor_threshold": 8.0, "charge_max": 65}],
		["heavy_up", "Load Bearing", 23, 7, 33, 18.5, 7.0, 0.128, 86, 0.15, 2.02, 0.87, {"armor_windows": [Vector2i(13, 23)], "armor_threshold": 8.0, "charge_max": 65}],
		["heavy_down", "Deck Clearance", 24, 8, 36, 19.0, 6.7, 0.122, 24, 0.30, 0.26, 1.18, {"armor_windows": [Vector2i(14, 24)], "armor_threshold": 8.0, "charge_max": 65}],
		["air_neutral", "Wide Load", 9, 10, 24, 10.0, 4.7, 0.078, 42, 0.1, 0.94, 1.03],
		["air_forward", "Special Delivery", 13, 6, 29, 14.0, 5.7, 0.102, 32, 1.03, 1.05, 0.78],
		["air_back", "Rear Exit", 11, 5, 27, 15.0, 6.1, 0.117, 151, -0.95, 0.97, 0.70],
		["air_up", "Top Shelf", 10, 6, 24, 10.0, 4.9, 0.085, 84, 0.12, 1.86, 0.77],
		["air_down", "Dead Weight", 18, 7, 34, 15.0, 5.9, 0.106, -65, 0.08, -0.12, 0.75],
		["special_neutral", "Complaint Department", 22, 6, 30, 15.0, 5.8, 0.089, 40, 1.15, 1.12, 1.05, {"ability": "heavy_clap", "shield_damage": 31.0, "shield_stun": 18, "ability_data": {"shockwave_radius": 1.4}, "purpose": "Thunderous short-range clap creates heavy shield pressure.", "counterplay": "Back away during the windup; the shockwave has no long-range travel."}],
		["special_side", "Please Remain Seated", 17, 7, 37, 14.0, 5.1, 0.081, 63, 0.72, 1.43, 0.25, {"ability": "heavy_grab", "movement": [{"from": 12, "to": 23, "velocity": Vector2(9.0, 0), "mode": "set"}], "ownership": {"friendly_fire": true, "hit_owner": false, "clear_on_stock_loss": true, "max_targets": 1}, "ability_data": {"command_grab": true, "capture_ticks": 25, "release_on_interrupt": true}, "purpose": "Committed rush grabs through shields into a lift-and-slam.", "counterplay": "Jump or dodge the grab, then punish 37 ticks of whiff recovery."}],
		["special_up", "Carry-On", 11, 11, 38, 12.0, 5.4, 0.087, 74, 0.69, 1.53, 0.80, {"ability": "heavy_recovery", "movement": [{"from": 11, "to": 15, "velocity": Vector2(2.6, 12.5), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.12}, "purpose": "A powerful rising clothesline with deliberately limited recovery distance.", "counterplay": "Respect the arm, then cover the short, vulnerable descent."}],
		["special_down", "Floor Inspection", 17, 5, 33, 13.0, 5.2, 0.088, 55, 0.30, 0.16, 1.12, {"ability": "heavy_stomp", "ability_data": {"air_velocity": -18.0, "landing_radius": 1.65, "landing_damage": 11.0, "ground_only_wave": true}, "purpose": "Ground stomp or committed airborne elbow drop; landing produces a short shockwave.", "counterplay": "Jump over the shockwave; an offstage elbow drop cannot rescue its user."}],
		["ultimate", "Folded Like Furniture", 31, 6, 43, 12.0, 4.0, 0.040, 65, 1.08, 1.10, 0.80, {"ability": "heavy_ultimate", "ownership": {"friendly_fire": true, "hit_owner": false, "clear_on_stock_loss": true, "max_targets": 1}, "ability_data": {"meter_cost": 100.0, "command_grab": true, "requires_opener": true, "capture_ticks": 45, "finisher_damage": 25.0, "finisher_base": 8.7, "finisher_growth": 0.135, "temporary_prop": "folding_chair", "release_on_interrupt": true}, "purpose": "A telegraphed grab confirms an absurd wrestling slam onto a temporary chair.", "counterplay": "Jump away from the visible grab; the move can miss and spend all meter."}],
		["grab", "Official Escort", 9, 4, 26, 0, 0, 0, 0, 1.00, 1.06, 0.61],
		["throw_forward", "Exit Strategy", 9, 1, 22, 12, 6.2, 0.105, 30, 0.8, 1.0, 0.5],
		["throw_back", "Service Entrance", 12, 1, 24, 14, 6.6, 0.116, 145, -0.8, 1.0, 0.5],
		["throw_up", "Freight Elevator", 10, 1, 22, 11, 5.9, 0.097, 87, 0.3, 1.6, 0.5],
		["throw_down", "Damage Deposit", 12, 1, 23, 10, 3.9, 0.058, 74, 0.6, 0.3, 0.5]
	])
