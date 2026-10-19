extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage_script: Script = load("res://stages/ember_foundry/ember_stage.gd")
	if not stage_script or not stage_script.can_instantiate():
		push_error("Ember stage failed to load")
		quit(1)
		return
	var stage: RooftopStage = stage_script.new()
	stage.preset = "Party"
	root.add_child(stage)
	await process_frame
	assert(stage.platforms.size() == 4)
	assert(stage.hazard_warnings.size() == 2)
	assert(stage.hazard_flames.size() == 2)
	stage.apply_quality("Low")
	assert(stage.ember_batch.multimesh.visible_instance_count == 24)
	stage.apply_quality("High")
	assert(stage.ember_batch.multimesh.visible_instance_count == -1)
	for i in 600: stage.step()
	assert(stage.tick == 600)
	assert(absf(stage.center_visual.position.y - float(stage.platforms[3].y)) < 0.001)
	stage.reset_match(8261)
	assert(stage.tick == 0)
	assert(is_equal_approx(stage.center_visual.position.y, 6.4))
	assert(is_equal_approx(stage.turbine_roots[0].rotation.z, 0.0))
	print("EMBER SCENE PASS: 4 platforms, 2 announced hazards, 600 ticks, reversible quality, restored lift/scenery")
	stage.queue_free()
	await process_frame
	await process_frame
	quit()
