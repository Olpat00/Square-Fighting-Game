class_name EffectsDirector
extends Node3D

var settings: SettingsStore
var world: MatchWorld
var particles: Array[Dictionary] = []
var impulse: float = 0.0
var rng := RandomNumberGenerator.new()
var spare_particles: Array[MeshInstance3D] = []
var mesh_cache: Dictionary = {}
const ENERGY_SHADER = preload("res://presentation/shaders/impact_energy.gdshader")
const SOFT_SHADER = preload("res://presentation/shaders/impact_soft.gdshader")
const SIGNATURE_SHADER = preload("res://presentation/shaders/signature_impact.gdshader")
var observed_flashes: float = -1.0

func configure(store: SettingsStore, match_world: MatchWorld) -> void:
	settings = store
	world = match_world
	# Fighter visuals can also run in isolated test worlds without a main scene.
	# Share the live settings resource only when a presentation director exists.
	world.set_meta("presentation_settings", settings)
	rng.seed = 8742

func on_event(event: String, actor: int, at: Vector3, details: Dictionary) -> void:
	var color := Color("ffd3a2")
	var facing: float = 0.0
	if actor >= 0 and actor < world.fighters.size():
		color = world.fighters[actor].definition.palette
		facing = world.fighters[actor].facing
	match event:
		"hit":
			var surface_point: Vector3 = _melee_surface_point(at, actor, details)
			# Light contact stays crisp; only committed strikes move the camera.
			impulse = maxf(impulse, 0.115 if details.get("heavy", false) else 0.022)
			if actor >= 0 and actor < world.fighters.size():
				_signature_impact(surface_point, world.fighters[actor], bool(details.get("heavy", false)))
			else:
				burst(surface_point, color, 10 if details.get("heavy", false) else 6, 4.0, false, "impact", facing, actor)
			if settings.values.blood: burst(surface_point, Color("8d2034"), 4, 2.5, true, "impact", facing, actor)
			if details.get("heavy", false):
				var broken_at := world.stage.break_nearby_decoration(at)
				if broken_at.is_finite(): burst(broken_at, Color("bc9970"), 8, 3.0, false, "debris")
		"parry":
			burst(at + Vector3(0, 1, 0), Color("eeffff"), 14, 5)
			impulse = maxf(impulse, 0.055)
		"shield": burst(at + Vector3(0, 1, 0), Color("80b9ed"), 4, 1.2, false, "guard")
		"launch":
			burst(at + Vector3(0, 0.8, 0), color, 6, 4.5, false, "launch", facing, actor)
			impulse = maxf(impulse, 0.07)
		"ko":
			var p := Vector3(clampf(at.x, -15, 15), clampf(at.y, -4, 12), 0)
			burst(p, color, 22, 8)
			impulse = 0.25
		"jump", "land", "recovery": burst(at, color, 5, 2, false, "dust")
		"citation", "encore": burst(at + Vector3(0, 1.5, 0), color, 6, 2)
		"hazard_fire": burst(at, Color("ff803a"), 16, 6)
		"shield_break": burst(at + Vector3(0, 1, 0), Color("b2d8ff"), 18, 5)
		"armor": burst(at + Vector3(0, 0.8, 0), Color("e0b78d"), 5, 2)
		"tool_break": burst(at, color, 9, 3.5, false, "debris", facing)

func _melee_surface_point(at: Vector3, actor_slot: int, details: Dictionary) -> Vector3:
	# A broad melee capsule can cover the belly while an imported person's fist
	# visibly touches the chest. Project only the rendered contact height toward
	# that real limb, inside the existing volume and the target's body. Explicit
	# authored contact points, projectile impacts and captured sequences keep the
	# exact resolver point; this never changes damage, range or contact collection.
	if actor_slot < 0 or actor_slot >= world.fighters.size(): return at
	var source: RiotFighter = world.fighters[actor_slot]
	var move: MoveDefinition = source.move
	if source.state != "attack" or move == null or not move.is_active(source.move_tick): return at
	if move.impact_offset.is_finite() or world.abilities.suppresses_melee(move): return at
	if move.ability in ["grab", "heavy_grab", "heavy_ultimate"]: return at
	var visual: FighterAttackPresentation = source.visual.attack_presentation
	if visual == null: return at
	var target_slot: int = int(details.get("target", -1))
	if target_slot < 0 or target_slot >= world.fighters.size(): return at
	var target: RiotFighter = world.fighters[target_slot]
	var limb: Vector3 = visual.contact_limb(move.id)
	var adjustment: float = clampf(limb.y - at.y, -move.hit_radius * 0.60, move.hit_radius * 0.60)
	var center := Vector2(source.position.x + move.hit_offset.x * source.facing, source.position.y + move.hit_offset.y)
	var radius: float = move.hit_radius * (1.0 + clampf(float(source.charge_ticks) / maxi(1, move.charge_max), 0.0, 1.0) * move.charge_reach_scale)
	var span: float = sqrt(maxf(0.0, radius * radius - pow(at.x - center.x, 2.0)))
	var projected_y: float = clampf(at.y + adjustment, center.y - span, center.y + span)
	return Vector3(at.x, clampf(projected_y, target.position.y + 0.15, target.position.y + 1.60), at.z)

func _flash_brightness() -> float:
	return lerpf(0.28, 1.65, clampf(float(settings.values.flashes), 0.0, 1.0))

func _particle_limit() -> int:
	return 64 if world.graphics_quality == "Low" else 144

func _take_particle(mesh: Mesh, at: Vector3) -> MeshInstance3D:
	var instance: MeshInstance3D
	if not spare_particles.is_empty():
		instance = spare_particles.pop_back()
	else:
		instance = MeshInstance3D.new()
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
	instance.mesh = mesh
	instance.position = at
	instance.scale = Vector3.ONE
	instance.rotation = Vector3.ZERO
	instance.set_instance_shader_parameter("age", 0.0)
	instance.visible = true
	return instance

func _signature_bundle(mechanic: String) -> Dictionary:
	var profile: Dictionary = FighterAttackPresentation.SIGNATURES.get(mechanic, FighterAttackPresentation.SIGNATURES.momentum)
	var color: Color = profile.color
	var accent: Color = profile.accent
	var signature: int = int(profile.index)
	var disk := QuadMesh.new()
	disk.size = Vector2(1.08, 1.08)
	disk.center_offset.z = 0.30
	var material := ShaderMaterial.new()
	material.shader = SIGNATURE_SHADER
	material.set_shader_parameter("effect_color", color)
	material.set_shader_parameter("accent_color", accent)
	material.set_shader_parameter("signature", signature)
	material.set_shader_parameter("brightness", _flash_brightness())
	disk.material = material
	var chip_material := StandardMaterial3D.new()
	chip_material.albedo_color = accent.darkened(0.18)
	chip_material.roughness = 0.56
	chip_material.metallic = 0.45
	var chip: PrimitiveMesh
	var smoke := Color("9aa5af").lerp(color, 0.18)
	match signature:
		1:
			var ember := PrismMesh.new()
			ember.size = Vector3(0.028, 0.055, 0.025)
			chip = ember
			chip_material.albedo_color = Color("d87728")
			chip_material.emission_enabled = true
			chip_material.emission = Color("ffbc60")
			chip_material.emission_energy_multiplier = _flash_brightness()
		2:
			var fleck := PrismMesh.new()
			fleck.size = Vector3(0.074, 0.048, 0.036)
			chip = fleck
			chip_material.albedo_color = Color("797d7d")
			chip_material.roughness = 0.71
			smoke = Color("afb4b5")
		3:
			var splinter := BoxMesh.new()
			splinter.size = Vector3(0.13, 0.018, 0.028)
			chip = splinter
			chip_material.albedo_color = Color("a6895d")
			chip_material.metallic = 0.0
			chip_material.roughness = 0.90
			smoke = Color("a7a590")
		4:
			var paper := BoxMesh.new()
			paper.size = Vector3(0.068, 0.003, 0.105)
			chip = paper
			chip_material.albedo_color = Color("ece4d5")
			chip_material.metallic = 0.0
			chip_material.roughness = 0.86
		5:
			var grit := PrismMesh.new()
			grit.size = Vector3(0.062, 0.064, 0.055)
			chip = grit
			chip_material.albedo_color = Color("9b8369")
			chip_material.roughness = 0.85
			chip_material.metallic = 0.02
			smoke = Color("aaa08f")
		6:
			var plate := PrismMesh.new()
			plate.size = Vector3(0.075, 0.022, 0.065)
			chip = plate
			chip_material.albedo_color = Color("b7c8d1")
			chip_material.metallic = 0.86
			chip_material.roughness = 0.28
		7:
			var facet := PrismMesh.new()
			facet.size = Vector3(0.030, 0.080, 0.025)
			chip = facet
			chip_material.albedo_color = Color("b9a573")
			chip_material.metallic = 0.72
			smoke = Color("514458")
		_:
			var shard := PrismMesh.new()
			shard.size = Vector3(0.032, 0.069, 0.029)
			chip = shard
			chip_material.albedo_color = Color("bad8e1")
	chip.material = chip_material
	return {"ring": disk, "spark": _quad(Vector2(0.20, 0.040), accent, false, 0), "smoke": _quad(Vector2(0.85, 0.65), smoke, true, 0), "chip": chip}

func _signature_impact(at: Vector3, fighter: RiotFighter, heavy: bool) -> void:
	var mechanic: String = fighter.definition.mechanic
	var key: String = "signature:" + mechanic
	if not mesh_cache.has(key): mesh_cache[key] = _signature_bundle(mechanic)
	var bundle: Dictionary = mesh_cache[key]
	var low: bool = world.graphics_quality == "Low"
	var count: int = (7 if heavy else 4) if low else (13 if heavy else 7)
	for index: int in count:
		if particles.size() >= _particle_limit(): break
		var physical: bool = mechanic in ["commitment", "fieldcraft", "trailblazer", "sentinel"]
		var shape: String = "ring" if index == 0 else "smoke" if heavy and index == 1 else "chip" if index % (2 if physical else 3) == 0 else "spark"
		var node := _take_particle(bundle[shape], at)
		var angle: float = rng.randf_range(-PI * 0.67, PI * 0.67)
		var direction := Vector3(cos(angle) * fighter.facing, sin(angle), rng.randf_range(-0.18, 0.18)).normalized()
		var velocity: Vector3 = direction * rng.randf_range(2.1, 6.4 if heavy else 4.4)
		var life: float = rng.randf_range(0.18, 0.34)
		var gravity: float = 3.0
		var scale_value: float = 1.20 if heavy else 0.64
		var stretch := Vector3.ONE
		if shape == "ring":
			velocity = Vector3.ZERO
			gravity = 0.0
			life = 0.26 if heavy else 0.20
			node.rotation = Vector3(-0.16, 0.44 * fighter.facing, rng.randf_range(-0.22, 0.22))
		elif shape == "smoke":
			velocity *= 0.18
			velocity.y = absf(velocity.y) + 0.18
			gravity = -0.10
			life = 0.52 if heavy else 0.40
			node.position.z -= 0.03
		elif shape == "chip":
			if physical: scale_value *= 0.65
			gravity = 6.0 if mechanic == "citations" else 11.0
			velocity *= 0.62
			velocity.y = absf(velocity.y) + 0.35
			node.position += direction * rng.randf_range(0.02, 0.10)
			life = rng.randf_range(0.30, 0.54)
			node.rotation = Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), angle)
		else:
			node.rotation.z = atan2(velocity.y, velocity.x)
			node.position += direction * rng.randf_range(0.03, 0.13)
			stretch = Vector3(rng.randf_range(0.45, 1.05), rng.randf_range(0.60, 1.0), 1.0)
		node.scale = stretch * scale_value
		particles.append({"node": node, "velocity": velocity, "life": life, "initial": life, "shape": shape, "gravity": gravity, "spin": rng.randf_range(-11, 11), "scale": scale_value, "stretch": stretch, "owner": fighter.slot})

func _quad(size_value: Vector2, color: Color, soft: bool, shape: int) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = size_value
	# Combat happens on Z=0; lift the flat visual just in front of the torso.
	# This is mesh-local, so pooled node origins remain the real impact position.
	mesh.center_offset.z = 0.34
	var material := ShaderMaterial.new()
	material.shader = SOFT_SHADER if soft else ENERGY_SHADER
	material.set_shader_parameter("effect_color", color)
	material.set_shader_parameter("shape", shape)
	if not soft:
		material.set_shader_parameter("brightness", _flash_brightness())
	mesh.material = material
	return mesh

func _mesh_bundle(color: Color, splash: bool, kind: String) -> Dictionary:
	# One immutable, shared bundle per color/settings family. No per-frame
	# material allocations: normalized lifetime uses an instance shader uniform.
	if kind == "debris":
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.76
		var splinter := BoxMesh.new()
		splinter.size = Vector3(0.26, 0.042, 0.055)
		splinter.material = material
		var chunk := PrismMesh.new()
		chunk.size = Vector3(0.16, 0.09, 0.12)
		chunk.material = material
		return {"splinter": splinter, "chunk": chunk}
	if splash:
		return {"drop": _quad(Vector2(0.19, 0.10), color, true, 1)}
	if kind == "guard":
		return {"ring": _quad(Vector2(0.80, 0.80), color, false, 1), "spark": _quad(Vector2(0.25, 0.06), color, false, 0)}
	if kind == "launch":
		return {"ring": _quad(Vector2(1.65, 0.95), color, false, 1), "spark": _quad(Vector2(0.82, 0.08), color, false, 0)}
	var smoke_color := Color("848f9a").lerp(color, 0.16)
	var bundle := {"smoke": _quad(Vector2(0.72, 0.52), smoke_color, true, 0)}
	if kind != "dust":
		bundle["spark"] = _quad(Vector2(0.50, 0.16), color, false, 0)
		bundle["ring"] = _quad(Vector2(1.35, 1.35), color, false, 1)
	return bundle

func burst(p: Vector3, color: Color, count: int, speed: float, splash: bool = false, kind: String = "impact", facing: float = 0.0, owner_slot: int = -1) -> void:
	var key := color.to_html() + str(splash) + kind
	if not mesh_cache.has(key): mesh_cache[key] = _mesh_bundle(color, splash, kind)
	var bundle: Dictionary = mesh_cache[key]
	var actual_count: int = maxi(2, int(ceil(count * 0.55))) if world.graphics_quality == "Low" else count
	for i in actual_count:
		if particles.size() >= _particle_limit(): break
		var shape: String = "spark"
		if kind == "debris": shape = "splinter" if i % 2 == 0 else "chunk"
		elif splash: shape = "drop"
		elif kind == "dust": shape = "smoke"
		elif i == 0: shape = "ring"
		elif i == 1 and kind not in ["guard", "launch"]: shape = "smoke"
		var instance := _take_particle(bundle[shape], p)
		var angle: float = TAU * float(i) / float(maxi(actual_count, 1)) + rng.randf_range(-0.22, 0.22)
		var direction := Vector3(cos(angle) + facing * 0.45, sin(angle) * 0.85 + 0.25, rng.randf_range(-0.04, 0.04)).normalized()
		var velocity: Vector3 = direction * speed * rng.randf_range(0.65, 1.12)
		var gravity: float = 2.0
		if shape == "ring":
			velocity = Vector3.ZERO
			gravity = 0.0
		elif shape == "smoke":
			velocity *= 0.24
			velocity.y = absf(velocity.y) + 0.3
			gravity = -0.15
		elif shape in ["drop", "splinter", "chunk"]:
			gravity = 8.0
		if kind == "debris":
			velocity.y = absf(velocity.y) + 0.8
			instance.rotation = Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), angle)
		elif shape != "ring": instance.rotation.z = atan2(velocity.y, velocity.x)
		particles.append({"node": instance, "velocity": velocity, "life": 0.45, "initial": 0.45,
			"shape": shape, "gravity": gravity, "spin": rng.randf_range(-9, 9), "scale": 1.0, "owner": owner_slot})

func update(delta: float) -> void:
	if not is_equal_approx(observed_flashes, float(settings.values.flashes)):
		observed_flashes = float(settings.values.flashes)
		for bundle: Dictionary in mesh_cache.values():
			for mesh: PrimitiveMesh in bundle.values():
				var material: Material = mesh.material
				if material is ShaderMaterial and material.shader in [ENERGY_SHADER, SIGNATURE_SHADER]:
					material.set_shader_parameter("brightness", _flash_brightness())
				elif material is StandardMaterial3D and material.emission_enabled:
					material.emission_energy_multiplier = _flash_brightness()
	# Settings still apply immediately while paused, but particle transforms and
	# the shake envelope must retain even a newly emitted burst's first frame.
	if delta <= 0.0: return
	impulse = move_toward(impulse, 0, delta * 0.7)
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		var owner_slot: int = int(p.get("owner", -1))
		if world.running and owner_slot >= 0 and owner_slot < world.fighters.size():
			var source: RiotFighter = world.fighters[owner_slot]
			if source.hitstop > 0 and source.state not in ["ko", "eliminated"]: continue
		p.life -= delta
		p.velocity.y -= delta * float(p.gravity)
		p.node.position += p.velocity * delta
		var age: float = clampf(1.0 - float(p.life) / float(p.initial), 0, 1)
		p.node.set_instance_shader_parameter("age", age)
		if p.shape in ["splinter", "chunk", "chip"]:
			p.node.rotation += Vector3(0.6, 1.0, 0.4) * float(p.spin) * delta
		elif p.shape == "smoke": p.node.rotation.z += delta * float(p.spin) * 0.12
		elif p.shape != "ring": p.node.rotation.z = atan2(p.velocity.y, p.velocity.x)
		var size_value: float = float(p.get("scale", 1.0))
		if p.shape == "smoke":
			p.node.scale = Vector3.ONE * size_value * lerpf(0.65, 1.65, age)
		elif p.shape == "ring":
			p.node.scale = Vector3.ONE * size_value
		elif p.shape in ["chip", "splinter", "chunk"]:
			p.node.scale = Vector3.ONE * size_value * (1.0 - smoothstep(0.72, 1.0, age))
		else:
			p.node.scale = Vector3(p.get("stretch", Vector3.ONE)) * size_value * maxf(0.01, 1.0 - age)
		if p.life <= 0:
			p.node.visible = false
			spare_particles.append(p.node)
			particles.remove_at(i)

func clear_effects() -> void:
	for particle in particles:
		particle.node.visible = false
		spare_particles.append(particle.node)
	particles.clear()
	impulse = 0
