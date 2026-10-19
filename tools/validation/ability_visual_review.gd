extends "presentation_scenarios.gd"
## Reuses the real input/ability fixtures, with normal combat framing so effect
## legibility is reviewed at playable scale. Optional --flashes=0..1 is local
## to this test process; the user's saved settings are never changed.

func _detail_camera(_single: bool = false) -> void:
	# Keep the camera produced by the fixture's ordinary _update_camera calls.
	camera_mode = "ordinary gameplay camera; detail override disabled for ability readability review"

func _fresh(id: String, other: String = "f04_deadfall", distance: float = 2.0, mode: String = "Fair Fight") -> void:
	await super._fresh(id, other, distance, mode)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--flashes="):
			app.settings.values.flashes = clampf(float(arg.trim_prefix("--flashes=")), 0.0, 1.0)
