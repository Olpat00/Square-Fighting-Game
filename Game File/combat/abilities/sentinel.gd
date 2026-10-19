extends AbilityKit

func move_started(move: MoveDefinition) -> void:
	if move.ability == "sentinel_ultimate":
		var data: Dictionary = move.ability_data
		controller.zone(fighter, at(move.hit_offset), Vector2(float(data.zone_width), float(data.zone_height)), move, int(data.warning_ticks), int(move.active_windows[-1].y) - int(data.warning_ticks) + 1, "geometry")

func activate(move: MoveDefinition) -> void:
	match move.ability:
		"sentinel_bolt":
			var data: Dictionary = move.ability_data
			controller.spawn(fighter, "ring", at(move.hit_offset), Vector2(fighter.facing * float(data.speed), 0), move, {"life": int(data.lifetime), "max_count": 1})
		"sentinel_drive":
			controller.world.emit_event("ability", fighter, fighter.position, {"type": "containment_drive"})
		"sentinel_recovery":
			controller.world.emit_event("recovery", fighter, fighter.position)
		"sentinel_pulse":
			var data: Dictionary = move.ability_data
			var offset := Vector2(0, 1.0)
			controller.spawn(fighter, "ring", at(offset), Vector2.ZERO, move, {"life": 5, "max_count": 1, "follow_owner": true, "offset": offset, "cancel_on_interrupt": true, "radius": float(data.pulse_radius) * (float(data.empowered_radius_scale) if fighter.mechanics.empowered else 1.0), "damage_scale": float(data.empowered_damage_scale) if fighter.mechanics.empowered else 1.0})
