class_name AbyssalStage
extends RooftopStage
## The fighting gallery of a submerged art-deco marine observatory.
## Editable near/midground geometry surrounds a distant ocean matte.
## Only inherited top planes collide.

const BACKDROP_SCRIPT = preload("res://stages/arena_backdrop.gd")
const PLATFORM_GEOMETRY = preload("res://stages/platform_geometry.gd")
const OCEAN_ART = preload("res://assets/arenas/abyssal_observatory/backdrop.png")
const MARBLE_SHADER = preload("res://stages/abyssal_observatory/caustic_marble.gdshader")
const BEAM_SHADER = preload("res://stages/abyssal_observatory/ocean_beam.gdshader")
const PRESSURE_SHADER = preload("res://stages/abyssal_observatory/pressure_jet.gdshader")
const FISH_SHADER = preload("res://stages/abyssal_observatory/swimming_fish.gdshader")
const FILAMENT_SHADER = preload("res://stages/abyssal_observatory/jelly_filament.gdshader")

var palette: Dictionary = {}
var ocean_rng := RandomNumberGenerator.new()
var animated_materials: Array[ShaderMaterial] = []
var jellyfish: Array[Dictionary] = []
var shoals: Array[Dictionary] = []
var sea_creatures: Array[Dictionary] = []
var light_shafts: Array[Dictionary] = []
var water_particles: Dictionary = {}
var expensive_scenery: Array[Node3D] = []
var high_detail: Node3D
var caustic_floor: ShaderMaterial
var plain_floor: StandardMaterial3D
var floor_nodes: Array[MeshInstance3D] = []
var ocean_key: DirectionalLight3D
var distant_art: ArenaBackdrop

func _ready() -> void:
	name = "AbyssalObservatory"
	platforms = [
		{"id": 0, "x": 0.0, "width": 19.2, "y": 0.0, "previous_y": 0.0, "thickness": 0.64},
		{"id": 1, "x": -5.8, "width": 3.6, "y": 4.2, "previous_y": 4.2},
		{"id": 2, "x": 5.8, "width": 3.6, "y": 4.2, "previous_y": 4.2},
		{"id": 3, "x": 0.0, "width": 4.2, "y": 2.5, "previous_y": 2.5, "base_y": 2.5, "amplitude": 0.65, "period_ticks": 720.0}]
	event_rng.seed = seed_value
	ocean_rng.seed = 801763
	_create_palette()
	_create_environment()
	_create_ocean()
	_create_gallery()
	_create_architecture()
	_create_reef()
	_create_sealife()
	_create_pressure_vents()
	_animate_ocean()

func _material(color: String, metal: float = 0.0, rough: float = 0.6, emission: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.metallic = metal
	material.roughness = rough
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = Color(color)
		material.emission_energy_multiplier = emission
	return material

func _create_palette() -> void:
	palette.brass = _material("c8a161", 0.40, 0.3)
	palette.old_brass = _material("77613c", 0.52, 0.5)
	palette.ivory = _material("babca9", 0.04, 0.5)
	palette.stone_border = _material("576761", 0.08, 0.54)
	palette.fascia = _material("22495b", 0.40, 0.36)
	palette.polished_brass = _material("a98a52", 0.62, 0.32)
	palette.cobalt = _material("172e46", 0.25, 0.34)
	palette.dark = _material("102a36", 0.22, 0.66)
	palette.teal = _material("2b6a70", 0.25, 0.42)
	palette.trim_light = _material("97d5ce", 0.12, 0.3, 0.62)
	palette.warm_light = _material("f5d393", 0.1, 0.38, 0.75)
	palette.reef = _material("10363e", 0.0, 0.97)
	palette.far_reef = _material("123746", 0.0, 1.0)
	palette.coral_rose = _material("a96479", 0.0, 0.8)
	palette.coral_gold = _material("aa8552", 0.0, 0.86)
	palette.coral_teal = _material("4a8c8f", 0.0, 0.7)
	palette.polyps = _material("62bbc2", 0.0, 0.5, 0.36)
	palette.whale = _material("164452", 0.0, 0.8)
	palette.fish = _material("346779", 0.0, 0.8)
	palette.jelly = _material("559aa9", 0.06, 0.35, 0.16)
	palette.jelly.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	palette.jelly.albedo_color.a = 0.42
	palette.jelly.cull_mode = BaseMaterial3D.CULL_DISABLED
	palette.tentacle = _material("679da8", 0.0, 0.6, 0.16)
	caustic_floor = ShaderMaterial.new()
	caustic_floor.shader = MARBLE_SHADER
	animated_materials.append(caustic_floor)
	plain_floor = _material("929b8e", 0.04, 0.60)
	high_detail = Node3D.new()
	high_detail.name = "CoralAndShellDetail"
	add_child(high_detail)

func _create_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "OceanGalleryLighting"
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("041c2b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("89b7bc")
	environment.ambient_light_energy = 0.52
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_agx_contrast = 1.1
	environment.glow_enabled = true
	environment.glow_intensity = 0.26
	environment.glow_hdr_threshold = 1.5
	environment.ssao_enabled = RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.ssao_radius = 0.8
	environment.ssao_intensity = 1.25
	environment.ssil_enabled = RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.ssil_intensity = 0.25
	environment.fog_enabled = false
	world.environment = environment
	add_child(world)
	ocean_key = DirectionalLight3D.new()
	ocean_key.name = "GallerySkylight"
	ocean_key.rotation_degrees = Vector3(-42, -32, 0)
	ocean_key.light_color = Color("d4e8de")
	ocean_key.light_energy = 1.7
	ocean_key.shadow_enabled = true
	ocean_key.shadow_blur = 1.7
	ocean_key.shadow_normal_bias = 0.35
	ocean_key.directional_shadow_max_distance = 44
	add_child(ocean_key)
	var fighter_fill := DirectionalLight3D.new()
	fighter_fill.name = "WarmGalleryBounce"
	fighter_fill.rotation_degrees = Vector3(-28, 15, 0)
	fighter_fill.light_color = Color("ead6b6")
	fighter_fill.light_energy = 1.25
	fighter_fill.light_cull_mask = 2
	add_child(fighter_fill)
	var rim := DirectionalLight3D.new()
	rim.name = "OceanFighterRim"
	rim.rotation_degrees = Vector3(-25, 145, 0)
	rim.light_color = Color("92d8db")
	rim.light_energy = 0.8
	rim.light_cull_mask = 2
	add_child(rim)
	for x: float in [-10.5, 10.5]:
		var practical := OmniLight3D.new()
		practical.position = Vector3(x, 2, -3.4)
		practical.light_color = Color("f3d7a4")
		practical.light_energy = 1.1
		practical.omni_range = 6.0
		add_child(practical)

func _create_ocean() -> void:
	distant_art = BACKDROP_SCRIPT.new()
	distant_art.configure(OCEAN_ART, 0.80)
	distant_art.configure_living("ocean")
	add_child(distant_art)
	for i in 7:
		var quad := QuadMesh.new()
		quad.size = Vector2(1.3 + float(i % 3) * 0.4, 14.0)
		var beam := ShaderMaterial.new()
		beam.shader = BEAM_SHADER
		beam.set_shader_parameter("phase", i * 1.71)
		animated_materials.append(beam)
		var shaft := _mesh(quad, Vector3(-10.0 + i * 3.0, -3.5, -24.0 - (i % 2) * 3.0), beam)
		shaft.name = "DescendingSunshaft%d" % i
		shaft.rotation.z = -0.19
		shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		light_shafts.append({"node": shaft, "phase": float(i) * 1.71})
		# Low still has three broad, slowly drifting rays through the window.
		if i % 3 != 0: expensive_scenery.append(shaft)

func _create_gallery() -> void:
	var deck := _terrace(19.2, 3.7, 0.64, Vector3(0, 0, -0.45))
	deck.name = "IvoryFightingGallery"
	for i in [1, 2]:
		var p: Dictionary = platforms[i]
		var terrace := _terrace(p.width, 2.0, 0.46, Vector3(p.x, p.y, -0.15))
		terrace.name = "CantileverBalcony%d" % i
		# The rear supports stop well behind the fighting plane.
		for offset: float in [-1.15, 1.15]:
			_rod(Vector3(p.x + offset, p.y - 0.40, -0.90), Vector3(p.x + offset, -2.0, -4.5), 0.085, palette.old_brass)
			_beveled(Vector3(0.40, 0.19, 0.50), Vector3(p.x + offset, p.y - 0.46, -0.87), palette.polished_brass)
	center_visual = _terrace(4.2, 1.85, 0.46, Vector3(0, 2.5, 0))
	center_visual.name = "PressureBalancedLift"
	# The compass is a fine inlay, surrounded by actual jointed stone slabs.
	_ring_xz(Vector3(0, 0.006, -0.40), 1.0, 0.011, palette.old_brass, 64)
	_ring_xz(Vector3(0, 0.006, -0.40), 0.87, 0.008, palette.old_brass, 56)
	for i in 8:
		var angle: float = i * PI * 0.25
		_rod(Vector3(sin(angle) * 0.26, 0.008, -0.4 + cos(angle) * 0.26), Vector3(sin(angle) * 0.78, 0.008, -0.4 + cos(angle) * 0.78), 0.009, palette.brass)
	# Under-deck ventilation and substantial, tapered gallery brackets.
	for x: float in [-7.8, -3.9, 3.9, 7.8]:
		var bracket := _beveled(Vector3(0.44, 1.70, 0.55), Vector3(x, -1.36, -1.4), palette.cobalt)
		bracket.rotation.x = -0.36
		var bracket_edge := _beveled(Vector3(0.12, 1.62, 0.09), Vector3(x, -1.36, -1.10), palette.old_brass)
		bracket_edge.rotation.x = -0.36
		_beveled(Vector3(0.62, 0.13, 0.76), Vector3(x, -0.65, -1.1), palette.brass)
	for x: float in [-8.0, 8.0]:
		_cylinder(0.62, 0.035, Vector3(x, 0.015, -0.3), palette.dark)
		_ring_xz(Vector3(x, 0.045, -0.3), 0.54, 0.025, palette.brass, 32)
		for d in 5:
			_box(Vector3(0.63, 0.012, 0.032), Vector3(x, 0.035, -0.54 + d * 0.12), palette.old_brass)

func _terrace(width: float, depth: float, thickness: float, at: Vector3) -> Node3D:
	var terrace := Node3D.new()
	add_child(terrace)
	terrace.position = at
	# All walking slabs meet the authored collision plane at local y=0. The
	# layered shoulder, apron and plinth stay within the deck's visual depth.
	_beveled(Vector3(width, 0.145, depth), Vector3(0, -0.1075, 0), palette.old_brass, terrace, 0.028, 0.16)
	_beveled(Vector3(width - 0.14, thickness - 0.13, depth - 0.10), Vector3(0, -(thickness + 0.13) * 0.5, 0), palette.cobalt, terrace, 0.04, 0.18)
	_beveled(Vector3(width - 0.18, 0.070, depth - 0.12), Vector3(0, -thickness + 0.035, 0), palette.polished_brass, terrace, 0.018, 0.15)
	_beveled(Vector3(width - 0.40, 0.045, depth - 0.30), Vector3(0, -thickness + 0.0225, 0), palette.dark, terrace, 0.013, 0.14)
	# Small, separated marble blocks have a readable joint pattern even in Low.
	var inset_width: float = width - 0.32
	var inset_depth: float = depth - 0.32
	var columns: int = int(ceil(inset_width / 1.18))
	var rows: int = 4 if depth > 3.0 else 2
	var tile_width: float = inset_width / float(columns)
	var tile_depth: float = inset_depth / float(rows)
	for row in rows:
		for column in columns:
			var tile_at := Vector3(-inset_width * 0.5 + (column + 0.5) * tile_width, -0.045, -inset_depth * 0.5 + (row + 0.5) * tile_depth)
			_beveled(Vector3(tile_width - 0.018, 0.09, tile_depth - 0.018), tile_at, caustic_floor, terrace, 0.008, 0.013)
	# Narrow muted green border stones sit inside a warm brass pencil edge.
	for side: float in [-1.0, 1.0]:
		_beveled(Vector3(width - 0.27, 0.075, 0.10), Vector3(0, -0.040, side * (depth * 0.5 - 0.09)), palette.stone_border, terrace, 0.009, 0.025)
		_beveled(Vector3(width - 0.18, 0.08, 0.045), Vector3(0, -0.042, side * (depth * 0.5 - 0.024)), palette.polished_brass, terrace, 0.010, 0.019)
		_beveled(Vector3(0.10, 0.075, depth - 0.16), Vector3(side * (width * 0.5 - 0.09), -0.040, 0), palette.stone_border, terrace, 0.009, 0.025)
		_beveled(Vector3(0.045, 0.08, depth - 0.15), Vector3(side * (width * 0.5 - 0.024), -0.042, 0), palette.polished_brass, terrace, 0.010, 0.019)
	# The recessed enamel apron has a repeating fan motif and machined seams.
	# Relief is deliberately below the contact edge, away from attack silhouettes.
	var panel_count: int = int(round((width - 0.36) / 1.75))
	var panel_width: float = (width - 0.38) / float(panel_count)
	var panel_height: float = thickness - 0.24
	var panel_y: float = -(0.19 + panel_height * 0.5)
	var face_z: float = depth * 0.5 - 0.034
	for i in panel_count:
		var x: float = (float(i) - float(panel_count - 1) * 0.5) * panel_width
		_beveled(Vector3(panel_width - 0.055, panel_height, 0.046), Vector3(x, panel_y, face_z), palette.old_brass, terrace, 0.012, 0.02)
		_beveled(Vector3(panel_width - 0.10, panel_height - 0.035, 0.055), Vector3(x, panel_y, face_z + 0.018), palette.fascia, terrace, 0.013, 0.025)
		for flute in 5:
			var spread: float = float(flute - 2) * (panel_width - 0.26) * 0.21
			_rod(Vector3(x + spread * 0.15, panel_y - panel_height * 0.28, face_z + 0.055), Vector3(x + spread, panel_y + panel_height * 0.29, face_z + 0.055), 0.011, palette.polished_brass, terrace)
		for side: float in [-1.0, 1.0]:
			var pin := _cylinder(0.024, 0.027, Vector3(x + side * (panel_width * 0.5 - 0.082), panel_y, face_z + 0.052), palette.brass, terrace)
			pin.rotation.x = PI * 0.5
	# Art-deco end caps make the shelf read as a built balcony at either facing.
	for side: float in [-1.0, 1.0]:
		_beveled(Vector3(0.13, thickness - 0.16, depth - 0.26), Vector3(side * (width * 0.5 - 0.09), -(thickness + 0.16) * 0.5, 0), palette.old_brass, terrace, 0.022, 0.035)
		_beveled(Vector3(0.045, thickness - 0.25, depth - 0.43), Vector3(side * (width * 0.5 - 0.025), -(thickness + 0.16) * 0.5, 0), palette.fascia, terrace, 0.012, 0.025)
	_merge_terrace(terrace)
	return terrace

func _beveled(size_value: Vector3, at: Vector3, material: Material, parent: Node3D = null, edge: float = 0.035, corner: float = 0.075) -> MeshInstance3D:
	return _mesh(PLATFORM_GEOMETRY.beveled_box(size_value, edge, corner), at, material, parent)

func _merge_terrace(terrace: Node3D) -> void:
	# Each material becomes one static surface, including every marble slab.
	# Keeping this local to the terrace preserves the animated lift's parent.
	var groups: Dictionary = {}
	for child in terrace.get_children():
		if not child is MeshInstance3D: continue
		var part := child as MeshInstance3D
		var material: Material = part.material_override
		var key: int = material.get_instance_id()
		if not groups.has(key):
			var new_surface := SurfaceTool.new()
			new_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = {"surface": new_surface, "material": material}
		var group: Dictionary = groups[key]
		var append_surface: SurfaceTool = group.surface
		append_surface.append_from(part.mesh, 0, part.transform)
		terrace.remove_child(part)
		part.free()
	for key in groups:
		var group: Dictionary = groups[key]
		var final_surface: SurfaceTool = group.surface
		final_surface.index()
		var merged := _mesh(final_surface.commit(), Vector3.ZERO, group.material, terrace)
		if group.material == caustic_floor:
			merged.name = "JointedMarbleSlabs"
			floor_nodes.append(merged)

func _create_architecture() -> void:
	# The broad porthole is composed for the actual 17-degree gameplay camera:
	# projected height is approximately .956*y-.292*z. Its ribs frame the visible
	# action instead of disappearing above a vast, featureless ocean rectangle.
	for layer in 3:
		var z: float = -7.8 - layer * 0.75
		var rx: float = 10.3 + layer * 0.17
		var ry: float = 6.0 + layer * 0.10
		_arc(Vector3(0, -2.65, z), rx, ry, -0.20, PI + 0.20, 0.13 if layer == 0 else 0.065, palette.brass if layer == 0 else palette.old_brass, 72)
		_arc(Vector3(0, -2.65, z - 0.04), rx + 0.18, ry + 0.18, -0.2, PI + 0.2, 0.07, palette.cobalt, 64)
		if layer == 0:
			_arc(Vector3(0, -2.65, z + 0.08), rx - 0.14, ry - 0.14, 0.05, PI - 0.05, 0.025, palette.warm_light, 64)
	# Radial mullions only occupy the upper corners. The center remains quiet.
	for angle: float in [0.12, 0.38, 0.68, 1.0, 2.14, 2.46, 2.76, 3.02]:
		var a := Vector3(cos(angle) * 10.3, -2.65 + sin(angle) * 6.0, -7.8)
		var b := Vector3(cos(angle) * 10.64, -2.65 + sin(angle) * 6.2, -9.3)
		_rod(a, b, 0.075, palette.brass)
	for x: float in [-10.0, 10.0]:
		var column := _cylinder(0.35, 9.2, Vector3(x, -3.0, -7.8), palette.cobalt)
		column.name = "FlutedWindowPier"
		for i in 9:
			var a: float = i * TAU / 9.0
			_cylinder(0.025, 8.9, Vector3(x + sin(a) * 0.35, -3.0, -7.8 + cos(a) * 0.35), palette.brass)
		for y: float in [-7.4, 1.4]:
			_cylinder(0.47, 0.20, Vector3(x, y, -7.8), palette.brass)
		for y: float in [-5.0, -2.0, 0.7]:
			_cylinder(0.16, 0.49, Vector3(x * 0.966, y, -7.42), palette.warm_light)
		# Warm ribbed lanterns and stepped capitals make the gallery a designed
		# architectural space rather than a floating grid of fighting platforms.
		_box(Vector3(0.7, 0.17, 0.8), Vector3(x, 1.62, -7.8), palette.ivory)
		_box(Vector3(0.9, 0.11, 1.0), Vector3(x, 1.77, -7.8), palette.brass)
	# An open undercroft preserves the visible ocean chasm and recovery routes.
	# The earlier full-width promenade obscured that depth and received coarse
	# platform shadows, so the gallery now rests on narrow diagonal rear struts.
	for x: float in [-7.8, 7.8]:
		_rod(Vector3(x, -0.65, -1.2), Vector3(x * 1.2, -3.2, -5.8), 0.08, palette.brass)

func _create_reef() -> void:
	# Small living coral specimens sit by the gallery window. The distant
	# geological silhouettes live in the matte so rounded proxy rocks cannot
	# obscure its carved ocean ruins and detailed reef walls.
	for side in [-1.0, 1.0]:
		for i in 4:
			var base := Vector3(side * (8.2 + i * 0.48), -3.1 + sin(i * 1.4) * 0.2, -10.5 - (i % 3) * 0.5)
			_fan_coral(base, 0.5 + (i % 3) * 0.18, palette.coral_rose if i % 2 == 0 else palette.coral_gold, high_detail)

func _fan_coral(base: Vector3, height: float, material: Material, parent: Node3D) -> void:
	var root_tip: Vector3 = base + Vector3(0, height * 0.52, 0)
	_rod(base, root_tip, 0.045, material, parent)
	for branch in 5:
		var spread: float = (branch - 2) * 0.37
		var end: Vector3 = base + Vector3(spread * height, height * (0.85 + (1.0 - absf(spread)) * 0.32), sin(branch * 1.5) * 0.10)
		_rod(base + Vector3(0, height * 0.30, 0), end, 0.025, material, parent)
		for twig in 2:
			var middle: Vector3 = root_tip.lerp(end, 0.5 + twig * 0.18)
			_rod(middle, middle + Vector3((1.0 if branch >= 2 else -1.0) * 0.24 * height, height * 0.27, 0.0), 0.014, material, parent)

func _create_sealife() -> void:
	# Live animals occupy actual depth behind the gallery. Broad paths cross the
	# frame at visible swimming speeds; the larger matte whale stays distant.
	_create_manta(Vector3(6.5, -4.0, -21.0), 0.48)
	_create_manta(Vector3(-6.4, -8.3, -22.0), 0.43)
	for i in 7:
		var base := Vector3(-9.1 + i * 3.05, -2.8 + (i % 3) * 0.62, -12.0 - (i % 2) * 2.4)
		_create_jelly(base, 0.23 + (i % 3) * 0.05, float(i))
	# The upper and undercroft lanes remain visible when fighters spread out or
	# recover. Fish near the action are fewer and subdued, away from hit cues.
	_create_shoal("WindowSilverfish", Vector3(-7.4, -3.1, -14.0), 18, 0.24, 0.78, 1.0, Color("77a5b2"), 0.28, 0.3)
	_create_shoal("HighPelagicShoal", Vector3(4.2, -1.5, -24.0), 20, 0.19, 0.66, -1.0, Color("5a8499"), 0.40, 2.1)
	_create_shoal("UndercroftReefFish", Vector3(6.4, -8.6, -17.0), 14, 0.28, 0.88, -1.0, Color("81a6ae"), 0.30, 4.0)
	_create_shoal("WarmReefVisitors", Vector3(-8.8, -5.8, -13.0), 10, 0.30, 0.58, 1.0, Color("9f9872"), 0.36, 5.3)
	_create_water_particles()

func _create_shoal(label: String, base: Vector3, count: int, size_value: float, speed: float, direction: float, tint: Color, depth_mix: float, phase: float) -> void:
	var shoal := MultiMeshInstance3D.new()
	shoal.name = label
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.use_custom_data = true
	multi.mesh = _fish_mesh()
	multi.instance_count = count
	# One draw per school, with independent tail strokes and staggered bodies.
	# Leading and trailing fish make a loose formation rather than a rigid row.
	for i in count:
		var trail: float = float(i) / maxf(1.0, float(count - 1))
		var spread: float = sin(trail * PI) * 0.48 + 0.12
		var p := Vector3(1.9 - trail * 4.6 + ocean_rng.randf_range(-0.19, 0.19), ocean_rng.randf_range(-spread, spread), ocean_rng.randf_range(-0.55, 0.55))
		var scale_value: float = size_value * ocean_rng.randf_range(0.79, 1.20)
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), p))
		multi.set_instance_color(i, tint * ocean_rng.randf_range(0.83, 1.12))
		multi.set_instance_custom_data(i, Color(ocean_rng.randf(), ocean_rng.randf(), trail, 1))
	shoal.multimesh = multi
	var material := ShaderMaterial.new()
	material.shader = FISH_SHADER
	material.set_shader_parameter("depth_mix", depth_mix)
	animated_materials.append(material)
	shoal.material_override = material
	shoal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shoal.rotation.y = PI if direction < 0.0 else 0.0
	add_child(shoal)
	shoals.append({"node": shoal, "base": base, "phase": phase, "speed": speed, "direction": direction, "low_count": maxi(4, count / 2)})

func _fish_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs: Array[float] = [-0.70, -0.50, -0.25, 0.10, 0.45, 0.75, 0.95]
	var heights: Array[float] = [0.04, 0.16, 0.23, 0.26, 0.20, 0.14, 0.02]
	var depths: Array[float] = [0.025, 0.07, 0.15, 0.17, 0.12, 0.075, 0.02]
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	for section in xs.size():
		for ring in 8:
			var angle: float = ring * TAU / 8.0
			vertices.append(Vector3(xs[section], sin(angle) * heights[section], cos(angle) * depths[section]))
			normals.append(Vector3(0, sin(angle), cos(angle)))
	for section in xs.size() - 1:
		for ring in 8:
			var a: int = section * 8 + ring
			var b: int = section * 8 + (ring + 1) % 8
			for index: int in [a, a + 8, b, b, a + 8, b + 8]:
				st.set_color(Color(0.80, 0.89, 0.92))
				st.set_normal(normals[index])
				st.add_vertex(vertices[index])
	# Forked tail, translucent-looking dorsal and paired pectoral silhouettes.
	_fish_face(st, [Vector3(-0.66, 0, 0), Vector3(-1.13, 0.34, 0), Vector3(-0.97, 0, 0)], Color(0.53, 0.72, 0.79))
	_fish_face(st, [Vector3(-0.66, 0, 0), Vector3(-0.97, 0, 0), Vector3(-1.13, -0.34, 0)], Color(0.53, 0.72, 0.79))
	_fish_face(st, [Vector3(-0.26, 0.22, 0), Vector3(-0.08, 0.46, 0), Vector3(0.40, 0.22, 0)], Color(0.44, 0.64, 0.71))
	for side: float in [-1.0, 1.0]:
		_fish_face(st, [Vector3(0.22, -0.04, side * 0.14), Vector3(-0.13, -0.28, side * 0.34), Vector3(-0.12, -0.10, side * 0.12)], Color(0.57, 0.74, 0.78))
		# Eye sits on the head instead of being a disconnected particle highlight.
		var eye := Vector3(0.73, 0.052, side * 0.078)
		for segment in 6:
			var angle: float = float(segment) * TAU / 6.0
			var next: float = float(segment + 1) * TAU / 6.0
			_fish_face(st, [eye, eye + Vector3(cos(angle), sin(angle), 0) * 0.035, eye + Vector3(cos(next), sin(next), 0) * 0.035], Color(0.045, 0.085, 0.10))
	st.index()
	return st.commit()

func _fish_face(st: SurfaceTool, points: Array[Vector3], color: Color) -> void:
	for point in points:
		st.set_color(color)
		st.set_normal(Vector3.BACK)
		st.add_vertex(point)

func _create_water_particles() -> void:
	var particles := MultiMeshInstance3D.new()
	particles.name = "WindowCurrentParticles"
	var shape := SphereMesh.new()
	shape.radius = 0.028
	shape.height = 0.056
	shape.radial_segments = 6
	shape.rings = 3
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = shape
	multi.instance_count = 30
	var entries: Array[Dictionary] = []
	for i in multi.instance_count:
		var base := Vector3(ocean_rng.randf_range(-13.5, 13.5), ocean_rng.randf_range(-10.0, 1.8), ocean_rng.randf_range(-20.0, -10.0))
		entries.append({"base": base, "phase": ocean_rng.randf() * TAU, "speed": ocean_rng.randf_range(0.12, 0.29)})
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, base))
	particles.multimesh = multi
	var material := _material("739caa", 0, 1)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.23
	particles.material_override = material
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	water_particles = {"node": particles, "entries": entries}

func _create_manta(at: Vector3, size_value: float) -> void:
	var manta := Node3D.new()
	manta.name = "GlidingManta"
	manta.position = at
	manta.scale = Vector3.ONE * size_value
	add_child(manta)
	_ellipsoid(Vector3(0.70, 0.10, 0.35), Vector3.ZERO, palette.whale, manta)
	var left := _poly_fin([Vector3(0.45, 0, 0.25), Vector3(0.50, 0.02, 0.62), Vector3(-0.10, 0.15, 1.60), Vector3(-0.60, 0.12, 2.0), Vector3(-0.42, 0.0, 1.0), Vector3(-0.90, -0.02, 0.45), Vector3(-0.55, 0, 0)], palette.whale, manta)
	var right := _poly_fin([Vector3(0.45, 0, -0.25), Vector3(0.50, 0.02, -0.62), Vector3(-0.10, 0.15, -1.60), Vector3(-0.60, 0.12, -2.0), Vector3(-0.42, 0.0, -1.0), Vector3(-0.90, -0.02, -0.45), Vector3(-0.55, 0, 0)], palette.whale, manta)
	_rod(Vector3(-0.6, 0, 0), Vector3(-2.5, 0.10, 0.0), 0.035, palette.whale, manta)
	manta.rotation.x = 0.45
	var direction: float = 1.0 if at.x > 0.0 else -1.0
	manta.rotation.y = PI if direction < 0.0 else 0.0
	sea_creatures.append({"node": manta, "base": at, "phase": at.x, "direction": direction, "speed": 0.36 if direction > 0.0 else 0.42, "kind": "manta", "left": left, "right": right})

func _create_jelly(at: Vector3, radius: float, phase: float) -> void:
	var jelly := Node3D.new()
	jelly.name = "DriftingMoonJelly"
	jelly.position = at
	add_child(jelly)
	var bell := Node3D.new()
	bell.name = "PulsingBell"
	jelly.add_child(bell)
	var dome := SphereMesh.new()
	dome.radius = radius
	dome.height = radius * 1.25
	dome.radial_segments = 16
	dome.rings = 8
	dome.is_hemisphere = true
	_mesh(dome, Vector3.ZERO, palette.jelly, bell)
	_ring_xz(Vector3(0, 0.02, 0), radius * 0.95, 0.013, palette.tentacle, 20, bell)
	# Six continuous ribbons share one draw and trail behind each bell stroke.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length_value: float = radius * 2.75
	for filament in 6:
		var angle: float = filament * TAU / 6.0
		var begin := Vector3(sin(angle) * radius * 0.64, 0, cos(angle) * radius * 0.64)
		for segment in 8:
			var t0: float = float(segment) / 8.0
			var t1: float = float(segment + 1) / 8.0
			var p0: Vector3 = begin + Vector3(sin(t0 * 5.0 + filament) * radius * 0.19 * t0, -t0 * length_value, 0)
			var p1: Vector3 = begin + Vector3(sin(t1 * 5.0 + filament) * radius * 0.19 * t1, -t1 * length_value, 0)
			var width0: float = lerpf(0.016, 0.006, t0)
			var width1: float = lerpf(0.016, 0.006, t1)
			var points: Array[Vector3] = [p0 - Vector3.RIGHT * width0, p0 + Vector3.RIGHT * width0, p1 - Vector3.RIGHT * width1, p0 + Vector3.RIGHT * width0, p1 + Vector3.RIGHT * width1, p1 - Vector3.RIGHT * width1]
			var uvs: Array[Vector2] = [Vector2(0, t0), Vector2(1, t0), Vector2(0, t1), Vector2(1, t0), Vector2(1, t1), Vector2(0, t1)]
			for vertex in 6:
				st.set_normal(Vector3.BACK)
				st.set_uv(uvs[vertex])
				st.add_vertex(points[vertex])
	var filament_material := ShaderMaterial.new()
	filament_material.shader = FILAMENT_SHADER
	filament_material.set_shader_parameter("phase", phase)
	filament_material.set_shader_parameter("length_scale", length_value)
	animated_materials.append(filament_material)
	var tendrils := _mesh(st.commit(), Vector3.ZERO, filament_material, jelly)
	tendrils.name = "TrailingFilaments"
	tendrils.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	jellyfish.append({"node": jelly, "bell": bell, "tendrils": tendrils, "base": at, "phase": phase})
	if int(phase) % 2 == 1: expensive_scenery.append(jelly)

func _create_pressure_vents() -> void:
	for x: float in [-8.0, 8.0]:
		var warning_mesh := QuadMesh.new()
		warning_mesh.size = Vector2(1.8, 1.5)
		var warning_material := ShaderMaterial.new()
		warning_material.shader = PRESSURE_SHADER
		warning_material.set_shader_parameter("warning", true)
		animated_materials.append(warning_material)
		var warning := _mesh(warning_mesh, Vector3(x, 0.055, 0), warning_material)
		warning.rotation.x = -PI * 0.5
		warning.visible = false
		warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hazard_warnings.append(warning)
		var plume_mesh := QuadMesh.new()
		plume_mesh.size = Vector2(1.8, 2.15)
		var plume_material := ShaderMaterial.new()
		plume_material.shader = PRESSURE_SHADER
		plume_material.set_shader_parameter("phase", x)
		animated_materials.append(plume_material)
		var jet := _mesh(plume_mesh, Vector3(x, 1.085, 0.06), plume_material)
		jet.visible = false
		jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hazard_flames.append(jet)

func step() -> void:
	super.step()
	_animate_ocean()

func frame_horizon(camera: Camera3D) -> void:
	if distant_art: distant_art.frame(camera)

func reset_match(new_seed: int) -> void:
	super.reset_match(new_seed)
	_animate_ocean()

func _animate_ocean() -> void:
	var seconds: float = tick / 60.0
	if distant_art: distant_art.set_scenery_time(seconds)
	for material in animated_materials: material.set_shader_parameter("scene_time", seconds)
	for entry in light_shafts:
		entry.node.rotation.z = -0.19 + sin(seconds * 0.19 + entry.phase) * 0.023
	for entry in jellyfish:
		var jelly: Node3D = entry.node
		var stroke: float = seconds * 2.0 + entry.phase
		var pulse: float = sin(stroke)
		# Slow current carries the animal while the contracted bell pushes up.
		jelly.position = entry.base + Vector3(sin(seconds * 0.19 + entry.phase) * 1.0, sin(seconds * 0.35 + entry.phase) * 0.45 + pulse * 0.11, sin(seconds * 0.14 + entry.phase) * 0.3)
		jelly.rotation.z = sin(seconds * 0.32 + entry.phase) * 0.08
		entry.bell.scale = Vector3(1.0 + pulse * 0.13, 1.0 - pulse * 0.20, 1.0 + pulse * 0.13)
		entry.tendrils.scale.y = 1.0 + sin(stroke - 0.70) * 0.11
	for entry in shoals:
		# Wrap beyond the visible window; the school never reverses unnaturally.
		var x: float = fposmod(entry.base.x * entry.direction + 18.0 + seconds * entry.speed, 36.0) - 18.0
		entry.node.position = Vector3(x * entry.direction, entry.base.y + sin(seconds * 0.41 + entry.phase) * 0.26, entry.base.z + sin(seconds * 0.17 + entry.phase) * 0.30)
		entry.node.rotation.z = sin(seconds * 0.41 + entry.phase) * 0.035 * entry.direction
	if not water_particles.is_empty():
		var multi: MultiMesh = water_particles.node.multimesh
		var visible: int = 10 if graphics_quality == "Low" else multi.instance_count
		for i in visible:
			var entry: Dictionary = water_particles.entries[i]
			var base: Vector3 = entry.base
			var y: float = fposmod(base.y + 10.0 + seconds * entry.speed, 11.8) - 10.0
			var at := Vector3(base.x + sin(seconds * 0.26 + entry.phase) * 0.35, y, base.z)
			multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
	for entry in sea_creatures:
		var x: float = fposmod(entry.base.x * entry.direction + 18.0 + seconds * entry.speed, 36.0) - 18.0
		entry.node.position = Vector3(x * entry.direction, entry.base.y + sin(seconds * 0.29 + entry.phase) * 0.34, entry.base.z)
		entry.node.rotation.z = sin(seconds * 0.18 + entry.phase) * 0.035
		if entry.kind == "manta":
			entry.left.rotation.x = sin(seconds * 1.2 + entry.phase) * 0.24
			entry.right.rotation.x = -sin(seconds * 1.2 + entry.phase) * 0.24

func apply_quality(value: String) -> void:
	super.apply_quality(value)
	var low: bool = graphics_quality == "Low"
	high_detail.visible = not low
	for node in expensive_scenery: node.visible = not low
	for entry in shoals: entry.node.multimesh.visible_instance_count = entry.low_count if low else -1
	if not water_particles.is_empty(): water_particles.node.multimesh.visible_instance_count = 10 if low else -1
	for floor in floor_nodes: floor.material_override = plain_floor if low else caustic_floor
	if ocean_key: ocean_key.shadow_enabled = not low
	# The gallery uses authored sheen; screen reflections would echo the HUD lane.
	if environment: environment.ssr_enabled = false
	_animate_ocean()

func _mesh(shape: Mesh, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material
	node.position = at
	(parent if parent else self).add_child(node)
	return node

func _box(size_value: Vector3, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size_value
	return _mesh(shape, at, material, parent)

func _cylinder(radius: float, height: float, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 32 if radius > 0.5 else 10
	return _mesh(shape, at, material, parent)

func _ellipsoid(scale_value: Vector3, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	shape.radial_segments = 24
	shape.rings = 12
	var result := _mesh(shape, at, material, parent)
	result.scale = scale_value
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result

func _rod(from: Vector3, to: Vector3, radius: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var rod := _cylinder(radius, from.distance_to(to), (from + to) * 0.5, material, parent)
	var up: Vector3 = (to - from).normalized()
	var right: Vector3 = up.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.1: right = up.cross(Vector3.RIGHT).normalized()
	rod.basis = Basis(right, up, right.cross(up).normalized())
	return rod

func _arc(at: Vector3, rx: float, ry: float, start: float, end: float, radius: float, material: Material, segments: int, parent: Node3D = null) -> void:
	# One tube mesh per arch avoids a separate draw for each brass segment.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in segments + 1:
		var a: float = lerpf(start, end, float(i) / segments)
		var tangent := Vector3(-sin(a) * rx, cos(a) * ry, 0).normalized()
		var radial := Vector3(tangent.y, -tangent.x, 0)
		var center := Vector3(cos(a) * rx, sin(a) * ry, 0)
		for j in 8:
			var b: float = j * TAU / 8.0
			var normal: Vector3 = radial * cos(b) + Vector3.BACK * sin(b)
			vertices.append(center + normal * radius)
			normals.append(normal)
	for i in segments:
		for j in 8:
			var a: int = i * 8 + j
			var b: int = i * 8 + (j + 1) % 8
			indices.append_array(PackedInt32Array([a, b, a + 8, b, b + 8, a + 8]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh(mesh, at, material, parent)

func _ring_xz(at: Vector3, radius: float, thickness: float, material: Material, segments: int, parent: Node3D = null) -> void:
	var ring := Node3D.new()
	(parent if parent else self).add_child(ring)
	ring.position = at
	ring.rotation.x = PI * 0.5
	_arc(Vector3.ZERO, radius, radius, 0, TAU, thickness, material, segments, ring)

func _poly_fin(points: Array[Vector3], material: Material, parent: Node3D) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, points.size() - 1):
		for point: Vector3 in [points[0], points[i], points[i + 1], points[0], points[i + 1], points[i]]:
			st.add_vertex(point)
	st.generate_normals()
	return _mesh(st.commit(), Vector3.ZERO, material, parent)
