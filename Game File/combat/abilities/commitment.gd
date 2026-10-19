extends AbilityKit

var drop_instance: int = -1

func taunted(clip: String) -> void:
	if clip == "taunt1" and fighter.grounded:
		controller.spawn(fighter, "chair", at(Vector2.ZERO), Vector2.ZERO, fighter.definition.get_move("ultimate"), {"life": 55, "delay": 12, "unfold_ticks": 8, "cosmetic": true, "cancel_on_interrupt": true, "taunt_only": true, "max_count": 1})

func activate(move: MoveDefinition) -> void:
	match move.ability:
		"heavy_clap":
			controller.spawn(fighter, "ring", at(move.hit_offset), Vector2.ZERO, move, {"life": 6, "radius": move.hit_radius, "cosmetic": true, "follow_owner": true, "offset": move.hit_offset, "cancel_on_interrupt": true})
		"heavy_recovery": controller.world.emit_event("recovery", fighter, fighter.position)
		"heavy_stomp":
			if not fighter.grounded:
				drop_instance = fighter.attack_instance
				fighter.velocity.y = float(move.ability_data.air_velocity)
			else:
				shockwave(move, false)

func shockwave(move: MoveDefinition, landing: bool) -> void:
	controller.spawn(fighter, "ring", at(Vector2(0, 0.16)), Vector2.ZERO, move, {"life": 5, "radius": float(move.ability_data.landing_radius) if landing else move.hit_radius, "damage": float(move.ability_data.landing_damage) if landing else move.damage, "ground_wave": true, "max_count": 1})

func landed() -> void:
	if fighter.attack_instance == drop_instance and fighter.move != null and fighter.move.ability == "heavy_stomp":
		shockwave(fighter.move, true)
	drop_instance = -1

func captured(target: RiotFighter, ability: String) -> void:
	if ability == "heavy_grab":
		controller.combo(fighter, target, fighter.definition.get_move("special_side"))
	elif ability == "heavy_ultimate":
		controller.combo(fighter, target, fighter.definition.get_move("ultimate"))
