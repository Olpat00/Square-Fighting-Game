class_name SettingsStore
extends RefCounted

const DEFAULTS: Dictionary = {"master": 0.8, "music": 0.36, "effects": 0.85, "blood": true, "profanity": false, "shake": 0.5, "flashes": 0.45, "rumble": 0.5, "ui_scale": 1.0, "graphics": "High", "fullscreen": false, "resolution": "1920x1080"}
var values: Dictionary = DEFAULTS.duplicate(true)
var path: String = "user://settings.cfg"

func load_settings() -> void:
	var cfg := ConfigFile.new()
	values = DEFAULTS.duplicate(true)
	if cfg.load(path) != OK:
		return
	for key in DEFAULTS:
		var value: Variant = cfg.get_value("settings", key, DEFAULTS[key])
		if typeof(value) == typeof(DEFAULTS[key]):
			if value is float:
				if is_finite(value): values[key] = clampf(value, 0.8 if key == "ui_scale" else 0.0, 1.25 if key == "ui_scale" else 1.0)
			else: values[key] = value
	if values.graphics not in ["High", "Low"]: values.graphics = DEFAULTS.graphics
	if values.resolution not in ["1280x720", "1600x900", "1920x1080"]: values.resolution = DEFAULTS.resolution

func save_settings() -> Error:
	var cfg := ConfigFile.new()
	for key in values:
		cfg.set_value("settings", key, values[key])
	return cfg.save(path)

func apply_display() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not values.fullscreen:
		var size_parts: PackedStringArray = str(values.resolution).split("x")
		if size_parts.size() == 2:
			DisplayServer.window_set_size(Vector2i(int(size_parts[0]), int(size_parts[1])))
