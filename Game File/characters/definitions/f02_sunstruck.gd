extends RefCounted

static func create() -> FighterDefinition:
	return FighterContentBuilder.build({
		"id": "f02_sunstruck", "display_name": "Sunstruck", "archetype": "Ricochet trickster",
		"final_ko_caption": "VIP EXIT",
		"description": "Returning cap discs, theatrical spacing, and reflector routes turn the rooftop into a stage.",
		"palette": Color("ffcf4e"), "accent": Color("ff64bc"), "run_speed": 8.8, "air_speed": 7.6, "weight": 0.88,
		"acceleration": 67.0, "air_acceleration": 31.0, "jump_velocity": 12.4, "gravity": 20.5,
		"mechanic": "encore", "passive_description": "Catch your returning disc 3 times to empower the next throw. Encore resets after spending it or losing a stock. One disc and one reflector at a time.",
		"taunts": ["You were an incredible audience.", "VIP section. Very exclusive."],
		"beginner_combos": ["Side tilt → forward air against a nearby low-damage opponent; follow their drift.", "Returning Hat Trick → dash attack when the disc brings pressure from behind; the return may be dodged."]
	}, [
		["jab1", "Opening Act", 6, 3, 12, 3.0, 2.1, 0.034, 12, 0.72, 1.15, 0.40],
		["jab2", "Double Booking", 6, 3, 12, 3.5, 2.5, 0.036, 18, 0.89, 1.08, 0.43],
		["jab3", "Standing Ovation", 8, 5, 20, 6.0, 4.2, 0.071, 40, 1.02, 0.90, 0.57],
		["tilt_side", "Guest List", 9, 5, 17, 7.0, 3.8, 0.077, 34, 1.22, 0.88, 0.54],
		["tilt_up", "Raise the Roof", 8, 5, 18, 6.0, 3.7, 0.071, 87, 0.22, 1.83, 0.62],
		["tilt_down", "Low Cover", 7, 4, 15, 5.5, 3.4, 0.056, 66, 0.98, 0.26, 0.53],
		["dash", "Late Entrance", 10, 7, 22, 8.0, 4.4, 0.080, 40, 1.06, 0.70, 0.63, {"movement": [{"from": 7, "to": 16, "velocity": Vector2(11.8, 0), "mode": "set"}]}],
		["heavy_side", "Headliner Heel", 21, 5, 29, 14.5, 5.8, 0.112, 30, 1.37, 1.05, 0.64],
		["heavy_up", "Roof Raiser", 18, 7, 27, 13.0, 5.6, 0.111, 86, 0.0, 1.96, 0.75],
		["heavy_down", "Afterparty Sweep", 23, 8, 30, 13.5, 5.4, 0.103, 24, 0.10, 0.27, 1.13],
		["air_neutral", "Disco Radius", 7, 10, 17, 6.0, 3.5, 0.064, 43, 0.0, 0.98, 1.03],
		["air_forward", "Velvet Heel", 10, 5, 20, 9.0, 4.4, 0.088, 34, 1.25, 0.95, 0.60],
		["air_back", "Encore Exit", 8, 4, 19, 10.0, 4.9, 0.102, 149, -1.13, 1.00, 0.58],
		["air_up", "Skybox", 6, 6, 17, 6.5, 3.8, 0.070, 83, 0.18, 1.89, 0.65],
		["air_down", "Curtain Drop", 15, 6, 28, 11.0, 4.7, 0.083, -62, 0.10, -0.04, 0.62],
		["special_neutral", "Hat Trick", 12, 3, 20, 6.0, 3.4, 0.053, 35, 0.85, 1.10, 0.43, {"ability": "sun_disc", "rehit_ticks": 24, "ability_data": {"speed": 9.2, "return_tick": 32, "lifetime": 115, "max_owned": 1, "catch_radius": 0.85, "empowered_damage_scale": 1.45, "empowered_radius_scale": 1.15}, "purpose": "Throw a returning energy cap. Catching three returns empowers the next disc.", "counterplay": "Jump the outward route, shield its return, or pressure the catch position."}],
		["special_side", "Velvet Rope", 13, 6, 24, 9.0, 4.2, 0.078, 32, 1.28, 1.03, 0.74, {"ability": "sun_ribbon", "movement": [{"from": 18, "to": 25, "velocity": Vector2(8.0, 0), "mode": "set"}], "purpose": "Sweeping ribbon creates room before a short lateral reposition.", "counterplay": "Punish startup or follow the visible reposition; the move is not invulnerable."}],
		["special_up", "VIP Launch", 12, 10, 34, 8.0, 4.5, 0.071, 83, 0.0, 0.50, 0.79, {"ability": "sun_recovery", "movement": [{"from": 12, "to": 16, "velocity": Vector2(2.5, 15.5), "mode": "set"}], "ability_data": {"recovery": true, "helpless": true, "steering": 0.28}, "effects": ["pyro_burst", "sun_rays"], "purpose": "Visible pyro startup propels Sunstruck upward once per airtime.", "counterplay": "Hit the startup or wait for the vulnerable descent."}],
		["special_down", "Mirror Service", 17, 1, 26, 0.0, 0.0, 0.0, 0, 0.85, 0.20, 0.42, {"ability": "sun_reflector", "ability_data": {"max_owned": 1, "lifetime": 420, "durability": 9.0, "redirect_angle": 30.0, "radius": 0.65}, "purpose": "Place one visible, destructible puck that redirects your disc 30 degrees upward.", "counterplay": "Destroy the puck, avoid its visible route, or punish the placement."}],
		["ultimate", "The Main Event", 38, 24, 37, 8.0, 4.2, 0.077, 78, 3.0, 0.75, 1.80, {"ability": "sun_ultimate", "rehit_ticks": 8, "active_windows": [Vector2i(38, 40), Vector2i(46, 48), Vector2i(54, 56)], "ability_data": {"meter_cost": 100.0, "warning_ticks": 38, "zone_radius": 1.8, "aim_range": 5.0, "impacts": 3, "finisher_base": 7.2, "finisher_growth": 0.12}, "effects": ["spotlight_warning", "solar_impact"], "purpose": "Aim a bounded spotlight before three solar impacts strike the marked region.", "counterplay": "Exit the warning circle or punish the visibly stationary setup."}],
		["grab", "Backstage Pass", 8, 3, 24, 0, 0, 0, 0, 0.90, 1.02, 0.45],
		["throw_forward", "Front Row", 8, 1, 17, 7, 4.8, 0.084, 33, 0.8, 1.0, 0.5],
		["throw_back", "VIP Exit", 10, 1, 20, 8, 5.2, 0.096, 148, -0.8, 1.0, 0.5],
		["throw_up", "Upper Circle", 8, 1, 19, 6, 4.2, 0.069, 86, 0.3, 1.6, 0.5],
		["throw_down", "No Re-entry", 10, 1, 18, 6, 3.2, 0.052, 72, 0.6, 0.3, 0.5]
	])
