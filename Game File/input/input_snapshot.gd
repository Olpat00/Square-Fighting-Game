class_name InputSnapshot
extends RefCounted
## One player's inputs for one authoritative tick. Positive move.y means UP.

var move: Vector2 = Vector2.ZERO
var held: Dictionary = {}
var pressed: Dictionary = {}
var released: Dictionary = {}

func is_down(action: String) -> bool:
	return bool(held.get(action, false))

func was_pressed(action: String) -> bool:
	return bool(pressed.get(action, false))

func was_released(action: String) -> bool:
	return bool(released.get(action, false))
