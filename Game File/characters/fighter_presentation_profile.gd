class_name FighterPresentationProfile
extends Resource
## Visual-only authoring. Combat clocks, collision and root travel live on RiotFighter.

@export var transition_ticks: Dictionary = {"move_start": 10, "turnaround": 10, "move_stop": 12}
@export var strides: Dictionary = {"walk": 1.0, "run": 2.0}
@export var contacts: Dictionary = {
	"walk": {"L": Vector2(0.0, 0.43), "R": Vector2(0.5, 0.93)},
	"run": {"L": Vector2(0.0, 0.36), "R": Vector2(0.5, 0.86)}
}
@export var blend_times: Dictionary = {
	"idle": 0.12, "walk": 0.10, "run": 0.09, "move_start": 0.04,
	"move_stop": 0.06, "turnaround": 0.025, "jump_anticipation": 0.025,
	"jump_rise": 0.07, "fall": 0.11, "land_soft": 0.035, "land_hard": 0.025,
	"hit_light": 0.015, "hit_heavy": 0.01, "launch": 0.015, "tumble": 0.06,
	"parry": 0.015, "shield_enter": 0.025, "shield_hold": 0.08,
	"win": 0.16, "lose": 0.16
}
@export var effect_sockets: Dictionary = {}
@export var turn_response: float = 24.0
@export var foot_plant_strength: float = 0.85
@export var max_foot_correction: float = 0.14

func transition_duration(clip: String, fallback: int = 6) -> int:
	return int(transition_ticks.get(clip, fallback))

func blend_for(previous: String, next: String, combat_move: bool = false) -> float:
	if combat_move: return 0.025 if previous.begins_with("jab") else 0.035
	return float(blend_times.get(next, 0.07))

func stride(clip: String) -> float:
	return maxf(0.05, float(strides.get(clip, 1.0)))

func planted(clip: String, side: String, phase: float) -> bool:
	if not contacts.has(clip): return false
	var window: Vector2 = contacts[clip].get(side, Vector2.ZERO)
	return phase >= window.x and phase <= window.y if window.x <= window.y else phase >= window.x or phase <= window.y

func socket(semantic_name: String) -> String:
	if effect_sockets.has(semantic_name): return str(effect_sockets[semantic_name])
	var aliases: Dictionary = {"hand.L": "left_hand", "hand.R": "right_hand", "foot.L": "left_foot", "foot.R": "right_foot"}
	return str(effect_sockets.get(aliases.get(semantic_name, semantic_name), semantic_name))

func load_metadata(path: String) -> void:
	if not FileAccess.file_exists(path): return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary: return
	for clip: String in data.get("strides", {}):
		var value: float = float(data.strides[clip])
		if is_finite(value) and value > 0.05: strides[clip] = value
	for clip: String in data.get("contacts", {}):
		var windows: Dictionary = {}
		for side: String in data.contacts[clip]:
			var values: Array = data.contacts[clip][side]
			if values.size() == 2: windows[side] = Vector2(clampf(float(values[0]), 0, 1), clampf(float(values[1]), 0, 1))
		if not windows.is_empty(): contacts[clip] = windows
	for clip: String in data.get("transition_ticks", {}):
		transition_ticks[clip] = clampi(int(data.transition_ticks[clip]), 1, 30)
	for bone: String in data.get("effect_sockets", {}): effect_sockets[bone] = str(data.effect_sockets[bone])
