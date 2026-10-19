class_name EmberStage
extends RooftopStage
## Editable 3D foreground over distant matte art; only four top planes collide.
## Every animation is driven by combat tick, so pause freezes the entire forge.

const SURFACE = preload("res://stages/ember_foundry/forge_surface.gdshader")
const MOLTEN = preload("res://stages/ember_foundry/molten_flow.gdshader")
const EMBERS = preload("res://stages/ember_foundry/forge_embers.gdshader")
const VENT = preload("res://stages/ember_foundry/forge_vent.gdshader")
const BACKDROP = preload("res://stages/arena_backdrop.gd")
const PLATFORM_GEOMETRY = preload("res://stages/platform_geometry.gd")
const PLATFORM_STEEL = preload("res://stages/ember_foundry/platform_steel.gdshader")
const CALDERA_SPILLWAY = preload("res://stages/ember_foundry/caldera_spillway.gdshader")
const CALDERA_SMOKE = preload("res://stages/ember_foundry/caldera_smoke.gdshader")

var palette: Dictionary = {}
var animated_materials: Array[ShaderMaterial] = []
var turbine_roots: Array[Node3D] = []
var optional_details: Array[Node3D] = []
var forge_backdrop: MeshInstance3D
var ember_batch: MultiMeshInstance3D
var chain_transforms: Array[Transform3D] = []
var rivet_transforms: Array[Transform3D] = []
var art_rng := RandomNumberGenerator.new()
var piston_rods: Array[MeshInstance3D] = []
var smoke_batch: MultiMeshInstance3D
var molten_bounce_lights: Array[OmniLight3D] = []

func _ready() -> void:
	platforms = [
		{"id": 0, "x": 0.0, "width": 18.4, "y": 0.0, "previous_y": 0.0, "thickness": 0.76},
		{"id": 1, "x": -5.6, "width": 3.6, "y": 2.9, "previous_y": 2.9},
		{"id": 2, "x": 5.6, "width": 3.6, "y": 2.9, "previous_y": 2.9},
		{"id": 3, "x": 0.0, "width": 3.2, "y": 6.4, "previous_y": 6.4,
			"base_y": 6.4, "amplitude": 0.9, "period_ticks": 174.0}]
	event_rng.seed = seed_value
	art_rng.seed = 726031
	_create_palette()
	_create_lighting()
	_create_caldera()
	_create_living_caldera()
	_create_bridge()
	_create_machinery()
	_create_vents()
	_create_embers()
	_finish_batches()
	_animate_scenery()

func _create_palette() -> void:
	palette.steel = _alloy(Color("40555a"), 0.78, 0.48)
	palette.dark = _alloy(Color("1b272b"), 0.69, 0.62)
	palette.bronze = _alloy(Color("a17846"), 0.76, 0.47)
	palette.copper = _alloy(Color("6d452e"), 0.63, 0.64)
	palette.edge = _alloy(Color("9aaba6"), 0.55, 0.46)
	palette.deck = _alloy(Color("344347"), 0.34, 0.73)
	palette.black = _alloy(Color("101719"), 0.28, 0.84)
	palette.tread = _platform_material(Color("42575b"), 0.68, 0.62, 1)
	palette.tread_alt = _platform_material(Color("394b50"), 0.70, 0.65, 1)
	palette.frame = _platform_material(Color("53666a"), 0.76, 0.48)
	palette.cast_iron = _platform_material(Color("243237"), 0.65, 0.68)
	palette.machined_bronze = _platform_material(Color("a58153"), 0.70, 0.50)
	palette.vent_panel = _platform_material(Color("344346"), 0.62, 0.76, 2)
	palette.caution = _platform_material(Color("b59a52"), 0.36, 0.73, 3)
	palette.amber = _emissive(Color("ef9d42"), 1.25)
	palette.molten = _emissive(Color("f56e22"), 1.7)
	palette.teal = _emissive(Color("70c0c1"), 0.95)
	var lava := ShaderMaterial.new()
	lava.shader = MOLTEN
	palette.lava = lava
	animated_materials.append(lava)

func _platform_material(color: Color, metallic: float, roughness: float, pattern: int = 0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = PLATFORM_STEEL
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("metallic_value", metallic)
	material.set_shader_parameter("roughness_value", roughness)
	material.set_shader_parameter("surface_pattern", pattern)
	return material

func _alloy(color: Color, metallic: float, roughness: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("metallic_value", metallic)
	material.set_shader_parameter("roughness_value", roughness)
	return material

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.25
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _create_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "CalderaAtmosphere"
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("121c24")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("708c9a")
	environment.ambient_light_energy = 0.45
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_agx_contrast = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.36
	environment.glow_hdr_threshold = 1.6
	environment.fog_enabled = true
	environment.fog_light_color = Color("273339")
	environment.fog_light_energy = 0.5
	environment.fog_density = 0.0036
	environment.fog_sky_affect = 0.0
	world.environment = environment
	add_child(world)
	var skylight := DirectionalLight3D.new()
	skylight.name = "CalderaSkylight"
	skylight.rotation_degrees = Vector3(-38, -24, 0)
	skylight.light_color = Color("a9c3cd")
	skylight.light_energy = 1.9
	skylight.shadow_enabled = true
	skylight.shadow_blur = 1.8
	skylight.shadow_normal_bias = 0.35
	skylight.directional_shadow_max_distance = 56.0
	add_child(skylight)
	var furnace_rim := DirectionalLight3D.new()
	furnace_rim.name = "FurnaceRim"
	furnace_rim.rotation_degrees = Vector3(-14, 145, 0)
	furnace_rim.light_color = Color("ffb073")
	furnace_rim.light_energy = 0.65
	add_child(furnace_rim)
	var fighter_fill := DirectionalLight3D.new()
	fighter_fill.name = "CoolFighterFill"
	fighter_fill.rotation_degrees = Vector3(-22, 5, 0)
	fighter_fill.light_color = Color("c0e2e3")
	fighter_fill.light_energy = 1.2
	fighter_fill.light_cull_mask = 2
	add_child(fighter_fill)
	for x: float in [-11.5, 11.5]:
		var molten_light := OmniLight3D.new()
		molten_light.name = "MoltenBounce"
		molten_light.position = Vector3(x, -4, -7)
		molten_light.light_color = Color("ff8042")
		molten_light.light_energy = 2.1
		molten_light.omni_range = 12
		molten_light.light_specular = 0.4
		add_child(molten_light)
		molten_bounce_lights.append(molten_light)

func _create_caldera() -> void:
	# Architectural scale and caldera depth come from the curated distant art.
	# Opaque geometry must not cover its open, smoky central fighter backdrop.
	forge_backdrop = BACKDROP.new()
	forge_backdrop.configure(preload("res://assets/arenas/ember_foundry/backdrop.png"), 0.80)
	forge_backdrop.configure_living("foundry")
	add_child(forge_backdrop)
	# Local motion on the distant falls/river is complemented by dimensional
	# spillways and rising soot. The art's architecture remains rigid.

func _create_living_caldera() -> void:
	# Slender spillways sit beyond the fighting deck, next to the wheel machinery.
	# They have a real lip, moving molten ribbons and a collecting bowl, rather
	# than adding an opaque sheet across the center of the cavern.
	for side: float in [-1.0, 1.0]:
		var source := Vector3(side * 9.96, 3.05, -18.1)
		var finish := Vector3(side * 10.10, -3.95, -17.65)
		var material := ShaderMaterial.new()
		material.shader = CALDERA_SPILLWAY
		material.set_shader_parameter("flow_speed", 0.62 if side < 0 else 0.48)
		material.set_shader_parameter("phase", 0.0 if side < 0 else 5.7)
		animated_materials.append(material)
		var stream := _mesh(_molten_ribbon(source, finish, 0.48 if side < 0 else 0.39), Vector3.ZERO, material)
		stream.name = "LeftMoltenSpillway" if side < 0 else "RightMoltenSpillway"
		stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Short bronze outlet and support set the scale without framing fighters.
		_slab(0.87, 0.10, 0.94, 0.06, source + Vector3(0, -0.04, -0.48), palette.copper)
		for flank: float in [-1.0, 1.0]:
			_slab(0.10, 0.20, 0.93, 0.03, source + Vector3(flank * 0.36, 0.11, -0.48), palette.dark)
		_rod(source + Vector3(0, -0.04, -0.63), source + Vector3(side * 0.66, -0.81, -0.63), 0.075, palette.dark)
		var pool_material: ShaderMaterial = material.duplicate()
		pool_material.set_shader_parameter("pool", true)
		pool_material.set_shader_parameter("flow_speed", 0.17)
		animated_materials.append(pool_material)
		var feed_mesh := QuadMesh.new()
		feed_mesh.size = Vector2(0.59, 0.90)
		var feed := _mesh(feed_mesh, source + Vector3(0, 0.016, -0.45), pool_material)
		feed.name = "MoltenOutletChannel"
		feed.rotation.x = -PI * 0.5
		feed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var pool_mesh := QuadMesh.new()
		pool_mesh.size = Vector2(0.88, 1.05)
		var pool := _mesh(pool_mesh, finish + Vector3(0, 0.045, 0), pool_material)
		pool.name = "SpillwayMoltenCatch"
		pool.rotation.x = -PI * 0.5
		pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_slab(1.12, 0.18, 1.30, 0.15, finish + Vector3(0, -0.06, 0), palette.dark)
	_create_smoke()

func _molten_ribbon(from: Vector3, to: Vector3, width: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections: int = 18
	for i in sections:
		for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
			var along: float = float(i + corner.y) / sections
			var center: Vector3 = from.lerp(to, along)
			var lip_width: float = width * (1.0 + sin(along * 8.0) * 0.06 + along * 0.16)
			center.x += (corner.x - 0.5) * lip_width
			center.z += sin(along * PI) * 0.08
			surface.set_normal(Vector3.BACK)
			surface.set_uv(Vector2(corner.x, along))
			surface.add_vertex(center)
	return surface.commit()

func _create_smoke() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.7, 1.8)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = mesh
	batch.instance_count = 18
	# The first six are spread across all three sources, so Low retains smoke
	# at both spillways and at the distant central furnace.
	for i in batch.instance_count:
		var source_index: int = i % 3
		var at: Vector3 = [Vector3(-10.10, -3.6, -17.4), Vector3(10.10, -3.6, -17.4), Vector3(0.9, -4.1, -30.0)][source_index]
		var phase: float = floorf(float(i) / 3.0) / 6.0 + source_index * 0.13
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
		batch.set_instance_custom_data(i, Color(fmod(phase, 1.0), 0.30 + source_index * 0.17, 0.16 if source_index == 2 else 0.24, 1.0))
	smoke_batch = MultiMeshInstance3D.new()
	smoke_batch.name = "DriftingCalderaSmoke"
	smoke_batch.multimesh = batch
	smoke_batch.custom_aabb = AABB(Vector3(-16, -6, -33), Vector3(32, 14, 20))
	smoke_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = CALDERA_SMOKE
	smoke_batch.material_override = material
	animated_materials.append(material)
	add_child(smoke_batch)

func frame_horizon(camera: Camera3D) -> void:
	if forge_backdrop: forge_backdrop.frame(camera)

func _create_bridge() -> void:
	# The authored collision remains at y = 0. Individual inset tread panels,
	# machined rims and recessed service cassettes replace the single smooth slab.
	_slab(18.4, 0.67, 3.10, 0.18, Vector3(0, -0.405, -0.3), palette.cast_iron)
	_slab(18.12, 0.10, 2.86, 0.12, Vector3(0, -0.105, -0.3), palette.black)
	var tread_a: Array[Transform3D] = []
	var tread_b: Array[Transform3D] = []
	var ribs: Array[Transform3D] = []
	var vents: Array[Transform3D] = []
	var lower_beams: Array[Transform3D] = []
	var fascia_screws: Array[Transform3D] = []
	for row in 2:
		for i in 16:
			var x: float = -8.10 + i * 1.08
			var at := Vector3(x, -0.044, -0.97 + row * 1.34)
			if (row + i) % 2 == 0: tread_a.append(Transform3D(Basis.IDENTITY, at))
			else: tread_b.append(Transform3D(Basis.IDENTITY, at))
	_plate_batch("InterlockingTreadA", Vector3(1.05, 0.088, 1.30), tread_a, palette.tread)
	_plate_batch("InterlockingTreadB", Vector3(1.05, 0.088, 1.30), tread_b, palette.tread_alt)
	for z: float in [-1.765, 1.165]:
		_slab(17.70, 0.12, 0.17, 0.055, Vector3(0, -0.061, z), palette.frame)
		_slab(17.72, 0.10, 0.14, 0.035, Vector3(0, -0.668, z), palette.machined_bronze)
	for x: float in [-8.93, 8.93]:
		_slab(0.54, 0.22, 3.08, 0.12, Vector3(x, -0.112, -0.3), palette.machined_bronze)
		_slab(0.18, 0.055, 2.36, 0.045, Vector3(x, -0.029, -0.3), palette.caution)
		_slab(0.48, 0.56, 0.20, 0.07, Vector3(x, -0.407, 1.20), palette.machined_bronze)
		for z: float in [-1.56, 0.97]: _rivet(Vector3(x, -0.004, z), 0.058)
	for i in 16:
		var x: float = -8.10 + i * 1.08
		vents.append(Transform3D(Basis.IDENTITY, Vector3(x, -0.386, 1.259)))
		for y: float in [-0.232, -0.534]:
			for side: float in [-1.0, 1.0]:
				fascia_screws.append(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x + side * 0.42, y, 1.286)))
		if i % 4 == 1:
			_slab(0.30, 0.063, 0.018, 0.014, Vector3(x, -0.62, 1.256), palette.teal)
	for i in 17:
		var x: float = -8.64 + i * 1.08
		ribs.append(Transform3D(Basis.IDENTITY, Vector3(x, -0.382, 1.277)))
		lower_beams.append(Transform3D(Basis.IDENTITY, Vector3(x, -0.69, -0.3)))
	_plate_batch("BridgeFasciaRibs", Vector3(0.10, 0.49, 0.14), ribs, palette.frame)
	_plate_batch("RecessedCoolingCassettes", Vector3(0.95, 0.34, 0.025), vents, palette.vent_panel)
	_plate_batch("BridgeCrossMembers", Vector3(0.15, 0.18, 2.98), lower_beams, palette.cast_iron)
	_fastener_batch("BridgeServiceBolts", fascia_screws, 0.039, palette.machined_bronze)
	for x: float in [-7.82, 7.82]:
		_slab(0.75, 0.14, 0.035, 0.04, Vector3(x, -0.386, 1.291), palette.caution)
	# The hanging deck is carried by scalloped trusses, diagonals and suspension
	# eyes. These occupy the underside; no bars cross the fighter silhouette.
	for z: float in [-1.6, 1.05]:
		for i in 8:
			var x: float = -8.2 + i * 2.34
			var next_x: float = minf(9.0, x + 2.34)
			var lower_y: float = -1.25 - (1.0 - absf(x) / 9.2) * 0.62
			_rod(Vector3(x, -0.66, z), Vector3((x + next_x) * 0.5, lower_y, z), 0.105, palette.bronze)
			_rod(Vector3(next_x, -0.66, z), Vector3((x + next_x) * 0.5, lower_y, z), 0.105, palette.dark)
			_rod(Vector3(x, lower_y, z), Vector3(next_x, lower_y, z), 0.10, palette.dark)
	for side: float in [-1.0, 1.0]:
		var x: float = side * 8.55
		_ring(0.33, 0.115, Vector3(x, -0.91, 0.50), palette.bronze)
		_chain(Vector3(x, -1.15, 0.50), Vector3(side * 15.8, -4.0, -4.5), 30)
		var platform := _forge_platform(3.6, Vector3(side * 5.6, 2.9, 0), "CantileverDais")
		for offset: float in [-1.2, 1.2]:
			_rod(Vector3(offset, -0.40, -0.65), Vector3(offset * 0.4, -1.05, -0.65), 0.055, palette.dark, platform)
		# Chains recede behind the platforms and attach to outlying columns.
		_chain(Vector3(side * 6.95, 2.73, -0.8), Vector3(side * 12.0, 8.4, -5), 27)
	center_visual = _forge_platform(3.2, Vector3(0, 6.4, 0), "HydraulicCrown")
	for x: float in [-1.08, 1.08]:
		_cylinder(0.19, 0.5, Vector3(x, -0.62, -0.68), palette.bronze, center_visual)
		var rod := _cylinder(0.10, 3.0, Vector3(x, 4.4, -0.68), palette.edge)
		piston_rods.append(rod)
		_cylinder(0.24, 1.65, Vector3(x, 2.82, -0.68), palette.dark)
		_cylinder(0.27, 0.12, Vector3(x, 3.68, -0.68), palette.bronze)
		_cylinder(0.31, 0.16, Vector3(x, 1.95, -0.68), palette.bronze)
	# Copper pressure lines terminate below the fight; the machinery is scenery.
	for x: float in [-0.55, 0.55]:
		_rod(Vector3(x, -0.9, -1.9), Vector3(x, 2.7, -1.9), 0.095, palette.copper)
		_rod(Vector3(x, 2.7, -1.9), Vector3(signf(x) * 1.05, 2.7, -0.8), 0.095, palette.copper)
	_label("EMBER  /  07", Vector3(0, -0.27, 1.3), 0.0018, 36, Color("aebbb4"))

func _forge_platform(width: float, at: Vector3, title: String) -> Node3D:
	var root := Node3D.new()
	root.name = title
	root.position = at
	add_child(root)
	# Layered cast frame, replaceable tread panels and an underslung lift housing.
	# All top-facing caps stay at or below local y = 0; no visual rail blocks combat.
	_slab(width, 0.23, 1.84, 0.18, Vector3(0, -0.175, 0), palette.machined_bronze, root)
	_slab(width - 0.20, 0.15, 1.62, 0.12, Vector3(0, -0.115, 0), palette.black, root)
	_slab(width - 0.40, 0.26, 1.41, 0.16, Vector3(0, -0.40, 0), palette.cast_iron, root)
	_slab(width - 0.83, 0.09, 1.20, 0.12, Vector3(0, -0.575, 0), palette.frame, root)
	var panels: Array[Transform3D] = []
	var brackets: Array[Transform3D] = []
	var vents: Array[Transform3D] = []
	var bolts: Array[Transform3D] = []
	var pitch: float = (width - 0.37) / 4.0
	for i in 4:
		var x: float = (i - 1.5) * pitch
		panels.append(Transform3D(Basis.IDENTITY, Vector3(x, -0.045, 0)))
		vents.append(Transform3D(Basis.IDENTITY, Vector3(x, -0.407, 0.716)))
		for z: float in [-0.59, 0.59]:
			bolts.append(Transform3D(Basis.IDENTITY, Vector3(x, -0.012, z)))
	for i in 5:
		var x: float = (i - 2.0) * pitch
		brackets.append(Transform3D(Basis.IDENTITY, Vector3(x, -0.408, 0.765)))
	_plate_batch("ReplaceableLiftTreads", Vector3(pitch - 0.035, 0.09, 1.43), panels, palette.tread, root)
	_plate_batch("LiftCoolingSlots", Vector3(pitch - 0.11, 0.20, 0.025), vents, palette.vent_panel, root)
	_plate_batch("LiftFrameRibs", Vector3(0.075, 0.25, 0.15), brackets, palette.frame, root)
	_fastener_batch("LiftTreadFasteners", bolts, 0.040, palette.machined_bronze, root)
	for z: float in [-0.825, 0.825]:
		_slab(width - 0.18, 0.09, 0.14, 0.04, Vector3(0, -0.055, z), palette.frame, root)
	for side: float in [-1.0, 1.0]:
		_slab(0.19, 0.12, 1.56, 0.075, Vector3(side * (width * 0.5 - 0.10), -0.061, 0), palette.machined_bronze, root)
		_slab(0.46, 0.12, 0.025, 0.035, Vector3(side * width * 0.32, -0.186, 0.927), palette.caution, root)
		_slab(0.105, 0.062, 0.025, 0.018, Vector3(side * width * 0.39, -0.514, 0.727), palette.teal, root)
	return root

func _plate_batch(title: String, size: Vector3, transforms: Array[Transform3D], material: Material, parent: Node3D = null) -> MultiMeshInstance3D:
	var edge: float = minf(0.035, size.y * 0.27)
	var corner: float = minf(0.075, minf(size.x, size.z) * 0.20)
	return _multimesh(title, PLATFORM_GEOMETRY.beveled_box(size, edge, corner), transforms, material, parent)

func _fastener_batch(title: String, transforms: Array[Transform3D], radius: float, material: Material, parent: Node3D = null) -> MultiMeshInstance3D:
	var bolt := CylinderMesh.new()
	bolt.radial_segments = 6
	bolt.height = radius * 0.46
	bolt.top_radius = radius
	bolt.bottom_radius = radius
	var batch := _multimesh(title, bolt, transforms, material, parent)
	optional_details.append(batch)
	return batch

func _create_machinery() -> void:
	# Two sculptural counter-rotating flywheels establish scale and a wholly
	# different visual identity from the terrace and moon observatory.
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * 8.6, -0.6, -16.0)
		var turbine := Node3D.new()
		turbine.name = "BronzeFlywheel"
		turbine.position = at
		turbine.scale = Vector3.ONE * 0.19
		add_child(turbine)
		turbine_roots.append(turbine)
		optional_details.append(turbine)
		_ring(5.5, 0.38, Vector3.ZERO, palette.dark, turbine)
		_ring(4.82, 0.22, Vector3(0, 0, 0.10), palette.bronze, turbine)
		_ring(4.44, 0.11, Vector3(0, 0, 0.12), palette.copper, turbine)
		_ring(1.16, 0.19, Vector3(0, 0, 0.25), palette.bronze, turbine)
		var hub := _cylinder(0.76, 0.86, Vector3(0, 0, 0.15), palette.dark, turbine)
		hub.rotation.x = PI * 0.5
		for i in 12:
			var angle: float = TAU * i / 12.0
			var start := Vector3(cos(angle), sin(angle), 0.03) * 1.1
			var end := Vector3(cos(angle + 0.32), sin(angle + 0.32), 0.0) * 4.5
			var spoke := _rod(start, end, 0.21, palette.dark, turbine)
			spoke.scale.z = 0.56
			_rod(start + Vector3(0, 0, 0.13), end + Vector3(0, 0, 0.13), 0.055, palette.bronze, turbine)
		var teeth: Array[Transform3D] = []
		var tooth := BoxMesh.new()
		tooth.size = Vector3(0.39, 0.72, 0.70)
		for i in 48:
			var angle: float = TAU * i / 48.0
			teeth.append(Transform3D(Basis(Vector3.FORWARD, -angle), Vector3(sin(angle), cos(angle), 0) * 5.6))
		_multimesh("CastGearTeeth", tooth, teeth, palette.bronze, turbine)
		# Bearing pillars and overhead ducts visually connect the wheel assembly.
		_slab(0.7, 0.35, 0.9, 0.10, Vector3(side * 8.6, -2.4, -16.0), palette.dark)
		_rod(Vector3(side * 8.6, -2.3, -16.4), Vector3(side * 8.6, -0.6, -16.4), 0.10, palette.dark)
		_crucible(Vector3(side * 9.75, -3.80, -12), 0.64)
		_chain(Vector3(side * 9.75 - 0.54, -2.90, -12), Vector3(side * 9.75 - 0.54, 1.8, -12), 24)
		_chain(Vector3(side * 9.75 + 0.54, -2.90, -12), Vector3(side * 9.75 + 0.54, 1.8, -12), 24)

func _crucible(at: Vector3, radius: float) -> void:
	# Small squat vessel with open mouth, rolled bands and reinforcing staves.
	var vessel := Node3D.new()
	vessel.name = "BandedCrucible"
	vessel.position = at
	vessel.scale = Vector3(0.85, 0.48, 0.85)
	add_child(vessel)
	optional_details.append(vessel)
	var profile: Array[Vector2] = [Vector2(radius * 0.53, 0.0), Vector2(radius * 0.72, 0.22), Vector2(radius, 2.1), Vector2(radius * 1.06, 2.28), Vector2(radius * 1.06, 2.46), Vector2(radius * 0.84, 2.46), Vector2(radius * 0.84, 2.08)]
	_mesh(_lathe(profile, 40), Vector3.ZERO, palette.copper, vessel)
	var pool := _cylinder(radius * 0.83, 0.015, Vector3(0, 2.12, 0), palette.lava, vessel)
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for band: Vector2 in [Vector2(0.78, 0.52), Vector2(0.96, 1.81), Vector2(1.05, 2.37)]:
		var hoop := _ring(radius * band.x, 0.055, Vector3(0, band.y, 0), palette.bronze, vessel)
		hoop.rotation.x = 0
	for i in 12:
		var angle: float = TAU * i / 12.0
		var radial := Vector3(cos(angle), 0, sin(angle))
		_rod(radial * radius * 0.73 + Vector3(0, 0.26, 0), radial * radius * 1.02 + Vector3(0, 2.14, 0), 0.025, palette.dark, vessel)
	for offset: float in [-radius, radius]:
		var ear := _ring(0.20, 0.07, Vector3(offset, 1.87, 0), palette.bronze, vessel)
		ear.rotation.y = PI * 0.5

func _create_vents() -> void:
	for x: float in [-8.0, 8.0]:
		_cylinder(0.40, 0.05, Vector3(x, -0.02, 0), palette.bronze, null, 12)
		for i in 5:
			_box(Vector3(0.64, 0.014, 0.035), Vector3(x, 0.013, -0.25 + i * 0.125), palette.dark)
		var warning_material := ShaderMaterial.new()
		warning_material.shader = VENT
		warning_material.set_shader_parameter("warning", true)
		animated_materials.append(warning_material)
		var warning_quad := QuadMesh.new()
		warning_quad.size = Vector2(1.8, 1.5)
		var warning := _mesh(warning_quad, Vector3(x, 0.04, 0), warning_material)
		warning.rotation.x = -PI * 0.5
		warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		warning.visible = false
		hazard_warnings.append(warning)
		var flame_material := ShaderMaterial.new()
		flame_material.shader = VENT
		animated_materials.append(flame_material)
		var flame_quad := QuadMesh.new()
		flame_quad.size = Vector2(1.8, 2.15)
		var flame := _mesh(flame_quad, Vector3(x, 1.085, 0.06), flame_material)
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.visible = false
		hazard_flames.append(flame)

func _create_embers() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.045, 0.11)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = mesh
	batch.instance_count = 96
	for i in batch.instance_count:
		var at := Vector3(art_rng.randf_range(-24, 24), art_rng.randf_range(-9.0, -3.5), art_rng.randf_range(-19, -5))
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
		batch.set_instance_custom_data(i, Color(art_rng.randf(), art_rng.randf(), art_rng.randf(), 1))
	ember_batch = MultiMeshInstance3D.new()
	ember_batch.name = "RisingForgeSparks"
	ember_batch.multimesh = batch
	ember_batch.custom_aabb = AABB(Vector3(-28, -12, -24), Vector3(56, 25, 23))
	var material := ShaderMaterial.new()
	material.shader = EMBERS
	ember_batch.material_override = material
	ember_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	animated_materials.append(material)
	add_child(ember_batch)

func step() -> void:
	super.step()
	_animate_scenery()

func reset_cosmetics() -> void:
	super.reset_cosmetics()
	_animate_scenery()

func reset_match(seed_number: int) -> void:
	super.reset_match(seed_number)
	_animate_scenery()

func _animate_scenery() -> void:
	var seconds: float = tick / 60.0
	if forge_backdrop: forge_backdrop.set_scenery_time(seconds)
	for material: ShaderMaterial in animated_materials:
		material.set_shader_parameter("simulation_time", seconds)
	for i in turbine_roots.size():
		turbine_roots[i].rotation.z = seconds * (0.12 if i == 0 else -0.098)
	for i in molten_bounce_lights.size():
		molten_bounce_lights[i].light_energy = 2.1 * (1.0 + sin(seconds * 1.13 + i * 2.7) * 0.055 + sin(seconds * 2.31 + i) * 0.024)
	if platforms.size() > 3:
		var top: float = float(platforms[3].y) - 0.65
		for rod: MeshInstance3D in piston_rods:
			rod.position.y = (top + 3.48) * 0.5
			rod.scale.y = maxf(0.1, top - 3.48) / 3.0

func apply_quality(value: String) -> void:
	super.apply_quality(value)
	var low: bool = graphics_quality == "Low"
	# No reflective water is present. Scenery and shader work really reduce in
	# Low, while complete foreground silhouettes and every collision stay intact.
	if environment:
		environment.ssr_enabled = false
		environment.fog_density = 0.0036
	for node: Node3D in optional_details: node.visible = not low
	if ember_batch: ember_batch.multimesh.visible_instance_count = 24 if low else -1
	if smoke_batch: smoke_batch.multimesh.visible_instance_count = 6 if low else -1
	for material: ShaderMaterial in animated_materials:
		material.set_shader_parameter("low_quality", low)
	for material: Material in palette.values():
		if material is ShaderMaterial and material.shader == PLATFORM_STEEL:
			material.set_shader_parameter("low_quality", low)

func _mesh(mesh: Mesh, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	(parent if parent else self).add_child(node)
	return node

func _box(size: Vector3, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(mesh, at, material, parent)

func _cylinder(radius: float, height: float, at: Vector3, material: Material, parent: Node3D = null, sides: int = 24) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	return _mesh(mesh, at, material, parent)

func _rod(from: Vector3, to: Vector3, radius: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var delta := to - from
	var node := _cylinder(radius, delta.length(), (from + to) * 0.5, material, parent, 12)
	node.basis = Basis(Quaternion(Vector3.UP, delta.normalized()))
	return node

func _ring(radius: float, tube: float, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube
	mesh.outer_radius = radius + tube
	mesh.rings = 64 if radius > 2.0 else 24
	mesh.ring_segments = 12 if radius > 2.0 else 8
	var node := _mesh(mesh, at, material, parent)
	node.rotation.x = PI * 0.5
	return node

func _slab(width: float, height: float, depth: float, bevel: float, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var edge: float = minf(0.045, height * 0.25)
	return _mesh(PLATFORM_GEOMETRY.beveled_box(Vector3(width, height, depth), edge, bevel), at, material, parent)

func _lathe(profile: Array[Vector2], segments: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in profile.size() - 1:
		for i in segments:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var angle: float = TAU * (i + corner.x) / float(segments)
				var p: Vector2 = profile[j + corner.y]
				surface.set_uv(Vector2((i + corner.x) / float(segments), float(j + corner.y) / (profile.size() - 1)))
				surface.add_vertex(Vector3(cos(angle) * p.x, p.y, sin(angle) * p.x))
	surface.generate_normals()
	return surface.commit()

func _chain(from: Vector3, to: Vector3, count: int) -> void:
	var direction: Vector3 = (to - from).normalized()
	var base := Basis(Quaternion(Vector3.UP, direction))
	for i in count:
		var basis: Basis = base * Basis(Vector3.UP, PI * 0.5 if i % 2 == 1 else 0.0) * Basis(Vector3.RIGHT, PI * 0.5)
		chain_transforms.append(Transform3D(basis.scaled(Vector3(0.115, 0.18, 0.115)), from.lerp(to, i / float(count - 1))))

func _rivet(at: Vector3, radius: float, front: bool = false) -> void:
	var basis := Basis(Vector3.RIGHT, PI * 0.5) if front else Basis.IDENTITY
	rivet_transforms.append(Transform3D(basis.scaled(Vector3(radius, radius * 0.40, radius)), at))

func _finish_batches() -> void:
	var link := TorusMesh.new()
	link.inner_radius = 0.55
	link.outer_radius = 1.0
	link.rings = 12
	link.ring_segments = 6
	_multimesh("SuspensionLinks", link, chain_transforms, palette.dark)
	var bolt := CylinderMesh.new()
	bolt.radial_segments = 6
	bolt.height = 1
	bolt.top_radius = 1
	bolt.bottom_radius = 1
	var rivets := _multimesh("HexFasteners", bolt, rivet_transforms, palette.bronze)
	optional_details.append(rivets)

func _multimesh(title: String, mesh: Mesh, transforms: Array[Transform3D], material: Material, parent: Node3D = null) -> MultiMeshInstance3D:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for i in transforms.size(): batch.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = batch
	node.material_override = material
	(parent if parent else self).add_child(node)
	return node

func _label(text: String, at: Vector3, pixel_size: float, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.pixel_size = pixel_size
	label.font_size = font_size
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	add_child(label)
