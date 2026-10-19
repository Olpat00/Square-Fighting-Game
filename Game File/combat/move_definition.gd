class_name MoveDefinition
extends Resource
## Immutable authored combat data. Frame indices are zero based and inclusive.
## World/local coordinates use +X forward and +Y up; the resolver mirrors X.

@export var id: String = ""
@export var display_name: String = ""
@export var context: String = "any"
@export var input_action: String = "light"
@export var direction: String = "neutral"
@export var animation_id: String = ""
@export var startup: int = 6
@export var active_windows: Array[Vector2i] = [Vector2i(6, 8)]
@export var recovery: int = 12
@export var damage: float = 5.0
@export var base_knockback: float = 4.0
@export var knockback_growth: float = 0.085
@export var angle: float = 35.0
@export var hitstun: int = 16
@export var hitstop: int = 4
@export var shield_damage: float = 6.0
@export var shield_stun: int = 7
@export var hit_offset: Vector2 = Vector2(0.75, 0.95)
@export var hit_radius: float = 0.5
# Optional authored effect point within a broad attack volume. This does not
# participate in collision; projectile contacts use their actual swept position.
@export var impact_offset: Vector2 = Vector2.INF
@export var hit_group: String = "main"
@export var rehit_ticks: int = 0
@export var charge_max: int = 0
@export var charge_damage_scale: float = 0.6
@export var charge_reach_scale: float = 0.25
@export var landing_lag: int = 10
# Fraction of ordinary air acceleration allowed during this attack. Authored
# movement segments and ability-controlled motion always take precedence.
@export_range(0.0, 1.0) var air_control: float = 0.0
@export var cancel_windows: Array[Dictionary] = []
@export var armor_windows: Array[Vector2i] = []
@export var armor_threshold: float = 8.0
@export var invulnerable_windows: Array[Vector2i] = []
@export var movement: Array[Dictionary] = []
@export var effects: Array[String] = []
@export var ownership: Dictionary = {"friendly_fire": true, "hit_owner": false, "clear_on_stock_loss": true, "max_targets": 4}
@export var ability: String = ""
@export var ability_data: Dictionary = {}
@export var purpose: String = ""
@export var counterplay: String = ""

func total_ticks() -> int:
	var last_tick: int = startup - 1
	for window: Vector2i in active_windows:
		last_tick = maxi(last_tick, window.y)
	return last_tick + 1 + recovery

func is_active(tick: int) -> bool:
	return _in_windows(tick, active_windows)

func has_armor(tick: int) -> bool:
	return _in_windows(tick, armor_windows)

func is_invulnerable(tick: int) -> bool:
	return _in_windows(tick, invulnerable_windows)

func can_cancel(tick: int, next_id: String, confirmed_hit: bool) -> bool:
	for window: Dictionary in cancel_windows:
		if tick >= int(window.get("from", 0)) and tick <= int(window.get("to", 0)):
			if next_id in window.get("into", []) and (not bool(window.get("on_hit", false)) or confirmed_hit):
				return true
	return false

func movement_at(tick: int) -> Dictionary:
	for segment: Dictionary in movement:
		if tick >= int(segment.get("from", 0)) and tick <= int(segment.get("to", 0)):
			return segment
	return {}

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty() or animation_id.is_empty():
		errors.append("Move needs a stable id and animation_id")
	if startup < 0 or recovery < 0 or damage < 0.0 or hit_radius <= 0.0:
		errors.append("%s has invalid timing, damage or radius" % id)
	var previous_end: int = -1
	for window: Vector2i in active_windows:
		if window.x < startup or window.y < window.x or window.x <= previous_end:
			errors.append("%s has an invalid/overlapping active window" % id)
		previous_end = window.y
	for window: Dictionary in cancel_windows:
		if int(window.get("from", -1)) < 0 or int(window.get("to", 0)) >= total_ticks():
			errors.append("%s cancel window is outside move duration" % id)
	if charge_max < 0 or charge_max > 75:
		errors.append("%s charge maximum is outside 0–75 ticks" % id)
	if not is_finite(air_control) or air_control < 0.0 or air_control > 1.0:
		errors.append("%s air control must be between zero and one" % id)
	return errors

func _in_windows(tick: int, windows: Array[Vector2i]) -> bool:
	for window: Vector2i in windows:
		if tick >= window.x and tick <= window.y:
			return true
	return false
