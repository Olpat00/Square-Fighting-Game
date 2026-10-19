class_name VerdantShrineStage
extends RooftopStage
## Authored rainforest sanctuary. The four combat planes are the only collision;
## roots, temple, water, foliage and falling water never obstruct recovery.

const STONE = preload("res://stages/verdant_shrine/shrine_stone.gdshader")
const BARK = preload("res://stages/verdant_shrine/ancient_bark.gdshader")
const LEAF = preload("res://stages/verdant_shrine/jungle_leaf.gdshader")
const ATMOSPHERE = preload("res://stages/verdant_shrine/atmosphere.gdshader")
const GEYSER = preload("res://stages/verdant_shrine/spirit_geyser.gdshader")
const BACKDROP_SCRIPT = preload("res://stages/arena_backdrop.gd")
const BACKDROP_SHADER = preload("res://stages/verdant_shrine/shrine_backdrop.gdshader")
const PLATFORM_GEOMETRY = preload("res://stages/platform_geometry.gd")

var shrine_materials: Dictionary = {}
var animated_materials: Array[ShaderMaterial] = []
var lush_batches: Array[MultiMeshInstance3D] = []
var high_detail: Array[Node3D] = []
var scenery_rng := RandomNumberGenerator.new()
var stone_noise := FastNoiseLite.new()
var firefly_batch: MultiMeshInstance3D
var firefly_origins: Array[Vector3] = []
var distant_art
var valley_birds: Array[MeshInstance3D] = []

func _ready() -> void:
	platforms = [
		{"id":0,"x":0.0,"width":20.0,"y":0.0,"previous_y":0.0},
		{"id":1,"x":-5.8,"width":4.0,"y":3.25,"previous_y":3.25},
		{"id":2,"x":5.8,"width":4.0,"y":3.25,"previous_y":3.25},
		{"id":3,"x":0.0,"width":4.0,"y":6.2,"previous_y":6.2,"base_y":6.2,"amplitude":0.65,"period_ticks":180.0}]
	event_rng.seed = seed_value
	scenery_rng.seed = 818204
	stone_noise.seed = 412
	stone_noise.frequency = 1.6
	_make_materials()
	_make_light()
	_make_backdrop()
	_make_dais()
	_make_foreground_garden()
	_make_atmosphere()
	_make_valley_birds()
	_make_geysers()
	_animate_scene(0.0)

func _make_backdrop() -> void:
	distant_art = BACKDROP_SCRIPT.new()
	distant_art.configure(preload("res://assets/arenas/verdant_shrine/backdrop.png"),0.84)
	distant_art.material_override.shader = BACKDROP_SHADER
	distant_art.material_override.set_shader_parameter("exposure",0.84)
	animated_materials.append(distant_art.material_override)
	add_child(distant_art)

func frame_horizon(camera: Camera3D) -> void:
	if distant_art: distant_art.frame(camera)

func _make_materials() -> void:
	for entry: Array in [
		["dais",Color("727b6e"),Color("485c34"),0.26],
		["edge",Color("939888"),Color("5e744a"),0.19],
		["paving_1",Color("858e80"),Color("556b43"),0.22],
		["paving_2",Color("a1a18a"),Color("67764e"),0.16],
		["paving_3",Color("757f76"),Color("486143"),0.29],
		["course_1",Color("636e60"),Color("435837"),0.27],
		["course_2",Color("7b806c"),Color("52633c"),0.25],
		["temple",Color("465b4c"),Color("38563c"),0.54],
		["cliff",Color("38493f"),Color("244638"),0.62],
		["far",Color("344f46"),Color("335344"),0.38]]:
		var mat := ShaderMaterial.new()
		mat.shader = STONE
		mat.set_shader_parameter("stone_color",entry[1])
		mat.set_shader_parameter("moss_color",entry[2])
		mat.set_shader_parameter("moss_amount",entry[3])
		shrine_materials[entry[0]] = mat
	var bark := ShaderMaterial.new()
	bark.shader = BARK
	shrine_materials.bark = bark
	shrine_materials.bronze = _standard(Color("8a8b4c"),0.53,0.30)
	shrine_materials.recess = _standard(Color("263d34"),0.97)
	shrine_materials.mortar = _standard(Color("354438"),0.97)
	shrine_materials.rune = _standard(Color("638f79"),0.66,0.12,0.035)
	shrine_materials.pollen = _standard(Color("c5d594"),0.6,0.0,0.45)
	for i in 4:
		var leaf := ShaderMaterial.new()
		leaf.shader = LEAF
		leaf.set_shader_parameter("leaf_color",[Color("204a31"),Color("3c6630"),Color("163f32"),Color("3a7050")][i])
		shrine_materials["leaf%d" % i] = leaf
		animated_materials.append(leaf)

func _standard(color: Color, roughness: float, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metal
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat

func _make_light() -> void:
	var world := WorldEnvironment.new()
	world.name = "RainforestAtmosphere"
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var palette := ProceduralSkyMaterial.new()
	palette.sky_top_color = Color("335750")
	palette.sky_horizon_color = Color("9cb29a")
	palette.ground_bottom_color = Color("1c3631")
	palette.ground_horizon_color = Color("7c9987")
	palette.sky_curve = 0.22
	palette.sun_angle_max = 2.0
	sky.sky_material = palette
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("aec4bc")
	environment.ambient_light_energy = 0.43
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_agx_contrast = 1.1
	environment.fog_enabled = true
	environment.fog_light_color = Color("668a79")
	environment.fog_density = 0.00035
	environment.fog_sky_affect = 0.32
	environment.glow_enabled = true
	environment.glow_intensity = 0.22
	environment.glow_hdr_threshold = 1.7
	environment.ssao_radius = 1.0
	environment.ssao_intensity = 1.0
	environment.ssil_intensity = 0.28
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "CanopySun"
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_color = Color("ffe9c3")
	sun.light_energy = 1.95
	sun.shadow_enabled = true
	sun.shadow_blur = 2.2
	sun.shadow_normal_bias = 0.35
	sun.directional_shadow_max_distance = 56
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name = "FighterLagoonBounce"
	fill.rotation_degrees = Vector3(-24,20,0)
	fill.light_color = Color("e2e8ed")
	fill.light_energy = 1.20
	fill.light_cull_mask = 2
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.name = "FighterCanopyRim"
	rim.rotation_degrees = Vector3(-30,145,0)
	rim.light_color = Color("bbd9c7")
	rim.light_energy = 0.48
	rim.light_cull_mask = 2
	add_child(rim)
	for x: float in [-8.0,8.0]:
		var bounce := OmniLight3D.new()
		bounce.name = "WaterDetailBounce"
		bounce.position = Vector3(x,-1.0,-5.0)
		bounce.light_color = Color("62b69c")
		bounce.light_energy = 0.75
		bounce.omni_range = 6.0
		add_child(bounce)

func _make_dais() -> void:
	var deck := Node3D.new()
	deck.name = "MossStoneFightingDais"
	add_child(deck)
	var blocks: Dictionary = {}
	# Each flagstone has its own bevel and a dark, recessed mortar bed. The
	# paving remains exactly on y = 0, including the two outer ledge stones.
	_stone_block(blocks,"mortar",Vector3(19.98,0.77,3.22),Vector3(0,-0.445,-0.25),0.04)
	_paving(blocks,20.0,3.48,-0.25,14,0.16)
	_masonry_course(blocks,20.0,3.22,-0.25,-0.315,0.30,13,0.0)
	_masonry_course(blocks,19.80,3.10,-0.25,-0.625,0.30,12,0.5)
	_stone_block(blocks,"temple",Vector3(19.50,0.11,2.99),Vector3(0,-0.825,-0.25),0.06)
	# Projecting stone corbels punctuate the lower cornice; they stay within
	# the ledges and never cover the approach to a recovery catch.
	for i in 13:
		var x: float = -9.12+i*1.52
		_stone_block(blocks,"course_2",Vector3(0.38,0.25,0.36),Vector3(x,-0.825,1.16),0.05)
		_carving(blocks,Vector3(x,-0.325,1.367),0.24,i)
	# A narrow inset under the light stone nosing carries the shrine's jade
	# motif without becoming a bright stripe across the combat surface.
	for i in 14:
		var x: float = -10.0+(i+0.5)*20.0/14.0
		_stone_block(blocks,"rune",Vector3(1.03,0.018,0.018),Vector3(x,-0.125,1.489),0.003)
	_finish_stonework(blocks,deck)
	# Sparse moss tongues hang from seams below the front lip. Their tips
	# stay below the playing surface, preserving hands, feet and attack cues.
	for cluster: float in [-8.5,-5.9,-1.9,3.1,6.6,8.9]:
		for i in 5:
			var at := Vector3(cluster+(i-2)*0.12,-0.14-i*0.026,1.46)
			var sprig := _mesh(_leaf_mesh(),at,shrine_materials["leaf%d" % (i%4)],deck)
			var size: float = 0.10+float(i%3)*0.035
			sprig.scale = Vector3(size*0.63,size,size)
			sprig.rotation_degrees = Vector3(72,12.0*(i-2),float(i-2)*13)
			sprig.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			high_detail.append(sprig)
	for side: float in [-1.0,1.0]:
		var base := Vector3(side*5.8,3.25,0)
		_platform("RootTerrace",base,4.0)
	center_visual = _platform("LevitatingHeartstone",Vector3(0,6.2,0),4.0)
	for x: float in [-1.1,0,1.1]:
		var pendant := _rock(Vector3(x,-0.53,-0.1),Vector3(0.25,0.34,0.30),shrine_materials.temple,center_visual)
		pendant.name = "HeartstonePendant"
	# Keep the existing short roots and the open recovery space beneath them.
	for x: float in [-7.7,-1.6,6.8]:
		_tube([Vector3(x,-0.76,0.4),Vector3(x-0.12,-1.03,0.45),Vector3(x+0.09,-1.44,0.46),Vector3(x-0.04,-1.84,0.43)],0.055,0.012,shrine_materials.bark)

func _platform(node_name: String, at: Vector3, width: float) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	add_child(root)
	var blocks: Dictionary = {}
	_stone_block(blocks,"mortar",Vector3(width-0.025,0.36,1.74),Vector3(0,-0.205,0),0.035)
	_paving(blocks,width,1.95,0.0,4,0.13)
	_masonry_course(blocks,width-0.035,1.75,0.0,-0.245,0.22,5,0.0)
	_stone_block(blocks,"temple",Vector3(width-0.30,0.10,1.62),Vector3(0,-0.405,0),0.08)
	for i in 5:
		var x: float = -width*0.40+i*width*0.20
		_carving(blocks,Vector3(x,-0.245,0.881),0.115,i+2)
		_stone_block(blocks,"course_2",Vector3(0.24,0.10,0.20),Vector3(x,-0.428,0.69),0.022)
	for i in 4:
		var x: float = -width*0.5+(i+0.5)*width/4.0
		_stone_block(blocks,"rune",Vector3(0.64,0.015,0.015),Vector3(x,-0.100,0.974),0.002)
	_finish_stonework(blocks,root)
	return root

func _paving(blocks: Dictionary, width: float, depth: float, center_z: float, columns: int, thickness: float) -> void:
	var pitch: float = width/columns
	var gap: float = 0.019
	for row in 2:
		# Shift the rear row by half a stone. End pieces still finish exactly
		# at the collision edge, while joints no longer form a tiled grid.
		var offset: float = pitch*0.5 if row == 1 else 0.0
		for i in columns+1:
			var left: float = maxf(-width*0.5,-width*0.5+i*pitch-offset)
			var right: float = minf(width*0.5,-width*0.5+(i+1)*pitch-offset)
			if right-left < 0.05: continue
			var left_gap: float = gap*0.5 if left > -width*0.5 else 0.0
			var right_gap: float = gap*0.5 if right < width*0.5 else 0.0
			left += left_gap
			right -= right_gap
			var tone: String = ["edge","paving_1","paving_2","paving_3"][(i*7+row*3)%4]
			var tile_depth: float = depth*0.5-gap*0.5
			var z: float = center_z+(depth*0.25+gap*0.25)*(1.0 if row == 0 else -1.0)
			_stone_block(blocks,tone,Vector3(right-left,thickness,tile_depth),Vector3((left+right)*0.5,-thickness*0.5,z),0.024+float((i+row)%3)*0.009)

func _masonry_course(blocks: Dictionary, width: float, depth: float, center_z: float, center_y: float, height: float, columns: int, stagger: float) -> void:
	var pitch: float = width/columns
	for i in columns+1:
		var left: float = maxf(-width*0.5,-width*0.5+i*pitch-stagger*pitch)
		var right: float = minf(width*0.5,-width*0.5+(i+1)*pitch-stagger*pitch)
		if right-left < 0.05: continue
		var tone: String = ["dais","course_1","course_2"][(i*5+int(stagger*2))%3]
		_stone_block(blocks,tone,Vector3(right-left-0.024,height,depth),Vector3((left+right)*0.5,center_y,center_z),0.023+float(i%3)*0.011)

func _carving(blocks: Dictionary, at: Vector3, size: float, index: int) -> void:
	# Dark incised stepped diamonds with a small aged-jade central chip.
	# These sit on the vertical stone face, entirely below the walking plane.
	for side: float in [-1.0,1.0]:
		_stone_block(blocks,"mortar",Vector3(size*0.15,size*0.62,0.009),at+Vector3(side*size*0.37,0,0),0.0)
		_stone_block(blocks,"mortar",Vector3(size*0.74,size*0.12,0.009),at+Vector3(0,side*size*0.30,0),0.0)
		_stone_block(blocks,"mortar",Vector3(size*0.13,size*0.28,0.009),at+Vector3(side*size*0.62,side*size*0.13,0),0.0)
	_stone_block(blocks,"rune",Vector3(size*0.23,size*0.38,0.014),at+Vector3(0,0.015 if index%2 == 0 else -0.015,0.002),0.01)

func _stone_block(blocks: Dictionary, kind: String, size: Vector3, at: Vector3, corner: float) -> void:
	var parts: Array = blocks.get(kind,[])
	parts.append({"size":size,"at":at,"corner":corner})
	blocks[kind] = parts

func _finish_stonework(blocks: Dictionary, parent: Node3D) -> void:
	# Merge masonry by material: dozens of individual stones cost one draw
	# per finish, instead of making every flagstone a separate render item.
	for kind: String in blocks:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part: Dictionary in blocks[kind]:
			var size: Vector3 = part.size
			var mesh: ArrayMesh = PLATFORM_GEOMETRY.beveled_box(size,minf(0.021,size.y*0.16),part.corner)
			surface.append_from(mesh,0,Transform3D(Basis.IDENTITY,part.at))
		var node := _mesh(surface.commit(),Vector3.ZERO,shrine_materials[kind],parent)
		node.name = "Masonry_"+kind

func _make_foreground_garden() -> void:
	var leaves: Array[Array] = [[],[],[],[]]
	# World-space growth only at the frame margins and beneath the dais. The
	# illustrated valley owns the distance; no opaque plane obscures its depth.
	for side: float in [-1.0,1.0]:
		_tube([Vector3(side*15.5,-5.2,-3),Vector3(side*14.0,-2.1,-4),Vector3(side*14.7,1.0,-5),Vector3(side*12.8,4.5,-6)],0.28,0.075,shrine_materials.bark)
		for i in 8:
			var angle: float = side*(0.2+i*0.19)
			var at := Vector3(side*(11.9+i*0.28),4.15-i*0.1,-7.0)
			for j in 4:
				var basis := Basis.from_euler(Vector3(0.3+j*0.18,angle+j*0.51,side*0.35))
				var size: float = 0.78+j*0.12
				leaves[(i+j)%4].append(Transform3D(basis.scaled(Vector3(size*0.48,size,size)),at))
		for i in 8:
			var at := Vector3(side*(12.7+i*0.68),-4.8-i*0.12,-4.5-i*0.23)
			for j in 7:
				var basis := Basis.from_euler(Vector3(-0.4,j*TAU/7+i,0.5))
				var size: float = 0.95+float((i+j)%4)*0.18
				leaves[(i+j)%4].append(Transform3D(basis.scaled(Vector3(size*0.48,size,size)),at))
	for i in 4:
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = _leaf_mesh()
		batch.instance_count = leaves[i].size()
		for j in batch.instance_count: batch.set_instance_transform(j,leaves[i][j])
		var node := MultiMeshInstance3D.new()
		node.name = "ShrineMarginFoliage%d" % i
		node.multimesh = batch
		node.material_override = shrine_materials["leaf%d" % i]
		add_child(node)
		lush_batches.append(node)

func _make_atmosphere() -> void:
	_mist(Vector3(0,-3.4,-6),Vector2(24,1.5),Color(0.38,0.57,0.62,0.035),false)
	# Separate drifting banks give the falls depth without veiling combat.
	_mist(Vector3(-8.5,-0.7,-14),Vector2(8.0,2.5),Color(0.57,0.72,0.69,0.075),false)
	_mist(Vector3(8.3,-0.2,-17),Vector2(7.0,2.8),Color(0.57,0.72,0.69,0.065),false)
	for info: Vector3 in [Vector3(-11.5,0.0,-8),Vector3(12.0,1.0,-10)]:
		var shaft := _mist(info,Vector2(1.2,9),Color(0.91,0.84,0.55,0.055),true)
		shaft.rotation.z = -0.36
		high_detail.append(shaft)
	var firefly := SphereMesh.new()
	firefly.radius = 0.021
	firefly.height = 0.042
	firefly.radial_segments = 6
	firefly.rings = 3
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = firefly
	batch.instance_count = 18
	for i in batch.instance_count:
		var at := Vector3(scenery_rng.randf_range(-21,21),scenery_rng.randf_range(-2.0,7.0),scenery_rng.randf_range(-9,-4))
		firefly_origins.append(at)
		batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,at))
	firefly_batch = MultiMeshInstance3D.new()
	firefly_batch.name = "WaterDetailPollen"
	firefly_batch.multimesh = batch
	firefly_batch.material_override = shrine_materials.pollen
	firefly_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(firefly_batch)
	high_detail.append(firefly_batch)

func _make_valley_birds() -> void:
	for i in 6:
		var quad := QuadMesh.new()
		quad.size = Vector2(0.54,0.24)
		var material := ShaderMaterial.new()
		material.shader = preload("res://stages/verdant_shrine/valley_bird.gdshader")
		material.set_shader_parameter("phase",i*1.27)
		animated_materials.append(material)
		var bird := _mesh(quad,Vector3(-18,6.7,-18),material)
		bird.name = "ValleySwallow%d" % i
		bird.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		valley_birds.append(bird)

func _make_geysers() -> void:
	for x: float in [-8.0,8.0]:
		var well := CylinderMesh.new()
		well.top_radius = 0.29
		well.bottom_radius = 0.29
		well.height = 0.023
		well.radial_segments = 24
		_mesh(well,Vector3(x,0.012,0),shrine_materials.recess)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.28
		ring.outer_radius = 0.35
		ring.rings = 24
		ring.ring_segments = 8
		_mesh(ring,Vector3(x,0.012,0),shrine_materials.bronze)
		for is_warning: bool in [true,false]:
			var mat := ShaderMaterial.new()
			mat.shader = GEYSER
			mat.set_shader_parameter("warning",is_warning)
			animated_materials.append(mat)
			var quad := QuadMesh.new()
			quad.size = Vector2(1.8,1.5) if is_warning else Vector2(1.8,2.15)
			var effect := _mesh(quad,Vector3(x,0.04,0) if is_warning else Vector3(x,1.085,0.06),mat)
			effect.name = "SpiritWellWarning" if is_warning else "SpiritGeyser"
			effect.visible = false
			effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if is_warning:
				effect.rotation.x = -PI*0.5
				hazard_warnings.append(effect)
			else: hazard_flames.append(effect)

func step() -> void:
	super.step()
	_animate_scene(tick/60.0)

func reset_match(new_seed: int) -> void:
	super.reset_match(new_seed)
	_animate_scene(0.0)

func _animate_scene(seconds: float) -> void:
	for material: ShaderMaterial in animated_materials: material.set_shader_parameter("scene_time",seconds)
	for i in valley_birds.size():
		# A small flock crosses the valley, then leaves a long quiet interval.
		var flight: float = fposmod(seconds+i*0.72+4.0,42.0)
		var bird: MeshInstance3D = valley_birds[i]
		bird.visible = flight < 19.0 and (graphics_quality != "Low" or i < 3)
		bird.position = Vector3(lerpf(-19.0,19.0,flight/19.0),1.15+float(i%3)*0.27+sin(flight*0.27+i)*0.44,-19.0-i*0.4)
		bird.rotation.z = sin(flight*0.27+i)*0.085
	if graphics_quality != "Low" and firefly_batch:
		for i in firefly_origins.size():
			var at: Vector3 = firefly_origins[i]+Vector3(sin(seconds*0.22+i)*0.45,sin(seconds*0.37+i*0.62)*0.24,0)
			firefly_batch.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,at))

func apply_quality(value: String) -> void:
	super.apply_quality(value)
	var low: bool = graphics_quality == "Low"
	for node: Node3D in high_detail: node.visible = not low
	for node: MultiMeshInstance3D in lush_batches:
		node.multimesh.visible_instance_count = node.multimesh.instance_count/3 if low else -1
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if low else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Low retains flowing falls, three birds, mist and reduced foliage sway.
	_animate_scene(tick/60.0)
	if environment:
		environment.ssr_enabled = false
		environment.fog_density = 0.00035

func _mist(at: Vector3, size: Vector2, color: Color, shaft: bool) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var material := ShaderMaterial.new()
	material.shader = ATMOSPHERE
	material.set_shader_parameter("tint",color)
	material.set_shader_parameter("shaft",shaft)
	animated_materials.append(material)
	var node := _mesh(quad,at,material)
	node.name = "CanopyShaft" if shaft else "RiverMist"
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func _glyph(at: Vector3, size: float, index: int, parent: Node3D) -> void:
	# Repeating geometric incisions form a hand-authored river-and-leaf language.
	for offset: Vector3 in [Vector3(-0.48,0,0),Vector3(0.48,0,0),Vector3(0,0.38,0),Vector3(0,-0.38,0)]:
		var glyph := _box(Vector3(size*0.65,size*0.13,0.022),at+offset*size,shrine_materials.bronze,parent)
		glyph.rotation.z = PI*0.25 if (index+int(offset.x*10))%2 == 0 else -PI*0.25

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
	return _mesh(mesh,at,material,parent)

func _slab(size: Vector3, bevel: float, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh: ArrayMesh = PLATFORM_GEOMETRY.beveled_box(size,minf(0.035,size.y*0.22),bevel)
	return _mesh(mesh,at,material,parent)

func _rock(at: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 20
	sphere.rings = 12
	var arrays: Array = sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var p: Vector3 = vertices[i]
		var amount: float = 0.86+stone_noise.get_noise_3d(p.x*2+at.x,p.y*2+at.y,p.z*2+at.z)*0.22
		p *= amount
		p.y = minf(p.y,0.70+p.x*0.14)
		vertices[i] = p
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TANGENT] = null
	var raw := ArrayMesh.new()
	raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var st := SurfaceTool.new()
	st.create_from(raw,0)
	st.generate_normals()
	var node := _mesh(st.commit(),at,material,parent)
	node.scale = size
	return node

func _tube(points: Array[Vector3], radius_start: float, radius_end: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var curve := Curve3D.new()
	for i in points.size():
		var tangent: Vector3 = (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)])*0.18
		curve.add_point(points[i],-tangent,tangent)
	curve.bake_interval = 0.55
	var path: PackedVector3Array = curve.get_baked_points()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in path.size():
		var forward: Vector3 = (path[mini(i+1,path.size()-1)]-path[maxi(i-1,0)]).normalized()
		var axis: Vector3 = forward.cross(Vector3.FORWARD).normalized()
		if axis.length_squared() < 0.1: axis = Vector3.RIGHT
		var other: Vector3 = forward.cross(axis).normalized()
		var radius: float = lerpf(radius_start,radius_end,float(i)/(path.size()-1))
		var ring := PackedVector3Array()
		for j in 8:
			var angle: float = j*TAU/8.0
			ring.append(path[i]+(axis*cos(angle)+other*sin(angle))*radius)
		rings.append(ring)
	for i in rings.size()-1:
		for j in 8:
			var k: int = (j+1)%8
			for p: Vector3 in [rings[i][j],rings[i+1][j],rings[i][k],rings[i][k],rings[i+1][j],rings[i+1][k]]: surface.add_vertex(p)
	surface.generate_normals()
	return _mesh(surface.commit(),Vector3.ZERO,material,parent)

func _leaf_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var t0: float = i/7.0
		var t1: float = (i+1)/7.0
		for side: float in [-1.0,1.0]:
			var a := Vector3(0,sin(t0*PI)*0.18,t0*1.8)
			var b := Vector3(side*sin(t0*PI)*0.48,sin(t0*PI)*0.03,t0*1.8)
			var c := Vector3(0,sin(t1*PI)*0.18,t1*1.8)
			var d := Vector3(side*sin(t1*PI)*0.48,sin(t1*PI)*0.03,t1*1.8)
			var points: Array[Vector3] = [a,b,c,d]
			var uv: Array[Vector2] = [Vector2(0.5,t0),Vector2(0.5+side*0.5,t0),Vector2(0.5,t1),Vector2(0.5+side*0.5,t1)]
			for index in [0,2,1,1,2,3]:
				surface.set_uv(uv[index])
				surface.add_vertex(points[index])
	surface.generate_normals()
	return surface.commit()
