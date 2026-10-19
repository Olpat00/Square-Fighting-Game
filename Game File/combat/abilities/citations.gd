extends AbilityKit

func move_started(move: MoveDefinition) -> void:
	if move.ability == "fine_ultimate":
		var data: Dictionary = move.ability_data
		controller.zone(fighter, at(move.hit_offset), Vector2(float(data.zone_width), float(data.zone_height)), move, move.startup, int(move.active_windows[-1].y) - move.startup + 1, "geometry")

func activate(move: MoveDefinition) -> void:
	if move.ability == "fine_recovery":
		controller.world.emit_event("recovery", fighter, fighter.position)
		for index in 3:
			controller.spawn(fighter, "step", at(Vector2.ZERO), Vector2.ZERO, move, {"life": 18 + index * 6, "delay": index * 6, "cosmetic": true, "max_count": 3, "anchor_on_show": true, "offset": Vector2(0, -0.04), "cancel_on_interrupt": true})
	elif move.ability == "fine_thrust":
		controller.spawn(fighter, "precision_line", at(move.hit_offset), Vector2.ZERO, move, {"life": 5, "cosmetic": true, "follow_owner": true, "offset": move.hit_offset, "cancel_on_interrupt": true})

func confirm(target: RiotFighter, contact: Dictionary) -> void:
	var ability: String = str(contact.get("ability", ""))
	if ability == "fine_kick":
		controller.combo(fighter, target, fighter.definition.get_move("special_side"), 0, 0, 0, false)
	elif ability == "fine_ultimate":
		controller.combo(fighter, target, fighter.definition.get_move("ultimate"))
