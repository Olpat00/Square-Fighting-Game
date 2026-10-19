class_name CpuInputProvider
extends InputProvider
## Seeded perception decisions; attacks use the same edge-triggered inputs as humans.
## No damage, movement, or defensive stat changes are applied by difficulty.

const DIFFICULTIES: Dictionary = {
	"Easy": {"delay": 18, "jitter": 8, "mistake": 0.24, "defend": 0.13, "special": 0.19},
	"Normal": {"delay": 10, "jitter": 4, "mistake": 0.09, "defend": 0.29, "special": 0.26},
	"Hard": {"delay": 5, "jitter": 3, "mistake": 0.025, "defend": 0.45, "special": 0.32}
}

var difficulty: String = "Normal"
var dummy_mode: String = ""
var rng := RandomNumberGenerator.new()
var _decision_in: int = 0
var _move: Vector2 = Vector2.ZERO
var _previous: Dictionary = {}
var _presses: Dictionary = {}
var _hold_ticks: Dictionary = {}
var _approach_side: float = 1.0
var _ticks: int = 0
var intent: String = "approach"
var _target_slot: int = -1
var _target_until: int = 0
var _spacing_until: int = 0

func _init(level: String = "Normal", seed_value: int = 1) -> void:
	difficulty = level if DIFFICULTIES.has(level) else "Normal"
	rng.seed = seed_value
	_approach_side = -1.0 if rng.randf() < 0.5 else 1.0

func sample(fighter: Node, world: Node) -> InputSnapshot:
	_ticks += 1
	_presses.clear()
	for action: String in _hold_ticks.keys():
		_hold_ticks[action] = maxi(0, int(_hold_ticks[action]) - 1)
	if not dummy_mode.is_empty():
		_move = Vector2.ZERO
		if dummy_mode == "defending":
			_hold_ticks["defend"] = 2
		elif dummy_mode == "jumping" and bool(fighter.get("grounded")) and _ticks % 24 == 0:
			_press("jump")
	else:
		_decision_in -= 1
		if _decision_in <= 0:
			var settings: Dictionary = DIFFICULTIES[difficulty]
			_decision_in = int(settings["delay"]) + rng.randi_range(0, int(settings["jitter"]))
			_decide(fighter, world, settings)
	var snapshot := InputSnapshot.new()
	snapshot.move = _move
	for action: String in ACTIONS:
		var down: bool = _presses.has(action) or int(_hold_ticks.get(action, 0)) > 0
		snapshot.held[action] = down
		if down and not bool(_previous.get(action, false)):
			snapshot.pressed[action] = true
		if not down and bool(_previous.get(action, false)):
			snapshot.released[action] = true
	_previous = snapshot.held.duplicate()
	return snapshot

func reset() -> void:
	_move = Vector2.ZERO
	_previous.clear()
	_presses.clear()
	_hold_ticks.clear()
	_decision_in = 0
	_ticks = 0
	_target_slot = -1
	_target_until = 0
	_spacing_until = 0
	intent = "approach"

func _decide(fighter: Node, world: Node, settings: Dictionary) -> void:
	_move = Vector2.ZERO
	if int(fighter.get("stocks")) <= 0:
		return
	var position: Vector3 = fighter.get("position")
	var velocity: Vector3 = fighter.get("velocity")
	var grounded: bool = bool(fighter.get("grounded"))
	var definition: FighterDefinition = fighter.get("definition") as FighterDefinition
	var recovery_used: bool = bool(fighter.get("recovery_used"))
	var stage: Node = world.get("stage") as Node
	var deck_edges: Vector2 = stage.call("main_bounds") if stage != null else Vector2(-9.0, 9.0)
	var deck_center: float = (deck_edges.x + deck_edges.y) * 0.5
	# Stage return takes precedence over pursuit and attacks, including on Easy.
	if position.x < deck_edges.x + 1.0 or position.x > deck_edges.y - 1.0 or position.y < -0.3:
		intent = "recover"
		_move.x = signf(deck_center - position.x)
		if not grounded:
			if int(fighter.get("air_jumps")) > 0 and (velocity.y < 0.0 or position.y < -0.6):
				_press("jump", 4)
			elif not recovery_used and (position.y < -1.2 or (position.y < 1.3 and velocity.y < -3.0)):
				_move.y = 1.0
				_press("special")
		elif position.x < deck_edges.x + 0.5 or position.x > deck_edges.y - 0.5:
			_press("jump", 5)
		return
	var target: Node = _nearest_target(fighter, world)
	if target == null:
		return
	var target_position: Vector3 = target.get("position")
	var offset: Vector3 = target_position - position
	var range_x: float = absf(offset.x)
	var toward: float = signf(offset.x) if range_x > 0.05 else _approach_side
	var target_state: String = str(target.get("state"))
	# Continue a confirmed string intentionally, through the same edge-triggered
	# light input as a human. Whiffs never earn this branch.
	var own_move: MoveDefinition = fighter.get("move") as MoveDefinition
	if str(fighter.get("state")) == "attack" and own_move != null and own_move.id in ["jab1", "jab2"] and bool(fighter.get("confirmed_hit")):
		intent = "confirm"
		_press("light")
		return
	# React to visible hazard warnings if supplied by the stage controller.
	if stage != null and stage.has_method("is_hazard_warning_at") and bool(stage.call("is_hazard_warning_at", position.x)):
		_move.x = -signf(position.x)
		if grounded:
			_press("jump", 4)
		return
	if rng.randf() < float(settings["mistake"]):
		intent = "hesitate"
		_move.x = toward * 0.3
		return
	# Choose a platform waypoint under an elevated opponent, then jump toward it.
	if offset.y > 1.6 and grounded:
		var waypoint: float = target_position.x
		if stage != null:
			var platforms: Array = stage.get("platforms")
			var best_height: float = INF
			for platform: Dictionary in platforms:
				var height: float = float(platform.get("y", 0.0)) - position.y
				if height > 0.3 and height < 4.2 and height < best_height:
					best_height = height
					waypoint = float(platform.get("x", 0.0))
		_move.x = clampf((waypoint - position.x) * 0.6, -1.0, 1.0)
		_press("jump", 7)
		return
	if offset.y < -2.0 and grounded and position.y > 1.5:
		_move.y = -1.0
		_press("jump") # Common drop-through input.
		return
	var target_move: MoveDefinition = target.get("move") as MoveDefinition
	var target_tick: int = int(target.get("move_tick"))
	var recovering: bool = target_state in ["landing", "getup"]
	if target_state == "attack" and target_move != null:
		recovering = target_tick > target_move.active_windows.back().y
	if range_x < 2.2 and not recovering and target_state in ["attack", "attacking", "charge"] and rng.randf() < float(settings["defend"]):
		intent = "defend"
		_hold_ticks["defend"] = rng.randi_range(8, 18)
		if rng.randf() < 0.25:
			_move.x = -toward
		return
	var preferred_range: float = 1.45
	if definition != null:
		if definition.mechanic in ["encore", "fieldcraft"]:
			preferred_range = 3.6
		elif definition.mechanic == "citations":
			preferred_range = 2.3
		elif definition.mechanic == "commitment":
			preferred_range = 1.1
		elif definition.mechanic in ["trailblazer", "sentinel"]:
			preferred_range = 2.7
		elif definition.mechanic == "shadowstep":
			preferred_range = 1.8
	# Punish visible recovery with a quick strike instead of randomly shielding
	# its harmless tail. Otherwise keep a spacing goal for a short readable beat.
	if recovering and range_x < 2.2 and absf(offset.y) < 1.4:
		intent = "punish"
		_move.x = toward if range_x > 1.25 else 0.0
		_press("light")
		return
	if _ticks >= _spacing_until or intent not in ["approach", "space"]:
		intent = "approach" if range_x > preferred_range else "space"
		_spacing_until = _ticks + rng.randi_range(15, 27)
	preferred_range += 0.25 if intent == "space" else -0.15
	if range_x > preferred_range + 0.35:
		_move.x = toward
	elif range_x < preferred_range - 0.55 and preferred_range > 2.0 and position.x > deck_edges.x + 2.0 and position.x < deck_edges.y - 2.0:
		_move.x = -toward * 0.7
	if float(fighter.get("ultimate_meter")) >= 100.0 and range_x < 4.5 and absf(offset.y) < 1.8:
		_move.x = toward
		_press("ultimate")
		return
	if range_x < 5.3 and absf(offset.y) < 1.4 and rng.randf() < float(settings["special"]):
		_move = Vector2.ZERO
		var choice: float = rng.randf()
		if definition != null and definition.mechanic in ["fieldcraft", "encore"] and choice < 0.22 and grounded:
			_move.y = -1.0 # Own trap/reflector setups.
		elif definition != null and definition.mechanic in ["momentum", "citations"] and range_x < 1.6 and target_state in ["attack", "attacking"]:
			_move.y = -1.0 # Counter a presently visible attack.
		elif definition != null and definition.mechanic == "sentinel" and range_x < 1.8:
			_move.y = -1.0 # Close defensive pulse, not an out-of-range brace.
		elif definition != null and definition.mechanic == "trailblazer" and range_x > 2.6:
			pass # Neutral hook starts the Explorer's approach.
		elif range_x < 3.3 and choice < 0.58:
			_move.x = toward
		_press("special", 3)
		return
	if range_x < 2.3 and absf(offset.y) < 1.6:
		_move.x = toward
		if target_state in ["shield", "defend", "shielding"] and grounded:
			_press("grab")
		elif not grounded:
			_move.y = clampf(offset.y, -1.0, 1.0)
			_press("light")
		elif range_x < 1.35 and rng.randf() < 0.12:
			_press("grab")
		elif float(target.get("damage")) > 75.0 and rng.randf() < 0.40:
			_move.y = 1.0 if offset.y > 0.7 else 0.0
			_press("heavy", rng.randi_range(8, 23))
		else:
			if range_x < 1.2 and rng.randf() < 0.65:
				_move.x = 0.0
			elif rng.randf() < 0.24:
				_move.y = -1.0
			_press("light")
	elif range_x < 5.0 and grounded and rng.randf() < 0.12:
		_press("jump", rng.randi_range(3, 8))

func _nearest_target(fighter: Node, world: Node) -> Node:
	var closest: Node = null
	var best: float = INF
	var fighters: Array = world.get("fighters")
	var position: Vector3 = fighter.get("position")
	for candidate: Node in fighters:
		if candidate == fighter or not is_instance_valid(candidate) or int(candidate.get("stocks")) <= 0 or str(candidate.get("state")) in ["ko", "eliminated"]:
			continue
		if int(candidate.get("slot")) == _target_slot and _ticks < _target_until:
			return candidate
		var candidate_position: Vector3 = candidate.get("position")
		var distance: float = Vector2(candidate_position.x - position.x, (candidate_position.y - position.y) * 0.8).length_squared()
		if distance < best:
			closest = candidate
			best = distance
	if closest != null:
		_target_slot = int(closest.get("slot"))
		_target_until = _ticks + 45
	return closest

func _press(action: String, hold_for: int = 1) -> void:
	if bool(_previous.get(action, false)):
		return # A release tick must separate physical button presses.
	_presses[action] = true
	_hold_ticks[action] = hold_for
