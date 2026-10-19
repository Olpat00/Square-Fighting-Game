class_name LunarStage
extends RooftopStage
## A lunar rim observatory. Only the four inherited top planes are collidable;
## the geology and all observatory machinery are visual scenery.

const REGOLITH_SHADER = preload("res://stages/lunar_reach/regolith.gdshader")
const METAL_SHADER = preload("res://stages/lunar_reach/aerospace_metal.gdshader")
const EARTH_SHADER = preload("res://stages/lunar_reach/earth.gdshader")
const VENT_SHADER = preload("res://stages/lunar_reach/vent_jet.gdshader")
const PLATFORM_GEOMETRY = preload("res://stages/platform_geometry.gd")

var earth: MeshInstance3D
var earth_material: ShaderMaterial
var crater_horizon: MeshInstance3D
var lunar_environment: Environment
var geology_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var grain_texture: NoiseTexture2D
var rock_material: ShaderMaterial
var materials: Dictionary = {}
var crater_centers: Array[Vector4] = []
var art_rng := RandomNumberGenerator.new()
var bolt_transforms: Array[Transform3D] = []
var warning_lights: Array[MeshInstance3D] = []
var terrain_node: MeshInstance3D
var terrain_high: ArrayMesh
var terrain_low: ArrayMesh
var dish_heads: Array[Node3D] = []
var solar_faces: Array[Node3D] = []
var beacon_materials: Array[StandardMaterial3D] = []
var survey_rover: Node3D
var rover_wheels: Array[MeshInstance3D] = []
var orbital_relay: Node3D
var extra_scenery: Array[Node3D] = []
var scenery_seconds: float = 0.0

func _ready() -> void:
	platforms = [
		{"id": 0, "x": 0.0, "width": 18.0, "y": 0.0, "previous_y": 0.0},
		{"id": 1, "x": -5.0, "width": 4.5, "y": 3.6, "previous_y": 3.6},
		{"id": 2, "x": 5.0, "width": 4.5, "y": 3.6, "previous_y": 3.6},
		{"id": 3, "x": 0.0, "width": 3.5, "y": 5.5, "previous_y": 5.5}]
	event_rng.seed = seed_value
	art_rng.seed = 20260929
	_create_materials()
	_create_lighting()
	_create_geology()
	_create_observatory()
	_create_outpost()
	_create_earth()
	_create_living_outpost()
	_create_vents()
	_finish_bolts()
	_animate_scene(0.0)

func _create_materials() -> void:
	var grain := FastNoiseLite.new()
	grain.seed = 82191
	grain.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	grain.frequency = 0.037
	grain.fractal_octaves = 6
	grain.fractal_gain = 0.58
	grain_texture = NoiseTexture2D.new()
	grain_texture.noise = grain
	grain_texture.width = 1024
	grain_texture.height = 1024
	grain_texture.seamless = true
	grain_texture.generate_mipmaps = true
	rock_material = ShaderMaterial.new()
	rock_material.shader = REGOLITH_SHADER
	rock_material.set_shader_parameter("grain_map", grain_texture)
	materials["titanium"] = _metal(Color("4c5762"), 0.68, 0.38)
	materials["dark"] = _metal(Color("202a31"), 0.82, 0.46)
	materials["white"] = _metal(Color("828c88"), 0.17, 0.66)
	materials["gold"] = _metal(Color("b69657"), 0.78, 0.47)
	materials["rubber"] = _metal(Color("151b21"), 0.05, 0.88)
	materials["orange"] = _metal(Color("d7883c"), 0.24, 0.5)
	materials["cyan"] = _glow(Color("b0e4f3"), 2.8)
	materials["amber"] = _glow(Color("f6b455"), 2.3)
	materials["red"] = _glow(Color("ed6344"), 1.7)
	materials["solar"] = _metal(Color("172538"), 0.72, 0.22)
	var deck_finish := ShaderMaterial.new()
	deck_finish.shader = preload("res://stages/lunar_reach/deck_panel.gdshader")
	deck_finish.set_shader_parameter("panel_color",Color("727f82"))
	materials["deck_panel"] = deck_finish

func _metal(color: Color, metal: float, rough: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = METAL_SHADER
	# Vector3 shader parameters bypass Color's automatic sRGB conversion. Match
	# StandardMaterial3D's palette handling instead of overexposing every alloy.
	var linear_color: Color = color.srgb_to_linear()
	mat.set_shader_parameter("base_color", Vector3(linear_color.r, linear_color.g, linear_color.b))
	mat.set_shader_parameter("metalness", metal)
	mat.set_shader_parameter("base_roughness", rough)
	mat.set_shader_parameter("grain_map", grain_texture)
	return mat

func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

func _create_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "LunarVacuum"
	lunar_environment = Environment.new()
	environment = lunar_environment
	lunar_environment.background_mode = Environment.BG_COLOR
	lunar_environment.background_color = Color("010205")
	lunar_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lunar_environment.ambient_light_color = Color("8099b9")
	lunar_environment.ambient_light_energy = 0.30
	lunar_environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	lunar_environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	lunar_environment.tonemap_agx_contrast = 1.10
	lunar_environment.glow_enabled = true
	lunar_environment.glow_intensity = 0.32
	lunar_environment.glow_hdr_threshold = 1.75
	var high_quality: bool = RenderingServer.get_current_rendering_method() == "gl_compatibility" or RenderingServer.get_current_rendering_method() == "mobile"
	lunar_environment.ssao_enabled = not high_quality
	lunar_environment.ssao_radius = 1.1
	lunar_environment.ssao_intensity = 1.6
	lunar_environment.ssao_power = 1.3
	lunar_environment.ssao_light_affect = 0.1
	lunar_environment.ssil_enabled = not high_quality
	lunar_environment.ssil_intensity = 0.35
	# No haze, moving clouds or atmospheric fog on the airless surface.
	lunar_environment.fog_enabled = false
	world.environment = lunar_environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "UnfilteredSolarKey"
	sun.rotation_degrees = Vector3(-28.0, -38.0, 0.0)
	sun.light_color = Color("fff2db")
	sun.light_energy = 2.25
	sun.shadow_enabled = true
	sun.shadow_blur = 0.65
	sun.shadow_normal_bias = 0.30
	sun.directional_shadow_max_distance = 70
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)
	var earthshine := DirectionalLight3D.new()
	earthshine.name = "Earthshine"
	earthshine.rotation_degrees = Vector3(-36, 135, 0)
	earthshine.light_color = Color("95b5e3")
	earthshine.light_energy = 0.38
	add_child(earthshine)
	var fighter_fill := DirectionalLight3D.new()
	fighter_fill.name = "SuitBounce"
	fighter_fill.rotation_degrees = Vector3(-26, 8, 0)
	fighter_fill.light_color = Color("c4d5e8")
	fighter_fill.light_energy = 1.0
	fighter_fill.light_cull_mask = 2
	add_child(fighter_fill)
	for x: float in [-7.8, 7.8]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 0.3, -2.0)
		light.light_color = Color("a8cfe7")
		light.light_energy = 1.7
		light.omni_range = 3.8
		light.light_specular = 0.5
		add_child(light)

func _create_geology() -> void:
	geology_noise.seed = 44627
	geology_noise.frequency = 0.035
	geology_noise.fractal_octaves = 5
	geology_noise.fractal_gain = 0.56
	detail_noise.seed = 90532
	detail_noise.frequency = 0.58
	detail_noise.fractal_octaves = 4
	# Overlapping impact structures: x, z, rim radius, excavation depth.
	crater_centers = [Vector4(-19, -42, 18, 7.5), Vector4(20, -66, 13, 4.7), Vector4(4, -22, 5.8, 1.8), Vector4(-13, -9, 4, 1.0), Vector4(15, -10, 3.4, 1.05)]
	for i in 32:
		crater_centers.append(Vector4(art_rng.randf_range(-72, 72), art_rng.randf_range(-108, 10), art_rng.randf_range(0.9, 4.7), art_rng.randf_range(0.25, 1.1)))
	terrain_node = _build_terrain("ImpactBasin", Vector2(-85, -119), Vector2(170, 140), 186, 168, false)
	terrain_high = terrain_node.mesh
	var low_node: MeshInstance3D = _build_terrain("ImpactBasinLow", Vector2(-85, -119), Vector2(170, 140), 62, 56, false)
	terrain_low = low_node.mesh
	low_node.free()
	# The distant surveyed-looking terrain lives in the panorama. Keeping only
	# nearby geometry avoids an orthographic mountain wall swallowing the sky.
	_create_rocks()

func _height(x: float, z: float, distant: bool = false) -> float:
	if distant:
		var base: float = z * 0.306 - 5.5
		var ridge: float = exp(-pow((z + 187.0) / 53.0, 2.0))
		var peaks: float = 8.5 + absf(geology_noise.get_noise_2d(x * 2.4, z * 0.37)) * 29.0
		var strata: float = detail_noise.get_noise_2d(x * 0.34, z * 0.4) * 1.7
		return base + ridge * peaks + strata + geology_noise.get_noise_2d(x * 3.5, z * 2.0) * 3.7
	var height: float = -4.7 + minf(z + 8.0, 0.0) * 0.29
	height += geology_noise.get_noise_2d(x, z) * 2.8 + detail_noise.get_noise_2d(x, z) * 0.19
	for crater in crater_centers:
		var r: float = Vector2(x - crater.x, (z - crater.y) * 0.88).length() / crater.z
		if r > 1.65: continue
		var rim: float = exp(-pow((r - 1.03) / 0.12, 2.0)) * crater.w * 0.38
		var bowl: float = -pow(maxf(0.0, 1.0 - r * r), 1.35) * crater.w
		var terraces: float = sin(r * 32.0) * 0.085 * crater.w * smoothstep(0.40, 0.75, r) * (1.0 - smoothstep(0.85, 1.0, r))
		height += rim + bowl + terraces
	# The observatory is cantilevered from the rear crater rim. Keep the central
	# distant ridge below fighters' silhouettes, and leave a real open chasm
	# across their entire recovery plane instead of hiding them inside scenery.
	var backdrop_lane: float = (1.0 - smoothstep(12.0, 24.0, absf(x))) * (1.0 - smoothstep(-14.0, -4.0, z))
	height = lerpf(height, minf(height, -6.4 + z * 0.306), backdrop_lane)
	var landing_area: float = (1.0 - smoothstep(7.0, 12.0, absf(x))) * (1.0 - smoothstep(2.0, 6.0, absf(z)))
	height = lerpf(height, -4.4 + detail_noise.get_noise_2d(x, z) * 0.10, landing_area)
	var recovery_lane: float = (1.0 - smoothstep(20.0, 27.0, absf(x))) * smoothstep(-2.8, -1.4, z)
	return lerpf(height, minf(height, -15.0), recovery_lane)

func _build_terrain(node_name: String, origin: Vector2, extent: Vector2, nx: int, nz: int, distant: bool) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.resize((nx + 1) * (nz + 1))
	normals.resize(vertices.size())
	uvs.resize(vertices.size())
	var epsilon: float = 0.24 if not distant else 0.7
	for iz in nz + 1:
		for ix in nx + 1:
			var x: float = origin.x + extent.x * float(ix) / nx
			var z: float = origin.y + extent.y * float(iz) / nz
			var index: int = iz * (nx + 1) + ix
			vertices[index] = Vector3(x, _height(x, z, distant), z)
			normals[index] = Vector3(_height(x - epsilon, z, distant) - _height(x + epsilon, z, distant), epsilon * 2.0, _height(x, z - epsilon, distant) - _height(x, z + epsilon, distant)).normalized()
			uvs[index] = Vector2(x, z) * 0.25
	for iz in nz:
		for ix in nx:
			var a: int = iz * (nx + 1) + ix
			var b: int = a + 1
			var c: int = a + nx + 1
			indices.append_array(PackedInt32Array([a, b, c, b, c + 1, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var terrain := ArrayMesh.new()
	terrain.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := _mesh(terrain, Vector3.ZERO, rock_material)
	node.name = node_name
	if distant:
		var distant_mat: ShaderMaterial = rock_material.duplicate()
		distant_mat.set_shader_parameter("texture_scale", 0.16)
		distant_mat.set_shader_parameter("relief", 1.1)
		node.material_override = distant_mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func _rock_mesh(variant: int) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 14
	var arrays: Array = sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var p: Vector3 = vertices[i]
		var n: float = detail_noise.get_noise_3d(p.x * 3.5 + variant * 10.0, p.y * 3.5, p.z * 3.5)
		p *= 0.85 + n * 0.27
		# Ejecta breaks along planes; it should not look like rounded river stone.
		p.x = minf(p.x, 0.64 + p.z * 0.20)
		p.z = maxf(p.z, -0.60 + p.y * 0.21)
		p.y = minf(p.y, 0.69 - p.x * 0.25)
		p.y = maxf(p.y, -0.42)
		vertices[i] = p
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TANGENT] = null
	var raw := ArrayMesh.new()
	raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface := SurfaceTool.new()
	surface.create_from(raw, 0)
	surface.generate_normals()
	return surface.commit()

func _create_rocks() -> void:
	var fractured_material: ShaderMaterial = rock_material.duplicate()
	fractured_material.set_shader_parameter("fracture_strength", 0.26)
	fractured_material.set_shader_parameter("relief", 0.012)
	for variant in 7:
		var rock := _rock_mesh(variant)
		var scatter := MultiMesh.new()
		scatter.transform_format = MultiMesh.TRANSFORM_3D
		scatter.mesh = rock
		scatter.instance_count = 120
		for i in scatter.instance_count:
			var x: float = art_rng.randf_range(-45, 45)
			var z: float = art_rng.randf_range(-72, 12)
			if z > -3.5 and absf(x) < 24.0: z = -9.0 - art_rng.randf() * 20.0
			if z > -22.0 and absf(x) < 12.0: z = -25.0 - art_rng.randf() * 20.0
			var size: float = pow(art_rng.randf(), 3.0) * 1.55 + 0.035
			var basis := Basis.from_euler(Vector3(art_rng.randf_range(-0.4, 0.4), art_rng.randf() * TAU, art_rng.randf_range(-0.2, 0.2)))
			basis = basis.scaled(Vector3(size, size * art_rng.randf_range(0.55, 1.1), size * art_rng.randf_range(0.7, 1.3)))
			scatter.set_instance_transform(i, Transform3D(basis, Vector3(x, _height(x, z) + size * 0.18, z)))
		var node := MultiMeshInstance3D.new()
		node.name = "ImpactEjecta%d" % variant
		node.multimesh = scatter
		node.material_override = fractured_material
		add_child(node)
	# Near-camera angular boulders give the distant ridges a readable scale cue.
	for entry: Vector3 in [Vector3(-23, 2.5, -9.0), Vector3(24, 3.2, -9.0), Vector3(-28, 4.8, -18.0), Vector3(28, 2.8, -15.0)]:
		var node := _mesh(_rock_mesh(int(absf(entry.x))), Vector3(entry.x, _height(entry.x, entry.z) + entry.y * 0.14, entry.z), fractured_material)
		node.scale = Vector3(entry.y, entry.y * 0.78, entry.y * 0.9)
		node.rotation_degrees.y = entry.x * 7

func _create_observatory() -> void:
	var deck := Node3D.new()
	deck.name = "RimObservatoryDeck"
	add_child(deck)
	_slab(18.0, 0.64, 3.6, 0.38, Vector3(0, -0.48, -0.25), materials.dark, deck)
	# The panel tops define the visual walking plane; the continuous backing
	# sits beneath them so its cap cannot fight their depth at y = 0.
	_slab(18.0, 0.14, 3.65, 0.36, Vector3(0, -0.12, -0.25), materials.titanium, deck)
	for i in 12:
		var x: float = -8.23 + i * 1.495
		_slab(1.44,0.06,2.82,0.09,Vector3(x,-0.03,-0.24),materials.deck_panel,deck)
		if i % 3 == 1:
			_box(Vector3(1.18, 0.012, 0.58), Vector3(x, 0.010, -0.28), materials.titanium, deck)
			for j in 7:
				_box(Vector3(0.87, 0.007, 0.018), Vector3(x, 0.021, -0.48 + j * 0.067), materials.dark, deck)
		_box(Vector3(1.23, 0.012, 0.055), Vector3(x, 0.012, 1.065), materials.dark, deck)
		for z: float in [-1.52, 1.03]:
			for offset: float in [-0.61, 0.61]:
				_bolt(Vector3(x + offset, 0.021, z), 0.031)
	# Exposed sandwich-panel fascia, recessed service bays, individual vents.
	for i in 9:
		var x: float = -8.0 + i * 2.0
		_box(Vector3(1.75, 0.32, 0.07), Vector3(x, -0.43, 1.573), materials.titanium, deck)
		_box(Vector3(0.9, 0.16, 0.083), Vector3(x, -0.43, 1.62), materials.dark, deck)
		for j in 6:
			_box(Vector3(0.055, 0.12, 0.016), Vector3(x - 0.33 + j * 0.13, -0.43, 1.672), materials.rubber, deck)
		_box(Vector3(0.5, 0.027, 0.035), Vector3(x, -0.20, 1.62), materials.cyan, deck)
	for x: float in [-8.65, 8.65]:
		_box(Vector3(0.30, 0.023, 3.08), Vector3(x, 0.016, -0.27), materials.orange, deck)
		for j in 7:
			var stripe := _box(Vector3(0.32, 0.025, 0.16), Vector3(x, 0.023, -1.52 + j * 0.43), materials.dark, deck)
			stripe.rotation.y = -0.38
		_box(Vector3(0.10, 0.06, 2.7), Vector3(x + signf(x) * 0.23, -0.05, -0.3), materials.amber, deck)
	# Landing struts are intentionally below the fight plane.
	for x: float in [-7.4, -3.6, 3.6, 7.4]:
		for z: float in [-1.4]:
			var foot := Vector3(x + signf(x) * 0.55, -4.35, z + signf(z) * 0.48)
			_rod(Vector3(x, -0.75, z), foot + Vector3.UP * 0.2, 0.14, materials.white, deck)
			_rod(Vector3(x, -0.85, z), foot + Vector3.UP * 1.0, 0.065, materials.titanium, deck)
			_cylinder(0.50, 0.12, foot, materials.dark, deck)
			_cylinder(0.34, 0.16, foot + Vector3.UP * 0.10, materials.titanium, deck)
	for z: float in [-1.37]:
		_rod(Vector3(-8.1, -1.65, z), Vector3(8.1, -1.65, z), 0.075, materials.titanium, deck)
		for i in 8:
			var x: float = -8.0 + i * 2.0
			_rod(Vector3(x, -0.8, z), Vector3(x + 1.0, -1.65, z), 0.055, materials.white, deck)
			_rod(Vector3(x + 1.0, -1.65, z), Vector3(x + 2.0, -0.8, z), 0.055, materials.white, deck)
	for x: float in [-5.0, 5.0]:
		var side := _upper_platform(4.5, "CantileverPlatform", Vector3(x, 3.6, 0))
		for offset: float in [-1.65, 1.65]:
			_rod(Vector3(x + offset, 0.0, -1.45), Vector3(x + offset, 3.39, -1.10), 0.08, materials.titanium)
			_rod(Vector3(x + offset - signf(offset) * 0.8, 0.10, -1.45), Vector3(x + offset, 3.0, -1.10), 0.05, materials.white)
		_label("02" if x < 0 else "03", Vector3(0, -0.27, 1.055), 0.0016, 42, Color("bbd0d9"), side)
	center_visual = _upper_platform(3.5, "OrbitalLift", Vector3(0, 5.5, 0))
	_label("ZENITH  /  01", Vector3(0, -0.25, 1.055), 0.00135, 34, Color("c9dbe1"), center_visual)
	for x: float in [-1.20, 1.20]:
		_rod(Vector3(x, -0.3, -1.42), Vector3(x, 4.8, -1.42), 0.055, materials.dark)
		_rod(Vector3(x, -1.2, -1.42), Vector3(x, -0.32, -1.42), 0.093, materials.titanium, center_visual)
		_cylinder(0.15, 0.26, Vector3(x, -0.5, -1.42), materials.gold, center_visual)
	_label("L U N A R   R E A C H", Vector3(0, -0.42, 1.682), 0.0016, 38, Color("cad2d3"), deck)
	# Railings are confined to the back, keeping all attack silhouettes clear.
	for x: float in [-8.2, -6.5, 6.5, 8.2]:
		_rod(Vector3(x, 0, -1.91), Vector3(x, 0.8, -1.91), 0.029, materials.titanium, deck)
	for ends: Vector2 in [Vector2(-8.2, -6.5), Vector2(6.5, 8.2)]:
		for y: float in [0.42, 0.8]:
			_rod(Vector3(ends.x, y, -1.91), Vector3(ends.y, y, -1.91), 0.025, materials.titanium, deck)

func _upper_platform(width: float, node_name: String, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	add_child(root)
	_slab(width,0.18,2.0,0.12,Vector3(0,-0.15,0),materials.titanium,root)
	_slab(width-0.16,0.05,1.83,0.09,Vector3(0,-0.075,0),materials.rubber,root)
	var count: int = maxi(3,int(width/0.68))
	var pitch: float = (width-0.32)/float(count)
	for i in count:
		var x: float = -width*0.5+0.16+(i+0.5)*pitch
		_slab(pitch-0.022,0.065,1.70,0.055,Vector3(x,-0.0325,0),materials.deck_panel,root)
		for z: float in [-0.63,0.63]:
			_slab(pitch*0.58,0.012,0.075,0.015,Vector3(x,-0.002,z),materials.titanium,root)
	# Ribbed load-bearing frame, nested vent pockets, and service-panel latches.
	_slab(width-0.25,0.27,1.63,0.14,Vector3(0,-0.355,0),materials.dark,root)
	for i in count:
		var x: float = -width*0.5+0.24+(i+0.5)*(width-0.48)/count
		_slab((width-0.48)/count-0.06,0.20,0.10,0.025,Vector3(x,-0.355,0.83),materials.titanium,root)
		_box(Vector3(pitch*0.51,0.075,0.016),Vector3(x,-0.355,0.887),materials.rubber,root)
		for fin in 4:
			_box(Vector3(0.023,0.065,0.023),Vector3(x-0.09+fin*0.06,-0.355,0.905),materials.white,root)
	_box(Vector3(width-0.24,0.04,0.05),Vector3(0,-0.21,0.987),materials.white,root)
	for x: float in [-width * 0.44, width * 0.44]:
		_box(Vector3(0.13, 0.033, 1.65), Vector3(x, 0.019, 0), materials.orange, root)
		_box(Vector3(0.28, 0.032, 0.035), Vector3(x, -0.15, 1.02), materials.cyan, root)
	PLATFORM_GEOMETRY.merge_parts(root)
	return root

func _create_outpost() -> void:
	# A cylindrical pressure habitat: thermal blankets, structural rings, round
	# airlock, radiator fins and wiring, all at a coherent human scale.
	var hab := Node3D.new()
	hab.name = "PressureHabitat"
	hab.position = Vector3(-10.7, -5.0, -11.8)
	hab.rotation_degrees.y = -12
	add_child(hab)
	var shell := _cylinder(1.5, 5.5, Vector3(0, 1.75, 0), materials.white, hab)
	shell.rotation.z = PI * 0.5
	for x: float in [-2.7, -2.1, -0.8, 0.8, 2.1, 2.7]:
		var band := _cylinder(1.53, 0.065, Vector3(x, 1.75, 0), materials.titanium, hab)
		band.rotation.z = PI * 0.5
	for z: float in [-0.92, 0.92]:
		_box(Vector3(5.0, 0.18, 0.45), Vector3(0, 0, z), materials.dark, hab)
		for x: float in [-2.0, 2.0]:
			_rod(Vector3(x, 0.1, z), Vector3(x, 1.0, z * 1.2), 0.12, materials.titanium, hab)
	var hatch := _cylinder(0.72, 0.16, Vector3(0.5, 1.5, 1.36), materials.dark, hab)
	hatch.rotation.x = PI * 0.5
	var hatch_inner := _cylinder(0.59, 0.19, Vector3(0.5, 1.5, 1.4), materials.titanium, hab)
	hatch_inner.rotation.x = PI * 0.5
	for angle in 8:
		var a: float = angle * TAU / 8.0
		_box(Vector3(0.13, 0.13, 0.13), Vector3(0.5 + sin(a) * 0.61, 1.5 + cos(a) * 0.61, 1.53), materials.orange, hab)
	_box(Vector3(0.9, 0.025, 0.06), Vector3(0.5, 2.45, 1.1), materials.cyan, hab)
	_label("SELENE / 04", Vector3(-1.23, 2.05, 1.38), 0.0024, 34, Color("273b49"), hab)
	for x: float in [-1.5, -0.7]:
		_box(Vector3(0.46, 0.33, 0.06), Vector3(x, 1.42, 1.45), materials.dark, hab)
		_box(Vector3(0.35, 0.23, 0.075), Vector3(x, 1.42, 1.47), materials.solar, hab)
	# Thermal radiators and photovoltaic fields on the far slope.
	for i in 5:
		var x: float = 5.5 + i * 2.55
		var z: float = -23.0 - i * 1.4
		var y: float = _height(x, z)
		_solar_array(Vector3(x, y + 1.4, z), 2.1, 2.5)
	for i in 4:
		_box(Vector3(0.9, 2.8, 0.08), Vector3(-15.5 + i * 1.1, -4.4, -16), materials.white)
		for j in 9:
			_box(Vector3(0.8, 0.032, 0.024), Vector3(-15.5 + i * 1.1, -5.65 + j * 0.29, -15.94), materials.titanium)
	_create_dish(Vector3(12.5, _height(12.5, -15), -15), 1.0)
	_create_dish(Vector3(-22, _height(-22, -34), -34), 0.52)
	# Insulated surface cable and power junctions link the structures.
	for i in 24:
		var x: float = -10.0 + i * 0.7
		var z: float = -7.7 + sin(i * 0.19) * 0.8
		var next_z: float = -7.7 + sin((i + 1) * 0.19) * 0.8
		_rod(Vector3(x, _height(x, z) + 0.08, z), Vector3(x + 0.7, _height(x + 0.7, next_z) + 0.08, next_z), 0.037, materials.rubber)
	for x: float in [-8.0, 8.0]:
		var equipment := Node3D.new()
		equipment.name = "BreakableTelemetry"
		equipment.position = Vector3(x, 0, -1.05)
		add_child(equipment)
		_box(Vector3(0.34, 0.42, 0.3), Vector3(0, 0.24, 0), materials.white, equipment)
		_box(Vector3(0.25, 0.12, 0.035), Vector3(0, 0.30, 0.165), materials.dark, equipment)
		_box(Vector3(0.08, 0.012, 0.038), Vector3(0.045, 0.30, 0.19), materials.cyan, equipment)
		breakable_furniture.append(equipment)

func _solar_array(at: Vector3, width: float, depth: float) -> void:
	var panel := Node3D.new()
	panel.name = "PhotovoltaicWing"
	panel.position = at
	add_child(panel)
	_rod(Vector3(0, -1.4, 0), Vector3(0, -0.05, 0), 0.055, materials.titanium, panel)
	var face := Node3D.new()
	face.rotation_degrees.x = -19
	panel.add_child(face)
	solar_faces.append(face)
	_box(Vector3(width + 0.07, 0.055, depth + 0.07), Vector3.ZERO, materials.titanium, face)
	_box(Vector3(width, 0.062, depth), Vector3.ZERO, materials.solar, face)
	for i in 7:
		_box(Vector3(0.012, 0.012, depth), Vector3(-width * 0.5 + width * i / 6.0, 0.037, 0), materials.titanium, face)
	for j in 11:
		_box(Vector3(width, 0.012, 0.009), Vector3(0, 0.037, -depth * 0.5 + depth * j / 10.0), materials.titanium, face)

func _create_dish(at: Vector3, size: float, face_material: Material = null) -> void:
	var root := Node3D.new()
	root.name = "DeepSpaceArray"
	root.position = at
	root.scale = Vector3.ONE * size
	add_child(root)
	for angle in 3:
		var a: float = angle * TAU / 3.0
		_rod(Vector3(sin(a) * 1.2, 0, cos(a) * 1.2), Vector3(0, 3.0, 0), 0.075, materials.titanium, root)
	_cylinder(0.28, 0.55, Vector3(0, 2.55, 0), materials.dark, root)
	var bowl := Node3D.new()
	bowl.position = Vector3(0, 3.15, 0)
	bowl.rotation_degrees = Vector3(-26, -32, 0)
	root.add_child(bowl)
	dish_heads.append(bowl)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 64
	var rings: int = 14
	for ring in rings:
		for segment in segments:
			var r0: float = 1.75 * ring / rings
			var r1: float = 1.75 * (ring + 1) / rings
			var a0: float = TAU * segment / segments
			var a1: float = TAU * (segment + 1) / segments
			var points: Array[Vector3] = [Vector3(sin(a0) * r0, cos(a0) * r0, r0 * r0 * 0.25), Vector3(sin(a1) * r0, cos(a1) * r0, r0 * r0 * 0.25), Vector3(sin(a0) * r1, cos(a0) * r1, r1 * r1 * 0.25), Vector3(sin(a1) * r1, cos(a1) * r1, r1 * r1 * 0.25)]
			for index in [0, 2, 1, 1, 2, 3]:
				surface.add_vertex(points[index])
	surface.generate_normals()
	var dish_mat: ShaderMaterial = materials.white.duplicate()
	_mesh(surface.commit(), Vector3.ZERO, face_material if face_material else dish_mat, bowl)
	for angle in 12:
		var a: float = angle * TAU / 12.0
		_rod(Vector3.ZERO, Vector3(sin(a) * 1.72, cos(a) * 1.72, 0.75), 0.018, materials.titanium, bowl)
	for angle in 3:
		var a: float = angle * TAU / 3.0
		_rod(Vector3(sin(a) * 1.45, cos(a) * 1.45, 0.53), Vector3(0, 0, 1.72), 0.025, materials.dark, bowl)
	var feed := _cylinder(0.12, 0.29, Vector3(0, 0, 1.72), materials.gold, bowl)
	feed.rotation.x = PI * 0.5
	_box(Vector3(0.12, 0.12, 0.12), Vector3(0, 4.7, 0.6), _beacon_material(), root)

func _beacon_material() -> StandardMaterial3D:
	var beacon: StandardMaterial3D = materials.red.duplicate()
	beacon_materials.append(beacon)
	return beacon

func _create_living_outpost() -> void:
	# A raised communications mast makes tracking machinery visible over the
	# crater rim. Its tripod is rooted in the terrain, wholly behind combat.
	var relay_at := Vector3(-8.4,-3.8,-22.0)
	var ground: float = _height(relay_at.x,relay_at.z)
	_rod(Vector3(relay_at.x,ground,relay_at.z),relay_at,0.15,materials.titanium)
	for side: float in [-1.0,1.0]:
		_rod(Vector3(relay_at.x+side*1.5,_height(relay_at.x+side*1.5,relay_at.z),relay_at.z),relay_at,0.065,materials.dark)
	# Keep the moving bowl in the left valley opening. A dedicated muted alloy
	# prevents this background machine from competing with the combat deck.
	_create_dish(relay_at,0.56,_metal(Color("425763"),0.16,0.75))
	# An engineering causeway crosses the far survey basin. The dark surface
	# stays beneath the rover, leaving a quiet silhouette behind the fighters.
	var road := Node3D.new()
	road.name = "RemoteSurveyCauseway"
	add_child(road)
	_slab(10.4,0.18,2.95,0.12,Vector3(3.4,-7.43,-26.0),materials.dark,road)
	for x: float in [-1.2,3.4,8.0]:
		var floor: float = _height(x,-26.0)
		_rod(Vector3(x,floor,-26.0),Vector3(x,-7.43,-26.0),0.11,materials.titanium,road)
	for z: float in [-27.43,-24.57]:
		_box(Vector3(10.0,0.025,0.045),Vector3(3.4,-7.33,z),materials.titanium,road)
	PLATFORM_GEOMETRY.merge_parts(road)
	survey_rover = Node3D.new()
	survey_rover.name = "AutonomousSurveyRover"
	survey_rover.scale = Vector3.ONE*0.8
	add_child(survey_rover)
	_box(Vector3(1.7,0.30,0.96),Vector3(0,0.49,0),materials.titanium,survey_rover)
	_box(Vector3(1.25,0.47,0.76),Vector3(-0.13,0.82,0),materials.white,survey_rover)
	_box(Vector3(0.43,0.22,0.81),Vector3(0.42,0.94,0),materials.dark,survey_rover)
	_box(Vector3(0.53,0.14,0.62),Vector3(-0.43,1.10,0),materials.solar,survey_rover)
	_rod(Vector3(-0.60,0.72,0),Vector3(-0.60,1.63,0),0.025,materials.titanium,survey_rover)
	_box(Vector3(0.20,0.12,0.16),Vector3(-0.60,1.63,0),materials.dark,survey_rover)
	_box(Vector3(0.16,0.035,0.05),Vector3(0.85,0.62,0.3),materials.amber,survey_rover)
	for x: float in [-0.67,0.0,0.67]:
		for z: float in [-0.54,0.54]:
			var wheel := _cylinder(0.26,0.17,Vector3(x,0.28,z),materials.rubber,survey_rover)
			wheel.rotation.x = PI*0.5
			rover_wheels.append(wheel)
			var hub := _cylinder(0.13,0.18,Vector3(x,0.28,z),materials.titanium,survey_rover)
			hub.rotation.x = PI*0.5
			extra_scenery.append(hub)
	# A relay crosses the black sky on a slow apparent orbit. It has rigid solar
	# wings and no exhaust, invented atmosphere, or drifting surface dust.
	orbital_relay = Node3D.new()
	orbital_relay.name = "PassingOrbitalRelay"
	add_child(orbital_relay)
	_box(Vector3(0.60,0.40,0.30),Vector3.ZERO,materials.gold,orbital_relay)
	for side: float in [-1.0,1.0]:
		_box(Vector3(1.04,0.55,0.04),Vector3(side*1.04,0,0),materials.solar,orbital_relay)
		for strip in 3:
			_box(Vector3(0.012,0.55,0.047),Vector3(side*1.04-0.30+strip*0.30,0,0),materials.titanium,orbital_relay)
		_box(Vector3(0.60,0.025,0.025),Vector3(side*0.52,0,0),materials.titanium,orbital_relay)
	_rod(Vector3(0,-0.15,0),Vector3(0,-0.53,0),0.019,materials.white,orbital_relay)
	_box(Vector3(0.07,0.07,0.06),Vector3(0.31,0.10,0.17),_beacon_material(),orbital_relay)
	for child: Node in orbital_relay.get_children():
		if child is GeometryInstance3D: child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _create_earth() -> void:
	var horizon_quad := QuadMesh.new()
	horizon_quad.size = Vector2(100, 56.25)
	var horizon_material := ShaderMaterial.new()
	horizon_material.shader = preload("res://stages/lunar_reach/lunar_horizon.gdshader")
	horizon_material.set_shader_parameter("panorama", preload("res://assets/lunar_reach/crater_horizon.png"))
	crater_horizon = _mesh(horizon_quad, Vector3(0, 0, -600), horizon_material)
	crater_horizon.name = "DistantCraterPanorama"
	crater_horizon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	earth_material = ShaderMaterial.new()
	earth_material.shader = EARTH_SHADER
	earth_material.set_shader_parameter("earth_map", preload("res://assets/lunar_reach/earth_blue_marble.jpg"))
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	earth = _mesh(quad, Vector3(12, 12, -150), earth_material)
	earth.name = "Earthrise"
	earth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _create_vents() -> void:
	for x: float in [-8.0, 8.0]:
		_cylinder(0.27, 0.13, Vector3(x, -0.09, 0), materials.dark)
		for i in 6:
			_box(Vector3(0.44, 0.012, 0.035), Vector3(x, 0.005, -0.16 + i * 0.064), materials.titanium)
		var warning_quad := QuadMesh.new()
		warning_quad.size = Vector2(1.8, 1.5)
		var warning_material := ShaderMaterial.new()
		warning_material.shader = preload("res://stages/rooftop_riot/pyro_warning.gdshader")
		var warning := _mesh(warning_quad, Vector3(x, 0.036, 0), warning_material)
		warning.rotation.x = -PI * 0.5
		warning.visible = false
		warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hazard_warnings.append(warning)
		var plume_quad := QuadMesh.new()
		plume_quad.size = Vector2(1.8, 2.15)
		var jet := ShaderMaterial.new()
		jet.shader = VENT_SHADER
		jet.set_shader_parameter("phase", x * 0.3)
		var plume := _mesh(plume_quad, Vector3(x, 1.085, 0.06), jet)
		plume.visible = false
		plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hazard_flames.append(plume)

func step() -> void:
	super.step()
	_animate_scene(tick/60.0)

func reset_match(new_seed: int) -> void:
	super.reset_match(new_seed)
	_animate_scene(0.0)

func _animate_scene(seconds: float) -> void:
	scenery_seconds = seconds
	if earth_material:
		earth_material.set_shader_parameter("longitude",0.075+seconds*0.00006)
		earth_material.set_shader_parameter("scene_time",seconds)
	for i in dish_heads.size():
		dish_heads[i].rotation_degrees = Vector3(-26.0+sin(seconds*0.12+i*0.71)*8.0,-32.0+sin(seconds*0.073+i*1.1)*29.0,0)
	for i in solar_faces.size():
		solar_faces[i].rotation_degrees.x = -19.0+sin(seconds*0.021+i*0.3)*2.0
	for i in beacon_materials.size():
		var pulse: float = pow(sin(seconds*1.2+i*1.8)*0.5+0.5,5.0)
		beacon_materials[i].emission_energy_multiplier = 0.42+pulse*1.9
	if survey_rover:
		var angle: float = seconds*0.049+2.35
		survey_rover.position = Vector3(3.4+cos(angle)*4.6,-7.33,-26.0+sin(angle)*1.02)
		survey_rover.rotation.y = atan2(-cos(angle)*1.02,-sin(angle)*4.6)
		for wheel: MeshInstance3D in rover_wheels: wheel.rotation.z = -seconds*0.60

func apply_quality(value: String) -> void:
	super.apply_quality(value)
	# Geology remains decorative. Quality never alters the four collision planes.
	if terrain_node: terrain_node.mesh = terrain_low if graphics_quality == "Low" else terrain_high
	# There is no reflective water/atmosphere on the Moon.
	if lunar_environment: lunar_environment.ssr_enabled = false
	for node: Node3D in extra_scenery: node.visible = graphics_quality != "Low"
	_animate_scene(tick/60.0)

func frame_horizon(camera: Camera3D) -> void:
	if not earth: return
	var rect: Vector2 = camera.get_viewport().get_visible_rect().size
	var aspect: float = rect.x / maxf(rect.y, 1.0)
	var distance: float = 490.0
	var height: float = camera.size if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 2.0 * tan(deg_to_rad(camera.fov * 0.5)) * distance
	var diameter: float = height * 0.19
	(earth.mesh as QuadMesh).size = Vector2.ONE * diameter
	# Infinity-layer parallax is deliberately minimal: a planetary body must not
	# move like a nearby billboard when the fight camera follows a launched player.
	earth.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(height * aspect * 0.245, height * 0.375, -distance))
	var panorama_distance: float = 610.0
	var panorama_height: float = camera.size if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 2.0 * tan(deg_to_rad(camera.fov * 0.5)) * panorama_distance
	var cover_height: float = maxf(panorama_height, panorama_height * aspect / (16.0 / 9.0)) * 1.015
	(crater_horizon.mesh as QuadMesh).size = Vector2(16.0 / 9.0, 1.0) * cover_height
	crater_horizon.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, -panorama_distance))
	if orbital_relay:
		var orbit: float = fposmod(scenery_seconds/180.0+0.15,1.0)
		var position_in_sky := Vector3(height*aspect*lerpf(-0.65,0.65,orbit),height*(0.31+sin(orbit*PI)*0.035),-280.0)
		var satellite_basis := Basis.from_euler(Vector3(0.0,sin(scenery_seconds*0.04)*0.2,-0.18)).scaled(Vector3.ONE*height*0.013)
		orbital_relay.global_transform = camera.global_transform*Transform3D(satellite_basis,position_in_sky)

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

func _cylinder(radius: float, height: float, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 64 if radius > 0.6 else 24
	return _mesh(mesh, at, material, parent)

func _rod(from: Vector3, to: Vector3, radius: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var delta: Vector3 = to - from
	var node := _cylinder(radius, delta.length(), (from + to) * 0.5, material, parent)
	node.basis = Basis(Quaternion(Vector3.UP, delta.normalized()))
	return node

func _slab(width: float, height: float, depth: float, bevel: float, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	return _mesh(PLATFORM_GEOMETRY.beveled_box(Vector3(width,height,depth),minf(0.032,height*0.24),bevel),at,material,parent)

func _bolt(at: Vector3, radius: float) -> void:
	bolt_transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(radius, radius * 0.5, radius)), at))

func _finish_bolts() -> void:
	var bolt := CylinderMesh.new()
	bolt.radial_segments = 6
	bolt.top_radius = 1
	bolt.bottom_radius = 1
	bolt.height = 1
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = bolt
	batch.instance_count = bolt_transforms.size()
	for i in bolt_transforms.size(): batch.set_instance_transform(i, bolt_transforms[i])
	var node := MultiMeshInstance3D.new()
	node.name = "HexFasteners"
	node.multimesh = batch
	node.material_override = materials.dark
	add_child(node)

func _label(text: String, at: Vector3, pixel_size: float, font_size: int, color: Color, parent: Node3D = null) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.pixel_size = pixel_size
	label.font_size = font_size
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	(parent if parent else self).add_child(label)
