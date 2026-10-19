class_name AbilityController
extends Node3D

const ABILITY_ART = preload("res://presentation/ability_art.gd")

var world: Node
var kits: Dictionary = {}
var objects: Array[Dictionary] = []
var sequences: Array[Dictionary] = []
var pending_contacts: Array[Dictionary] = []
var spent_counters: Dictionary = {}
var prop_cache: Dictionary = {}

func on_move_start(fighter: RiotFighter, move: MoveDefinition) -> void:
	if kits.has(fighter.slot):
		kits[fighter.slot].move_started(move)

func on_landing(fighter: RiotFighter) -> void:
	if kits.has(fighter.slot):
		kits[fighter.slot].landed()

func on_taunt_start(fighter: RiotFighter, clip: String) -> void:
	if kits.has(fighter.slot): kits[fighter.slot].taunted(clip)

func movement_for(fighter: RiotFighter, move: MoveDefinition, tick: int) -> Dictionary:
	var segment: Dictionary = move.movement_at(tick).duplicate(true)
	if segment.is_empty():
		return segment
	var v: Vector2 = segment.velocity
	if fighter.mechanics.empowered:
		v *= float(move.ability_data.get("empowered_velocity_scale", move.ability_data.get("quick_fix_velocity_scale", 1.0)))
	if bool(move.ability_data.get("recovery", false)):
		v.x += fighter.recovery_direction * fighter.facing * absf(v.x) * float(move.ability_data.get("steering", 0.0))
	segment.velocity = v
	return segment

func prepare_damage(contact: Dictionary) -> Dictionary:
	var source: RiotFighter = contact.get("source")
	var target: RiotFighter = contact.get("target")
	if source == null or target == null:
		return contact
	var move: MoveDefinition = source.definition.get_move(str(contact.get("move_id", "")))
	if move == null:
		return contact
	var data: Dictionary = contact.get("ability_data", move.ability_data)
	if str(contact.get("ability", "")) == "fine_thrust":
		var distance: float = absf(source.position.x - target.position.x)
		contact.precise = distance >= float(data.get("citation_min_range", 1.8)) and distance <= float(data.get("citation_max_range", 2.7))
	if source.definition.mechanic == "citations" and bool(data.get("consume_citations", false)) and (move.id == "heavy_side" or str(contact.get("group", "")) == "ultimate_final"):
		var count: int = mini(int(data.get("citation_max", 3)), source.mechanics.consume_marks(target))
		contact.damage = float(contact.damage) + count * float(data.get("citation_damage_per_mark", 0.0))
		contact.base = float(contact.base) + count * float(data.get("citation_knockback_per_mark", 0.0))
	return contact

func counter_contact(fighter: RiotFighter, incoming: Dictionary) -> Dictionary:
	if fighter.move == null or spent_counters.has(fighter.attack_instance):
		return {}
	var attacker: RiotFighter = incoming.get("source")
	if attacker == null:
		return {}
	spent_counters[fighter.attack_instance] = world.tick
	var move: MoveDefinition = fighter.move
	var data: Dictionary = move.ability_data
	var toward: int = 1 if attacker.position.x >= fighter.position.x else -1
	var response_center := Vector2(fighter.position.x + move.hit_offset.x * toward, fighter.position.y + move.hit_offset.y)
	if not CombatResolver.circle_capsule(response_center, move.hit_radius, attacker.position):
		return {} # Blocks the projectile but cannot strike its distant owner.
	var contact: Dictionary = world.resolver.from_move(fighter, attacker, move)
	contact.instance = world.next_attack_id()
	contact.group = "counter"
	contact.damage = minf(float(data.get("counter_damage_cap", move.damage)), maxf(move.damage, float(incoming.damage) * float(data.get("counter_damage_scale", 1.0))))
	contact.facing = 1 if attacker.position.x >= fighter.position.x else -1
	contact.defense = "none"
	contact.kind = "strike"
	contact.precise = move.ability == "fine_counter"
	contact.ability = "counter_response"
	contact.ability_data = data.duplicate(true)
	fighter.visual.play("counter_success", 22)
	return contact

func capture_position(target: RiotFighter) -> Vector3:
	var source: RiotFighter = target.captured_by
	if source == null:
		return target.position
	for sequence: Dictionary in sequences:
		if sequence.target == target and sequence.capture and not sequence.cancelled:
			var phase: float = float(sequence.age) / maxi(1, int(sequence.duration))
			if sequence.move.ability in ["heavy_grab", "heavy_ultimate"]:
				# Authored hands rise to 1.9–2.1m, then descend toward 0.8m.
				# Keep the victim's waist in that grip; a 2m root lift previously
				# put even their feet above the hands. These are fixed tick paths,
				# independent of interpolated bones and combat contact collection.
				var points: Array[Vector3] = [Vector3(0, 0.85, 0.10), Vector3(0.28, 0.40, 0.85), Vector3(1, 0.70, 0.03)]
				if sequence.move.ability == "heavy_ultimate":
					points = [Vector3(0, 0.85, 0.10), Vector3(0.27, 0.40, 0.85), Vector3(0.62, 0.30, 1.00), Vector3(1, 0.70, 0.08)]
				for index: int in range(1, points.size()):
					if phase <= points[index].x:
						var previous: Vector3 = points[index - 1]
						var next: Vector3 = points[index]
						var weight: float = smoothstep(previous.x, next.x, phase)
						return source.position + Vector3(source.facing * lerpf(previous.y, next.y, weight), lerpf(previous.z, next.z, weight), 0)
				return source.position + Vector3(source.facing * 0.70, 0.08, 0)
			return source.position + Vector3(source.facing * float(sequence.data.get("capture_distance", 1.0)), 0.15, 0)
	return source.position + Vector3(source.facing * 0.7, 0.2, 0)

func configure(match_world: Node) -> void:
	world = match_world

func register(fighter: RiotFighter) -> void:
	var path := "res://combat/abilities/%s.gd" % fighter.definition.mechanic
	if ResourceLoader.exists(path):
		var kit: AbilityKit = load(path).new()
		kit.setup(self, fighter)
		kits[fighter.slot] = kit

func activate(fighter: RiotFighter, move: MoveDefinition) -> void:
	if move.ability == "throw" and is_instance_valid(fighter.capture_target):
		throw_target(fighter, fighter.capture_target, move)
	elif kits.has(fighter.slot):
		kits[fighter.slot].activate(move)

func suppresses_melee(move: MoveDefinition) -> bool:
	return move.ability in ["clutch_palm", "sun_disc", "sun_reflector", "sun_ultimate", "deadfall_log", "deadfall_trap", "deadfall_ultimate", "heavy_stomp", "fine_ultimate", "clutch_counter", "fine_counter", "throw", "explorer_hook", "sentinel_bolt", "sentinel_pulse", "sentinel_ultimate", "gentleman_arc", "gentleman_retreat"]

func counter_open(fighter: RiotFighter) -> bool:
	if fighter.state != "attack" or fighter.move == null or spent_counters.has(fighter.attack_instance):
		return false
	var data: Dictionary = fighter.move.ability_data
	return data.has("counter_from") and fighter.move_tick >= int(data.counter_from) and fighter.move_tick <= int(data.counter_to)

func on_confirm(source: RiotFighter, target: RiotFighter, contact: Dictionary) -> void:
	if kits.has(source.slot):
		kits[source.slot].confirm(target, contact)

func on_capture(source: RiotFighter, target: RiotFighter, ability: String) -> void:
	if kits.has(source.slot):
		kits[source.slot].captured(target, ability)

func interrupt(fighter: RiotFighter) -> void:
	for sequence in sequences:
		if sequence.owner == fighter or sequence.target == fighter:
			sequence.cancelled = true
	for item: Dictionary in objects:
		if item.owner == fighter and bool(item.options.get("cancel_on_interrupt", false)):
			item.expired = true

func clear_owner(fighter: RiotFighter) -> void:
	for item in objects:
		if item.owner == fighter:
			item.expired = true
	interrupt(fighter)
	for other: RiotFighter in world.fighters:
		other.mechanics.marks.erase(fighter.slot)

func reset() -> void:
	for item in objects:
		if is_instance_valid(item.visual): item.visual.queue_free()
	for sequence: Dictionary in sequences:
		if is_instance_valid(sequence.get("visual")): sequence.visual.queue_free()
	objects.clear()
	sequences.clear()
	pending_contacts.clear()
	spent_counters.clear()

func owned_count(fighter: RiotFighter, type: String) -> int:
	var count: int = 0
	for item in objects:
		if item.owner == fighter and item.type == type and not item.expired:
			count += 1
	return count

func spawn(fighter: RiotFighter, type: String, p: Vector2, v: Vector2, move: MoveDefinition, options: Dictionary = {}) -> void:
	var data: Dictionary = move.ability_data
	var max_count: int = int(options.get("max_count", data.get("max_owned", 2)))
	if owned_count(fighter, type) >= max_count:
		for item in objects:
			if item.owner == fighter and item.type == type and not item.expired:
				item.expired = true
				break
	var visual: Node3D = make_prop(type, fighter.definition.palette, fighter.definition.mechanic, move.ability)
	visual.position = Vector3(p.x, p.y, 0)
	if type in ["reflector", "plank", "branch", "chair", "precision_line", "ribbon", "ring", "hook"] and fighter.facing < 0:
		visual.rotation.y = PI
	add_child(visual)
	var item: Dictionary = {"owner": fighter, "type": type, "position": p, "previous": p, "velocity": v, "move": move, "age": -1, "life": int(options.get("life", data.get("lifetime", 60))), "instance": world.next_attack_id(), "birth_attack": fighter.attack_instance, "facing": fighter.facing, "charge": fighter.charge_ticks, "radius": float(options.get("radius", data.get("radius", move.hit_radius))), "visual": visual, "expired": false, "returning": false, "reflected": false, "hits": {}, "object_hits": {}, "options": options.duplicate(true), "data": data.duplicate(true), "hp": float(data.get("durability", 12.0)), "support": -1}
	if type in ["trap", "reflector", "log"]:
		item.support = _support_at(p, 0.8)
	if type == "ring":
		visual.scale = Vector3.ONE * float(item.radius) / 0.45
	if type in ["spotlight", "tree", "geometry"]:
		visual.add_child(_zone_marker(item, fighter.definition.palette))
	objects.append(item)
	world.emit_event("ability", fighter, visual.position, {"type": type})

func zone(fighter: RiotFighter, center: Vector2, size_value: Vector2, move: MoveDefinition, warning: int, duration: int, shape: String = "zone") -> void:
	spawn(fighter, shape, center, Vector2.ZERO, move, {"life": warning + duration, "warning": warning, "size": size_value, "max_count": 1, "owner_clock": true, "cancel_on_interrupt": true, "angle": float(move.ability_data.get("zone_angle", 0.0)) if fighter.facing > 0 else 180.0 - float(move.ability_data.get("zone_angle", 0.0))})

func combo(fighter: RiotFighter, target: RiotFighter, move: MoveDefinition, _hits: int = 0, _interval: int = 0, _final_damage: float = 0.0, capture: bool = true) -> void:
	if fighter.state in ["hitstun", "ko", "eliminated"] or fighter.captured_by != null:
		return
	for seq in sequences:
		if seq.owner == fighter and seq.instance == fighter.attack_instance:
			return
	if target.captured_by != null and target.captured_by != fighter:
		return
	var data: Dictionary = move.ability_data
	var duration: int = int(data.get("capture_ticks", data.get("followup_delay", 9)))
	var events: Array[Dictionary] = []
	var followup: float = float(data.get("followup_damage", 0.0))
	if data.has("finisher_damage"):
		if followup > 0:
			for index: int in range(1, 4):
				events.append({"tick": maxi(1, int(duration * index / 4.0)), "damage": followup / 3.0, "final": false})
		events.append({"tick": duration, "damage": float(data.finisher_damage), "final": true})
	else:
		events.append({"tick": duration, "damage": followup if followup > 0 else move.damage, "final": true})
	if capture:
		fighter.capture_target = target
		target.captured_by = fighter
		target.change_state("captured")
		target.visual.play("victim_grab", 0, true)
	fighter.change_state("ability_sequence")
	fighter.velocity.x = 0.0 # A confirmed sequence plants its attacker; no leftover rush drift.
	if move.ability in ["heavy_grab", "heavy_ultimate"]:
		fighter.visual.play(move.animation_id, move.total_ticks())
		if fighter.visual.animation_player != null:
			var player: AnimationPlayer = fighter.visual.animation_player
			player.seek(player.current_animation_length * float(move.startup) / float(move.total_ticks()), true)
	for item: Dictionary in objects:
		if item.owner == fighter and int(item.birth_attack) == fighter.attack_instance and bool(item.options.get("owner_clock", false)):
			item.expired = true
	var sequence_visual: Node3D = null
	if move.id == "ultimate":
		sequence_visual = ABILITY_ART.sequence_art(fighter.definition.mechanic, fighter.definition.palette, _flash_level(), _low_quality())
		add_child(sequence_visual)
		sequence_visual.position = target.position + Vector3(0, 0.95, -0.06)
	sequences.append({"owner": fighter, "target": target, "move": move, "data": data.duplicate(true), "age": 0, "start_tick": fighter.move_tick, "duration": duration, "events": events, "capture": capture, "instance": fighter.attack_instance, "facing": fighter.facing, "cancelled": false, "visual": sequence_visual})
	if sequence_visual != null: ABILITY_ART.animate_sequence(sequence_visual, sequences[-1])
	if str(data.get("temporary_prop", "")) == "folding_chair":
		spawn(fighter, "chair", Vector2(fighter.position.x + fighter.facing * 0.70, fighter.position.y), Vector2.ZERO, move, {"life": duration + 16, "cosmetic": true, "cancel_on_interrupt": true})

func throw_target(source: RiotFighter, target: RiotFighter, move: MoveDefinition) -> void:
	target.captured_by = null
	source.capture_target = null
	var contact: Dictionary = world.resolver.from_move(source, target, move)
	contact.kind = "throw"
	contact.instance = world.next_attack_id()
	contact.facing = source.facing # Back throw already has a backward launch angle.
	pending_contacts.append(contact)
	target.visual.play("victim_throw", 20)

func step() -> Array[Dictionary]:
	var contacts: Array[Dictionary] = pending_contacts.duplicate()
	pending_contacts.clear()
	for item: Dictionary in objects:
		_step_object(item, contacts)
	for sequence: Dictionary in sequences:
		_step_sequence(sequence, contacts)
	for i in range(objects.size() - 1, -1, -1):
		if objects[i].expired:
			objects[i].visual.queue_free()
			objects.remove_at(i)
	for i in range(sequences.size() - 1, -1, -1):
		if sequences[i].cancelled:
			_end_sequence(sequences[i])
			sequences.remove_at(i)
	if world.tick % 240 == 0:
		for key: Variant in spent_counters.keys():
			if world.tick - int(spent_counters[key]) > 300:
				spent_counters.erase(key)
	return contacts

func _step_object(item: Dictionary, contacts: Array[Dictionary]) -> void:
	if item.expired:
		return
	var source: RiotFighter = item.owner
	if source.stocks <= 0 or source.state in ["ko", "eliminated"]:
		item.expired = true
		return
	if bool(item.options.get("taunt_only", false)) and source.state != "taunt":
		item.expired = true
		return
	# Attached attack presentation holds with its fighter during local hitstop.
	# Independent damaging projectiles keep their own world clock.
	if int(item.age) >= 0 and source.hitstop > 0 and bool(item.options.get("cosmetic", false)):
		return
	item.age += 1
	if bool(item.options.get("owner_clock", false)):
		if source.attack_instance != int(item.birth_attack) or source.move == null:
			item.expired = true
			return
		item.age = source.move_tick
	if int(item.age) >= int(item.life):
		item.expired = true
		return
	var delay: int = int(item.options.get("delay", 0))
	item.visual.visible = item.age >= delay
	if item.age < delay:
		return
	var unfold_ticks: int = int(item.options.get("unfold_ticks", 0))
	if unfold_ticks > 0:
		item.visual.scale.x = lerpf(0.18, 1.0, smoothstep(0, unfold_ticks, item.age - delay))
	if item.age == delay and bool(item.options.get("anchor_on_show", false)):
		var anchor_offset: Vector2 = item.options.get("offset", Vector2.ZERO)
		item.position = Vector2(source.position.x + anchor_offset.x * source.facing, source.position.y + anchor_offset.y)
	item.previous = item.position
	var type: String = item.type
	if type == "disc":
		_step_disc(item)
	elif type in ["log", "trap", "reflector"]:
		_step_terrain_object(item)
	elif bool(item.options.get("follow_owner", false)):
		var offset: Vector2 = item.options.get("offset", Vector2.ZERO)
		item.position = Vector2(source.position.x + offset.x * source.facing, source.position.y + offset.y)
	if item.expired:
		return
	if type not in ["log", "trap", "reflector"]:
		item.position += item.velocity * CombatTuning.DT
	item.visual.position = Vector3(item.position.x, item.position.y, 0)
	_present_object(item)
	if absf(item.position.x) > 22.0 or item.position.y < -9.0:
		item.expired = true
		return
	if type in ["disc", "log"]:
		item.visual.rotation.z += 0.17
	var active: bool = true
	if type in ["spotlight", "tree", "geometry"]:
		active = item.move.is_active(int(item.age))
		_present_zone(item, active)
	elif type == "trap":
		active = item.age >= int(item.data.get("arming_ticks", 30)) and int(item.support) >= 0
		item.visual.scale = Vector3.ONE * (1.0 if active else 0.65)
	if type in ["trap", "reflector"]:
		_damage_object(item)
	if item.expired or not active or type == "reflector" or bool(item.options.get("cosmetic", false)):
		if item.age >= item.life:
			item.expired = true
		return
	var rehit: int = int(item.options.get("rehit", item.move.rehit_ticks))
	# Attached zones freeze with their attack during hitstop. A world-clock
	# cooldown could expire while the same pulse is still frozen on screen.
	var contact_tick: int = int(item.age) if bool(item.options.get("owner_clock", false)) else world.tick
	for target: RiotFighter in world.fighters:
		if target == source or target.stocks <= 0 or target.state in ["ko", "eliminated"]:
			continue
		if item.hits.has(target.slot) and (rehit <= 0 or contact_tick - int(item.hits[target.slot]) < rehit):
			continue
		if _inside(item, target):
			item.hits[target.slot] = contact_tick
			var contact: Dictionary = _object_contact(item, target)
			contact.rehit = rehit
			contacts.append(contact)
			if type in ["trap", "hook"]:
				item.expired = true
				break
	if item.age >= item.life or absf(item.position.x) > 22.0 or item.position.y < -9.0:
		item.expired = true

func _step_disc(item: Dictionary) -> void:
	var source: RiotFighter = item.owner
	if item.age >= int(item.data.get("return_tick", 32)):
		item.returning = true
	var speed: float = float(item.data.get("speed", 9.2))
	if item.returning:
		var home := Vector2(source.position.x, source.position.y + 1.1)
		item.velocity = (home - Vector2(item.position)).normalized() * speed
		if Vector2(item.position).distance_to(home) <= float(item.data.get("catch_radius", 0.85)):
			source.mechanics.catch_disc()
			item.expired = true
	elif not item.reflected:
		for puck: Dictionary in objects:
			if puck.type == "reflector" and puck.owner == source and not puck.expired and Vector2(item.position).distance_to(puck.position) < float(puck.radius) + float(item.radius):
				var angle: float = deg_to_rad(float(puck.data.get("redirect_angle", 30.0)))
				item.velocity = Vector2(cos(angle) * int(puck.facing), sin(angle)) * speed
				item.reflected = true
				break

func _step_terrain_object(item: Dictionary) -> void:
	var support: Dictionary = _platform_by_id(int(item.support))
	var offset_y: float = float(item.radius) if item.type == "log" else 0.16 if item.type == "trap" else 0.20
	if not support.is_empty() and absf(float(item.position.x) - float(support.x)) <= float(support.width) * 0.5:
		item.position.y = float(support.y) + offset_y
		item.velocity.y = 0.0
	else:
		item.support = -1
		item.velocity.y -= 21.0 * CombatTuning.DT
	var next: Vector2 = Vector2(item.position) + Vector2(item.velocity) * CombatTuning.DT
	if int(item.support) < 0 and float(item.velocity.y) <= 0.0:
		for platform: Dictionary in world.stage.platforms:
			if absf(next.x - float(platform.x)) <= float(platform.width) * 0.5 and float(item.position.y) - offset_y >= float(platform.get("previous_y", platform.y)) - 0.03 and next.y - offset_y <= float(platform.y):
				item.support = int(platform.id)
				next.y = float(platform.y) + offset_y
				item.velocity.y = 0.0
				break
	item.position = next

func _support_at(p: Vector2, tolerance: float) -> int:
	var selected: int = -1
	var distance: float = tolerance
	for platform: Dictionary in world.stage.platforms:
		var dy: float = p.y - float(platform.y)
		if dy >= -0.05 and dy < distance and absf(p.x - float(platform.x)) <= float(platform.width) * 0.5:
			selected = int(platform.id)
			distance = dy
	return selected

func _platform_by_id(id: int) -> Dictionary:
	for platform: Dictionary in world.stage.platforms:
		if int(platform.id) == id:
			return platform
	return {}

func _damage_object(item: Dictionary) -> void:
	for attacker: RiotFighter in world.fighters:
		if attacker == item.owner or attacker.state != "attack" or attacker.move == null or not attacker.move.is_active(attacker.move_tick) or suppresses_melee(attacker.move):
			continue
		var key: String = "%d:%s" % [attacker.attack_instance, attacker.move.hit_group]
		if not item.object_hits.has(key) and attacker.attack_center().distance_to(item.position) < attacker.move.hit_radius + float(item.radius):
			item.object_hits[key] = true
			item.hp -= attacker.move.damage
	for projectile: Dictionary in objects:
		if projectile.owner == item.owner or projectile.expired or projectile.type not in ["disc", "ring", "log", "hook"]:
			continue
		var key: String = str(projectile.instance)
		var near: Vector2 = Geometry2D.get_closest_point_to_segment(item.position, projectile.previous, projectile.position)
		if not item.object_hits.has(key) and near.distance_to(item.position) < float(projectile.radius) + float(item.radius):
			item.object_hits[key] = true
			item.hp -= float(projectile.move.damage) * float(projectile.options.get("damage_scale", 1.0))
	if item.hp <= 0:
		item.expired = true
		world.emit_event("tool_break", item.owner, Vector3(item.position.x, item.position.y, 0))

func _inside(item: Dictionary, target: RiotFighter) -> bool:
	var center: Vector2 = item.position
	if bool(item.options.get("ground_wave", false)) and absf(target.position.y - (center.y - 0.16)) > 0.40:
		return false
	if item.type == "tree":
		var length_value: float = float(item.data.get("zone_length", 5.6))
		var width: float = float(item.data.get("zone_width", 1.3))
		var angle: float = deg_to_rad(float(item.options.angle))
		var half := Vector2(cos(angle), sin(angle)) * (length_value - width) * 0.5
		var near: Vector2 = Geometry2D.get_closest_point_to_segment(target.hurt_center(), center - half, center + half)
		return CombatResolver.circle_capsule(near, width * 0.5, target.position)
	if item.type == "spotlight":
		return CombatResolver.circle_capsule(center, float(item.data.get("zone_radius", 1.8)), target.position)
	if item.type == "geometry":
		var half_size: Vector2 = item.options.size * 0.5
		var delta: Vector2 = target.hurt_center() - center
		return absf(delta.x) <= half_size.x + CombatTuning.HURT_RADIUS and absf(delta.y) <= half_size.y + CombatTuning.HURT_RADIUS
	var near: Vector2 = Geometry2D.get_closest_point_to_segment(target.hurt_center(), item.previous, center)
	return CombatResolver.circle_capsule(near, float(item.radius), target.position)

func _object_contact(item: Dictionary, target: RiotFighter) -> Dictionary:
	var source: RiotFighter = item.owner
	var move: MoveDefinition = item.move
	var contact: Dictionary = world.resolver.from_move(source, target, move)
	# Snapshot the actual object/sweep position for impact presentation; this
	# metadata never changes _inside(), hit ownership, damage, or rehit rules.
	contact.center = item.position if item.type in ["spotlight", "tree", "geometry", "trap"] else Geometry2D.get_closest_point_to_segment(target.hurt_center(), item.previous, item.position)
	contact.instance = item.instance
	contact.kind = "trap" if item.type == "trap" else "projectile"
	contact.facing = 1 if item.velocity.x > 0 else -1 if item.velocity.x < 0 else int(item.facing)
	contact.damage = float(item.options.get("damage", move.damage)) * float(item.options.get("damage_scale", 1.0)) * (1.0 + float(item.charge) / maxf(1.0, float(move.charge_max)) * move.charge_damage_scale)
	contact.ability_data = item.data
	if item.type == "spotlight" and int(item.age) >= int(move.active_windows[-1].x):
		contact.base = float(item.data.get("finisher_base", move.base_knockback))
		contact.growth = float(item.data.get("finisher_growth", move.knockback_growth))
	return contact

func _step_sequence(sequence: Dictionary, contacts: Array[Dictionary]) -> void:
	if sequence.cancelled:
		return
	var source: RiotFighter = sequence.owner
	var target: RiotFighter = sequence.target
	if source.state in ["ko", "eliminated", "hitstun"] or target.state in ["ko", "eliminated"] or (sequence.capture and (source.capture_target != target or target.captured_by != source)):
		sequence.cancelled = true
		return
	if source.hitstop > 0 or target.hitstop > 0:
		return
	sequence.age += 1
	if is_instance_valid(sequence.get("visual")):
		ABILITY_ART.animate_sequence(sequence.visual, sequence)
		_set_energy_uniforms(sequence.visual, float(sequence.age) / maxi(1, int(sequence.duration)), 0.9, 1.0)
	for event: Dictionary in sequence.events:
		if int(event.tick) != int(sequence.age):
			continue
		var final_hit: bool = bool(event.final)
		if not sequence.capture and source.position.distance_to(target.position) > 2.8:
			sequence.cancelled = true
			return
		var move: MoveDefinition = sequence.move
		var data: Dictionary = sequence.data
		var contact: Dictionary = world.resolver.from_move(source, target, move)
		contact.instance = world.next_attack_id()
		contact.kind = "throw" if sequence.capture else "strike"
		contact.group = "ultimate_final" if final_hit and move.id == "ultimate" else "confirmed_final" if final_hit else "confirmed_link"
		contact.damage = float(event.damage)
		contact.base = float(data.get("finisher_base", data.get("followup_base", move.base_knockback))) if final_hit else 0.0
		contact.growth = float(data.get("finisher_growth", data.get("followup_growth", move.knockback_growth))) if final_hit else 0.0
		contact.angle = move.angle if final_hit else 75.0
		contact.hitstun = move.hitstun if final_hit else 12
		contact.hitstop = 8 if final_hit else 2
		contact.facing = int(sequence.facing)
		contact.ability = "sequence"
		contact.ability_data = data
		contact.hold_capture = sequence.capture and not final_hit
		if final_hit:
			_release_sequence_capture(sequence)
			target.visual.play("victim_throw", 20)
			sequence.cancelled = true
		contacts.append(contact)

func _release_sequence_capture(sequence: Dictionary) -> void:
	var source: RiotFighter = sequence.owner
	var target: RiotFighter = sequence.target
	if source.capture_target == target:
		source.capture_target = null
	if target.captured_by == source:
		target.captured_by = null

func _end_sequence(sequence: Dictionary) -> void:
	if is_instance_valid(sequence.get("visual")): sequence.visual.queue_free()
	_release_sequence_capture(sequence)
	var source: RiotFighter = sequence.owner
	var target: RiotFighter = sequence.target
	if source.state == "ability_sequence":
		source.move = sequence.move
		source.move_tick = maxi(int(source.move.active_windows[-1].y) + 1, int(sequence.start_tick) + int(sequence.age))
		source.change_state("attack") # Preserve the remaining authored vulnerable recovery.
	if target.state == "captured":
		target.stun = 10
		target.change_state("hitstun")

func make_prop(type: String, color: Color, mechanic: String = "", ability: String = "") -> Node3D:
	var root := Node3D.new()
	var authored: Node3D = ABILITY_ART.make(type, mechanic, ability, color, _flash_level(), _low_quality())
	if authored != null:
		root.add_child(authored)
		return root
	var names: Dictionary = {"disc": "solar_disc", "reflector": "reflector", "log": "log", "plank": "plank", "branch": "branch", "chair": "chair", "tree_prop": "tree"}
	if names.has(type):
		var path: String = "res://assets/props/%s.glb" % names[type]
		if ResourceLoader.exists(path):
			if not prop_cache.has(path):
				prop_cache[path] = load(path)
			var scene: PackedScene = prop_cache[path] as PackedScene
			if scene != null:
				var model: Node3D = scene.instantiate()
				# GLB base origins differ from the live combat-object offsets.
				# Seat visible surfaces without moving authoritative hitboxes.
				if type == "plank": model.position.y = -0.107
				elif type == "reflector": model.position.y = -0.20
				root.add_child(model)
				ABILITY_ART.polish_prop(model, type)
				ABILITY_ART.decorate(root, type, color, _flash_level(), _low_quality())
				return root
	if type in ["spotlight", "tree", "geometry"]:
		return root
	if type in ["disc", "ring", "reflector", "hook"]:
		root.add_child(_contour_mesh(color, Vector2.ONE * 0.43, 0, false))
		return root
	var mesh := MeshInstance3D.new()
	if type in ["precision_line", "ribbon", "geometry_impact"]:
		var trace := ImmediateMesh.new()
		trace.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _filament_material(color))
		if type == "precision_line":
			# Palm is at local (.65, 1.465); terminal frame stays centered on
			# the authoritative (2.05, 1.12) hit region. Connect the real palm.
			_trace_strip(trace, Vector3(-1.4, 0.345, 0), Vector3(0.53, 0, 0), 0.045)
			for ends in [[Vector3(-0.53, -0.11, 0), Vector3(0.53, -0.11, 0)], [Vector3(-0.53, 0.11, 0), Vector3(0.53, 0.11, 0)]]:
				_trace_strip(trace, ends[0], ends[1], 0.035)
			_trace_strip(trace, Vector3(0.53, -0.11, 0), Vector3(0.53, 0.11, 0), 0.035)
		elif type == "geometry_impact":
			# Two offset cuts resolve along one decisive direction. The area
			# remains established by its restrained corner-bracket telegraph.
			_trace_strip(trace, Vector3(-0.95, -0.48, 0.08), Vector3(0.94, 0.48, 0.08), 0.055)
			_trace_strip(trace, Vector3(-0.68, -0.54, 0.09), Vector3(0.87, 0.23, 0.09), 0.028)
			_trace_strip(trace, Vector3(0.48, 0.34, 0.08), Vector3(0.95, 0.35, 0.08), 0.025)
		else:
			for index in 28:
				var start_angle: float = -1.4 + index * 2.8 / 28.0
				var end_angle: float = -1.4 + (index + 1) * 2.8 / 28.0
				_trace_strip(trace, Vector3(cos(start_angle), sin(start_angle), 0) * 0.72, Vector3(cos(end_angle), sin(end_angle), 0) * 0.72, 0.095, false)
				_trace_strip(trace, Vector3(cos(start_angle - 0.13), sin(start_angle - 0.13), 0.01) * 0.64, Vector3(cos(end_angle - 0.13), sin(end_angle - 0.13), 0.01) * 0.64, 0.04, false)
		trace.surface_end()
		mesh.mesh = trace
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mesh)
		return root
	elif type == "log":
		var log_shape := CylinderMesh.new()
		log_shape.top_radius = 0.48
		log_shape.bottom_radius = 0.48
		log_shape.height = 0.65
		mesh.mesh = log_shape
		mesh.rotation.x = PI / 2.0
	else:
		var bar := BoxMesh.new()
		bar.size = Vector3(0.85, 0.045, 0.32) if type == "step" else Vector3(1.2, 0.09, 0.20)
		mesh.mesh = bar
	mesh.material_override = _effect_material(Color(color, 0.32) if type == "step" else color)
	root.add_child(mesh)
	return root

func _trace_strip(trace: ImmediateMesh, start: Vector3, end: Vector3, thickness: float, taper: bool = true) -> void:
	var normal := Vector3(-(end.y - start.y), end.x - start.x, 0).normalized() * thickness
	var vertices: Array[Vector3] = [start - normal, start + normal, end + normal, start - normal, end + normal, end - normal]
	var uv: Array[Vector2] = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(1, 0)]
	for index: int in vertices.size():
		# Linked arc segments use the opaque middle of the longitudinal mask;
		# their transverse soft fade is continuous across every joint.
		trace.surface_set_uv(uv[index] if taper else Vector2(0.4, uv[index].y))
		trace.surface_add_vertex(vertices[index])

func _flash_level() -> float:
	if is_instance_valid(world) and is_instance_valid(world.get_parent()):
		var store: Variant = world.get_parent().get("settings")
		if store is SettingsStore: return clampf(float(store.values.flashes), 0.0, 1.0)
	return 0.45

func _low_quality() -> bool:
	if is_instance_valid(world) and is_instance_valid(world.get_parent()):
		var store: Variant = world.get_parent().get("settings")
		if store is SettingsStore: return str(store.values.graphics) == "Low"
	return false

func _filament_material(color: Color, taper: bool = true) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://presentation/shaders/ability_filament.gdshader")
	material.set_shader_parameter("effect_color", color)
	material.set_shader_parameter("brightness", lerpf(0.75, 1.75, _flash_level()))
	material.set_shader_parameter("taper", taper)
	return material

func _contour_mesh(color: Color, half_size: Vector2, shape: int, warning: bool) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	var extent: Vector2 = half_size + Vector2.ONE * 0.075
	quad.size = extent * 2.0
	mesh.mesh = quad
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = preload("res://presentation/shaders/ability_contour.gdshader")
	material.set_shader_parameter("effect_color", color)
	material.set_shader_parameter("shape_size", half_size)
	material.set_shader_parameter("extent", extent)
	material.set_shader_parameter("shape", shape)
	material.set_shader_parameter("warning", warning)
	material.set_shader_parameter("line_width", 0.016 if warning else 0.008)
	material.set_shader_parameter("brightness", lerpf(0.72, 1.65, _flash_level()))
	mesh.material_override = material
	return mesh

func _present_object(item: Dictionary) -> void:
	# These uniforms and rotations are presentation-only. The sweep, object
	# radius, authoritative clock, and contacts continue to use the item above.
	ABILITY_ART.animate(item.visual, item)
	var duration: int = maxi(1, int(item.life) - int(item.options.get("delay", 0)))
	var age: float = clampf(float(int(item.age) - int(item.options.get("delay", 0))) / duration, 0.0, 1.0)
	var opacity: float = 1.0 - smoothstep(0.55, 1.0, age)
	if item.type == "ring" and bool(item.options.get("ground_wave", false)):
		# The stomp affects grounded feet. Its wave follows the surface instead
		# of drawing an upright hoop through the floor and building facade.
		item.visual.rotation.x = -PI * 0.5
		item.visual.position.y -= 0.125
	_set_energy_uniforms(item.visual, age, opacity, 1.0)

func _set_energy_uniforms(node: Node3D, age: float, opacity: float, intensity: float) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			var material: Material = child.get_active_material(0) if child.mesh != null and child.mesh.get_surface_count() > 0 else null
			if not material is ShaderMaterial: continue
			if material.shader not in [preload("res://presentation/shaders/ability_filament.gdshader"), preload("res://presentation/shaders/ability_contour.gdshader")]: continue
			child.set_instance_shader_parameter("age", age)
			child.set_instance_shader_parameter("opacity", opacity)
			child.set_instance_shader_parameter("intensity", intensity)
		elif child is Node3D:
			_set_energy_uniforms(child, age, opacity, intensity)

func _effect_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _zone_marker(item: Dictionary, color: Color) -> Node3D:
	var marker := Node3D.new()
	marker.name = "Warning"
	if item.type in ["spotlight", "geometry"]:
		var shape: int = 1 if item.type == "spotlight" else 2
		var half_size: Vector2 = Vector2.ONE * float(item.data.get("zone_radius", 1.8)) if item.type == "spotlight" else item.options.size * 0.5
		var contour: MeshInstance3D = _contour_mesh(color, half_size, shape, true)
		contour.position.z = 0.04
		_clip_to_support(contour, item)
		marker.add_child(contour)
		return marker
	var points: Array[Vector2] = []
	if item.type == "tree":
		var length_value: float = float(item.data.get("zone_length", 5.6))
		var radius: float = float(item.data.get("zone_width", 1.3)) * 0.5
		var angle: float = deg_to_rad(float(item.options.angle))
		for index: int in range(34):
			var theta: float = index * TAU / 33.0
			var point := Vector2(cos(theta) * radius + signf(cos(theta)) * (length_value * 0.5 - radius), sin(theta) * radius)
			points.append(point.rotated(angle))
	elif item.type == "spotlight":
		for index: int in range(41):
			points.append(Vector2.from_angle(index * TAU / 40.0) * float(item.data.get("zone_radius", 1.8)))
	else:
		var half_size: Vector2 = item.options.size * 0.5
		points.assign([Vector2(-half_size.x, -half_size.y), Vector2(half_size.x, -half_size.y), half_size, Vector2(-half_size.x, half_size.y), Vector2(-half_size.x, -half_size.y)])
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _filament_material(Color(color, 0.65), false))
	for index in range(points.size() - 1):
		_trace_strip(lines, Vector3(points[index].x, points[index].y, 0.06), Vector3(points[index + 1].x, points[index + 1].y, 0.06), 0.055, false)
	lines.surface_end()
	var mesh := MeshInstance3D.new()
	mesh.mesh = lines
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(mesh)
	return marker

func _present_zone(item: Dictionary, active: bool) -> void:
	var warning: Node3D = item.visual.get_node_or_null("Warning")
	if warning != null:
		warning.visible = true
		warning.scale = Vector3.ONE
		_set_energy_uniforms(warning, clampf(float(item.age) / maxi(1, item.move.startup), 0, 1), 0.65 if active else 1.0, 1.0)
	var impact: Node3D = item.visual.get_node_or_null("Impact")
	if active and impact == null:
		if item.type == "spotlight":
			impact = ABILITY_ART.solar_zone(float(item.data.get("zone_radius", 1.8)), item.owner.definition.palette, _flash_level(), _low_quality())
		else:
			impact = make_prop("tree_prop" if item.type == "tree" else "geometry_impact", item.owner.definition.palette, item.owner.definition.mechanic, item.move.ability)
		impact.name = "Impact"
		if item.type == "tree":
			impact.rotation.z = deg_to_rad(float(item.options.angle)) - PI / 2.0
			var direction := Vector2.from_angle(deg_to_rad(float(item.options.angle)))
			impact.position = Vector3(-direction.x, -direction.y, 0) * float(item.data.get("zone_length", 5.6)) * 0.5
		elif item.type == "geometry":
			impact.scale = Vector3(float(item.options.size.x) * 0.5, float(item.options.size.y) / 1.4, 1.0)
		else:
			var solar: MeshInstance3D = _contour_mesh(item.owner.definition.palette, Vector2.ONE * float(item.data.get("zone_radius", 1.8)), 1, false)
			_clip_to_support(solar, item)
			impact.add_child(solar)
		item.visual.add_child(impact)
	if impact != null:
		impact.visible = active
		if active and item.type != "tree":
			var pulse_age: float = 0.0
			for window: Vector2i in item.move.active_windows:
				if int(item.age) >= window.x and int(item.age) <= window.y:
					pulse_age = float(int(item.age) - window.x) / maxi(1, window.y - window.x)
			_set_energy_uniforms(impact, pulse_age, 1.0 - pulse_age * 0.45, 1.0)

func _clip_to_support(mesh: MeshInstance3D, item: Dictionary) -> void:
	# Clip only the solid platform's horizontal span. Airborne/offstage danger
	# remains visible; no arbitrary global-Y clipping hides recovery threats.
	if not item.owner.grounded or int(item.owner.support_id) != 0: return
	var support: Dictionary = _platform_by_id(int(item.owner.support_id))
	if support.is_empty(): return
	mesh.set_instance_shader_parameter("floor_limit", Vector3(float(support.y) + 0.012, float(support.x) - float(support.width) * 0.5, float(support.x) + float(support.width) * 0.5))
