extends SceneTree
## Passive diagnostic around the real main scene. It neither injects nor consumes
## inputs, changes providers, calls sample(), nor modifies the saved settings.
## Run externally with --main-pack <release.pck> --script <this absolute path>.
## Optional user arg: --probe-output=<absolute JSONL path>.

var app: Node
var tap: Node
var output: String
var stream: FileAccess
var previous_sample: String = ""
var heartbeat_elapsed: float = 0.0

class InputTap extends Node:
	var observer: Callable

	func _input(event: InputEvent) -> void:
		if event is InputEventKey and observer.is_valid():
			var details := {
				"pressed": event.pressed, "echo": event.echo, "device": event.device,
				"keycode": int(event.keycode), "physical_keycode": int(event.physical_keycode),
				"key_label": int(event.key_label), "unicode": int(event.unicode),
				"logical_name": OS.get_keycode_string(event.keycode),
				"physical_name": OS.get_keycode_string(event.physical_keycode),
				"shift": event.shift_pressed, "ctrl": event.ctrl_pressed,
				"alt": event.alt_pressed, "meta": event.meta_pressed,
				"text": event.as_text()
			}
			observer.call("raw_input_before_main", details)
			_after_input.call_deferred(details)

	func _after_input(details: Dictionary) -> void:
		if observer.is_valid(): observer.call("deferred_after_input", details)

	func _notification(what: int) -> void:
		if observer.is_valid() and what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
			observer.call("notification", {"id": what, "focus_out": what == NOTIFICATION_APPLICATION_FOCUS_OUT, "focus_in": what == NOTIFICATION_APPLICATION_FOCUS_IN})

func _initialize() -> void:
	_launch.call_deferred()

func _launch() -> void:
	output = ProjectSettings.globalize_path("user://native_input_probe.jsonl")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--probe-output="): output = arg.trim_prefix("--probe-output=")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	stream = FileAccess.open(output, FileAccess.WRITE)
	if stream == null:
		push_error("Cannot open native input probe output: " + output)
		quit(2)
		return
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	root.title = "Rooftop Native Input Probe"
	tap = InputTap.new()
	tap.name = "PassiveNativeInputTap"
	tap.observer = _record
	# Added after main: reverse input propagation observes the raw event before
	# main forwards it. The deferred record observes the resulting provider state.
	root.add_child(tap)
	if root.has_signal("focus_entered"):
		root.connect("focus_entered", func() -> void: _record("window_focus_entered", {}))
	if root.has_signal("focus_exited"):
		root.connect("focus_exited", func() -> void: _record("window_focus_exited", {}))
	process_frame.connect(_observe_frame)
	physics_frame.connect(_observe_physics)
	_record("probe_ready", {"engine": Engine.get_version_info().string, "output": output, "bindings": HumanInputProvider.get_keyboard_bindings(), "user_data_dir": OS.get_user_data_dir(), "pid": OS.get_process_id()})
	print("NATIVE_INPUT_PROBE_READY output=", output)

func _state() -> Dictionary:
	var state := {"focused": root.call("has_focus") if root.has_method("has_focus") else null}
	if not is_instance_valid(app) or app.closing or not is_instance_valid(app.world):
		state["closing"] = true
		return state
	state.merge({"screen": app.ui.screen_name, "remap_action": app.ui.remap_action, "tick": app.world.tick,
		"running": app.world.running, "paused": app.world.paused, "countdown": app.world.countdown,
		"training": app.world.training, "config": app.world.config.duplicate(true)})
	var fighters: Array[Dictionary] = []
	for fighter: RiotFighter in app.world.fighters:
		var provider: InputProvider = fighter.provider
		var snapshot: InputSnapshot = fighter.snapshot
		var row := {"slot": fighter.slot, "state": fighter.state, "move": fighter.move.id if fighter.move != null else "",
			"position": [fighter.position.x, fighter.position.y, fighter.position.z],
			"provider_script": provider.get_script().resource_path, "provider_id": provider.get_instance_id(),
			"snapshot_held": snapshot.held.duplicate() if snapshot != null else {}, "snapshot_pressed": snapshot.pressed.duplicate() if snapshot != null else {},
			"snapshot_released": snapshot.released.duplicate() if snapshot != null else {}, "snapshot_move": [snapshot.move.x, snapshot.move.y] if snapshot != null else []}
		if provider is HumanInputProvider:
			row.merge({"device_id": provider.device_id, "provider_held": provider._held.duplicate(),
				"provider_pressed": provider._pressed.duplicate(), "provider_released": provider._released.duplicate()})
		fighters.append(row)
	state["fighters"] = fighters
	return state

func _record(kind: String, details: Dictionary) -> void:
	if stream == null: return
	var row := {"kind": kind, "milliseconds": Time.get_ticks_msec(), "details": details, "state": _state()}
	stream.store_line(JSON.stringify(row))
	stream.flush()
	if kind != "heartbeat": print("NATIVE_INPUT_PROBE ", kind, " ", JSON.stringify(details))

func _observe_frame() -> void:
	heartbeat_elapsed += root.get_process_delta_time()
	if heartbeat_elapsed >= 1.0:
		heartbeat_elapsed = 0.0
		_record("heartbeat", {})

func _observe_physics() -> void:
	if not is_instance_valid(app) or app.closing: return
	# The signal occurs before node physics callbacks. Deferred observation sees
	# the snapshots consumed by this real main scene's next combat step.
	_observe_sample.call_deferred()

func _observe_sample() -> void:
	if not is_instance_valid(app) or app.closing or not is_instance_valid(app.world): return
	var samples: Array[Dictionary] = []
	for fighter: RiotFighter in app.world.fighters:
		if fighter.snapshot == null: continue
		samples.append({"slot": fighter.slot, "state": fighter.state, "held": fighter.snapshot.held,
			"pressed": fighter.snapshot.pressed, "released": fighter.snapshot.released, "move": fighter.snapshot.move})
	var signature: String = JSON.stringify(samples)
	if signature != previous_sample:
		previous_sample = signature
		_record("physics_sample_changed", {})
