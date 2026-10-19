extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f04_deadfall", "display_name": "Deadfall", "archetype": "Trap-setting scrapper",
		"final_ko_caption": "THAT WAS LOAD-BEARING",
		"description": "Layer visible triplines and rolling constructs, then improvise a route through the chaos.",
		"palette": Color("76d89b"), "accent": Color("ffb64a"), "run_speed": 7.6, "air_speed": 6.5, "weight": 1.06,
		"acceleration": 55.0, "air_acceleration": 25.0, "jump_velocity": 12.6, "gravity": 21.5,
		"mechanic": "fieldcraft", "passive_description": "A triggered armed trap grants one Quick Fix charge. The next side or up special spends it for 12% more travel. Charges never stack, and recovery remains once per airtime.",
		"taunts": ["The instructions were mostly pictures.", "That was load-bearing."],
		"beginner_combos": ["Armed Trip Hazard → side tilt while the opponent is nearby; they can destroy or jump over the setup.", "Down tilt → up air against low-damage opponents above you; DI can leave the arc."]
	}, [
		["jab1", "Quick Fix", 6, 3, 12, 3.5, 2.3, 0.033, 15, 0.69, 1.04, 0.44],
		["jab2", "Measure Twice", 7, 4, 13, 4.5, 2.8, 0.037, 22, 0.83, 1.10, 0.50],
		["jab3", "Cut Once", 9, 5, 20, 7.0, 4.5, 0.074, 35, 1.05, 1.06, 0.60],
		["tilt_side", "Backhand Estimate", 10, 5, 19, 9.0, 4.3, 0.084, 35, 1.18, 1.02, 0.60],
		["tilt_up", "Overhang", 8, 6, 19, 7.5, 4.1, 0.076, 80, 0.42, 1.84, 0.69],
		["tilt_down", "Loose Floorboard", 8, 5, 17, 7.0, 3.7, 0.061, 64, 1.05, 0.24, 0.59],
		["dash", "Weekend Rush", 11, 6, 24, 10.0, 4.8, 0.083, 42, 1.02, 0.77, 0.67, {"movement": [{"from": 8, "to": 16, "velocity": Vector2(10.5, 0), "mode": "set"}]}],
		["heavy_side", "Full Renovation", 22, 6, 31, 17.0, 6.3, 0.119, 32, 1.32, 1.12, 0.74],
		["heavy_up", "Open Plan", 20, 7, 29, 15.5, 6.0, 0.115, 84, 0.34, 2.01, 0.80],
		["heavy_down", "Groundwork", 22, 7, 32, 16.0, 5.9, 0.111, 25, 0.31, 0.23, 1.14],
		["air_neutral", "Loose Hardware", 8, 9, 20, 7.5, 3.9, 0.071, 45, 0.10, 1.02, 0.97],
		["air_forward", "Flying Estimate", 12, 6, 24, 11.0, 4.9, 0.095, 35, 1.20, 1.00, 0.67],
		["air_back", "Back Door", 9, 5, 23, 12.0, 5.2, 0.109, 149, -1.12, 1.03, 0.63],
		["air_up", "Attic Access", 8, 6, 19, 8.0, 4.2, 0.076, 83, 0.26, 1.88, 0.69],
		["air_down", "Demolition Drop", 16, 6, 30, 12.5, 5.0, 0.095, -63, 0.19, -0.08, 0.67],
		["special_neutral", "Splinter Service", 17, 3, 26, 9.0, 4.2, 0.071, 36, 0.96, 0.27, 0.48, {"ability": "deadfall_log", "ability_data": {"speed": 7.0, "lifetime": 95, "max_owned": 2, "terrain_bound": true, "fall_at_edges": true}, "effects": ["bark_arc"], "purpose": "Send a finite rolling energy log along its platform; it falls at the edge.", "counterplay": "Jump the ground route or occupy a different height."}],
		["special_side", "Shortcut", 13, 9, 28, 11.0, 5.0, 0.088, 59, 0.95, 0.60, 0.67, {"ability": "deadfall_slide", "movement": [{"from": 9, "to": 20, "velocity": Vector2(11.8, 0), "mode": "set"}], "ability_data": {"quick_fix_velocity_scale": 1.12}, "purpose": "Low plank rush ends in a rising strike; Quick Fix adds modest travel.", "counterplay": "Shield the rush and punish its committed recovery."}],
		["special_up", "Branch Office", 10, 14, 33, 8.5, 4.5, 0.078, 76, 0.73, 1.49, 0.70, {"ability": "deadfall_recovery", "movement": [{"from": 10, "to": 15, "velocity": Vector2(4.0, 13.3), "mode": "set"}, {"from": 16, "to": 22, "velocity": Vector2(7.2, 8.0), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.15, "quick_fix_velocity_scale": 1.12, "temporary_prop": "branch"}, "purpose": "Follow a fixed rising swing arc around a temporary branch; Quick Fix extends travel.", "counterplay": "Cover the predictable end of the swing; the branch is not a platform."}],
		["special_down", "Trip Hazard", 18, 1, 27, 8.0, 3.5, 0.056, 72, 0.90, 0.16, 0.67, {"ability": "deadfall_trap", "ability_data": {"arming_ticks": 30, "lifetime": 540, "max_owned": 2, "durability": 7.0, "trigger_limit": 1, "radius": 0.80, "replace_oldest": true}, "purpose": "Plant a visible tripline: arms after 30 ticks, hits once, grants Quick Fix. Maximum two.", "counterplay": "Destroy it during arming, jump over it, or wait for expiry."}],
		["ultimate", "Questionable Landscaping", 43, 7, 38, 31.0, 8.1, 0.129, 38, 2.4, 1.90, 1.6, {"ability": "deadfall_ultimate", "ability_data": {"meter_cost": 100.0, "warning_ticks": 43, "zone_length": 5.6, "zone_width": 1.3, "zone_angle": -48.0, "temporary_prop": "tree", "debris_damage": 0.0}, "effects": ["diagonal_warning", "tree_impact", "cosmetic_bark"], "purpose": "Mark a diagonal region before dropping a huge tree construct; debris is cosmetic.", "counterplay": "Move outside the marked diagonal or dodge the single committed impact."}],
		["grab", "Cable Management", 8, 3, 25, 0, 0, 0, 0, 0.91, 1.01, 0.49],
		["throw_forward", "Curbside Pickup", 8, 1, 19, 9, 5.2, 0.087, 33, 0.8, 1.0, 0.5],
		["throw_back", "Return to Sender", 11, 1, 21, 10, 5.6, 0.104, 148, -0.8, 1.0, 0.5],
		["throw_up", "Loft Conversion", 9, 1, 20, 8, 4.8, 0.077, 83, 0.3, 1.6, 0.5],
		["throw_down", "Foundation Work", 11, 1, 20, 8, 3.6, 0.057, 70, 0.6, 0.3, 0.5]
	])
