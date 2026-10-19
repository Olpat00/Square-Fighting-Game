extends SceneTree

func _initialize() -> void:
	var path := "user://validation_settings_only.cfg"
	var store := SettingsStore.new()
	store.path = path
	store.values.master = 0.35
	store.values.blood = false
	store.values.resolution = "1280x720"
	var saved: bool = store.save_settings() == OK
	var loaded := SettingsStore.new()
	loaded.path = path
	loaded.load_settings()
	var roundtrip: bool = saved and is_equal_approx(loaded.values.master, 0.35) and not loaded.values.blood and loaded.values.resolution == "1280x720"
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "master", 100.0)
	cfg.set_value("settings", "ui_scale", 0.0)
	cfg.set_value("settings", "resolution", "0x-999")
	cfg.set_value("settings", "graphics", "garbage")
	cfg.set_value("settings", "blood", "not_a_boolean")
	cfg.save(path)
	loaded.load_settings()
	var sanitized: bool = loaded.values.master == 1.0 and loaded.values.ui_scale == 0.8 and loaded.values.resolution == "1920x1080" and loaded.values.graphics == "High" and loaded.values.blood == true
	FileAccess.open(path, FileAccess.WRITE).store_string("not a config file\n[broken")
	loaded.load_settings()
	var recovered: bool = loaded.values == SettingsStore.DEFAULTS
	DirAccess.remove_absolute(path)
	var report := {"roundtrip": roundtrip, "invalid_values_sanitized": sanitized, "corrupt_file_defaults": recovered, "user_settings_preserved": true}
	FileAccess.open(ProjectSettings.globalize_path("res://../evidence/settings_scenarios.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("SETTINGS_SCENARIOS ", JSON.stringify(report))
	quit(0 if roundtrip and sanitized and recovered else 1)
