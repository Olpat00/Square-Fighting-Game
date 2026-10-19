extends AbilityKit

func move_started(move: MoveDefinition) -> void:
	if move.ability == "sun_ultimate":
		var data: Dictionary = move.ability_data
		var distance: float = clampf(move.hit_offset.x + fighter.snapshot.move.x * fighter.facing * 2.0, 1.0, float(data.aim_range))
		controller.zone(fighter, at(Vector2(distance, move.hit_offset.y)), Vector2.ONE * float(data.zone_radius) * 2.0, move, int(data.warning_ticks), int(move.active_windows[-1].y) - int(data.warning_ticks) + 1, "spotlight")

func activate(move: MoveDefinition) -> void:
	match move.ability:
		"sun_disc":
			var data: Dictionary = move.ability_data
			controller.spawn(fighter, "disc", at(move.hit_offset), Vector2(fighter.facing * float(data.speed), 0), move, {"damage_scale": float(data.empowered_damage_scale) if fighter.mechanics.empowered else 1.0, "radius": move.hit_radius * (float(data.empowered_radius_scale) if fighter.mechanics.empowered else 1.0)})
		"sun_ribbon":
			controller.spawn(fighter, "ribbon", at(move.hit_offset), Vector2.ZERO, move, {"life": 7, "cosmetic": true, "follow_owner": true, "offset": move.hit_offset, "cancel_on_interrupt": true})
		"sun_recovery": controller.world.emit_event("recovery", fighter, fighter.position)
		"sun_reflector":
			controller.spawn(fighter, "reflector", at(move.hit_offset), Vector2.ZERO, move)
