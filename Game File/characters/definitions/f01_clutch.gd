extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f01_clutch", "display_name": "Clutch", "archetype": "Kinetic all-rounder",
		"final_ko_caption": "CLUTCH PERFORMANCE",
		"description": "Clean combinations, flexible air control, and momentum-powered clutch plays.",
		"palette": Color("22bdff"), "accent": Color("edfbff"), "run_speed": 8.3, "air_speed": 6.9, "weight": 1.0,
		"acceleration": 62.0, "air_acceleration": 28.0, "jump_velocity": 12.5, "gravity": 21.0,
		"mechanic": "momentum", "passive_description": "Different successful attacks build up to 3 Momentum pips within 240 ticks. Neutral, side, and up specials spend one pip for an extra kinetic effect. Time Out preserves pips. Shields and repeated move IDs grant none.",
		"taunts": ["Check the scoreboard.", "I'd like a replay."],
		"beginner_combos": ["Jab 1 → Jab 2 → Jab 3 at low damage, pressing light again during confirmed links.", "Down tilt → short-hop forward air near center stage; DI and higher damage can escape."]
	}, [
		["jab1", "Quick Check", 5, 3, 10, 3.5, 2.4, 0.035, 15, 0.66, 1.12, 0.41, {"impact_offset": Vector2(0.78, 1.50)}],
		["jab2", "Cross Traffic", 6, 3, 11, 4.0, 2.8, 0.038, 20, 0.78, 1.08, 0.44],
		["jab3", "Final Word", 7, 4, 17, 6.5, 4.5, 0.072, 35, 0.90, 1.12, 0.52],
		["tilt_side", "Straight Answer", 8, 4, 15, 8.0, 4.3, 0.079, 32, 1.02, 0.92, 0.48],
		["tilt_up", "Ceiling Check", 7, 5, 16, 7.0, 4.1, 0.072, 82, 0.38, 1.75, 0.56],
		["tilt_down", "Ankle Breaker", 6, 4, 14, 6.0, 3.8, 0.060, 64, 0.88, 0.29, 0.49],
		["dash", "Fast Break", 9, 6, 21, 10.0, 4.9, 0.085, 38, 0.90, 0.99, 0.60, {"movement": [{"from": 6, "to": 15, "velocity": Vector2(11, 0), "mode": "set"}]}],
		["heavy_side", "Shoulder Season", 19, 5, 27, 16.0, 6.4, 0.121, 32, 1.05, 0.98, 0.65, {"impact_offset": Vector2(1.05, 1.42)}],
		["heavy_up", "Over the Top", 18, 6, 26, 14.0, 6.1, 0.118, 85, 0.28, 1.98, 0.70],
		["heavy_down", "Sweep the Series", 20, 6, 29, 15.0, 5.9, 0.115, 26, 0.52, 0.31, 0.96],
		["air_neutral", "Scissor Cut", 6, 8, 16, 7.0, 3.8, 0.070, 45, 0.10, 0.99, 0.92],
		["air_forward", "Away Game", 9, 5, 20, 10.0, 4.7, 0.097, 35, 1.01, 0.96, 0.64],
		["air_back", "Back Court", 7, 4, 22, 12.0, 5.4, 0.113, 150, -0.99, 1.03, 0.62],
		["air_up", "High Five", 6, 5, 16, 7.0, 4.0, 0.074, 82, 0.20, 1.84, 0.62],
		["air_down", "Down Payment", 13, 5, 27, 12.0, 5.0, 0.090, -68, 0.25, -0.10, 0.58],
		["special_neutral", "Overtime", 14, 4, 23, 10.0, 4.8, 0.087, 30, 1.1, 1.05, 0.64, {"ability": "clutch_palm", "charge_max": 60, "charge_reach_scale": 0.65, "ability_data": {"speed": 11.0, "lifetime": 22, "max_owned": 2, "empowered_second_ring_delay": 7, "empowered_damage_scale": 0.35}, "purpose": "Charge a short-to-medium palm blast. Momentum adds a small second ring.", "counterplay": "Jump the linear blast or close in during charge/recovery."}],
		["special_side", "Personal Foul", 11, 9, 27, 12.0, 5.7, 0.095, 34, 0.42, 1.30, 0.22, {"ability": "clutch_rush", "movement": [{"from": 9, "to": 19, "velocity": Vector2(14, 0), "mode": "set"}], "ability_data": {"empowered_burst_radius": 1.15, "empowered_burst_damage": 3.0}, "purpose": "Step-in shoulder check. Momentum adds an end-of-dash burst.", "counterplay": "Shield or sidestep with a dodge, then punish the 27-tick recovery."}],
		["special_up", "Second Wind", 7, 12, 32, 9.0, 4.8, 0.085, 76, 0.44, 1.72, 0.64, {"ability": "clutch_recovery", "movement": [{"from": 7, "to": 13, "velocity": Vector2(4.7, 13.8), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.20, "empowered_velocity_scale": 1.12}, "purpose": "Angled uppercut recovery once per airtime; Momentum modestly extends travel.", "counterplay": "Wait outside the rising fist and cover the helpless descent."}],
		["special_down", "Time Out", 5, 11, 30, 11.0, 5.7, 0.094, 40, 0.86, 1.0, 0.90, {"ability": "clutch_counter", "ability_data": {"counter_from": 5, "counter_to": 15, "counter_damage_scale": 1.25, "counter_damage_cap": 19.0}, "purpose": "Planted counter: strike during ticks 5–15 triggers a kinetic shove.", "counterplay": "Grab the stance or wait, then punish its long recovery."}],
		["ultimate", "Clutch Time", 26, 7, 36, 8.0, 3.5, 0.030, 25, 0.48, 1.25, 0.24, {"ability": "clutch_ultimate", "movement": [{"from": 26, "to": 32, "velocity": Vector2(15, 0), "mode": "set"}], "ability_data": {"meter_cost": 100.0, "requires_opener": true, "followup_damage": 16.0, "finisher_damage": 15.0, "finisher_base": 8.5, "finisher_growth": 0.13, "capture_ticks": 40, "capture_distance": 0.70}, "purpose": "Telegraphed rush confirms a short combination only if its opener connects.", "counterplay": "Jump, shield, or dodge the opener; a miss spends the meter."}],
		["grab", "Jersey Check", 7, 3, 23, 0, 0, 0, 0, 0.82, 1.02, 0.47],
		["throw_forward", "Home Delivery", 7, 1, 16, 8, 5.2, 0.092, 30, 0.8, 1.0, 0.5],
		["throw_back", "Reverse Call", 9, 1, 18, 9, 5.4, 0.102, 145, -0.8, 1.0, 0.5],
		["throw_up", "Raising Stakes", 8, 1, 18, 7, 4.5, 0.072, 85, 0.3, 1.6, 0.5],
		["throw_down", "Floor Seats", 9, 1, 17, 7, 3.5, 0.057, 68, 0.6, 0.3, 0.5]
	])
