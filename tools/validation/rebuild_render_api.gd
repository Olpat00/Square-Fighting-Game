extends SceneTree
func _initialize() -> void:
	for method: Dictionary in ClassDB.class_get_method_list("RenderingServer"):
		if "render_time" in str(method.name): print(method.name, " ", method.args)
	quit()
