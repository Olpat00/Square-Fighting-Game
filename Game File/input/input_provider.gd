class_name InputProvider
extends RefCounted

const ACTIONS: Array[String] = ["jump", "light", "heavy", "special", "defend", "grab", "ultimate", "taunt", "pause"]

func sample(_fighter: Node, _world: Node) -> InputSnapshot:
	return InputSnapshot.new()

func handle_event(_event: InputEvent) -> void:
	pass

func reset() -> void:
	pass
