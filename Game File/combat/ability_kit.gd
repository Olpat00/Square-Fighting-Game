class_name AbilityKit
extends RefCounted

var controller: AbilityController
var fighter: RiotFighter

func setup(system: AbilityController, actor: RiotFighter) -> void:
	controller = system
	fighter = actor

func activate(_move: MoveDefinition) -> void:
	pass

func move_started(_move: MoveDefinition) -> void:
	pass

func landed() -> void:
	pass

func taunted(_clip: String) -> void:
	pass

func confirm(_target: RiotFighter, _contact: Dictionary) -> void:
	pass

func captured(_target: RiotFighter, _ability: String) -> void:
	pass

func recovery(horizontal: float, vertical: float) -> void:
	fighter.grounded = false
	fighter.support_id = -1
	fighter.velocity = Vector3(horizontal, vertical, 0)
	controller.world.emit_event("recovery", fighter, fighter.position)

func at(offset: Vector2) -> Vector2:
	return Vector2(fighter.position.x + offset.x * fighter.facing, fighter.position.y + offset.y)
