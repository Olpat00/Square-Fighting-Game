extends "res://../tools/validation/presentation_scenarios.gd"
## Same real animation/input fixtures with the shipped Low setting applied.
## Run with -- --case=normal_light --output=<fresh evidence directory>.

func _fresh(id: String, other: String = "f04_deadfall", distance: float = 2.0, preset: String = "Fair Fight") -> void:
	app.settings.values.graphics = "Low"
	app.apply_settings()
	super._fresh(id, other, distance, preset)
