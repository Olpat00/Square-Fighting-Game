class_name FighterDefinition
extends Resource
## Shared definitions are immutable. All live resources belong to Fighter instances.

const REQUIRED_MOVES: Array[String] = ["jab1", "jab2", "jab3", "tilt_side", "tilt_up", "tilt_down", "dash", "heavy_side", "heavy_up", "heavy_down", "air_neutral", "air_forward", "air_back", "air_up", "air_down", "special_neutral", "special_side", "special_up", "special_down", "ultimate", "grab", "throw_forward", "throw_back", "throw_up", "throw_down"]
const REQUIRED_ANIMATIONS: Array[String] = ["intro", "idle", "move_start", "move_stop", "walk", "run", "turnaround", "crouch", "jump_anticipation", "jump_rise", "double_jump", "fall", "land_soft", "land_hard", "shield_enter", "shield_hold", "shield_exit", "parry", "spot_dodge", "roll_forward", "roll_back", "air_dodge", "hit_light", "hit_heavy", "launch", "tumble", "knockdown", "getup", "ledge_catch", "ledge_release", "grab_hold", "grab_release", "victim_grab", "victim_throw", "respawn", "win", "lose", "taunt1", "taunt2", "final_ko"]

@export var id: String = ""
@export var display_name: String = ""
@export var final_ko_caption: String = ""
@export var archetype: String = ""
@export_multiline var description: String = ""
@export_file("*.glb") var model_path: String = ""
@export_file("*.glb") var low_model_path: String = ""
@export_file("*.png") var portrait_path: String = ""
@export var palette: Color = Color.WHITE
@export var accent: Color = Color.WHITE
@export var run_speed: float = 8.0
@export var acceleration: float = 58.0
@export var air_speed: float = 6.6
@export var air_acceleration: float = 25.0
@export var weight: float = 1.0
@export var jump_velocity: float = 12.4
@export var gravity: float = 21.0
@export var fast_fall_speed: float = 17.0
@export var air_jumps: int = 1
@export var shield_max: float = 100.0
@export var mechanic: String = ""
@export_multiline var passive_description: String = ""
@export var moves: Dictionary = {}
@export var animation_profile: Dictionary = {}
@export var presentation: FighterPresentationProfile = FighterPresentationProfile.new()
@export var taunts: Array[String] = []
@export var beginner_combos: Array[String] = []

func get_move(move_id: String) -> MoveDefinition:
	return moves.get(move_id) as MoveDefinition

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty() or display_name.is_empty() or model_path.is_empty():
		errors.append("Fighter requires id, display_name, and model_path")
	if weight <= 0.0 or run_speed <= 0.0 or jump_velocity <= 0.0 or gravity <= 0.0:
		errors.append("%s has invalid movement stats" % id)
	for move_id: String in REQUIRED_MOVES:
		var move: MoveDefinition = get_move(move_id)
		if move == null:
			errors.append("%s missing move %s" % [id, move_id])
		else:
			errors.append_array(move.validate())
	for animation: String in REQUIRED_ANIMATIONS:
		if not animation_profile.has(animation):
			errors.append("%s missing animation mapping %s" % [id, animation])
	return errors
