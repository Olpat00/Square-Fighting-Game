class_name RiotFighter
extends CharacterBody3D
## Per-instance gameplay state. World owns tick order; rendering never resolves hits.

var definition: FighterDefinition
var slot: int = 0
var player_color: Color = Color.CYAN
var world: Node
var provider: InputProvider
var snapshot: InputSnapshot
var visual: FighterVisual
var facing: int = 1
var state: String = "idle"
var state_ticks: int = 0
var grounded: bool = false
var support_id: int = -1
var ignored_platform: int = -1
var ignore_ticks: int = 0
var coyote: int = 0
var air_jumps: int = 1
var recovery_used: bool = false
var air_dodge_used: bool = false
var helpless: bool = false
var damage: float = 0.0
var stocks: int = 3
var ultimate_meter: float = 0.0
var shield: float = 100.0
var shield_delay: int = 0
var shield_start_tick: int = -999
var stun: int = 0
var hitstop: int = 0
var invulnerability: int = 0
var ledge_lock: int = 0
var move: MoveDefinition
var move_tick: int = 0
var attack_instance: int = 0
var hit_registry: Dictionary = {} # Target slot -> current move tick, including hitstop.
var confirmed_hit: bool = false
var charge_ticks: int = 0
var armor_spent: bool = false
var buffered: Dictionary = {}
var previous_position: Vector3
var capture_target: RiotFighter
var captured_by: RiotFighter
var last_attacker: int = -1
var last_hit_tick: int = -999
var assists: Dictionary = {}
var recent_moves: Array[String] = []
var mechanics: FighterMechanics
var respawn_timer: int = 0
var taunt_alternate: bool = false
var jump_hold_ticks: int = 0
var recovery_direction: float = 0.0
var knocked_down: bool = false
var locomotion_clip: String = ""
var locomotion_transition: int = 0
var visual_facing: int = 1
var landing_ticks: int = CombatTuning.SOFT_LANDING_TICKS
var authored_motion_this_tick: bool = false

func configure(data: FighterDefinition, index: int, match_world: Node, input_provider: InputProvider) -> void:
	definition = data
	slot = index
	world = match_world
	provider = input_provider
	player_color = [Color("51daf5"), Color("ff865b"), Color("d4eb73"), Color("d6a2ff")][index % 4]
	shield = definition.shield_max
	air_jumps = definition.air_jumps
	mechanics = FighterMechanics.new()
	mechanics.configure(self)
	visual = FighterVisual.new()
	add_child(visual)
	visual.configure(self)
	visual.play("intro", 60)

func sample_input() -> void:
	snapshot = provider.sample(self, world)
	for action in snapshot.pressed:
		if snapshot.was_pressed(action):
			buffered[action] = CombatTuning.INPUT_BUFFER
	for action in buffered.keys():
		if not snapshot.was_pressed(action) and hitstop == 0:
			buffered[action] = int(buffered[action]) - 1
			if buffered[action] <= 0:
				buffered.erase(action)

func consume(action: String) -> bool:
	if buffered.has(action):
		buffered.erase(action)
		return true
	return false

func tick() -> void:
	authored_motion_this_tick = false
	if state == "eliminated":
		return
	if state == "ko":
		respawn_timer -= 1
		if respawn_timer <= 0:
			respawn()
		visual.step(false)
		return
	if hitstop > 0:
		hitstop -= 1
		visual.step(true)
		return
	state_ticks += 1
	invulnerability = maxi(0, invulnerability - 1)
	ledge_lock = maxi(0, ledge_lock - 1)
	shield_delay = maxi(0, shield_delay - 1)
	if ignore_ticks > 0:
		ignore_ticks -= 1
		if ignore_ticks == 0:
			ignored_platform = -1
	mechanics.tick()
	previous_position = position
	if captured_by != null:
		if not is_instance_valid(captured_by) or captured_by.capture_target != self:
			captured_by = null
			change_state("idle")
		else:
			position = world.abilities.capture_position(self)
			velocity = Vector3.ZERO
			visual.step(false)
			return
	if state == "ledge":
		if consume("jump") or snapshot.move.y > 0.5 or state_ticks > 50:
			position += Vector3(facing * 0.7, 0.75, 0)
			velocity = Vector3(facing * 3.0, 9.0, 0)
			ledge_lock = 100
			change_state("air")
			visual.play("ledge_release", 16)
		elif snapshot.move.y < -0.5:
			ledge_lock = 90
			change_state("air")
		else:
			visual.step(false)
			return
	if stun > 0:
		stun -= 1
		if state == "hitstun":
			velocity.x += snapshot.move.x * 0.07
			velocity.x = clampf(velocity.x, -42, 42)
		if stun == 0:
			if knocked_down and grounded:
				knocked_down = false
				change_state("getup")
				visual.play("getup", 12)
			else:
				knocked_down = false
				change_state("shield" if state == "shield_stun" and grounded and snapshot.is_down("defend") else "idle" if grounded else "air")
	elif state == "ability_sequence":
		pass
	elif state == "grab_hold":
		if capture_target == null or state_ticks > 75:
			release_capture()
			change_state("idle")
		elif snapshot.move.length() > 0.5 or consume("light") or consume("grab"):
			var direction := "forward"
			if absf(snapshot.move.y) > 0.5:
				direction = "up" if snapshot.move.y > 0 else "down"
			elif snapshot.move.x * facing < -0.5:
				direction = "back"
			start_move("throw_" + direction)
	elif state == "charge":
		charge_ticks += 1
		velocity.x = move_toward(velocity.x, 0, 0.9)
		if charge_ticks >= move.charge_max or not snapshot.is_down(move.input_action):
			change_state("attack")
			move_tick = 0
			visual.play(move.animation_id, move.total_ticks())
	elif state == "attack":
		_update_attack()
	elif state == "dodge":
		if state_ticks >= (26 if grounded else 35):
			change_state("idle" if grounded else "air")
	elif state == "landing":
		if state_ticks >= landing_ticks:
			change_state("idle")
	elif state == "getup":
		if state_ticks >= 12:
			change_state("idle" if grounded else "air")
	elif state == "taunt":
		if state_ticks >= 55:
			change_state("idle" if grounded else "air")
	else:
		_handle_actions()
	if state == "shield":
		shield = maxf(0, shield - 0.16)
		shield_delay = CombatTuning.SHIELD_REGEN_DELAY
		velocity.x = move_toward(velocity.x, 0, 0.8)
		if shield <= 0:
			break_shield()
		elif not snapshot.is_down("defend"):
			change_state("idle")
			visual.play("shield_exit", 6)
	elif shield_delay == 0:
		shield = minf(definition.shield_max, shield + 0.22)
	_move_body()
	_present_locomotion()
	visual.step(false)

func _handle_actions() -> void:
	if state == "shield" and snapshot.move.length() > 0.7:
		start_dodge()
		return
	if consume("jump") and not helpless:
		if grounded and snapshot.move.y < -0.5 and support_id > 0:
			ignored_platform = support_id
			ignore_ticks = 20
			grounded = false
			support_id = -1
			position.y -= 0.08
			velocity.y = -3.0
			change_state("air")
		elif grounded or coyote > 0 or air_jumps > 0:
			var first: bool = grounded or coyote > 0
			if not first:
				air_jumps -= 1
			grounded = false
			coyote = 0
			support_id = -1
			jump_hold_ticks = 0
			velocity.y = definition.jump_velocity * (1.0 if first else 0.92)
			change_state("air")
			visual.play("jump_anticipation" if first else "double_jump", 8)
			world.emit_event("jump", self, position)
	if helpless:
		return
	if consume("defend"):
		if grounded and snapshot.move.length() < 0.5:
			change_state("shield")
			shield_start_tick = world.tick
			visual.play("shield_enter", 5)
		elif grounded or not air_dodge_used:
			start_dodge()
		return
	for action in ["ultimate", "special", "grab", "heavy", "light"]:
		if buffered.has(action):
			var requested: String = requested_move(action)
			if not requested.is_empty() and can_start(requested):
				consume(action)
				start_move(requested)
				return
	if consume("taunt"):
		taunt_alternate = not taunt_alternate
		change_state("taunt")
		var taunt_clip: String = "taunt1" if taunt_alternate else "taunt2"
		visual.play(taunt_clip, 55)
		world.abilities.on_taunt_start(self, taunt_clip)
		world.emit_event("taunt", self, position)

func requested_move(action: String) -> String:
	var vertical: float = snapshot.move.y
	var horizontal: float = snapshot.move.x
	if action == "ultimate" or action == "grab":
		return action
	if action == "special":
		return "special_" + ("up" if vertical > 0.5 else "down" if vertical < -0.5 else "side" if absf(horizontal) > 0.5 else "neutral")
	if action == "heavy":
		return "heavy_" + ("up" if vertical > 0.5 else "down" if vertical < -0.5 else "side") if grounded else _air_direction()
	if not grounded:
		return _air_direction()
	if move != null and state == "attack" and move.id in ["jab1", "jab2"]:
		return "jab2" if move.id == "jab1" else "jab3"
	if absf(vertical) > 0.5:
		return "tilt_up" if vertical > 0 else "tilt_down"
	if absf(horizontal) > 0.5:
		return "dash" if absf(velocity.x) > definition.run_speed * 0.8 else "tilt_side"
	return "jab1"

func _air_direction() -> String:
	if absf(snapshot.move.y) > 0.5:
		return "air_up" if snapshot.move.y > 0 else "air_down"
	if absf(snapshot.move.x) > 0.5:
		return "air_forward" if snapshot.move.x * facing > 0 else "air_back"
	return "air_neutral"

func can_start(id: String) -> bool:
	var candidate := definition.get_move(id)
	if candidate == null: return false
	if candidate.context == "ground" and not grounded: return false
	if candidate.context == "air" and grounded: return false
	if candidate.context == "grab_hold" and capture_target == null: return false
	if id == "ultimate" and ultimate_meter < 100.0:
		return false
	if id == "special_up" and recovery_used:
		return false
	return not helpless

func start_move(id: String) -> void:
	var next := definition.get_move(id)
	if next == null:
		return
	move = next
	move_tick = 0
	attack_instance = world.next_attack_id()
	hit_registry.clear()
	confirmed_hit = false
	armor_spent = false
	charge_ticks = 0
	invulnerability = 0
	if id == "ultimate":
		ultimate_meter = maxf(0, ultimate_meter - 100)
	if absf(snapshot.move.x) > 0.4 and not id.begins_with("air_") and not id.begins_with("throw_"):
		facing = 1 if snapshot.move.x > 0 else -1
	if id == "special_up":
		recovery_used = true
		recovery_direction = snapshot.move.x
	change_state("charge" if move.charge_max > 0 else "attack")
	visual.play("special_down_air" if move.ability == "heavy_stomp" and not grounded else move.animation_id, move.total_ticks())
	mechanics.on_move_start(move)
	world.abilities.on_move_start(self, move)
	world.emit_event("move", self, position, {"move": id})

func _update_attack() -> void:
	move_tick += 1
	if move_tick == move.startup:
		var before_position: Vector3 = position
		var before_velocity: Vector3 = velocity
		world.abilities.activate(self, move)
		# Ability-authored teleports, dives and impulse launches own this tick.
		authored_motion_this_tick = position != before_position or velocity != before_velocity
	var motion: Dictionary = world.abilities.movement_for(self, move, move_tick)
	if not motion.is_empty():
		authored_motion_this_tick = true
		var v: Vector2 = motion.velocity
		if str(motion.get("mode", "set")) == "add":
			velocity += Vector3(v.x * facing, v.y, 0) * CombatTuning.DT
		else:
			velocity.x = v.x * facing
			if v.y != 0:
				grounded = false
				support_id = -1
				velocity.y = v.y
	if buffered.has("light"):
		var next := requested_move("light")
		if move.can_cancel(move_tick, next, confirmed_hit):
			consume("light")
			start_move(next)
			return
	if move_tick >= move.total_ticks():
		if move.id == "special_up":
			helpless = not grounded
		move = null
		change_state("idle" if grounded else "air")

func start_dodge() -> void:
	change_state("dodge")
	var axis := snapshot.move
	if grounded:
		velocity.x = axis.x * 10.5
		visual.play("spot_dodge" if absf(axis.x) < 0.4 else "roll_forward" if axis.x * facing > 0 else "roll_back", 26)
	else:
		air_dodge_used = true
		velocity = Vector3(axis.x * 8, axis.y * 6, 0)
		visual.play("air_dodge", 35)
	world.emit_event("dodge", self, position)

func _move_body() -> void:
	var mobile: bool = state in ["idle", "air", "shield"] and stun <= 0
	if mobile and state != "shield":
		var speed: float = definition.run_speed if grounded else definition.air_speed
		var acceleration: float = definition.acceleration if grounded else definition.air_acceleration
		velocity.x = move_toward(velocity.x, snapshot.move.x * speed, acceleration * CombatTuning.DT)
		if grounded and absf(snapshot.move.x) > 0.15:
			facing = 1 if snapshot.move.x > 0 else -1
	elif not grounded and state == "attack" and move != null and not authored_motion_this_tick and stun <= 0 and not helpless:
		# Drift changes trajectory without turning an already committed strike.
		velocity.x = move_toward(velocity.x, snapshot.move.x * definition.air_speed, definition.air_acceleration * move.air_control * CombatTuning.DT)
	elif grounded and state not in ["attack", "dodge", "hitstun"]:
		velocity.x = move_toward(velocity.x, 0, 0.9)
	if not grounded:
		velocity.y -= definition.gravity * CombatTuning.DT
		jump_hold_ticks += 1
		if snapshot.was_released("jump") and velocity.y > 4.0 and jump_hold_ticks < 14 and not recovery_used:
			velocity.y *= 0.55
		# Direction selects aerial attacks without skipping their startup. Special
		# dives own their descent curve; manual fast-fall belongs to free movement.
		if snapshot.move.y < -0.6 and velocity.y < 0 and mobile and state != "shield":
			velocity.y = minf(velocity.y, -definition.fast_fall_speed)
		coyote = maxi(0, coyote - 1)
	else:
		coyote = CombatTuning.COYOTE_TICKS
	var previous := position
	var landing_speed: float = velocity.y
	var solved: Dictionary = world.stage.solve_motion(position, position + velocity * CombatTuning.DT, velocity.y, ignored_platform, support_id if grounded else -1)
	position = solved.position
	var was_grounded: bool = grounded
	grounded = solved.landed
	support_id = solved.platform
	if grounded:
		velocity.y = 0
		if not was_grounded:
			world.abilities.on_landing(self)
			air_jumps = definition.air_jumps
			recovery_used = false
			air_dodge_used = false
			helpless = false
			if state == "attack" and move != null and move.context == "air":
				stun = move.landing_lag
				landing_ticks = move.landing_lag
				visual.play("land_hard", maxi(7, stun))
				move = null
				change_state("landing")
			elif state == "hitstun" and stun > 0:
				knocked_down = true
				visual.play("knockdown", maxi(10, stun))
			elif state in ["idle", "air"]:
				landing_ticks = CombatTuning.HARD_LANDING_TICKS if landing_speed < -9.0 else CombatTuning.SOFT_LANDING_TICKS
				change_state("landing")
				visual.play("land_hard" if landing_speed < -9.0 else "land_soft", landing_ticks)
			elif state == "attack" and move != null and move.ability == "heavy_stomp":
				# Floor Inspection explicitly resolves into a grounded shockwave.
				visual.play("land_hard", maxi(7, move.total_ticks() - move_tick))
			# Any-context specials keep their attack/charge clip through contact
			# with a platform, so their next active frame still has a visible strike.
			world.emit_event("land", self, position)
	elif was_grounded:
		support_id = -1
	if absf(position.x - previous.x) < 0.00001 and absf(velocity.x) > 0.1:
		velocity.x = 0
	var deck_edges: Vector2 = world.stage.main_bounds()
	var deck_height: float = float(world.stage.support(0).y)
	var right_side: bool = position.x > (deck_edges.x + deck_edges.y) * 0.5
	var edge_x: float = deck_edges.y if right_side else deck_edges.x
	var outward: float = 1.0 if right_side else -1.0
	if not grounded and velocity.y < 0 and ledge_lock == 0 and stun == 0 and state != "attack" and position.y > deck_height - 2.2 and position.y < deck_height - 0.3 and absf(position.x - (edge_x + outward * 0.35)) < 0.5:
		facing = -1 if right_side else 1
		position = Vector3(edge_x + outward * 0.3, deck_height - 1.15, 0)
		velocity = Vector3.ZERO
		invulnerability = 24
		change_state("ledge")
		visual.play("ledge_catch", 16)

func _present_locomotion() -> void:
	if state in ["idle", "air"]:
		if grounded:
			var desired := "crouch" if snapshot.move.y < -0.5 else "run" if absf(velocity.x) > 3 else "walk" if absf(velocity.x) > 0.5 else "idle"
			var moving: bool = desired in ["walk", "run"]
			if absf(snapshot.move.x) > 0.15 and visual_facing != facing:
				_play_locomotion_transition("turnaround", 10)
			elif desired == "idle" and locomotion_clip in ["walk", "run"]:
				_play_locomotion_transition("move_stop", 12)
			elif locomotion_transition > 0:
				locomotion_transition -= 1
			else:
				if moving and locomotion_clip == "idle":
					_play_locomotion_transition("move_start", 10)
				else: visual.play(desired, 0, true)
			locomotion_clip = desired
			visual_facing = facing
		elif state_ticks > 8:
			locomotion_clip = ""
			locomotion_transition = 0
			visual.play("jump_rise" if velocity.y > 0 else "fall", 0, true)
	else:
		locomotion_clip = ""
		locomotion_transition = 0
		if state == "shield" and state_ticks >= 5:
			visual.play("shield_hold", 0, true)
		elif state == "hitstun" and not grounded and velocity.length() > 16 and state_ticks > 10:
			visual.play("tumble", 0, true)

func _play_locomotion_transition(clip: String, fallback_ticks: int) -> void:
	var profile: FighterPresentationProfile = visual.presentation_profile if visual.presentation_profile != null else definition.presentation
	var duration: int = profile.transition_duration(clip, fallback_ticks) if profile != null else fallback_ticks
	visual.play(clip, duration)
	locomotion_transition = maxi(0, duration - 1)

func change_state(next: String) -> void:
	state = next
	state_ticks = 0

func vulnerable() -> bool:
	if state in ["ko", "eliminated"] or invulnerability > 0:
		return false
	if state == "dodge" and state_ticks >= 3 and state_ticks <= (15 if grounded else 16):
		return false
	if state == "attack" and move != null and move.is_invulnerable(move_tick):
		return false
	return true

func hurt_center() -> Vector2:
	return Vector2(position.x, position.y + 0.9)

func attack_center() -> Vector2:
	return Vector2(position.x + move.hit_offset.x * facing, position.y + move.hit_offset.y)

func break_shield() -> void:
	knocked_down = true
	shield = 20
	stun = 120
	shield_delay = 160
	change_state("shield_break")
	visual.play("knockdown", 120)
	world.emit_event("shield_break", self, position)

func release_capture() -> void:
	if is_instance_valid(capture_target):
		capture_target.captured_by = null
		capture_target.stun = 12
		capture_target.change_state("hitstun")
		capture_target.visual.play("grab_release", 12)
	capture_target = null
	if is_instance_valid(captured_by):
		captured_by.capture_target = null
	captured_by = null

func interrupt() -> void:
	knocked_down = false
	release_capture()
	move = null
	buffered.clear()
	world.abilities.interrupt(self)

func lose_stock() -> void:
	interrupt()
	provider.reset()
	stocks = maxi(0, stocks - 1)
	ultimate_meter = 0
	mechanics.reset()
	hit_registry.clear()
	world.abilities.clear_owner(self)
	respawn_timer = CombatTuning.RESPAWN_TICKS
	change_state("ko" if stocks > 0 else "eliminated")
	visual.visible = false

func respawn() -> void:
	interrupt()
	provider.reset()
	damage = 0
	velocity = Vector3.ZERO
	position = Vector3((slot - 1.5) * 2.4, 7.4, 0)
	grounded = false
	support_id = -1
	ignored_platform = -1
	air_jumps = definition.air_jumps
	recovery_used = false
	air_dodge_used = false
	helpless = false
	stun = 0
	hitstop = 0
	invulnerability = CombatTuning.RESPAWN_INVULNERABILITY
	shield = definition.shield_max
	last_attacker = -1
	assists.clear()
	buffered.clear()
	change_state("air")
	visual.visible = true
	visual.play("respawn", 45)
