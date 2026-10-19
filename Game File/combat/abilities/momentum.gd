extends AbilityKit

func activate(move: MoveDefinition) -> void:
	match move.ability:
		"clutch_palm":
			var data: Dictionary = move.ability_data
			var charge: float = float(fighter.charge_ticks) / maxf(1.0, float(move.charge_max))
			var life: int = int(float(data.lifetime) * (1.0 + charge * move.charge_reach_scale))
			controller.spawn(fighter, "ring", at(move.hit_offset), Vector2(fighter.facing * float(data.speed), 0), move, {"life": life})
			if fighter.mechanics.empowered:
				controller.spawn(fighter, "ring", at(move.hit_offset), Vector2(fighter.facing * float(data.speed), 0), move, {"life": life + int(data.empowered_second_ring_delay), "delay": int(data.empowered_second_ring_delay), "radius": move.hit_radius * 0.65, "damage_scale": float(data.empowered_damage_scale)})
		"clutch_rush":
			if fighter.mechanics.empowered:
				controller.spawn(fighter, "ring", at(move.hit_offset), Vector2.ZERO, move, {"life": 12, "delay": 8, "follow_owner": true, "offset": move.hit_offset, "radius": float(move.ability_data.empowered_burst_radius), "damage": float(move.ability_data.empowered_burst_damage), "cancel_on_interrupt": true})
		"clutch_recovery":
			controller.world.emit_event("recovery", fighter, fighter.position)

func confirm(target: RiotFighter, contact: Dictionary) -> void:
	if str(contact.get("ability", "")) == "clutch_ultimate":
		controller.combo(fighter, target, fighter.definition.get_move("ultimate"))
