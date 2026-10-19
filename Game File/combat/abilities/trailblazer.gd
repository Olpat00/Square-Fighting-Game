extends AbilityKit

func activate(move: MoveDefinition) -> void:
	match move.ability:
		"explorer_hook":
			var data: Dictionary = move.ability_data
			controller.spawn(fighter, "hook", at(move.hit_offset), Vector2(fighter.facing * float(data.speed), 0), move, {"life": int(data.lifetime), "max_count": 1})
		"explorer_rush":
			controller.world.emit_event("ability", fighter, fighter.position, {"type": "trail_rush"})
		"explorer_recovery":
			controller.world.emit_event("recovery", fighter, fighter.position)
		"explorer_anchor":
			controller.spawn(fighter, "ring", at(Vector2(0.75, 0.49)), Vector2.ZERO, move, {"life": 8, "cosmetic": true, "follow_owner": true, "offset": Vector2(0.75, 0.49), "cancel_on_interrupt": true})

func confirm(target: RiotFighter, contact: Dictionary) -> void:
	match str(contact.get("ability", "")):
		"explorer_hook":
			# The resolved hit and shield decision precede this callback. Pull only a
			# damaged target, and never use a visual object's position as authority.
			var data: Dictionary = contact.get("ability_data", fighter.definition.get_move("special_neutral").ability_data)
			var direction: float = signf(target.position.x - fighter.position.x)
			if direction == 0.0:
				return
			target.velocity.x = -direction * float(data.get("pull_speed", 12.0))
			target.velocity.y = maxf(target.velocity.y, 2.5)
			target.grounded = false
			target.support_id = -1
			target.stun = maxi(target.stun, int(data.get("pull_stun", 28)))
			controller.world.emit_event("ability", fighter, target.position, {"type": "hook_pull", "target": target.slot})
		"explorer_ultimate":
			controller.combo(fighter, target, fighter.definition.get_move("ultimate"))
