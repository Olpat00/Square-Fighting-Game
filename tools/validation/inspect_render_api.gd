extends SceneTree
func _initialize() -> void:
	for type: StringName in [&"Environment", &"DirectionalLight3D", &"ReflectionProbe", &"OmniLight3D"]:
		print(type)
		for property: Dictionary in ClassDB.class_get_property_list(type):
			var name_value: String = property.name
			if name_value.contains("tonemap") or name_value.contains("ssao") or name_value.contains("ssil") or name_value.contains("ssr") or name_value.contains("ambient") or name_value.contains("shadow") or name_value.contains("fog") or name_value.contains("glow") or name_value in ["intensity", "size", "origin_offset", "update_mode", "box_projection", "interior", "max_distance"]:
				print(name_value, " type=", property.type)
		for constant: StringName in ClassDB.class_get_integer_constant_list(type):
			if str(constant).contains("TONE_MAPPER"): print(constant, "=", ClassDB.class_get_integer_constant(type, constant))
	quit()
