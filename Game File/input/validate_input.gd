extends SceneTree
## Reproducible provider checks, independent of graphics and connected hardware.

class DummyFighter extends Node3D:
	var slot: int = 0
	var velocity: Vector3 = Vector3.ZERO
	var grounded: bool = true
	var facing: int = 1
	var damage: float = 0.0
	var stocks: int = 3
	var ultimate_meter: float = 0.0
	var state: String = "idle"
	var definition: FighterDefinition
	var air_jumps: int = 1
	var recovery_used: bool = false
	var move: MoveDefinition
	var move_tick: int = 0
	var confirmed_hit: bool = false

class DummyStage extends Node:
	func main_bounds() -> Vector2:
		return Vector2(-9.0, 9.0)
	var platforms: Array = [{"id": 1, "x": -4.0, "width": 3.0, "y": 2.5, "previous_y": 2.5}, {"id": 2, "x": 4.0, "width": 3.0, "y": 2.5, "previous_y": 2.5}]
	var warn: bool = false
	func is_hazard_warning_at(_x: float) -> bool:
		return warn

class DummyWorld extends Node:
	var fighters: Array = []
	var stage: Node

var checks: int = 0
var failures := PackedStringArray()

func _initialize() -> void:
	var original_bindings: Dictionary = HumanInputProvider.get_keyboard_bindings()
	HumanInputProvider.reset_keyboard_bindings()
	_test_human()
	_test_native_key_normalization()
	_test_cpu()
	HumanInputProvider.KEYBOARD_SETTINGS.bindings = original_bindings
	var report: Dictionary = {"engine": Engine.get_version_info().string, "checks": checks, "failures": failures, "hardware_scope": "Synthetic key/button events, disconnection path, and seeded CPU snapshots. Physical pad operation requires graphical play validation."}
	var file: FileAccess = FileAccess.open("res://../docs/moves/input-validation.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _test_human() -> void:
	var keyboard := HumanInputProvider.new(-1)
	var pad0 := HumanInputProvider.new(0)
	var pad1 := HumanInputProvider.new(1)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	key.pressed = true
	keyboard.handle_event(key)
	pad0.handle_event(key)
	var first: InputSnapshot = keyboard.sample(null, null)
	_check(first.was_pressed("light") and first.is_down("light"), "Keyboard press produces held + pressed")
	_check(not pad0._held.has("light"), "Keyboard does not affect pad slot")
	_check(not keyboard.sample(null, null).was_pressed("light"), "Pressed is consumed exactly once")
	key.echo = true
	keyboard.handle_event(key)
	_check(not keyboard.sample(null, null).was_pressed("light"), "Keyboard echo cannot retrigger")
	key.echo = false
	key.pressed = false
	keyboard.handle_event(key)
	var release: InputSnapshot = keyboard.sample(null, null)
	_check(release.was_released("light") and not release.is_down("light"), "Release edge is explicit")
	_check(not keyboard.sample(null, null).was_released("light"), "Release is consumed exactly once")
	key.physical_keycode = KEY_W
	key.pressed = true
	keyboard.handle_event(key)
	_check(keyboard.sample(null, null).move.y == 1.0, "Keyboard upward direction is positive Y")
	keyboard.reset()
	_check(keyboard.sample(null, null).move == Vector2.ZERO, "Reset clears keyboard direction")
	var button := InputEventJoypadButton.new()
	button.device = 0
	button.button_index = JOY_BUTTON_X
	button.pressed = true
	pad0.handle_event(button)
	pad1.handle_event(button)
	keyboard.handle_event(button)
	_check(bool(pad0._held.get("light", false)), "Matching pad receives its own button")
	_check(not bool(pad1._held.get("light", false)), "Pad device isolation prevents input leakage")
	_check(not keyboard.sample(null, null).is_down("light"), "Pad input does not affect keyboard")
	var disconnected := HumanInputProvider.new(91)
	button.device = 91
	disconnected.handle_event(button)
	var missing: InputSnapshot = disconnected.sample(null, null)
	_check(not missing.is_down("light") and not missing.was_pressed("light") and not disconnected.connected, "Disconnected device drops held actions and pending presses")
	_check(HumanInputProvider.set_keyboard_binding("jump", KEY_J), "Valid remap accepted")
	var remapped: Dictionary = HumanInputProvider.get_keyboard_bindings()
	_check(int(remapped.jump) == KEY_J and int(remapped.light) == KEY_SPACE, "Conflicting remap swaps keys without dropping an action")
	var second_keyboard := HumanInputProvider.new(-1)
	keyboard.reset()
	key.physical_keycode = KEY_J
	key.pressed = true
	keyboard.handle_event(key)
	second_keyboard.handle_event(key)
	_check(keyboard.sample(null, null).was_pressed("jump") and second_keyboard.sample(null, null).was_pressed("jump"), "Existing and newly created keyboard providers share remapped controls")
	remapped.jump = KEY_P
	_check(int(HumanInputProvider.get_keyboard_bindings().jump) == KEY_J, "Returned binding dictionaries cannot mutate shared control preferences")
	_check(not HumanInputProvider.set_keyboard_binding("undefined", KEY_P), "Unknown remapping action rejected")
	_check(not HumanInputProvider.set_keyboard_binding("jump", 0), "Invalid remapping code rejected")
	HumanInputProvider.reset_keyboard_bindings()

func _native_key(logical: Key, down: bool, unicode_value: int = 0) -> InputEventKey:
	# Exact native-probe J shape: logical/key label 74, physical 4194313
	# (KEY_PAUSE), device 16, echo false, Unicode 106 on down and 0 on up.
	# Space/Escape below are deliberate variants of that observed event shape.
	var event := InputEventKey.new()
	event.device = 16
	event.keycode = logical
	event.key_label = logical
	event.physical_keycode = KEY_PAUSE
	event.pressed = down
	event.echo = false
	event.unicode = unicode_value
	return event

func _test_native_key_normalization() -> void:
	var keyboard := HumanInputProvider.new(-1)
	var unrelated_pad := HumanInputProvider.new(16)
	var down: InputEventKey = _native_key(KEY_J, true, 106)
	var up: InputEventKey = _native_key(KEY_J, false)
	_check(HumanInputProvider.event_keycode(down) == KEY_J and HumanInputProvider.event_keycode(up) == KEY_J, "Observed native J down/up normalize the spurious physical Pause to logical J")
	keyboard.handle_event(down)
	unrelated_pad.handle_event(down)
	keyboard.handle_event(up) # Both native events arrived within one millisecond.
	var pulse: InputSnapshot = keyboard.sample(null, null)
	_check(pulse.was_pressed("light") and pulse.was_released("light") and not pulse.is_down("light"), "Observed native J down/up before a combat sample retain one light press and release")
	_check(unrelated_pad._held.is_empty() and unrelated_pad._pressed.is_empty(), "Native keyboard event device16 does not leak into gamepad16")
	var consumed: InputSnapshot = keyboard.sample(null, null)
	_check(consumed.pressed.is_empty() and consumed.released.is_empty() and not consumed.is_down("light"), "Native J pulse is consumed once without a stuck held action")
	down.echo = true
	keyboard.handle_event(down)
	var echoed: InputSnapshot = keyboard.sample(null, null)
	_check(echoed.pressed.is_empty() and not echoed.is_down("light"), "Native logical-key fallback does not turn echoes into fresh actions")
	for entry: Dictionary in [{"key": KEY_SPACE, "action": "jump"}, {"key": KEY_ESCAPE, "action": "pause"}]:
		keyboard.reset()
		var logical: Key = entry.key
		var event: InputEventKey = _native_key(logical, true)
		_check(HumanInputProvider.event_keycode(event) == logical, "Native-shaped %s resolves to the requested logical key" % entry.action)
		keyboard.handle_event(event)
		var held: InputSnapshot = keyboard.sample(null, null)
		_check(held.was_pressed(entry.action) and held.is_down(entry.action), "Native-shaped %s produces its normal provider action" % entry.action)
		event.pressed = false
		keyboard.handle_event(event)
		var released: InputSnapshot = keyboard.sample(null, null)
		_check(released.was_released(entry.action) and not released.is_down(entry.action), "Native-shaped %s release clears its held action" % entry.action)
	keyboard.reset()
	var real_pause: InputEventKey = _native_key(KEY_PAUSE, true)
	_check(HumanInputProvider.event_keycode(real_pause) == KEY_PAUSE, "A genuine logical and physical Pause key keeps its identity")
	HumanInputProvider.set_keyboard_binding("jump", KEY_PAUSE)
	keyboard.handle_event(real_pause)
	_check(keyboard.sample(null, null).was_pressed("jump"), "A genuine Pause key can still activate an explicitly remapped action")
	HumanInputProvider.reset_keyboard_bindings()
	keyboard.reset()
	var layout := InputEventKey.new()
	layout.keycode = KEY_Q
	layout.physical_keycode = KEY_A
	layout.pressed = true
	_check(HumanInputProvider.event_keycode(layout) == KEY_A, "A valid QWERTY physical position takes precedence over a differing logical layout")
	keyboard.handle_event(layout)
	_check(keyboard.sample(null, null).move.x == -1.0, "Differing logical Q at physical A still moves left with the default physical binding")
	keyboard.reset()
	layout.keycode = KEY_J
	layout.physical_keycode = 0
	_check(HumanInputProvider.event_keycode(layout) == KEY_J, "An absent physical code still uses the logical key")
	keyboard.handle_event(layout)
	_check(keyboard.sample(null, null).was_pressed("light"), "Logical-only key events continue to drive the normal light action")
	keyboard.reset()
	HumanInputProvider.set_keyboard_binding("jump", HumanInputProvider.event_keycode(_native_key(KEY_J, true, 106)))
	keyboard.handle_event(_native_key(KEY_J, true, 106))
	var remapped: InputSnapshot = keyboard.sample(null, null)
	_check(remapped.was_pressed("jump") and not remapped.was_pressed("light") and int(HumanInputProvider.get_keyboard_bindings().light) == KEY_SPACE, "Remapping a native-shaped J stores J and preserves the ordinary binding swap")
	HumanInputProvider.reset_keyboard_bindings()

func _test_cpu() -> void:
	var fighter := DummyFighter.new()
	var opponent := DummyFighter.new()
	opponent.slot = 1
	var world := DummyWorld.new()
	var stage := DummyStage.new()
	world.stage = stage
	world.fighters = [fighter, opponent]
	fighter.definition = RosterRegistry.by_id("f01_clutch")
	opponent.definition = RosterRegistry.by_id("f03_heavy_duty")
	opponent.position = Vector3(3.0, 0, 0)
	var first := CpuInputProvider.new("Normal", 44821)
	var second := CpuInputProvider.new("Normal", 44821)
	for tick: int in range(1200):
		var a: InputSnapshot = first.sample(fighter, world)
		var b: InputSnapshot = second.sample(fighter, world)
		_check(a.move == b.move and a.held == b.held and a.pressed == b.pressed and a.released == b.released, "Seeded decision mismatch at tick %d" % tick)
		_check(a.move.x >= -1.0 and a.move.x <= 1.0 and a.move.y >= -1.0 and a.move.y <= 1.0, "CPU direction is bounded at tick %d" % tick)
	fighter.position = Vector3(10.0, -1.5, 0)
	fighter.grounded = false
	fighter.velocity = Vector3(1, -2, 0)
	var recovery_cpu := CpuInputProvider.new("Hard", 7)
	var return_jump: InputSnapshot = recovery_cpu.sample(fighter, world)
	_check(return_jump.move.x < 0.0 and return_jump.was_pressed("jump"), "Offstage return uses inward aerial jump")
	fighter.air_jumps = 0
	recovery_cpu.reset()
	var up_special: InputSnapshot = recovery_cpu.sample(fighter, world)
	_check(up_special.move.x < 0.0 and up_special.move.y > 0.0 and up_special.was_pressed("special"), "Exhausted jumps request inward up special")
	fighter.recovery_used = true
	recovery_cpu.reset()
	_check(not recovery_cpu.sample(fighter, world).was_pressed("special"), "CPU does not request infinite recovery resets")
	fighter.position = Vector3.ZERO
	fighter.grounded = true
	fighter.recovery_used = false
	fighter.air_jumps = 1
	var defend_cpu := CpuInputProvider.new("Normal", 3)
	defend_cpu.dummy_mode = "defending"
	_check(defend_cpu.sample(fighter, world).is_down("defend"), "Training defense emits ordinary defend input")
	var still_cpu := CpuInputProvider.new("Normal", 3)
	still_cpu.dummy_mode = "stationary"
	var still: InputSnapshot = still_cpu.sample(fighter, world)
	_check(still.move == Vector2.ZERO and still.pressed.is_empty(), "Stationary training dummy produces no actions")
	stage.warn = true
	fighter.position.x = 6.0
	var hazard_cpu := CpuInputProvider.new("Hard", 3)
	var avoidance: InputSnapshot = hazard_cpu.sample(fighter, world)
	_check(avoidance.move.x < 0.0 and avoidance.was_pressed("jump"), "CPU avoids announced hazard via normal movement/jump")
	fighter.free()
	opponent.free()
	stage.free()
	world.free()
