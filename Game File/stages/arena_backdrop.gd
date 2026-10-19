class_name ArenaBackdrop
extends MeshInstance3D
## Infinite distant art; collision and animated midground remain stage-owned.
var framed_shader: Shader
var parallax_available: bool = false

func configure(texture: Texture2D, exposure: float = 0.8) -> void:
	name = "DistantArenaArtwork"
	mesh = QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = preload("res://stages/arena_backdrop.gdshader")
	material.set_shader_parameter("panorama", texture)
	material.set_shader_parameter("exposure", exposure)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position = Vector3(0, 0, -610)

func configure_living(kind: String) -> void:
	# Stage clocks own animation: pause and rematch never depend on shader TIME.
	material_override.set_shader_parameter("ambience_kind", {"ocean": 1, "foundry": 2}.get(kind, 0))

func set_scenery_time(seconds: float) -> void:
	material_override.set_shader_parameter("scenery_time", seconds)

func frame(camera: Camera3D) -> void:
	var rect: Vector2 = camera.get_viewport().get_visible_rect().size
	var aspect: float = rect.x / maxf(rect.y, 1.0)
	var distance: float = 610.0
	var height: float = camera.size if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 2.0 * tan(deg_to_rad(camera.fov * 0.5)) * distance
	var texture: Texture2D = material_override.get_shader_parameter("panorama")
	var art_aspect: float = float(texture.get_width()) / maxf(texture.get_height(), 1)
	var cover_height: float = maxf(height, height * aspect / art_aspect) * 1.055
	(mesh as QuadMesh).size = Vector2(art_aspect, 1) * cover_height
	global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(camera.h_offset, camera.v_offset, -distance))
	if framed_shader != material_override.shader:
		framed_shader = material_override.shader
		parallax_available = false
		for uniform: Dictionary in framed_shader.get_shader_uniform_list():
			if uniform.name == "parallax_offset": parallax_available = true
	if parallax_available:
		material_override.set_shader_parameter("parallax_offset", Vector2(clampf(camera.global_position.x * 0.001, -0.018, 0.018), clampf((8.0 - camera.global_position.y) * 0.0006, -0.018, 0.018)))
