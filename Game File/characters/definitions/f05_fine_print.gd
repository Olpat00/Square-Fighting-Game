extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f05_fine_print", "display_name": "Fine Print", "archetype": "Precision counter-striker",
		"final_ko_caption": "DENIED",
		"description": "Crisp spacing, narrow counters, and visible citations turn predictable choices into consequences.",
		"palette": Color("b7a2ff"), "accent": Color("f2efff"), "run_speed": 7.9, "air_speed": 6.6, "weight": 0.96,
		"acceleration": 60.0, "air_acceleration": 26.0, "jump_velocity": 12.2, "gravity": 20.0,
		"mechanic": "citations", "passive_description": "Precise outer-range special hits and parries mark an opponent up to 3 times for 420 ticks. Side heavy and the ultimate consume marks for a bounded launch bonus.",
		"taunts": ["Per my previous combination.", "Your appeal has been noted."],
		"beginner_combos": ["Jab 1 → Jab 2 → Jab 3 after a close whiff; shielded hits cannot confirm links.", "Outer-range Point Taken → advancing side tilt at low damage; respect shield and DI."]
	}, [
		["jab1", "Initial Notice", 5, 2, 12, 3.0, 2.1, 0.031, 12, 0.81, 1.16, 0.35],
		["jab2", "Second Notice", 6, 3, 13, 4.0, 2.7, 0.034, 18, 0.94, 1.11, 0.38],
		["jab3", "Enforcement", 8, 4, 20, 6.5, 4.3, 0.074, 33, 1.11, 1.07, 0.46],
		["tilt_side", "Due Process", 8, 4, 17, 8.5, 4.1, 0.084, 30, 1.29, 0.91, 0.46],
		["tilt_up", "Escalation", 7, 4, 18, 7.0, 4.0, 0.075, 85, 0.29, 1.91, 0.51],
		["tilt_down", "Fine Detail", 7, 3, 17, 6.0, 3.5, 0.058, 66, 1.12, 0.26, 0.45],
		["dash", "Priority Handling", 10, 5, 24, 9.0, 4.6, 0.084, 36, 1.13, 1.04, 0.50, {"movement": [{"from": 7, "to": 14, "velocity": Vector2(10.6, 0), "mode": "set"}]}],
		["heavy_side", "Final Ruling", 20, 4, 31, 16.0, 6.1, 0.120, 29, 1.05, 1.25, 0.54, {"ability_data": {"consume_citations": true, "citation_damage_per_mark": 1.25, "citation_knockback_per_mark": 0.55, "citation_max": 3}, "purpose": "Precise strong straight consumes up to three target citations for capped damage and launch.", "counterplay": "Duck out of its narrow range, shield, or punish the 31-tick recovery."}],
		["heavy_up", "Higher Authority", 19, 5, 29, 14.5, 5.9, 0.118, 87, 0.21, 2.08, 0.58],
		["heavy_down", "Closing Statement", 21, 5, 31, 14.5, 5.6, 0.111, 24, 0.28, 0.21, 1.00],
		["air_neutral", "Standard Clause", 6, 6, 18, 6.5, 3.7, 0.069, 44, 0.12, 1.05, 0.80],
		["air_forward", "Forward Notice", 8, 4, 21, 9.0, 4.5, 0.093, 31, 1.30, 1.03, 0.47],
		["air_back", "Retrospective", 7, 3, 22, 11.5, 5.2, 0.109, 150, -1.21, 1.12, 0.46],
		["air_up", "Executive Summary", 7, 4, 19, 7.5, 4.1, 0.077, 85, 0.20, 2.0, 0.54],
		["air_down", "Footnote", 14, 4, 30, 11.0, 4.8, 0.091, -68, 0.16, -0.12, 0.49],
		["special_neutral", "Point Taken", 12, 4, 26, 10.0, 4.6, 0.081, 30, 2.05, 1.12, 0.55, {"ability": "fine_thrust", "ability_data": {"citation_min_range": 1.8, "citation_max_range": 2.7, "citation_ticks": 420, "citation_max": 3}, "purpose": "A narrow extending palm at a specific range; a clean outer hit adds a citation.", "counterplay": "Move inside the distant hitbox or jump the thin horizontal line."}],
		["special_side", "Hostile Takeover", 14, 4, 30, 8.0, 3.8, 0.061, 30, 0.98, 1.13, 0.30, {"ability": "fine_kick", "movement": [{"from": 10, "to": 17, "velocity": Vector2(6.0, 0), "mode": "set"}], "ability_data": {"requires_opener": true, "followup_delay": 9, "followup_damage": 6.0, "followup_base": 4.9, "followup_growth": 0.088, "citation_ticks": 420}, "purpose": "Measured heel kick adds a follow-up only after confirmed contact.", "counterplay": "Shield or dodge the opener, then punish the committed recovery."}],
		["special_up", "Corporate Ladder", 8, 16, 34, 3.0, 2.7, 0.040, 83, 0.60, 1.54, 0.59, {"ability": "fine_recovery", "rehit_ticks": 5, "active_windows": [Vector2i(8, 10), Vector2i(14, 16), Vector2i(20, 23)], "movement": [{"from": 8, "to": 10, "velocity": Vector2(2.8, 12.4), "mode": "set"}, {"from": 14, "to": 15, "velocity": Vector2(3.6, 12.4), "mode": "set"}, {"from": 20, "to": 21, "velocity": Vector2(3.6, 12.4), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.15, "finisher_base": 5.0}, "effects": ["noncolliding_steps", "geometric_trace"], "purpose": "Three precise rising kicks recover once per airtime; the drawn steps have no collision.", "counterplay": "Stay outside the staircase arc and cover the helpless descent."}],
		["special_down", "Objection", 4, 7, 34, 13.0, 6.0, 0.103, 37, 1.02, 1.1, 0.73, {"ability": "fine_counter", "ability_data": {"counter_from": 4, "counter_to": 10, "counter_damage_scale": 1.4, "counter_damage_cap": 22.0, "citation_ticks": 420}, "purpose": "A narrow 7-tick counter window creates a strong precise reprisal and citation.", "counterplay": "Delay the strike or grab; a missed objection has 34 vulnerable recovery ticks."}],
		["ultimate", "Terms and Conditions", 30, 5, 38, 8.0, 3.5, 0.035, 35, 1.95, 1.08, 1.0, {"ability": "fine_ultimate", "ability_data": {"meter_cost": 100.0, "requires_opener": true, "zone_width": 2.8, "zone_height": 2.2, "capture_ticks": 37, "followup_damage": 13.0, "finisher_damage": 16.0, "finisher_base": 7.6, "finisher_growth": 0.124, "consume_citations": true, "citation_knockback_per_mark": 0.65, "citation_max": 3}, "effects": ["contract_warning", "geometric_impact"], "purpose": "A bounded geometric opener confirms precise attacks; existing citations boost the final launch within a cap.", "counterplay": "Leave the marked rectangle or dodge the opener; missed contact receives no combo."}],
		["grab", "Receipt Required", 7, 2, 25, 0, 0, 0, 0, 0.91, 1.06, 0.39],
		["throw_forward", "Notice Served", 7, 1, 18, 8, 5.0, 0.089, 30, 0.8, 1.0, 0.5],
		["throw_back", "Motion Denied", 9, 1, 20, 9, 5.4, 0.103, 150, -0.8, 1.0, 0.5],
		["throw_up", "Appeal Upheld", 8, 1, 19, 7, 4.5, 0.074, 87, 0.3, 1.6, 0.5],
		["throw_down", "Filed Away", 10, 1, 20, 7, 3.4, 0.054, 71, 0.6, 0.3, 0.5]
	])
