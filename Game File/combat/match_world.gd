class_name MatchWorld
extends Node3D

var graphics_quality: String = "High"

signal presentation_event(event: String, actor_slot: int, at: Vector3, details: Dictionary)
signal match_finished(result: Dictionary)

var stage: RooftopStage
var stage_id: String = "rooftop_riot"
var abilities: AbilityController
var resolver: CombatResolver
var fighters: Array[RiotFighter] = []
var tick: int = 0
var time_left: int = CombatTuning.MATCH_TICKS
var attack_serial: int = 0
var running: bool = false
var paused: bool = false
var training: bool = false
var sudden_death: bool = false
var sudden_timer: int = 0
var countdown: int = 180
var config: Array[Dictionary] = []
var ko_log: Array[Dictionary] = []
var result: Dictionary = {}
var hazards_seed: int = 4261
var training_combo_hits: int = 0
var training_combo_damage: float = 0.0
var training_combo_active: bool = false
var training_combo_target: int = -1
var training_combo_actor: int = -1

func _ready() -> void:
	stage = RooftopStage.new()
	add_child(stage)
	abilities = AbilityController.new()
	add_child(abilities)
	abilities.configure(self)
	resolver = CombatResolver.new()
	resolver.configure(self)

func select_stage(id: String) -> void:
	if not StageCatalog.IDS.has(id) or (id == stage_id and is_instance_valid(stage)):
		return
	var next_stage: RooftopStage = StageCatalog.create_stage(id)
	if next_stage == null: return
	# Remove the old environment before installing the next arena's sky/lights.
	if is_instance_valid(stage):
		remove_child(stage)
		stage.queue_free()
	stage_id = id
	stage = next_stage
	add_child(stage)

func start(slots: Array[Dictionary], preset: String, is_training: bool = false, seed_value: int = 4261, arena_id: String = "") -> void:
	clear()
	if not arena_id.is_empty(): select_stage(arena_id)
	config = slots.duplicate(true)
	training = is_training
	hazards_seed = seed_value
	stage.preset = "Fair Fight" if training else preset
	stage.reset_match(seed_value)
	tick = 0
	time_left = CombatTuning.MATCH_TICKS
	countdown = 60 if training else 180
	sudden_death = false
	paused = false
	result.clear()
	for i in slots.size():
		var slot: Dictionary = slots[i]
		var definition := RosterRegistry.by_id(slot.fighter)
		if definition == null:
			push_error("Unknown fighter: " + str(slot.fighter))
			continue
		var provider: InputProvider
		if training and i == 1:
			provider = TrainingInputProvider.new()
		elif slot.get("device", "CPU") == "CPU":
			provider = CpuInputProvider.new(str(slot.get("difficulty", "Normal")), seed_value + i * 1337)
		else:
			provider = HumanInputProvider.new(int(slot.get("device_id", -1)))
		var fighter := RiotFighter.new()
		fighter.name = "Player%d" % (i + 1)
		add_child(fighter)
		fighter.configure(definition, i, self, provider)
		fighter.position = Vector3([-5.5, 5.5, -2.5, 2.5][i], 0, 0)
		fighter.grounded = true
		fighter.support_id = 0
		fighter.facing = -1 if fighter.position.x > 0 else 1
		fighters.append(fighter)
		abilities.register(fighter)
		if training and i == 1:
			provider.set("dummy_mode", "stationary")
	running = fighters.size() >= 2
	ko_log.clear()
	resolver.environment_registry.clear()
	resolver.confirmed_instances.clear()

func clear() -> void:
	running = false
	training = false
	_reset_training_combo()
	if abilities:
		abilities.reset()
		abilities.kits.clear()
	for fighter in fighters:
		fighter.release_capture()
		fighter.queue_free()
	fighters.clear()

func next_attack_id() -> int:
	attack_serial += 1
	return attack_serial

func step() -> void:
	if not running or paused:
		return
	var tape: TrainingInputProvider = training_dummy()
	if tape != null and tape.loop_ready:
		training_reset()
	var controlling_dummy: bool = tape != null and tape.tape_mode == "recording"
	for fighter in fighters:
		fighter.sample_input()
		if fighter.snapshot.was_pressed("pause"):
			paused = true
			presentation_event.emit("pause", fighter.slot, Vector3.ZERO, {})
			return
	if controlling_dummy:
		fighters[0].snapshot = InputSnapshot.new()
		fighters[0].buffered.clear()
	if countdown > 0:
		countdown -= 1
		for fighter in fighters:
			fighter.buffered.clear()
			fighter.visual.step(false)
		return
	tick += 1
	stage.step()
	if stage.hazard_phase == 1 and stage.tick % stage.hazard_cycle == stage.hazard_cycle - 96:
		emit_event("hazard_warning", null, Vector3(stage.hazard_side * 8, 0, 0))
	if stage.hazard_phase == 2 and stage.tick % stage.hazard_cycle == stage.hazard_cycle - 24:
		emit_event("hazard_fire", null, Vector3(stage.hazard_side * 8, 0, 0))
	for fighter in fighters:
		fighter.tick()
	var contacts := resolver.collect(fighters)
	contacts.append_array(abilities.step())
	contacts.append_array(stage.hazard_contacts(fighters))
	resolver.resolve(contacts)
	if training and training_combo_active and training_combo_target >= 0:
		var victim: RiotFighter = fighters[training_combo_target]
		if victim.hitstop == 0 and victim.stun == 0 and victim.captured_by == null:
			training_combo_active = false
	var lost: Array[RiotFighter] = []
	for fighter in fighters:
		if fighter.stocks > 0 and fighter.state != "ko" and CombatTuning.beyond_blast(fighter.position):
			lost.append(fighter)
	# All stock losses are committed before winner evaluation, including double KOs.
	for fighter in lost:
		ko_log.append({"tick": tick, "victim": fighter.slot, "credited": fighter.last_attacker if tick - fighter.last_hit_tick < 600 else -1, "assists": fighter.assists.keys()})
		emit_event("ko", fighter, fighter.position, {"credit": fighter.last_attacker})
		fighter.lose_stock()
		if training:
			fighter.stocks = 3
			fighter.change_state("ko")
	if training:
		return
	time_left = maxi(0, time_left - 1)
	var alive: Array[RiotFighter] = []
	for fighter in fighters:
		if fighter.stocks > 0: alive.append(fighter)
	if alive.size() == 1:
		finish(alive[0].slot, "LAST ONE STANDING")
	elif alive.is_empty():
		start_sudden_death(lost, "DOUBLE KO · SUDDEN DEATH")
	elif time_left == 0 and not sudden_death:
		resolve_timeout()
	elif sudden_death:
		sudden_timer -= 1
		if sudden_timer <= 0:
			# Repeated exact ties are a draw, never arbitrary player-index priority.
			var lowest: float = 99999
			var tied: Array[RiotFighter] = []
			for fighter in alive:
				if fighter.damage < lowest - 0.001:
					lowest = fighter.damage
					tied = [fighter]
				elif is_equal_approx(fighter.damage, lowest): tied.append(fighter)
			finish(tied[0].slot if tied.size() == 1 else -1, "SUDDEN DEATH DECISION" if tied.size() == 1 else "EXACT TIE · DRAW")

func resolve_timeout() -> void:
	var best_stock: int = -1
	var best_damage: float = 999999
	var tied: Array[RiotFighter] = []
	for fighter in fighters:
		if fighter.stocks <= 0: continue
		if fighter.stocks > best_stock or (fighter.stocks == best_stock and fighter.damage < best_damage - 0.001):
			best_stock = fighter.stocks
			best_damage = fighter.damage
			tied = [fighter]
		elif fighter.stocks == best_stock and is_equal_approx(fighter.damage, best_damage): tied.append(fighter)
	if tied.size() == 1:
		finish(tied[0].slot, "TIME · STOCKS THEN DAMAGE")
	else:
		start_sudden_death(tied, "EXACT TIE · SUDDEN DEATH")

func start_sudden_death(tied: Array[RiotFighter], reason: String) -> void:
	if sudden_death:
		finish(-1, "SIMULTANEOUS FINAL KO · DRAW")
		return
	sudden_death = true
	sudden_timer = 45 * 60
	countdown = 120
	abilities.reset()
	for fighter in fighters:
		if fighter in tied:
			fighter.stocks = 1
			fighter.respawn()
			fighter.damage = 200
			fighter.position = Vector3(-4 + fighter.slot * 2.7, 0, 0)
		else:
			fighter.stocks = 0
			fighter.change_state("eliminated")
			fighter.visual.visible = false
	presentation_event.emit("sudden_death", -1, Vector3.ZERO, {"text": reason})

func finish(winner: int, reason: String) -> void:
	running = false
	result = {"winner": winner, "reason": reason, "ticks": tick, "ko_log": ko_log.duplicate(true)}
	abilities.reset()
	var loser_index: int = 0
	for fighter in fighters:
		fighter.provider.reset()
		fighter.buffered.clear()
		var pose_x: float = -6.4 if fighter.slot == winner else 6.3 + loser_index * 1.2
		if fighter.slot != winner: loser_index += 1
		if winner < 0: pose_x = -6.4 + fighter.slot * 4.2
		fighter.visual.present_result(fighter.slot == winner, Vector3(pose_x, 0, 0))
	match_finished.emit(result)

func emit_event(event: String, actor: RiotFighter, at: Vector3, details: Dictionary = {}) -> void:
	if training and event == "hit" and actor != null and details.has("target"):
		var target_slot: int = int(details.target)
		if not training_combo_active or training_combo_target != target_slot or training_combo_actor != actor.slot:
			training_combo_hits = 0
			training_combo_damage = 0.0
		training_combo_hits += 1
		training_combo_damage += float(details.get("damage", 0.0))
		training_combo_target = target_slot
		training_combo_actor = actor.slot
		training_combo_active = true
	presentation_event.emit(event, actor.slot if actor != null else -1, at, details)

func route_input(event: InputEvent) -> void:
	for fighter in fighters:
		if fighter.provider is HumanInputProvider:
			fighter.provider.handle_event(event)

func reset_inputs() -> void:
	for fighter in fighters:
		fighter.provider.reset()
		fighter.buffered.clear()

func training_reset(reset_positions: bool = true) -> void:
	_reset_training_combo()
	countdown = 0
	tick = 0
	stage.reset_match(hazards_seed)
	abilities.reset()
	resolver.environment_registry.clear()
	resolver.confirmed_instances.clear()
	for fighter in fighters:
		var saved_position: Vector3 = fighter.position
		fighter.respawn()
		fighter.stocks = 3
		fighter.invulnerability = 0
		fighter.ultimate_meter = 100
		fighter.mechanics.reset()
		fighter.recent_moves.clear()
		fighter.hit_registry.clear()
		fighter.confirmed_hit = false
		fighter.charge_ticks = 0
		fighter.armor_spent = false
		fighter.move_tick = 0
		fighter.ignore_ticks = 0
		fighter.coyote = 0
		fighter.jump_hold_ticks = 0
		fighter.recovery_direction = 0.0
		fighter.ledge_lock = 0
		fighter.shield_delay = 0
		fighter.shield_start_tick = -999
		fighter.last_hit_tick = -999
		fighter.taunt_alternate = false
		fighter.respawn_timer = 0
		fighter.landing_ticks = CombatTuning.SOFT_LANDING_TICKS
		fighter.locomotion_clip = ""
		fighter.locomotion_transition = 0
		fighter.snapshot = InputSnapshot.new()
		if reset_positions:
			fighter.position = Vector3(-3.5 if fighter.slot == 0 else 3.5, 0, 0)
			fighter.grounded = true
			fighter.support_id = 0
			fighter.facing = 1 if fighter.slot == 0 else -1
			fighter.change_state("idle")
		else:
			fighter.position = saved_position
		fighter.previous_position = fighter.position
		fighter.visual_facing = fighter.facing
	var dummy := training_dummy()
	if dummy != null:
		if dummy.tape_mode == "recording":
			# Resetting the world inside a recording starts a new take. A tape
			# contains inputs, so it cannot reproduce an unrecorded position reset.
			dummy.begin_recording()
		else:
			dummy.rewind()

func training_dummy() -> TrainingInputProvider:
	if training and fighters.size() >= 2 and fighters[1].provider is TrainingInputProvider:
		return fighters[1].provider as TrainingInputProvider
	return null

func training_cycle_dummy() -> void:
	var dummy := training_dummy()
	if dummy == null: return
	dummy.stop_tape()
	var modes := ["stationary", "defending", "jumping"]
	dummy.dummy_mode = modes[(modes.find(dummy.dummy_mode) + 1) % modes.size()]
	reset_inputs()

func training_toggle_recording() -> void:
	var dummy := training_dummy()
	if dummy == null: return
	if dummy.tape_mode == "recording":
		dummy.stop_tape()
		reset_inputs()
	else:
		dummy.stop_tape()
		training_reset()
		dummy.begin_recording()

func training_toggle_playback() -> void:
	var dummy := training_dummy()
	if dummy == null: return
	if dummy.tape_mode == "playing":
		dummy.stop_tape()
		reset_inputs()
	elif not dummy.tape.is_empty():
		# Save a recording before resetting; recording resets deliberately clear
		# the unfinished take, while playback resets must retain the saved tape.
		dummy.stop_tape()
		training_reset()
		dummy.begin_playback()

func _reset_training_combo() -> void:
	training_combo_hits = 0
	training_combo_damage = 0.0
	training_combo_active = false
	training_combo_target = -1
	training_combo_actor = -1
