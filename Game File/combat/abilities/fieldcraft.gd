extends AbilityKit

func move_started(move: MoveDefinition) -> void:
	if move.ability == "deadfall_ultimate":
		var data: Dictionary = move.ability_data
		controller.zone(fighter, at(move.hit_offset), Vector2(float(data.zone_length), float(data.zone_width)), move, int(data.warning_ticks), int(move.active_windows[-1].y) - int(data.warning_ticks) + 1, "tree")

func activate(move: MoveDefinition) -> void:
	match move.ability:
		"deadfall_log":
			controller.spawn(fighter, "log", at(move.hit_offset), Vector2(fighter.facing * float(move.ability_data.speed), 0), move)
		"deadfall_slide":
			controller.spawn(fighter, "plank", at(Vector2(0, 0.04)), Vector2.ZERO, move, {"life": 14, "cosmetic": true, "follow_owner": true, "offset": Vector2(0, 0.04), "cancel_on_interrupt": true})
		"deadfall_recovery":
			controller.world.emit_event("recovery", fighter, fighter.position)
			controller.spawn(fighter, "branch", at(Vector2(1.5, 3.3)), Vector2.ZERO, move, {"life": 24, "cosmetic": true, "cancel_on_interrupt": true})
		"deadfall_trap":
			controller.spawn(fighter, "trap", at(move.hit_offset), Vector2.ZERO, move)
