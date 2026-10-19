class_name FighterAttackPresentation
extends Node3D
## Rendering only. The authored move and the skeleton remain authoritative.
## World-space histories follow the real hands/feet; no animation or hit volume
## is moved to make an effect look larger. All clocks are fixed combat ticks.

const RIBBON_SHADER = preload("res://presentation/shaders/attack_ribbon.gdshader")
const CHARGE_SHADER = preload("res://presentation/shaders/attack_charge.gdshader")
const SIGNATURES: Dictionary = {
	"momentum": {"index": 0, "color": Color("56c9e6"), "accent": Color("e0f8ff"), "width": 0.13, "life": 9},
	"encore": {"index": 1, "color": Color("f8aa43"), "accent": Color("ffedbd"), "width": 0.22, "life": 12},
	"commitment": {"index": 2, "color": Color("becbd0"), "accent": Color("f4baa0"), "width": 0.29, "life": 10},
	"fieldcraft": {"index": 3, "color": Color("95b693"), "accent": Color("e4c689"), "width": 0.20, "life": 11},
	"citations": {"index": 4, "color": Color("c8b5e9"), "accent": Color("faf0d7"), "width": 0.13, "life": 9},
	"trailblazer": {"index": 5, "color": Color("cda672"), "accent": Color("b2e3d4"), "width": 0.18, "life": 11},
	"sentinel": {"index": 6, "color": Color("87bee1"), "accent": Color("f7e9a5"), "width": 0.24, "life": 10},
	"shadowstep": {"index": 7, "color": Color("977cbb"), "accent": Color("e7d9b6"), "width": 0.15, "life": 13}
}

var actor: Node
var rig: Skeleton3D
var profile: Dictionary
var store: SettingsStore
var trail: MeshInstance3D
var sweep: MeshInstance3D
var charge: MeshInstance3D
var contact_light: OmniLight3D
var trail_material: ShaderMaterial
var sweep_material: ShaderMaterial
var charge_material: ShaderMaterial
var history: Array[Dictionary] = []
var bones: Dictionary = {}
var last_attack: int = -1
var last_window: int = -1
var clock_ticks: int = 0
var sweep_remaining: int = 0
var sweep_duration: int = 10
var sweep_transform := Transform3D.IDENTITY
var strength: float = 0.0
var is_low: bool = false
var trail_mesh := ArrayMesh.new()

func configure(fighter: Node, character_model: Node3D) -> void:
	actor = fighter
	profile = SIGNATURES.get(actor.definition.mechanic, SIGNATURES.momentum)
	is_low = actor.world.graphics_quality == "Low"
	store = actor.world.get_meta("presentation_settings") as SettingsStore if actor.world.has_meta("presentation_settings") else null
	rig = _find_skeleton(character_model)
	if rig:
		for bone_name: String in ["hand.L", "hand.R", "forearm.L", "forearm.R", "foot.L", "foot.R", "shin.L", "shin.R", "upper_arm.L", "upper_arm.R", "chest"]:
			var socket: String = actor.visual.presentation_profile.socket(bone_name) if actor.visual.presentation_profile else bone_name
			bones[bone_name] = rig.find_bone(socket)
	trail_material = _material(RIBBON_SHADER)
	sweep_material = _material(RIBBON_SHADER)
	charge_material = _material(CHARGE_SHADER)
	trail = _mesh_node("SkeletalMotionRibbon", trail_material)
	trail.mesh = trail_mesh
	sweep = _mesh_node("ContactWake", sweep_material)
	charge = _mesh_node("ChargeFilaments", charge_material)
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	sphere.radial_segments = 20 if is_low else 32
	sphere.rings = 12 if is_low else 20
	charge.mesh = sphere
	contact_light = OmniLight3D.new()
	contact_light.name = "AttackBounceLight"
	contact_light.light_color = profile.color
	contact_light.omni_range = 2.3
	contact_light.omni_attenuation = 2.5
	contact_light.light_cull_mask = 2
	contact_light.shadow_enabled = false
	contact_light.visible = false
	add_child(contact_light)

func _material(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("primary_color", profile.color)
	material.set_shader_parameter("accent_color", profile.accent)
	material.set_shader_parameter("signature", profile.index)
	return material

func _mesh_node(label: String, material: ShaderMaterial) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override = material
	add_child(node)
	# Stored vertices/transforms stay behind the limb when the fighter travels.
	node.top_level = true
	node.global_transform = Transform3D.IDENTITY
	node.visible = false
	return node

func _find_skeleton(node: Node) -> Skeleton3D:
	if node == null: return null
	if node is Skeleton3D: return node
	for child: Node in node.get_children():
		var found := _find_skeleton(child)
		if found: return found
	return null

func _limb_name(move_id: String) -> String:
	if move_id in ["air_forward", "air_up", "air_neutral", "tilt_down"]: return "foot.L"
	if move_id in ["air_back", "air_down"]: return "foot.R"
	if move_id in ["jab2", "tilt_up", "special_up"]: return "hand.R"
	if move_id == "dash": return "upper_arm.L"
	if move_id == "special_side" and actor.definition.mechanic in ["momentum", "sentinel", "trailblazer"]: return "upper_arm.L"
	return "hand.L"

func _bone_point(bone_name: String) -> Vector3:
	var index: int = int(bones.get(bone_name, -1))
	if rig and index >= 0:
		return rig.global_transform * rig.get_bone_global_pose(index).origin
	return actor.global_position + Vector3(actor.facing * 0.6, 1.1, 0.0)

func contact_limb(move_id: String) -> Vector3:
	return _bone_point(_limb_name(move_id))

func step(frozen: bool) -> void:
	if actor.state in ["ko", "eliminated"]:
		clear()
		return
	if frozen: return
	clock_ticks += 1
	is_low = actor.world.graphics_quality == "Low"
	var flashes: float = clampf(float(store.values.flashes), 0.0, 1.0) if store else 0.45
	var brightness: float = lerpf(0.28, 1.65, flashes)
	trail_material.set_shader_parameter("brightness", brightness)
	sweep_material.set_shader_parameter("brightness", brightness)
	charge_material.set_shader_parameter("brightness", brightness)
	var phase: float = float(clock_ticks) / 15.0
	trail_material.set_shader_parameter("phase", phase)
	sweep_material.set_shader_parameter("phase", phase)
	charge_material.set_shader_parameter("phase", phase)
	for sample: Dictionary in history: sample.life = int(sample.life) - 1
	while not history.is_empty() and int(history[0].life) <= 0: history.pop_front()
	sweep_remaining = maxi(0, sweep_remaining - 1)
	strength = move_toward(strength, 0.0, 0.09)
	charge.visible = false
	var move: MoveDefinition = actor.move
	var attacking: bool = actor.state == "attack" and move != null
	var charging: bool = actor.state == "charge" and move != null
	if attacking or charging:
		if last_attack != actor.attack_instance:
			last_attack = actor.attack_instance
			last_window = -1
			# A cancel starts a new distinct stroke, never a connector between limbs.
			history.clear()
		var limb: Vector3 = _bone_point(_limb_name(move.id))
		var charge_amount: float = float(actor.charge_ticks) / maxf(1.0, float(move.charge_max))
		var anticipation: float = clampf(float(actor.move_tick) / maxf(1.0, float(move.startup)), 0.0, 1.0)
		if charging or (actor.move_tick < move.startup and move.startup >= 12):
			var amount: float = 0.20 + charge_amount * 0.80 if charging else anticipation * 0.46
			charge.visible = true
			charge.basis = Basis.IDENTITY
			charge.global_position = limb
			charge.scale = Vector3.ONE * (0.75 + amount * 0.90)
			charge_material.set_shader_parameter("amount", amount)
			strength = amount * 0.24
		# Every damaging melee active window gets its own wake. Projectiles and
		# placed objects have their own renderer, so only their casting tell lives here.
		var melee: bool = not actor.world.abilities.suppresses_melee(move) and move.damage > 0.0
		var collecting: bool = move.is_active(actor.move_tick) or (actor.move_tick >= maxi(0, move.startup - 3) and actor.move_tick < move.startup)
		if melee and collecting:
			_add_sample(limb, move, charge_amount)
		if melee and move.is_active(actor.move_tick):
			strength = 0.65 + charge_amount * 0.30
			_present_striking_limb(move, limb, charge_amount)
			for index: int in move.active_windows.size():
				var window: Vector2i = move.active_windows[index]
				if actor.move_tick >= window.x and actor.move_tick <= window.y and last_window != index:
					last_window = index
					_start_sweep(move, charge_amount)
		contact_light.position = to_local(limb)
	else:
		last_window = -1
	# Fixed-tick decay preserves an impact frame throughout hitstop and pause.
	_render_history()
	sweep.visible = sweep_remaining > 0
	if sweep.visible:
		sweep.global_transform = sweep_transform
		var fade: float = float(sweep_remaining) / maxf(1.0, float(sweep_duration))
		sweep_material.set_shader_parameter("strength", pow(fade, 1.4))
	contact_light.visible = not is_low and flashes > 0.01 and strength > 0.01
	contact_light.light_energy = strength * flashes * 0.85

func _present_striking_limb(move: MoveDefinition, tip: Vector3, charge_amount: float) -> void:
	# A narrow shell of moving filaments conforms to the striking forearm or
	# shin during contact. Its translucent silhouette gives the stroke depth
	# even while hitstop holds a nearly straight punch.
	var limb_name: String = _limb_name(move.id)
	var base_name: String = limb_name.replace("hand.", "forearm.").replace("foot.", "shin.")
	var base: Vector3 = _bone_point(base_name)
	var length_value: float = base.distance_to(tip)
	charge.visible = true
	charge_material.set_shader_parameter("amount", 0.72 + charge_amount * 0.28)
	if length_value > 0.07:
		var direction: Vector3 = (tip - base).normalized()
		var width: float = (0.95 if move.input_action == "heavy" else 0.65) + charge_amount * 0.15
		charge.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, direction)) * Basis.from_scale(Vector3(width, length_value / 0.32 + 0.15, width)), base.lerp(tip, 0.65))
	else:
		charge.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.95), tip)

func _add_sample(point: Vector3, move: MoveDefinition, charge_amount: float) -> void:
	var width: float = float(profile.width) * (1.45 if move.input_action == "heavy" else 1.0) * (1.0 + charge_amount * 0.35)
	var lifetime: int = int(profile.life)
	if not history.is_empty():
		var distance: float = point.distance_to(history[-1].point)
		# Teleports and replacement/respawn poses must not connect across space.
		if distance > 2.5: history.clear()
		elif distance < 0.015: return
	history.append({"point": point, "life": lifetime, "initial": lifetime, "width": width})
	while history.size() > (8 if is_low else 13): history.pop_front()

func _render_history() -> void:
	trail.visible = history.size() >= 2
	if not trail.visible: return
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for index: int in history.size():
		var sample: Dictionary = history[index]
		var before: Vector3 = history[maxi(0, index - 1)].point
		var after: Vector3 = history[mini(history.size() - 1, index + 1)].point
		var tangent: Vector3 = (after - before).normalized()
		var across := Vector3(-tangent.y, tangent.x, 0.1).normalized()
		var progress: float = float(index) / float(maxi(1, history.size() - 1))
		var life: float = float(sample.life) / float(sample.initial)
		var width: float = float(sample.width) * lerpf(0.12, 1.0, progress)
		var point: Vector3 = sample.point + Vector3(0, 0, 0.04)
		vertices.append(point - across * width)
		vertices.append(point + across * width)
		uvs.append(Vector2(progress, 0.0))
		uvs.append(Vector2(progress, 1.0))
		colors.append(Color(1, 1, 1, life))
		colors.append(Color(1, 1, 1, life))
		if index > 0:
			var base: int = index * 2
			indices.append_array(PackedInt32Array([base - 2, base - 1, base, base, base - 1, base + 1]))
	_ribbon_mesh(vertices, uvs, colors, indices, trail_mesh)

func _start_sweep(move: MoveDefinition, charge_amount: float) -> void:
	# A small crescent at the authored contact point conveys weight and attack
	# direction. Its radius stays inside the collision envelope and fades quickly.
	var heavy: bool = move.input_action == "heavy" or move.damage >= 12.0
	var segments: int = 14 if is_low else 28
	var radius: float = move.hit_radius * (0.9 + charge_amount * move.charge_reach_scale)
	var center := Vector3(move.hit_offset.x * actor.facing, move.hit_offset.y, 0.20)
	if move.impact_offset.is_finite(): center = Vector3(move.impact_offset.x * actor.facing, move.impact_offset.y, 0.20)
	# Imported humans have different shoulder/arm proportions. Bias the visual
	# toward the real limb, then shrink its extent by the same displacement so
	# the decorative crescent still fits the authored attack envelope.
	var limb: Vector3 = _bone_point(_limb_name(move.id)) - actor.global_position
	var correction := Vector3(limb.x - center.x, limb.y - center.y, 0.0).limit_length(radius * 0.40)
	center += correction
	radius -= correction.length()
	var axis: float = deg_to_rad(35.0)
	if move.id.ends_with("up"): axis = PI * 0.5
	elif move.id.ends_with("down"): axis = -PI * 0.42
	elif move.id.ends_with("back"): axis = PI * 0.86
	elif move.id.begins_with("jab"): axis = 0.12 if move.id == "jab2" else -0.18
	var span: float = 2.10 if heavy else 1.65
	if move.id == "air_neutral": span = 3.9
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for index: int in range(segments + 1):
		var t: float = float(index) / float(segments)
		var angle: float = axis - span * 0.50 + t * span
		var direction := Vector3(cos(angle) * actor.facing, sin(angle), sin(t * PI) * 0.12)
		var width: float = float(profile.width) * (1.6 if heavy else 1.0) * sin(t * PI)
		vertices.append(center + direction * (radius - width))
		vertices.append(center + direction * radius)
		uvs.append(Vector2(t, 0.0))
		uvs.append(Vector2(t, 1.0))
		colors.append(Color(1, 1, 1, 0.83 if heavy else 0.66))
		colors.append(Color(1, 1, 1, 0.83 if heavy else 0.66))
		if index > 0:
			var base: int = index * 2
			indices.append_array(PackedInt32Array([base - 2, base - 1, base, base, base - 1, base + 1]))
	sweep.mesh = _ribbon_mesh(vertices, uvs, colors, indices)
	sweep_transform = Transform3D(Basis.IDENTITY, actor.global_position)
	sweep_duration = 12 if heavy else 8
	sweep_remaining = sweep_duration

func _ribbon_mesh(vertices: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, existing: ArrayMesh = null) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := existing if existing != null else ArrayMesh.new()
	if mesh.get_surface_count() > 0: mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func clear() -> void:
	history.clear()
	sweep_remaining = 0
	strength = 0.0
	last_attack = -1
	last_window = -1
	if trail: trail.visible = false
	if sweep: sweep.visible = false
	if charge: charge.visible = false
	if contact_light: contact_light.visible = false
