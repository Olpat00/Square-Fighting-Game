extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f08_midnight_gentleman", "display_name": "Midnight Gentleman", "archetype": "Evasive duelist",
		"final_ko_caption": "GOOD EVENING",
		"description": "Uses bounded shadow steps to change sides and punish openings with precise close attacks.",
		"palette": Color("a78de8"), "accent": Color("e6d5a4"), "run_speed": 8.5, "air_speed": 7.3, "weight": 0.93,
		"acceleration": 63.0, "air_acceleration": 30.0, "jump_velocity": 12.7, "gravity": 20.6,
		"mechanic": "shadowstep", "passive_description": "A damaging aerial hit stores one Veil charge for 240 ticks. The next side special spends it for a longer Shadow Step. Shadow Step changes position only after visible startup, has a brief protected transition, and cannot travel beyond the arena bounds.",
		"taunts": ["A pleasure, as always.", "You seem to have lost your place."],
		"beginner_combos": ["Forward air → Shadow Step to change sides after a confirmed hit; watch where the rival lands.", "Down tilt → up tilt at close range; the second hit can be shielded."]
	}, [
		["jab1", "Polite Reminder", 5, 3, 12, 3.0, 2.1, 0.033, 17, 0.70, 1.12, 0.42],
		["jab2", "Second Opinion", 6, 3, 12, 3.6, 2.6, 0.037, 25, 0.84, 1.11, 0.45],
		["jab3", "Final Word", 8, 4, 19, 6.0, 4.1, 0.069, 39, 1.02, 1.04, 0.55],
		["tilt_side", "Cuff Check", 8, 5, 17, 7.0, 3.9, 0.076, 34, 1.18, 1.02, 0.55],
		["tilt_up", "Raised Glass", 7, 5, 18, 6.5, 3.8, 0.072, 84, 0.27, 1.84, 0.66],
		["tilt_down", "Low Courtesy", 7, 4, 16, 6.0, 3.4, 0.057, 65, 1.04, 0.27, 0.54],
		["dash", "Late Arrival", 10, 6, 21, 8.5, 4.5, 0.081, 42, 1.04, 0.78, 0.63, {"movement": [{"from": 8, "to": 16, "velocity": Vector2(11.5, 0), "mode": "set"}]}],
		["heavy_side", "Black Tie Break", 20, 5, 29, 15.0, 5.8, 0.112, 32, 1.37, 1.09, 0.66],
		["heavy_up", "Moonlit Toast", 18, 6, 27, 13.5, 5.5, 0.105, 85, 0.22, 1.96, 0.74],
		["heavy_down", "Curtain Sweep", 21, 7, 29, 14.0, 5.4, 0.103, 27, 0.26, 0.28, 1.04],
		["air_neutral", "Evening Turn", 7, 9, 18, 6.5, 3.6, 0.067, 43, 0.05, 1.01, 0.95],
		["air_forward", "Velvet Cut", 10, 5, 20, 9.5, 4.5, 0.090, 34, 1.22, 0.98, 0.61],
		["air_back", "Parting Gift", 8, 5, 20, 10.0, 4.9, 0.098, 148, -1.11, 1.00, 0.59],
		["air_up", "High Society", 6, 6, 17, 7.0, 3.9, 0.071, 84, 0.20, 1.88, 0.66],
		["air_down", "Last Waltz", 14, 6, 26, 11.0, 4.7, 0.087, -61, 0.14, -0.04, 0.63],
		["special_neutral", "Dusk Arc", 14, 3, 23, 7.5, 3.7, 0.060, 35, 0.91, 1.15, 0.43, {"ability": "gentleman_arc", "ability_data": {"speed": 10.0, "lifetime": 27, "max_owned": 1}, "purpose": "Send a short, straight shadow arc to check an approach.", "counterplay": "Jump above its line or rush the startup."}],
		["special_side", "Shadow Step", 16, 5, 29, 10.5, 4.8, 0.085, 38, 0.85, 1.04, 0.62, {"ability": "gentleman_step", "invulnerable_windows": [Vector2i(16, 19)], "ability_data": {"distance": 2.7, "empowered_distance": 3.5}, "purpose": "After a visible windup, step through a nearby rival and strike from the new position; Veil extends the step.", "counterplay": "Watch the destination and punish the lengthy recovery or shield its follow-up."}],
		["special_up", "Moonrise", 9, 13, 35, 8.5, 4.4, 0.077, 77, 0.48, 1.55, 0.70, {"ability": "gentleman_recovery", "movement": [{"from": 9, "to": 15, "velocity": Vector2(3.0, 13.9), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.20}, "purpose": "Rise in a controlled arc once per airtime.", "counterplay": "Cover the exposed approach before the rise or the helpless descent."}],
		["special_down", "Vanishing Courtesy", 10, 1, 32, 0.0, 0.0, 0.0, 0, 0.0, 1.0, 0.42, {"ability": "gentleman_retreat", "invulnerable_windows": [Vector2i(10, 14)], "ability_data": {"distance": 2.0}, "purpose": "Step backward after a visible tell, briefly avoiding attacks without dealing damage.", "counterplay": "Follow the retreat or punish its long recovery; grabs before the step still work."}],
		["ultimate", "Midnight Appointment", 30, 6, 40, 9.0, 3.8, 0.041, 37, 1.10, 1.08, 0.76, {"ability": "gentleman_ultimate", "movement": [{"from": 28, "to": 35, "velocity": Vector2(12.0, 0), "mode": "set"}], "ability_data": {"meter_cost": 100.0, "requires_opener": true, "capture_ticks": 39, "capture_distance": 0.82, "followup_damage": 12.0, "finisher_damage": 16.0, "finisher_base": 7.8, "finisher_growth": 0.125}, "purpose": "A telegraphed duelist's lunge confirms a short finishing sequence only if it connects.", "counterplay": "Dodge, jump, or shield the opener; a miss spends the meter."}],
		["grab", "Private Invitation", 8, 3, 24, 0, 0, 0, 0, 0.88, 1.02, 0.45],
		["throw_forward", "After You", 8, 1, 18, 8, 4.9, 0.084, 34, 0.8, 1.0, 0.5],
		["throw_back", "Exit Stage Left", 10, 1, 20, 9, 5.2, 0.097, 148, -0.8, 1.0, 0.5],
		["throw_up", "To the Rafters", 8, 1, 19, 7, 4.4, 0.070, 84, 0.3, 1.6, 0.5],
		["throw_down", "Final Bow", 10, 1, 19, 7, 3.3, 0.053, 71, 0.6, 0.3, 0.5]
	])
