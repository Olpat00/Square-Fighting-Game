extends "rebuild_stage_review.gd"
## Diagnostic variants of the exact same neutral frame. Does not change any
## saved settings or production lighting. Used to isolate surface artifacts.

func _capture(name_value: String, purpose: String) -> void:
	await super._capture(name_value, purpose)
	if name_value != "lunar_reach_high": return
	var environment: Environment = app.world.stage.environment
	var key: DirectionalLight3D = app.world.stage.get_node("UnfilteredSolarKey")
	var ssao: bool = environment.ssao_enabled
	var ssil: bool = environment.ssil_enabled
	environment.ssao_enabled = false
	await super._capture("probe_without_ssao", "Identical neutral frame without SSAO")
	environment.ssao_enabled = ssao
	environment.ssil_enabled = false
	await super._capture("probe_without_ssil", "Identical neutral frame without SSIL")
	environment.ssil_enabled = ssil
	key.shadow_enabled = false
	await super._capture("probe_without_shadows", "Identical neutral frame without directional shadows")
	key.shadow_enabled = true
