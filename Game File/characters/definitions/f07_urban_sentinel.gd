extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f07_urban_sentinel", "display_name": "Urban Sentinel", "archetype": "Defensive zone holder",
		"final_ko_caption": "AREA SECURED",
		"description": "Holds a line with guarded strikes, a short pulse, and a telegraphed lockdown zone.",
		"palette": Color("70b9e8"), "accent": Color("f4d66c"), "run_speed": 7.3, "air_speed": 6.2, "weight": 1.13,
		"acceleration": 52.0, "air_acceleration": 24.0, "jump_velocity": 12.1, "gravity": 22.0,
		"mechanic": "sentinel", "passive_description": "A successful parry stores one Guard charge for 300 ticks. Down special spends it to enlarge and strengthen its close pulse. The down-special windup has one-hit armor against attacks of at most 8 damage; grabs and stronger attacks interrupt it.",
		"taunts": ["This area is under control.", "Stand behind the line."],
		"beginner_combos": ["Shield a close attack → Fortify Pulse to push the rival away; the pulse is short range.", "Side tilt → forward air near an edge; the rival can drift out."]
	}, [
		["jab1", "Watch Tap", 6, 3, 12, 3.4, 2.3, 0.034, 17, 0.72, 1.11, 0.44],
		["jab2", "Guard Check", 7, 3, 13, 4.1, 2.8, 0.039, 23, 0.88, 1.11, 0.47],
		["jab3", "Clear the Line", 9, 5, 21, 7.0, 4.5, 0.073, 42, 1.05, 0.99, 0.59],
		["tilt_side", "Barrier Hand", 9, 5, 18, 8.0, 4.2, 0.079, 34, 1.16, 1.03, 0.58],
		["tilt_up", "High Alert", 9, 5, 19, 7.5, 4.0, 0.075, 83, 0.30, 1.85, 0.69],
		["tilt_down", "Street Sweep", 8, 5, 18, 7.0, 3.7, 0.063, 62, 1.00, 0.29, 0.59],
		["dash", "Patrol Break", 12, 6, 24, 9.5, 4.8, 0.085, 42, 1.02, 0.77, 0.67, {"movement": [{"from": 9, "to": 17, "velocity": Vector2(9.8, 0), "mode": "set"}]}],
		["heavy_side", "Security Breach", 22, 6, 31, 17.0, 6.3, 0.119, 31, 1.33, 1.10, 0.73],
		["heavy_up", "Roof Watch", 20, 7, 30, 15.5, 6.0, 0.115, 84, 0.25, 1.98, 0.80],
		["heavy_down", "Roadblock", 23, 7, 32, 16.0, 5.9, 0.110, 27, 0.28, 0.27, 1.08],
		["air_neutral", "Perimeter", 8, 9, 20, 7.5, 4.0, 0.071, 45, 0.04, 1.05, 1.00],
		["air_forward", "Air Patrol", 12, 6, 23, 11.0, 5.0, 0.094, 34, 1.20, 1.00, 0.67],
		["air_back", "Rear Guard", 10, 5, 22, 11.5, 5.2, 0.104, 149, -1.12, 1.03, 0.65],
		["air_up", "Overwatch", 8, 6, 19, 8.5, 4.4, 0.078, 84, 0.22, 1.91, 0.71],
		["air_down", "Checkpoint Drop", 16, 6, 29, 12.0, 5.0, 0.094, -62, 0.13, -0.05, 0.69],
		["special_neutral", "Warning Shot", 17, 3, 25, 8.0, 3.8, 0.061, 34, 0.92, 1.12, 0.45, {"ability": "sentinel_bolt", "ability_data": {"speed": 9.0, "lifetime": 30, "max_owned": 1}, "purpose": "Send one medium-range pulse straight ahead to hold space.", "counterplay": "Jump the straight shot or close in during its startup."}],
		["special_side", "Containment Drive", 15, 8, 30, 12.0, 5.2, 0.089, 41, 0.91, 0.83, 0.73, {"ability": "sentinel_drive", "armor_windows": [Vector2i(12, 19)], "armor_threshold": 6.0, "movement": [{"from": 13, "to": 23, "velocity": Vector2(10.2, 0), "mode": "set"}], "purpose": "A deliberate advancing shoulder strike with brief light-hit armor.", "counterplay": "Grab, hit hard, or jump the predictable forward lane."}],
		["special_up", "High Ground", 11, 12, 37, 10.0, 4.9, 0.081, 76, 0.48, 1.57, 0.77, {"ability": "sentinel_recovery", "movement": [{"from": 11, "to": 17, "velocity": Vector2(2.7, 12.9), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.12}, "purpose": "A guarded vertical ascent recovers once per airtime.", "counterplay": "Wait outside the rising shoulder and intercept the short descent."}],
		["special_down", "Fortify Pulse", 18, 5, 32, 8.5, 4.6, 0.082, 62, 0.0, 1.00, 1.37, {"ability": "sentinel_pulse", "armor_windows": [Vector2i(5, 22)], "armor_threshold": 8.0, "ability_data": {"pulse_radius": 1.37, "empowered_radius_scale": 1.20, "empowered_damage_scale": 1.30}, "purpose": "Brace through one light strike, then release a close pulse; Guard charge improves it.", "counterplay": "Grab or use a strong hit during the brace, or back out of pulse range."}],
		["ultimate", "Lockdown Protocol", 40, 7, 40, 29.0, 7.6, 0.123, 39, 1.88, 1.10, 1.8, {"ability": "sentinel_ultimate", "ability_data": {"meter_cost": 100.0, "warning_ticks": 40, "zone_width": 4.5, "zone_height": 2.4}, "purpose": "Mark a wide rectangle in front of the Sentinel before one powerful pulse.", "counterplay": "Leave the visible zone or punish the stationary setup before it fires."}],
		["grab", "Detain", 8, 3, 25, 0, 0, 0, 0, 0.90, 1.02, 0.48],
		["throw_forward", "Move Along", 8, 1, 19, 9, 5.2, 0.087, 34, 0.8, 1.0, 0.5],
		["throw_back", "Clear Out", 11, 1, 21, 10, 5.6, 0.103, 149, -0.8, 1.0, 0.5],
		["throw_up", "Upper Perimeter", 9, 1, 20, 8, 4.8, 0.077, 84, 0.3, 1.6, 0.5],
		["throw_down", "Hold Position", 11, 1, 20, 8, 3.6, 0.058, 72, 0.6, 0.3, 0.5]
	])
