extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f06_rugged_explorer", "display_name": "Rugged Explorer", "archetype": "Grappling pathfinder",
		"final_ko_caption": "END OF THE TRAIL",
		"description": "A compact grappling hook pulls rivals into his close-range routes. Hook hits prepare one faster traversal special.",
		"palette": Color("d9a66b"), "accent": Color("57d6b0"), "run_speed": 8.2, "air_speed": 7.0, "weight": 1.01,
		"acceleration": 60.0, "air_acceleration": 27.0, "jump_velocity": 12.8, "gravity": 21.0,
		"mechanic": "trailblazer", "passive_description": "A damaging Trail Line hook pulls its target toward the Explorer and grants one Route charge for 240 ticks. The next side or up special spends the charge for 12% more travel. Shields stop the hook; only one hook can be active.",
		"taunts": ["Found the shortcut.", "Keep up if you can."],
		"beginner_combos": ["Trail Line → side tilt when a hooked rival lands nearby; shielding the hook stops the pull.", "Down tilt → up air at low damage; follow the rival's drift."]
	}, [
		["jab1", "Trail Tap", 6, 3, 12, 3.2, 2.2, 0.034, 18, 0.70, 1.08, 0.43],
		["jab2", "Compass Check", 7, 3, 13, 3.8, 2.7, 0.039, 25, 0.82, 1.11, 0.46],
		["jab3", "Summit Strike", 9, 4, 20, 6.5, 4.3, 0.072, 39, 1.05, 1.02, 0.56],
		["tilt_side", "Ridge Sweep", 9, 5, 19, 8.0, 4.1, 0.080, 34, 1.16, 0.97, 0.58],
		["tilt_up", "Cliff Reach", 8, 5, 19, 7.0, 3.9, 0.074, 82, 0.30, 1.78, 0.65],
		["tilt_down", "Low Traverse", 8, 4, 17, 6.5, 3.5, 0.059, 64, 1.00, 0.28, 0.56],
		["dash", "Trail Charge", 11, 6, 23, 9.0, 4.7, 0.084, 41, 1.04, 0.80, 0.65, {"movement": [{"from": 8, "to": 17, "velocity": Vector2(10.9, 0), "mode": "set"}]}],
		["heavy_side", "Rockbreaker", 21, 5, 30, 16.0, 6.0, 0.116, 32, 1.32, 1.08, 0.68],
		["heavy_up", "Peak Finder", 19, 6, 28, 14.0, 5.7, 0.109, 84, 0.26, 1.95, 0.76],
		["heavy_down", "Fault Line", 22, 7, 31, 14.5, 5.7, 0.106, 25, 0.28, 0.28, 1.04],
		["air_neutral", "Rope Circle", 8, 8, 19, 7.0, 3.7, 0.069, 44, 0.05, 1.02, 0.95],
		["air_forward", "Trail Kick", 11, 5, 22, 10.0, 4.7, 0.093, 35, 1.18, 0.96, 0.63],
		["air_back", "Backtrack", 9, 5, 21, 10.5, 5.0, 0.101, 147, -1.10, 1.01, 0.61],
		["air_up", "Skyward Route", 7, 6, 18, 7.5, 4.0, 0.073, 84, 0.20, 1.88, 0.68],
		["air_down", "Falling Pick", 15, 6, 27, 11.5, 4.8, 0.091, -60, 0.15, -0.03, 0.64],
		["special_neutral", "Trail Line", 15, 3, 25, 6.5, 2.4, 0.042, 30, 0.85, 1.12, 0.38, {"ability": "explorer_hook", "ability_data": {"speed": 13.0, "lifetime": 29, "max_owned": 1, "pull_speed": 12.0, "pull_stun": 28}, "purpose": "Fire one short-range hook. A damaging hit reels the rival toward the Explorer and primes Route.", "counterplay": "Shield or dodge the narrow hook; its 25-tick recovery is vulnerable."}],
		["special_side", "Trail Rush", 13, 8, 28, 11.0, 5.1, 0.088, 39, 0.92, 0.85, 0.66, {"ability": "explorer_rush", "movement": [{"from": 10, "to": 22, "velocity": Vector2(11.6, 0), "mode": "set"}], "ability_data": {"empowered_velocity_scale": 1.12}, "purpose": "Rush along a committed ground route; a stored Route charge extends the travel.", "counterplay": "Jump or shield the line, then punish the long ending."}],
		["special_up", "Summit Ascent", 10, 12, 35, 9.0, 4.6, 0.079, 76, 0.52, 1.55, 0.72, {"ability": "explorer_recovery", "movement": [{"from": 10, "to": 16, "velocity": Vector2(3.5, 13.7), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.17, "empowered_velocity_scale": 1.12}, "purpose": "A rising climb recovers once per airtime; Route lengthens the arc slightly.", "counterplay": "Cover the predictable upper end or the helpless descent."}],
		["special_down", "Anchor Stance", 10, 6, 30, 9.0, 4.1, 0.077, 55, 0.75, 0.49, 0.74, {"ability": "explorer_anchor", "armor_windows": [Vector2i(7, 15)], "armor_threshold": 7.0, "purpose": "Plant a low strike with brief light-hit armor during its commitment.", "counterplay": "Grab, use a stronger hit, or wait for the 30-tick recovery."}],
		["ultimate", "Uncharted Finish", 29, 6, 39, 10.0, 4.1, 0.049, 35, 1.22, 1.07, 0.85, {"ability": "explorer_ultimate", "movement": [{"from": 28, "to": 34, "velocity": Vector2(11.0, 0), "mode": "set"}], "ability_data": {"meter_cost": 100.0, "requires_opener": true, "capture_ticks": 42, "capture_distance": 0.8, "followup_damage": 12.0, "finisher_damage": 17.0, "finisher_base": 8.2, "finisher_growth": 0.127}, "purpose": "A visible forward lunge confirms a grapple-and-slam sequence only on contact.", "counterplay": "Jump, shield, or dodge the opener; a whiff still spends the meter."}],
		["grab", "Handhold", 8, 3, 24, 0, 0, 0, 0, 0.86, 1.02, 0.46],
		["throw_forward", "Over the Ridge", 8, 1, 18, 8, 5.0, 0.084, 34, 0.8, 1.0, 0.5],
		["throw_back", "Wrong Turn", 10, 1, 20, 9, 5.3, 0.099, 147, -0.8, 1.0, 0.5],
		["throw_up", "High Pass", 8, 1, 19, 7, 4.4, 0.072, 84, 0.3, 1.6, 0.5],
		["throw_down", "Ground Route", 10, 1, 19, 7, 3.4, 0.055, 71, 0.6, 0.3, 0.5]
	])
