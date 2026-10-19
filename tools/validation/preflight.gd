extends SceneTree

var frame_count: int = 0
var scene: Node3D

func _initialize() -> void:
	scene = Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.5, 5)
	scene.add_child(camera)
	var mesh := MeshInstance3D.new()
	mesh.mesh = TorusMesh.new()
	scene.add_child(mesh)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	scene.add_child(light)
	print("PREFLIGHT_VERSION=", Engine.get_version_info())
	print("PREFLIGHT_RENDERER=", RenderingServer.get_current_rendering_method())
	print("PREFLIGHT_GPU=", RenderingServer.get_video_adapter_name())
	print("PREFLIGHT_DISPLAY=", DisplayServer.get_name())

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 30:
		if DisplayServer.get_name() != "headless":
			root.get_texture().get_image().save_png("../evidence/preflight/godot_graphical.png")
		print("PREFLIGHT_OK frames=", frame_count)
		quit()
	return false
