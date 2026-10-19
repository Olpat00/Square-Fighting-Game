class_name FighterVisual
extends Node3D

var actor: Node
var animation_player: AnimationPlayer
var current_clip: String = ""
var model: Node3D
var marker: Label3D
var ring: MeshInstance3D
var shield_mesh: MeshInstance3D
var imported_clips: Dictionary = {}
var result_win_pending: bool = false
var result_flourish_remaining: float = 0.0
var loaded_model_path: String = ""
var attack_presentation: FighterAttackPresentation
var presentation_profile: FighterPresentationProfile
var foot_plant: FighterFootPlant
var semantic_clip: String = ""
var last_blend_seconds: float = 0.0

func configure(fighter: Node) -> void:
	actor = fighter
	presentation_profile = actor.definition.presentation.duplicate(true) as FighterPresentationProfile
	presentation_profile.load_metadata("res://assets/characters/%s_presentation.json" % actor.definition.id)
	loaded_model_path = actor.definition.model_path
	if actor.world.graphics_quality == "Low" and not actor.definition.low_model_path.is_empty() and ResourceLoader.exists(actor.definition.low_model_path):
		loaded_model_path = actor.definition.low_model_path
	if ResourceLoader.exists(loaded_model_path):
		model = load(loaded_model_path).instantiate()
		add_child(model)
		_light_character(model)
		animation_player = _find_player(model)
		if animation_player:
			animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			for animation in animation_player.get_animation_list():
				imported_clips[str(animation).get_slice("/", str(animation).get_slice_count("/") - 1)] = animation
		var skeleton: Skeleton3D = _find_skeleton(model)
		if skeleton:
			foot_plant = FighterFootPlant.new()
			foot_plant.configure(skeleton, actor, presentation_profile)
	else:
		push_warning("Runtime model still pending: " + actor.definition.model_path)
	marker = Label3D.new()
	marker.text = "P%d" % (actor.slot + 1)
	marker.font_size = 40
	marker.outline_size = 10
	marker.modulate = actor.player_color
	marker.position.y = 2.22
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	add_child(marker)
	ring = _ground_marker(actor.player_color)
	ring.position.y = 0.018
	shield_mesh = _shield(actor.player_color)
	shield_mesh.position.y = 0.95
	shield_mesh.visible = false
	attack_presentation = FighterAttackPresentation.new()
	add_child(attack_presentation)
	attack_presentation.configure(actor, model)

func _ground_marker(color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.83, 0.83)
	var material := ShaderMaterial.new()
	material.shader = preload("res://presentation/shaders/fighter_marker.gdshader")
	material.set_shader_parameter("player_color", color)
	mesh.material = material
	instance.mesh = mesh
	instance.rotation.x = -PI / 2.0
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _shield(color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 48
	mesh.rings = 24
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://presentation/shaders/fighter_shield.gdshader")
	mat.set_shader_parameter("shield_color", color)
	mesh.material = mat
	instance.mesh = mesh
	instance.scale = Vector3(1.25, 1.55, 1.25)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _light_character(node: Node) -> void:
	# Dedicated portrait fill separates the supplied people from the environment
	# without flattening the architectural shadows. This changes rendering only.
	if node is MeshInstance3D:
		node.layers = 2
	for child in node.get_children(): _light_character(child)

func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found:
			return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child: Node in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found: return found
	return null

func play(clip: String, duration_ticks: int = 0, loop: bool = false) -> void:
	var resolved: String = str(actor.definition.animation_profile.get(clip, clip))
	if not imported_clips.has(resolved) or not animation_player:
		return
	var full_name: String = imported_clips[resolved]
	if current_clip == full_name and loop:
		return
	var previous_clip: String = semantic_clip
	var gait_change: bool = previous_clip in ["walk", "run"] and clip in ["walk", "run"]
	var previous_phase: float = fposmod(animation_player.current_animation_position / maxf(0.001, animation_player.current_animation_length), 1.0) if gait_change else 0.0
	if foot_plant:
		foot_plant.restore()
		if not gait_change: foot_plant.anchors.clear()
	current_clip = full_name
	semantic_clip = clip
	var animation := animation_player.get_animation(full_name)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	last_blend_seconds = presentation_profile.blend_for(previous_clip, clip, actor.definition.moves.has(clip))
	# Landing compression is visual and can settle beyond the actionable landing ticks.
	if clip in ["land_soft", "land_hard"]: duration_ticks = maxi(duration_ticks, 11 if clip == "land_soft" else 14)
	animation_player.play(full_name, last_blend_seconds)
	animation_player.speed_scale = animation.length / (float(duration_ticks) / 60.0) if duration_ticks > 0 else 1.0
	# A new attack/charge release owns a new move clock even when clip names match.
	animation_player.seek(previous_phase * animation.length if gait_change else 0.0, true)
	animation_player.advance(0)

func present_result(won: bool, at: Vector3) -> void:
	# The result is already authoritative. Only this visual child is staged;
	# fighter position, stocks and KO attribution remain untouched.
	global_position = at
	if foot_plant: foot_plant.clear()
	visible = true
	ring.visible = false
	shield_mesh.visible = false
	if attack_presentation: attack_presentation.clear()
	marker.modulate.a = 1.0
	if model: model.rotation.y = 0.0
	result_win_pending = won
	result_flourish_remaining = 70.0 / 60.0 if won else 0.0
	play("final_ko" if won else "lose", 70 if won else 100, not won)

func step_result(delta: float) -> void:
	if result_win_pending:
		result_flourish_remaining -= delta
		if result_flourish_remaining <= 0:
			result_win_pending = false
			play("win", 100, true)
	if animation_player: animation_player.advance(delta)

func step(frozen: bool) -> void:
	if model and not frozen:
		model.rotation.y = lerp_angle(model.rotation.y, actor.facing * PI / 2.0, 1.0 - exp(-presentation_profile.turn_response * CombatTuning.DT))
	visible = actor.state != "eliminated" and actor.state != "ko"
	shield_mesh.visible = actor.state == "shield" or actor.state == "shield_stun"
	if shield_mesh.visible:
		shield_mesh.scale = Vector3(1.3, 1.7, 1.3) * lerpf(0.65, 1.0, actor.shield / actor.definition.shield_max)
	ring.visible = actor.grounded
	marker.modulate.a = 0.5 + 0.5 * sin(actor.world.tick * 0.3) if actor.invulnerability > 0 else 1.0
	if not frozen and animation_player:
		if actor.state == "charge" and actor.move != null and animation_player.current_animation_position >= float(actor.move.startup - 2) / 60.0:
			attack_presentation.step(false)
			return
		if foot_plant: foot_plant.restore()
		if actor.state in ["idle", "air"] and actor.grounded and (current_clip.ends_with("run") or current_clip.ends_with("walk")):
			var stride: float = presentation_profile.stride(semantic_clip)
			animation_player.speed_scale = clampf(absf(actor.velocity.x) * animation_player.current_animation_length / stride, 0.05, 3.5)
		animation_player.advance(CombatTuning.DT)
		if foot_plant:
			var phase: float = fposmod(animation_player.current_animation_position / maxf(0.001, animation_player.current_animation_length), 1.0)
			foot_plant.apply(semantic_clip, phase, actor.grounded, actor.support_id, actor.velocity)
	if attack_presentation: attack_presentation.step(frozen)
