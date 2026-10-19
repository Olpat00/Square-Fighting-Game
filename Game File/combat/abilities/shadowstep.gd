extends AbilityKit

func activate(move: MoveDefinition) -> void:
	match move.ability:
		"gentleman_arc":
			var data: Dictionary = move.ability_data
			controller.spawn(fighter, "ring", at(move.hit_offset), Vector2(fighter.facing * float(data.speed), 0), move, {"life": int(data.lifetime), "max_count": 1})
		"gentleman_step":
			var data: Dictionary = move.ability_data
			_step(float(data.empowered_distance) if fighter.mechanics.empowered else float(data.distance), true, move)
		"gentleman_retreat":
			_step(-float(move.ability_data.distance), false, move)
		"gentleman_recovery":
			controller.world.emit_event("recovery", fighter, fighter.position)

func confirm(target: RiotFighter, contact: Dictionary) -> void:
	if str(contact.get("ability", "")) == "gentleman_ultimate":
		controller.combo(fighter, target, fighter.definition.get_move("ultimate"))

func _step(distance: float, turn_to_target: bool, move: MoveDefinition) -> void:
	var origin: Vector3 = fighter.position
	controller.spawn(fighter, "ring", at(Vector2(0, 1.0)), Vector2.ZERO, move, {"life": 7, "cosmetic": true, "max_count": 2})
	var limit: float = 8.25 if fighter.grounded else 16.0
	fighter.position.x = clampf(origin.x + fighter.facing * distance, -limit, limit)
	fighter.previous_position = fighter.position
	fighter.velocity.x = 0.0
	if turn_to_target:
		var nearest: RiotFighter = null
		var range_value: float = 2.2
		for candidate: RiotFighter in controller.world.fighters:
			if candidate == fighter or candidate.stocks <= 0 or candidate.state in ["ko", "eliminated"]:
				continue
			var separation: float = absf(candidate.position.x - fighter.position.x)
			if separation < range_value and absf(candidate.position.y - fighter.position.y) < 1.5:
				nearest = candidate
				range_value = separation
		if nearest != null:
			fighter.facing = 1 if nearest.position.x >= fighter.position.x else -1
	controller.spawn(fighter, "ring", at(Vector2(0, 1.0)), Vector2.ZERO, move, {"life": 7, "cosmetic": true, "max_count": 2})
	controller.world.emit_event("ability", fighter, fighter.position, {"type": "shadow_step"})
