class_name TrainingInputProvider
extends CpuInputProvider
## Training dummy with a bounded, local input tape. Records player one's controls
## while MatchWorld holds player one neutral; replay uses ordinary input edges.

const MAX_RECORDING_TICKS: int = 600
const LOOP_GAP_TICKS: int = 45
var tape: Array[Dictionary] = []
var tape_mode: String = "idle"
var cursor: int = 0
var loop_ready: bool = false
var _tape_previous: Dictionary = {}

func sample(fighter: Node, world: Node) -> InputSnapshot:
	if tape_mode == "idle":
		return super.sample(fighter, world)
	var entry: Dictionary = {"move": Vector2.ZERO, "held": {}}
	if tape_mode == "recording":
		var source: InputSnapshot = world.fighters[0].snapshot
		entry = {"move": source.move, "held": source.held.duplicate(), "pressed": source.pressed.duplicate(), "released": source.released.duplicate()}
		entry.held.erase("pause")
		entry.pressed.erase("pause")
		entry.released.erase("pause")
		tape.append(entry.duplicate(true))
		cursor = tape.size()
		if tape.size() >= MAX_RECORDING_TICKS:
			tape_mode = "idle"
	elif tape_mode == "playing":
		if cursor < tape.size(): entry = tape[cursor]
		cursor += 1
		loop_ready = cursor >= tape.size() + LOOP_GAP_TICKS
	var result := InputSnapshot.new()
	result.move = entry.move
	for action: String in ACTIONS:
		var down: bool = bool(entry.held.get(action, false))
		result.held[action] = down
		# Native events can contain both edges within one simulation sample.
		# Preserve those taps; held-only tapes and the loop gap derive their edges.
		var pressed: bool = bool(entry.pressed.get(action, false)) if entry.has("pressed") else down and not bool(_tape_previous.get(action, false))
		var released: bool = bool(entry.released.get(action, false)) if entry.has("released") else not down and bool(_tape_previous.get(action, false))
		if pressed: result.pressed[action] = true
		if released: result.released[action] = true
	_tape_previous = result.held.duplicate()
	return result

func begin_recording() -> void:
	rewind()
	tape.clear()
	tape_mode = "recording"

func begin_playback() -> bool:
	if tape.is_empty(): return false
	rewind()
	tape_mode = "playing"
	return true

func stop_tape() -> void:
	tape_mode = "idle"
	rewind()

func reset() -> void:
	super.reset()
	# Stock loss and pause reset live inputs, never the recording clock. Keeping
	# the previous tape state also avoids synthesizing a second held-button edge.

func rewind() -> void:
	reset()
	cursor = 0
	loop_ready = false
	_tape_previous.clear()

func status_text() -> String:
	if tape_mode == "recording": return "RECORDING P2 · %.1f / 10.0s · F6 saves" % (tape.size() / 60.0)
	if tape_mode == "playing": return "REPLAY P2 · %.1fs loop · F7 stops" % (tape.size() / 60.0)
	return "DUMMY %s · TAPE %.1fs" % [dummy_mode.to_upper(), tape.size() / 60.0]
