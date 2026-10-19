class_name ScriptedInputProvider
extends InputProvider
## Scheduled held inputs for reproducible gameplay scenarios. Edges are derived,
## exactly as for physical inputs; replay data cannot bypass combat restrictions.
## Each entry: {from: int, to: int, move: Vector2, actions: Array[String]}.

var schedule: Array[Dictionary] = []
var tick: int = 0
var _previous: Dictionary = {}

func _init(entries: Array[Dictionary] = []) -> void:
	schedule = entries.duplicate(true)

func sample(_fighter: Node, _world: Node) -> InputSnapshot:
	var snapshot := InputSnapshot.new()
	for entry: Dictionary in schedule:
		if tick >= int(entry.get("from", 0)) and tick <= int(entry.get("to", 0)):
			if entry.has("move"):
				snapshot.move = entry.move
			for action: String in entry.get("actions", []):
				if action in ACTIONS:
					snapshot.held[action] = true
	for action: String in ACTIONS:
		var down: bool = snapshot.is_down(action)
		if down and not bool(_previous.get(action, false)):
			snapshot.pressed[action] = true
		elif not down and bool(_previous.get(action, false)):
			snapshot.released[action] = true
	_previous = snapshot.held.duplicate()
	tick += 1
	return snapshot

func reset() -> void:
	tick = 0
	_previous.clear()
