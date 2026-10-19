class_name HumanInputProvider
extends InputProvider
## Device -1 is the single keyboard profile. Each pad belongs to exactly one slot.
## The host forwards _input(event) here; no global InputMap action state is used.

const SETTINGS_PATH: String = "user://controls.cfg"
const KEYBOARD_SETTINGS = preload("res://input/keyboard_bindings_store.gd")
const DEFAULT_KEYS: Dictionary = KEYBOARD_SETTINGS.DEFAULT_KEYS
const PAD_BUTTONS: Dictionary = {"jump": JOY_BUTTON_A, "light": JOY_BUTTON_X, "heavy": JOY_BUTTON_B, "special": JOY_BUTTON_Y, "defend": JOY_BUTTON_LEFT_SHOULDER, "grab": JOY_BUTTON_RIGHT_SHOULDER, "ultimate": JOY_BUTTON_LEFT_STICK, "taunt": JOY_BUTTON_DPAD_UP, "pause": JOY_BUTTON_START}

var device_id: int = -1
var deadzone: float = 0.22
var connected: bool = true
var _held: Dictionary = {}
var _pressed: Dictionary = {}
var _released: Dictionary = {}
var _trigger_defend: bool = false
var _pad_defend: bool = false

func _init(selected_device: int = -1) -> void:
	device_id = selected_device
	if not KEYBOARD_SETTINGS.loaded:
		load_keyboard_bindings()

func handle_event(event: InputEvent) -> void:
	if device_id < 0:
		if event is not InputEventKey or (event as InputEventKey).echo:
			return
		var key_event := event as InputEventKey
		var code: int = event_keycode(key_event)
		for action: String in KEYBOARD_SETTINGS.bindings:
			if code == int(KEYBOARD_SETTINGS.bindings[action]):
				_set_action(action, key_event.pressed)
	elif event is InputEventJoypadButton and event.device == device_id:
		var button_event := event as InputEventJoypadButton
		for action: String in PAD_BUTTONS:
			if button_event.button_index == int(PAD_BUTTONS[action]):
				if action == "defend":
					_pad_defend = button_event.pressed
					_set_action(action, _pad_defend or _trigger_defend)
				else:
					_set_action(action, button_event.pressed)

func sample(_fighter: Node, _world: Node) -> InputSnapshot:
	var result := InputSnapshot.new()
	if device_id < 0:
		result.move = Vector2(float(_held.get("right", false)) - float(_held.get("left", false)), float(_held.get("up", false)) - float(_held.get("down", false)))
	else:
		connected = device_id in Input.get_connected_joypads()
		if connected:
			var stick := Vector2(Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X), -Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y))
			var length: float = stick.length()
			if length > deadzone:
				result.move = stick.normalized() * clampf((length - deadzone) / (1.0 - deadzone), 0.0, 1.0)
			_trigger_defend = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > 0.35 or Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.35
			_set_action("defend", _trigger_defend or _pad_defend)
		else:
			_release_all()
	result.held = _held.duplicate()
	result.pressed = _pressed.duplicate()
	result.released = _released.duplicate()
	_pressed.clear()
	_released.clear()
	return result

func reset() -> void:
	_held.clear()
	_pressed.clear()
	_released.clear()
	_pad_defend = false
	_trigger_defend = false

func _release_all() -> void:
	_pressed.clear()
	for action: String in _held.keys():
		_set_action(action, false)
	_pad_defend = false
	_trigger_defend = false

func _set_action(action: String, down: bool) -> void:
	var previous: bool = bool(_held.get(action, false))
	_held[action] = down
	if down and not previous:
		_pressed[action] = true
	elif previous and not down:
		_released[action] = true

static func event_keycode(event: InputEventKey) -> int:
	# Windows virtual-key injection can report Pause as the physical key for
	# unrelated logical keys. Use the valid logical key for that malformed scan
	# code, while retaining physical bindings for normal hardware/layout input.
	if event.physical_keycode == 0 or (event.physical_keycode == KEY_PAUSE and event.keycode != KEY_PAUSE):
		return int(event.keycode)
	return int(event.physical_keycode)

static func get_keyboard_bindings() -> Dictionary:
	if not KEYBOARD_SETTINGS.loaded:
		load_keyboard_bindings()
	return KEYBOARD_SETTINGS.bindings.duplicate()

static func set_keyboard_binding(action: String, physical_keycode: int) -> bool:
	if not DEFAULT_KEYS.has(action) or physical_keycode <= 0:
		return false
	# Swap conflicting actions so every action remains accessible.
	var old_code: int = int(KEYBOARD_SETTINGS.bindings[action])
	for other_action: String in KEYBOARD_SETTINGS.bindings:
		if other_action != action and int(KEYBOARD_SETTINGS.bindings[other_action]) == physical_keycode:
			KEYBOARD_SETTINGS.bindings[other_action] = old_code
	KEYBOARD_SETTINGS.bindings[action] = physical_keycode
	return true

static func reset_keyboard_bindings() -> void:
	KEYBOARD_SETTINGS.bindings = DEFAULT_KEYS.duplicate()
	KEYBOARD_SETTINGS.loaded = true

static func save_keyboard_bindings() -> Error:
	var settings := ConfigFile.new()
	for action: String in KEYBOARD_SETTINGS.bindings:
		settings.set_value("keyboard", action, int(KEYBOARD_SETTINGS.bindings[action]))
	return settings.save(SETTINGS_PATH)

static func load_keyboard_bindings() -> void:
	KEYBOARD_SETTINGS.bindings = DEFAULT_KEYS.duplicate()
	KEYBOARD_SETTINGS.loaded = true
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	var proposed: Dictionary = {}
	var used: Dictionary = {}
	for action: String in DEFAULT_KEYS:
		var raw: Variant = settings.get_value("keyboard", action, DEFAULT_KEYS[action])
		if typeof(raw) != TYPE_INT or int(raw) <= 0 or used.has(int(raw)):
			return # Corrupt/incomplete collisions restore a coherent full default map.
		proposed[action] = int(raw)
		used[int(raw)] = true
	KEYBOARD_SETTINGS.bindings = proposed
