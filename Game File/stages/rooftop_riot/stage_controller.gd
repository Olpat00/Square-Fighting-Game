class_name RooftopStage
extends Node3D

var preset: String = "Fair Fight"
var seed_value: int = 4261
var platforms: Array[Dictionary] = []
var center_visual: Node3D
var hazard_warnings: Array[MeshInstance3D] = []
var hazard_flames: Array[MeshInstance3D] = []
var tick: int = 0
var hazard_side: int = -1
var hazard_phase: int = 0
var hazard_cycle: int = 540
var event_rng := RandomNumberGenerator.new()
var reactive_materials: Array[Dictionary] = []
var reaction: float = 0.0
var scene_materials: Array[Material] = []
var sunset_material: ShaderMaterial
var horizon_backdrop: MeshInstance3D
var water_material: ShaderMaterial
var crowd: Array[Dictionary] = []
var breakable_signs: Array[Node3D] = []
var broken_signs: Dictionary = {}
var breakable_furniture: Array[Node3D] = []
var broken_furniture: Dictionary = {}
var graphics_quality: String = "High"
var quality_nodes: Array[Dictionary] = []
var quality_materials: Array[ShaderMaterial] = []
var environment: Environment
var rooftop_life: Node3D
var rooftop_clock_materials: Array[ShaderMaterial] = []

func _ready() -> void:
	platforms = [
		{"id": 0, "x": 0.0, "width": 18.0, "y": 0.0, "previous_y": 0.0},
		{"id": 1, "x": -5.0, "width": 4.5, "y": 3.6, "previous_y": 3.6},
		{"id": 2, "x": 5.0, "width": 4.5, "y": 3.6, "previous_y": 3.6},
		{"id": 3, "x": 0.0, "width": 3.5, "y": 5.5, "previous_y": 5.5}]
	event_rng.seed = seed_value
	_build_environment()
	_build_sunset()
	if ResourceLoader.exists("res://assets/stage/stage.glb"):
		var scenery: Node3D = load("res://assets/stage/stage.glb").instantiate()
		add_child(scenery)
		_prepare_scenery(scenery)
	else:
		blockout()
	rooftop_life = preload("res://stages/rooftop_riot/rooftop_life.gd").new()
	add_child(rooftop_life)
	_cache_rooftop_clocks()
	_animate_rooftop()
	center_visual = preload("res://stages/rooftop_riot/platform_finish.gd").build(self)
	center_visual.position.y = 5.5
	for x in [-7.1, 0.0, 7.1]:
		var sign := Node3D.new()
		sign.position = Vector3(x, 0.2, -2.2)
		add_child(sign)
		var plate := box(Vector3(0.6, 0.35, 0.05), Vector3.ZERO, Color("29434a"))
		plate.reparent(sign, false)
		var lettering := Label3D.new()
		lettering.text = "NO FIGHTING"
		lettering.font_size = 28
		lettering.pixel_size = 0.0017
		lettering.position.z = 0.04
		sign.add_child(lettering)
		breakable_signs.append(sign)
	# Two curated background chairs share the sign debris pool. They are visual
	# scenery only: their GLB has no collision and never adds a gameplay surface.
	for x in [-3.55, 3.55]:
		var chair_path: String = "res://assets/stage/party_chair.glb" if ResourceLoader.exists("res://assets/stage/party_chair.glb") else "res://assets/props/chair.glb"
		var chair: Node3D = load(chair_path).instantiate()
		chair.position = Vector3(x, 0.0, -1.2)
		chair.scale = Vector3.ONE
		chair.rotation_degrees.y = -35.0 if x < 0 else 35.0
		add_child(chair)
		breakable_furniture.append(chair)
	for x in [-8.0, 8.0]:
		var warning := MeshInstance3D.new()
		var warning_quad := QuadMesh.new()
		warning_quad.size = Vector2(1.8, 1.5)
		var warning_material := ShaderMaterial.new()
		warning_material.shader = preload("res://stages/rooftop_riot/pyro_warning.gdshader")
		warning_quad.material = warning_material
		warning.mesh = warning_quad
		warning.position = Vector3(x, 0.035, 0)
		warning.rotation.x = -PI * 0.5
		warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(warning)
		warning.visible = false
		hazard_warnings.append(warning)
		var flame := MeshInstance3D.new()
		var flame_quad := QuadMesh.new()
		flame_quad.size = Vector2(1.8, 2.15)
		var flame_material := ShaderMaterial.new()
		flame_material.shader = preload("res://stages/rooftop_riot/pyro_flame.gdshader")
		flame_material.set_shader_parameter("phase", x * 0.3)
		flame_quad.material = flame_material
		flame.mesh = flame_quad
		flame.position = Vector3(x, 1.085, 0.06)
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.visible = false
		add_child(flame)
		hazard_flames.append(flame)

func blockout() -> void:
	box(Vector3(18, 0.9, 3.3), Vector3(0, -0.45, -0.4), Color("243741"))
	box(Vector3(18, 0.05, 0.05), Vector3(0, -0.06, 1.25), Color("ffaa51"), 2)
	for x in [-5.0, 5.0]:
		box(Vector3(4.5, 0.20, 1.8), Vector3(x, 3.5, 0), Color("294650"))
	box(Vector3(24, 0.5, 9), Vector3(0, -1.0, -7), Color("172831"))
	box(Vector3(15, 0.06, 5), Vector3(-1, -0.72, -6.3), Color("087b89"), 0.4)

func box(size_value: Vector3, p: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	mesh.material = mat
	node.mesh = mesh
	node.position = p
	add_child(node)
	return node

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	environment = env
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	# A directional dusk sky supplies coherent PBR reflections. The perspective
	# city photograph is a distant visual plate, not an equirectangular light map.
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("17334e")
	sky_mat.sky_horizon_color = Color("dcad87")
	sky_mat.ground_bottom_color = Color("16252d")
	sky_mat.ground_horizon_color = Color("9b8166")
	sky_mat.sky_curve = 0.22
	sky_mat.sky_energy_multiplier = 1.15
	sky_mat.sun_angle_max = 3.0
	sky_mat.sun_curve = 0.06
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8ba7c6")
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_agx_contrast = 1.20
	env.glow_enabled = true
	env.glow_intensity = 0.48
	env.glow_hdr_threshold = 1.4
	env.ssao_enabled = RenderingServer.get_current_rendering_method() != "mobile"
	env.ssao_radius = 0.75
	env.ssao_intensity = 1.65
	env.ssao_power = 1.25
	env.ssao_light_affect = 0.2
	env.ssr_enabled = RenderingServer.get_current_rendering_method() != "mobile"
	env.ssr_max_steps = 48
	env.ssil_enabled = RenderingServer.get_current_rendering_method() != "mobile"
	env.ssil_intensity = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color("39495e")
	env.fog_density = 0.0012
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "SunKey"
	sun.rotation_degrees = Vector3(-24, 145, 0)
	sun.light_color = Color("ffd2a3")
	sun.light_energy = 2.45
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 48
	sun.shadow_normal_bias = 0.3
	sun.shadow_blur = 2.0
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-32, -28, 0)
	fill.light_color = Color("bfdaed")
	fill.light_energy = 1.40
	fill.light_cull_mask = 2
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-12, -135, 0)
	rim.light_color = Color("ffd0a0")
	rim.light_energy = 1.10
	rim.light_cull_mask = 2
	add_child(rim)
	for x: float in [-8.0, 8.0]:
		var practical := OmniLight3D.new()
		practical.position = Vector3(x, 1.2, -4.5)
		practical.light_color = Color("ffc986")
		practical.light_energy = 2.0
		practical.light_specular = 0.25
		practical.omni_range = 5.0
		add_child(practical)
	var pool_glow := OmniLight3D.new()
	pool_glow.position = Vector3(-1.7, 0.4, -5.8)
	pool_glow.light_color = Color("42aeb5")
	pool_glow.light_energy = 2.0
	pool_glow.light_specular = 0.25
	pool_glow.omni_range = 7
	add_child(pool_glow)
	for x: float in [5.6, 8.8]:
		var bar_light := OmniLight3D.new()
		bar_light.position = Vector3(x, 1.85, -8.3)
		bar_light.light_color = Color("ffc27d")
		bar_light.light_energy = 2.0
		bar_light.light_specular = 0.4
		bar_light.omni_range = 3.0
		add_child(bar_light)

func step() -> void:
	tick += 1
	if sunset_material: sunset_material.set_shader_parameter("blue_hour", minf(tick / 21600.0, 1.0) * 0.45)
	reaction = move_toward(reaction, 0.0, 0.025)
	_animate_rooftop()
	for entry in reactive_materials:
		entry.material.emission_energy_multiplier = float(entry.base) * (1.0 + reaction * 0.5)
	platforms[3].previous_y = platforms[3].y
	var rest_height: float = float(platforms[3].get("base_y", 5.5))
	var amplitude: float = float(platforms[3].get("amplitude", 0.8))
	var period: float = maxf(1.0, float(platforms[3].get("period_ticks", 150.0)))
	platforms[3].y = rest_height + sin(tick / period) * amplitude if preset == "Party" else rest_height
	center_visual.position.y = platforms[3].y
	hazard_phase = 0
	if preset == "Party":
		var phase := tick % hazard_cycle
		if phase == 1:
			hazard_side = -1 if event_rng.randi_range(0, 1) == 0 else 1
		if phase >= hazard_cycle - 96:
			hazard_phase = 1 if phase < hazard_cycle - 24 else 2
	for i in hazard_warnings.size():
		hazard_warnings[i].visible = hazard_phase > 0 and (i == 0) == (hazard_side == -1)
		hazard_flames[i].visible = hazard_warnings[i].visible and hazard_phase == 2

func reset_match(seed_number: int) -> void:
	event_rng.seed = seed_number
	tick = 0
	reaction = 0.0
	hazard_phase = 0
	hazard_side = -1
	reset_cosmetics()
	for warning: MeshInstance3D in hazard_warnings: warning.visible = false
	for flame: MeshInstance3D in hazard_flames: flame.visible = false
	var rest_height: float = float(platforms[3].get("base_y", 5.5))
	platforms[3].y = rest_height
	platforms[3].previous_y = rest_height
	center_visual.position.y = rest_height
	_animate_rooftop()

func main_bounds() -> Vector2:
	var deck := support(0)
	return Vector2(float(deck.x) - float(deck.width) * 0.5, float(deck.x) + float(deck.width) * 0.5)

func support(id: int) -> Dictionary:
	for p in platforms:
		if p.id == id:
			return p
	return {}

func solve_motion(previous: Vector3, desired: Vector3, vertical_speed: float, ignore_id: int, supported_id: int) -> Dictionary:
	# Authoritative feet point and swept top-plane crossings. Only the selected
	# one-way platform is ignored during drop-through. Main deck is solid.
	var result := desired
	var platform_id: int = -1
	var landed: bool = false
	if supported_id >= 0 and supported_id != ignore_id:
		var p := support(supported_id)
		if not p.is_empty() and absf(desired.x - float(p.x)) <= float(p.width) / 2.0 + 0.08 and vertical_speed <= 0:
			result.y = p.y
			platform_id = supported_id
			landed = true
	if not landed and vertical_speed <= 0:
		var best_height: float = -999.0
		for p in platforms:
			if p.id == ignore_id:
				continue
			var surface: float = float(p.y)
			if previous.y >= float(p.previous_y) - 0.05 and result.y <= surface and absf(result.x - float(p.x)) <= float(p.width) / 2.0 + 0.08 and surface > best_height:
				best_height = surface
				platform_id = p.id
				landed = true
		if landed:
			result.y = best_height
	# Solid deck side/underside, including swept fast specials.
	var deck := support(0)
	var edges := main_bounds()
	var floor_y: float = float(deck.y)
	var underside: float = floor_y - float(deck.get("thickness", 0.9))
	if result.y < floor_y - 0.06 and result.y + CombatTuning.HURT_HEIGHT > underside:
		if previous.x <= edges.x - 0.25 and result.x > edges.x - 0.25:
			result.x = edges.x - 0.25
		if previous.x >= edges.y + 0.25 and result.x < edges.y + 0.25:
			result.x = edges.y + 0.25
	if previous.y + CombatTuning.HURT_HEIGHT <= underside and result.y + CombatTuning.HURT_HEIGHT > underside and result.x > edges.x and result.x < edges.y:
		result.y = underside - CombatTuning.HURT_HEIGHT
	return {"position": Vector3(result.x, result.y, 0), "landed": landed, "platform": platform_id}

func hazard_contacts(fighters: Array) -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	if preset != "Party" or hazard_phase != 2:
		return contacts
	for fighter in fighters:
		if fighter.stocks > 0 and absf(fighter.position.x - hazard_side * 8.0) < 0.9 and fighter.position.y < 1.8 and fighter.position.y > -0.1:
			contacts.append({"target": fighter, "source": null, "instance": 10000000 + tick / hazard_cycle, "group": "vent", "damage": 7.0, "base": 9.0, "growth": 0.04, "angle": 80.0, "hitstun": 18, "hitstop": 3, "facing": -hazard_side, "kind": "hazard"})
	return contacts

func is_hazard_warning_at(x: float) -> bool:
	return preset == "Party" and hazard_phase > 0 and absf(x - hazard_side * 8.0) < 1.25

func react(strength: float) -> void:
	reaction = maxf(reaction, strength if preset == "Party" else strength * 0.35)

func reset_cosmetics() -> void:
	broken_signs.clear()
	for sign in breakable_signs: sign.visible = true
	broken_furniture.clear()
	for furniture in breakable_furniture: furniture.visible = true

func break_nearby_decoration(at: Vector3) -> Vector3:
	var sign_position := break_nearby_sign(at)
	if sign_position.is_finite(): return sign_position
	if preset != "Party" or absf(at.y) >= 2.5: return Vector3.INF
	for i in breakable_furniture.size():
		var furniture: Node3D = breakable_furniture[i]
		if not broken_furniture.has(i) and absf(furniture.position.x - at.x) < 1.1:
			broken_furniture[i] = true
			furniture.visible = false
			return furniture.global_position + Vector3(0, 0.4, 0)
	return Vector3.INF

func break_nearby_sign(at: Vector3) -> Vector3:
	if preset != "Party": return Vector3.INF
	for i in breakable_signs.size():
		var sign: Node3D = breakable_signs[i]
		if not broken_signs.has(i) and absf(sign.position.x - at.x) < 2.5 and absf(at.y) < 2.5:
			broken_signs[i] = true
			sign.visible = false
			return sign.global_position
	return Vector3.INF

func _build_sunset() -> void:
	horizon_backdrop = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(100, 56.25)
	sunset_material = ShaderMaterial.new()
	sunset_material.shader = preload("res://stages/rooftop_riot/sunset.gdshader")
	sunset_material.set_shader_parameter("city_plate", preload("res://assets/environment/dusk_city.png"))
	quad.material = sunset_material
	horizon_backdrop.mesh = quad
	horizon_backdrop.position = Vector3(0, -19, -100)
	horizon_backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(horizon_backdrop)
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://stages/rooftop_riot/pool_water.gdshader")

func frame_horizon(camera: Camera3D) -> void:
	if not horizon_backdrop: return
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / maxf(1, viewport_size.y)
	var height: float = camera.size if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 2.0 * tan(deg_to_rad(camera.fov * 0.5)) * 130.0
	var plate: Texture2D = sunset_material.get_shader_parameter("city_plate")
	var art_aspect: float = float(plate.get_width()) / float(plate.get_height())
	var cover: float = maxf(height, height * aspect / art_aspect)
	(horizon_backdrop.mesh as QuadMesh).size = Vector2(art_aspect, 1.0) * cover * 1.055
	horizon_backdrop.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(camera.h_offset, camera.v_offset, -130))
	sunset_material.set_shader_parameter("parallax_offset", Vector2(clampf(camera.global_position.x * 0.001, -0.018, 0.018), clampf((8.0 - camera.global_position.y) * 0.0006, -0.018, 0.018)))

func _cache_rooftop_clocks() -> void:
	rooftop_clock_materials.assign([sunset_material, water_material])
	for material: Material in scene_materials:
		if material is ShaderMaterial:
			for uniform: Dictionary in material.shader.get_shader_uniform_list():
				if uniform.name == "scenery_time" and not rooftop_clock_materials.has(material):
					rooftop_clock_materials.append(material)

func _animate_rooftop() -> void:
	var seconds: float = tick / 60.0
	if sunset_material: sunset_material.set_shader_parameter("blue_hour", minf(tick / 21600.0, 1.0) * 0.45)
	for material: ShaderMaterial in rooftop_clock_materials:
		if material: material.set_shader_parameter("scenery_time", seconds)
	if rooftop_life: rooftop_life.animate(seconds, graphics_quality == "Low")
	# The GLB batches all guests by material, not by person. Move those batches
	# coherently; rotating a material batch separates heads and limbs.
	for member: Dictionary in crowd:
		member.node.position.y = float(member.y) + sin(seconds * 1.4) * 0.008 + sin(tick * 0.2) * reaction * 0.045

func _prepare_scenery(node: Node) -> void:
	# Replace only the imported upper-platform group with editable crafted
	# geometry; hotel architecture, supplied sources and collision stay intact.
	if node is Node3D and str(node.name).begins_with("fixed_platforms__"):
		node.visible = false
	if node is Node3D and str(node.name).begins_with("Crowd"):
		crowd.append({"node": node, "y": node.position.y, "yaw": node.rotation.y})
	if node is MeshInstance3D:
		var mesh_node: MeshInstance3D = node
		for i in mesh_node.mesh.get_surface_count():
			var original: Material = mesh_node.mesh.surface_get_material(i)
			if original is StandardMaterial3D:
				if str(node.name).begins_with("Crowd"):
					var guest_mat: StandardMaterial3D = original.duplicate()
					guest_mat.albedo_color = guest_mat.albedo_color.darkened(0.25)
					guest_mat.roughness = 0.88
					guest_mat.metallic = 0.0
					mesh_node.set_surface_override_material(i, guest_mat)
					scene_materials.append(guest_mat)
				elif original.resource_name.begins_with("City"):
					var city_mat: StandardMaterial3D = original.duplicate()
					city_mat.disable_receive_shadows = true
					mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					mesh_node.set_surface_override_material(i, city_mat)
					scene_materials.append(city_mat)
				elif str(node.name).begins_with("ReactionGlow"):
					var mat: StandardMaterial3D = original.duplicate()
					mesh_node.set_surface_override_material(i, mat)
					reactive_materials.append({"material": mat, "base": mat.emission_energy_multiplier})
				elif "water" in original.resource_name.to_lower() or "turquoise" in original.resource_name.to_lower():
					mesh_node.set_surface_override_material(i, water_material)
				elif original.resource_name.begins_with("Hotel | occupied"):
					var windows := ShaderMaterial.new()
					windows.shader = preload("res://stages/rooftop_riot/hotel_windows.gdshader")
					mesh_node.set_surface_override_material(i, windows)
					scene_materials.append(windows)
				elif str(node.name).begins_with("signage") and original.resource_name.begins_with("Brass"):
					var lettering: StandardMaterial3D = original.duplicate()
					lettering.emission_enabled = true
					lettering.emission = Color("d5ad72")
					lettering.emission_energy_multiplier = 0.65
					mesh_node.set_surface_override_material(i, lettering)
					scene_materials.append(lettering)
				elif original.resource_name.begins_with("Foliage"):
					var foliage := ShaderMaterial.new()
					foliage.shader = preload("res://stages/rooftop_riot/terrace_foliage.gdshader")
					foliage.set_shader_parameter("leaf_color", original.albedo_color)
					mesh_node.set_surface_override_material(i, foliage)
					scene_materials.append(foliage)
				elif original.resource_name.begins_with("Teak"):
					if str(node.name).begins_with("architecture__"):
						var deck_timber := ShaderMaterial.new()
						deck_timber.shader = preload("res://stages/rooftop_riot/platform_timber.gdshader")
						deck_timber.set_shader_parameter("timber_color", Color("805633"))
						mesh_node.set_surface_override_material(i, deck_timber)
						scene_materials.append(deck_timber)
						continue
					var timber: StandardMaterial3D = original.duplicate()
					timber.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					timber.clearcoat_enabled = true
					timber.clearcoat = 0.32
					timber.clearcoat_roughness = 0.23
					mesh_node.set_surface_override_material(i, timber)
					scene_materials.append(timber)
	for child in node.get_children(): _prepare_scenery(child)

func apply_quality(value: String) -> void:
	graphics_quality = "Low" if value == "Low" else "High"
	if quality_nodes.is_empty(): _capture_quality(self)
	var low: bool = graphics_quality == "Low"
	var advanced: bool = RenderingServer.get_current_rendering_method() == "forward_plus"
	if environment:
		environment.ssao_enabled = advanced and not low
		environment.ssil_enabled = advanced and not low
		environment.ssr_enabled = advanced and not low
		environment.glow_enabled = not low
	for entry: Dictionary in quality_nodes:
		var node: Node3D = entry.node
		if entry.has("optional"): node.visible = bool(entry.visible) and not low
		if entry.has("shadow"):
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if low else entry.shadow
		if node is DirectionalLight3D and entry.has("distance"):
			node.directional_shadow_max_distance = minf(float(entry.distance), 32.0) if low else entry.distance
			node.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if low else entry.mode
		if node is MultiMeshInstance3D and entry.has("instances"):
			node.multimesh.visible_instance_count = int(entry.instances) / 4 if low else -1
	for material: ShaderMaterial in quality_materials: material.set_shader_parameter("low_quality", low)
	_animate_rooftop()

func _capture_quality(node: Node) -> void:
	var entry: Dictionary = {"node": node}
	var node_name: String = str(node.name)
	if node is OmniLight3D or node_name.begins_with("Crowd") or node_name.begins_with("furniture__") or node_name.begins_with("WaterDetail") or node_name == "HexFasteners":
		entry["optional"] = true
		entry["visible"] = node.visible
	if node is GeometryInstance3D:
		# Platforms and actors retain sun shadows; incidental scenery does not.
		if node_name.begins_with("Crowd") or node_name.begins_with("planting") or node_name.begins_with("furniture__") or node.global_position.z < -3.0 or node is MultiMeshInstance3D:
			entry["shadow"] = node.cast_shadow
		if node is MeshInstance3D:
			for surface: int in node.mesh.get_surface_count(): _capture_material(node.get_active_material(surface))
		elif node is MultiMeshInstance3D:
			_capture_material(node.material_override)
			if node_name.begins_with("ImpactEjecta"): entry["instances"] = node.multimesh.instance_count
	if node is DirectionalLight3D and node.shadow_enabled:
		entry["distance"] = node.directional_shadow_max_distance
		entry["mode"] = node.directional_shadow_mode
	if entry.size() > 1: quality_nodes.append(entry)
	for child: Node in node.get_children(): _capture_quality(child)

func _capture_material(material: Material) -> void:
	if not material is ShaderMaterial or quality_materials.has(material): return
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		if uniform.name == "low_quality":
			quality_materials.append(material)
			return
