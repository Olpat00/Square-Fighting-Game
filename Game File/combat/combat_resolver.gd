class_name CombatResolver
extends RefCounted

# Match the launch reaction threshold; ordinary impacts keep their impact cue.
const LAUNCH_SOUND_MIN_SPEED: float = 16.0

var world: Node
var environment_registry: Dictionary = {}
var confirmed_instances: Dictionary = {}
var contacts_resolved: int = 0

func configure(match_world: Node) -> void:
	world = match_world

func collect(fighters: Array) -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	for source: RiotFighter in fighters:
		if source.state != "attack" or source.move == null or source.hitstop > 0 or not source.move.is_active(source.move_tick):
			continue
		var move: MoveDefinition = source.move
		if world.abilities.suppresses_melee(move):
			continue
		var center := source.attack_center()
		var radius: float = move.hit_radius * (1.0 + clampf(float(source.charge_ticks) / maxi(1, move.charge_max), 0.0, 1.0) * move.charge_reach_scale)
		for target: RiotFighter in fighters:
			if source == target or target.stocks <= 0 or target.state == "ko":
				continue
			# Melee advances with its move, including hitstop. A world-time rehit
			# could repeatedly hit the same frozen active frame and never recover.
			if source.hit_registry.has(target.slot) and (move.rehit_ticks <= 0 or source.move_tick - int(source.hit_registry[target.slot]) < move.rehit_ticks):
				continue
			if circle_capsule(center, radius, target.position):
				contacts.append(from_move(source, target, move))
	return contacts

static func circle_capsule(center: Vector2, radius: float, feet: Vector3) -> bool:
	var near := Vector2(feet.x, clampf(center.y, feet.y + 0.4, feet.y + 1.35))
	return center.distance_squared_to(near) <= pow(radius + CombatTuning.HURT_RADIUS, 2)

func from_move(source: RiotFighter, target: RiotFighter, move: MoveDefinition) -> Dictionary:
	var effect_offset: Vector2 = move.impact_offset if move.impact_offset.is_finite() else move.hit_offset
	return {"source": source, "target": target, "center": Vector2(source.position.x + effect_offset.x * source.facing, source.position.y + effect_offset.y), "instance": source.attack_instance, "group": move.hit_group, "damage": move.damage * (1.0 + clampf(float(source.charge_ticks) / maxi(1, move.charge_max), 0.0, 1.0) * move.charge_damage_scale), "base": move.base_knockback, "growth": move.knockback_growth, "angle": move.angle, "hitstun": move.hitstun, "hitstop": move.hitstop, "facing": source.facing, "kind": "grab" if move.ability in ["grab", "heavy_grab", "heavy_ultimate"] else "strike", "move_id": move.id, "ability": move.ability, "shield_damage": move.shield_damage, "shield_stun": move.shield_stun, "rehit": move.rehit_ticks, "radius": move.hit_radius}

func _impact_position(contact: Dictionary) -> Vector3:
	# Presentation only: retain the collected contact before interruptions and
	# trades change the attacker's move, rather than recomputing from live state.
	var target: RiotFighter = contact.target
	var center: Vector2 = contact.get("center", target.hurt_center())
	return Vector3(clampf(center.x, target.position.x - CombatTuning.HURT_RADIUS, target.position.x + CombatTuning.HURT_RADIUS), clampf(center.y, target.position.y + 0.15, target.position.y + 1.60), target.position.z)

func resolve(contacts: Array[Dictionary]) -> void:
	# Snapshot defensive eligibility before any interruption. Contacts already exist;
	# two active attackers trade regardless of node iteration order.
	var eligible: Array[Dictionary] = []
	for contact in contacts:
		var target: RiotFighter = contact.target
		if not target.vulnerable():
			continue
		var source: RiotFighter = contact.source
		var key := "%s:%s:%s" % [contact.instance, contact.group, target.slot]
		var previous: int = int(environment_registry.get(key, -99999))
		var rehit: int = int(contact.get("rehit", 0))
		if previous >= 0 and (rehit <= 0 or world.tick - previous < rehit):
			continue
		contact["defense"] = "none"
		if contact.kind != "grab" and target.state in ["shield", "shield_stun"]:
			contact.defense = "parry" if world.tick - target.shield_start_tick <= CombatTuning.PARRY_WINDOW and target.state == "shield" else "shield"
		elif contact.kind != "grab" and world.abilities.counter_open(target):
			contact.defense = "counter"
		elif contact.kind != "grab" and target.move != null and target.move.has_armor(target.move_tick) and not target.armor_spent and float(contact.damage) <= target.move.armor_threshold:
			contact.defense = "armor"
		contact["registry_key"] = key
		eligible.append(contact)
	# Simultaneous damaging strikes beat an unestablished grab. Sort only resolution
	# priority; strike eligibility was snapshotted, so ordinary trades still occur.
	eligible.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if (left.kind == "grab") != (right.kind == "grab"):
			return left.kind != "grab"
		var left_slot: int = left.source.slot if left.source != null else -1
		var right_slot: int = right.source.slot if right.source != null else -1
		return left_slot < right_slot)
	var grab_claims: Dictionary = {}
	for contact in eligible:
		var source: RiotFighter = contact.source
		var target: RiotFighter = contact.target
		if contact.kind == "grab":
			if source == null or source.state == "hitstun" or source.stun > 0 or target.captured_by != null or source.captured_by != null or source.capture_target != null or grab_claims.has(target.slot) or grab_claims.has(source.slot):
				continue
			# Mutual active grabs clash with recoil, neither acquires a victim.
			var mutual: bool = false
			for other in eligible:
				if other.kind == "grab" and other.source == target and other.target == source:
					mutual = true
			if mutual:
				source.stun = 14
				source.velocity.x = -source.facing * 4
				source.change_state("hitstun")
				continue
			grab_claims[target.slot] = source.slot
			grab_claims[source.slot] = -1
		environment_registry[contact.registry_key] = world.tick
		if source != null and int(contact.instance) == source.attack_instance:
			source.hit_registry[target.slot] = source.move_tick
		if contact.defense == "armor" and target.armor_spent:
			contact.defense = "none"
		match str(contact.defense):
			"parry", "counter": _parry(contact)
			"shield": _shield(contact)
			_: _damage(contact)
		contacts_resolved += 1
	if world.tick % 240 == 0:
		for key in environment_registry.keys():
			if world.tick - int(environment_registry[key]) > 600:
				environment_registry.erase(key)
		for key in confirmed_instances.keys():
			if world.tick - int(confirmed_instances[key]) > 600:
				confirmed_instances.erase(key)

func _parry(contact: Dictionary) -> void:
	var target: RiotFighter = contact.target
	var source: RiotFighter = contact.source
	target.shield_delay = 30
	target.shield = minf(target.definition.shield_max, target.shield + 8)
	target.invulnerability = 10
	if contact.defense == "parry": target.mechanics.on_parry(source)
	target.visual.play("parry", 16)
	if source != null and contact.defense == "parry" and contact.kind == "strike" and source.position.distance_to(target.position) < 3.0:
		source.interrupt()
		source.stun = 23
		source.change_state("hitstun")
		source.velocity = Vector3(-contact.facing * 6.5, 2, 0)
		source.visual.play("hit_heavy", source.stun)
	if contact.defense == "counter" and source != null:
		var counter: Dictionary = world.abilities.counter_contact(target, contact)
		if not counter.is_empty(): _damage(counter)
	world.emit_event("parry", target, target.position)

func _shield(contact: Dictionary) -> void:
	var target: RiotFighter = contact.target
	var source: RiotFighter = contact.source
	target.shield -= float(contact.get("shield_damage", contact.damage))
	target.shield_delay = CombatTuning.SHIELD_REGEN_DELAY
	target.stun = int(contact.get("shield_stun", 8))
	target.change_state("shield_stun")
	target.hitstop = int(contact.hitstop)
	if source:
		source.hitstop = int(contact.hitstop)
		source.velocity.x = -contact.facing * 1.5
	if target.shield <= 0:
		target.break_shield()
	world.emit_event("shield", target, target.position)

func _damage(contact: Dictionary) -> void:
	var target: RiotFighter = contact.target
	var source: RiotFighter = contact.source
	if contact.kind == "grab" and source != null:
		target.interrupt()
		source.capture_target = target
		target.captured_by = source
		target.grounded = false
		target.support_id = -1
		target.coyote = 0
		target.velocity = Vector3.ZERO
		target.change_state("captured")
		target.visual.play("victim_grab", 0, true)
		source.change_state("grab_hold")
		source.visual.play("grab_hold", 0, true)
		source.confirmed_hit = true
		world.abilities.on_capture(source, target, str(contact.get("ability", "")))
		return
	contact = world.abilities.prepare_damage(contact)
	var damage_value: float = float(contact.damage)
	var move_id: String = str(contact.get("move_id", "hazard"))
	var stale: float = 1.0
	if source != null:
		var repeats: int = source.recent_moves.count(move_id)
		stale = maxf(0.65, 1.0 - repeats * 0.08)
		var confirmation_key := "%d:%d" % [source.slot, int(contact.instance)]
		if not confirmed_instances.has(confirmation_key):
			confirmed_instances[confirmation_key] = world.tick
			source.recent_moves.append(move_id)
			if source.recent_moves.size() > 6: source.recent_moves.pop_front()
		if int(contact.instance) == source.attack_instance:
			source.confirmed_hit = true
		source.mechanics.on_hit(move_id, target, bool(contact.get("precise", false)), contact.kind == "trap")
	damage_value *= stale
	target.damage += damage_value
	var armored: bool = str(contact.get("defense", "")) == "armor"
	var launch_speed: float = 0.0
	if not armored and not bool(contact.get("hold_capture", false)):
		target.interrupt()
		var speed := CombatTuning.knockback(float(contact.base), float(contact.growth), target.damage, target.definition.weight)
		launch_speed = speed
		var angle: float = deg_to_rad(float(contact.angle))
		var influence: float = target.snapshot.move.y * 0.09 if target.snapshot else 0.0
		angle += influence
		target.velocity = Vector3(cos(angle) * speed * float(contact.facing), sin(angle) * speed, 0)
		if target.velocity.y > 0.1:
			target.grounded = false
			target.support_id = -1
		target.stun = mini(65, int(float(contact.hitstun) * stale) + int(speed * 0.25))
		target.change_state("hitstun")
		target.visual.play("victim_throw" if contact.kind == "throw" else "launch" if speed > 16 else "hit_heavy" if damage_value >= 10 else "hit_light", maxi(10, target.stun))
	elif armored:
		target.armor_spent = true
		target.world.emit_event("armor", target, target.position)
	target.hitstop = int(contact.hitstop)
	if source != null:
		source.hitstop = int(contact.hitstop)
		var old_meter: float = source.ultimate_meter
		source.ultimate_meter = minf(100, source.ultimate_meter + minf(6, damage_value * 0.42))
		if old_meter < 100 and source.ultimate_meter >= 100:
			world.emit_event("meter_ready", source, source.position)
		target.ultimate_meter = minf(100, target.ultimate_meter + minf(3, damage_value * 0.18))
		target.last_attacker = source.slot
		target.last_hit_tick = world.tick
		target.assists[source.slot] = world.tick
		world.abilities.on_confirm(source, target, contact)
	world.emit_event("hit", source, _impact_position(contact), {"damage": damage_value, "target": target.slot, "heavy": damage_value >= 10})
	if launch_speed > LAUNCH_SOUND_MIN_SPEED:
		world.emit_event("launch", source, target.position + Vector3(0, 0.9, 0), {"speed": launch_speed, "target": target.slot})
