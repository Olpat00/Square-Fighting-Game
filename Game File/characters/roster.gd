class_name RosterRegistry
extends RefCounted
## Discover Resource definitions recursively. Exported PCK remaps retain script paths.

const CONTENT_ROOT: String = "res://characters/definitions"

static func discover(content_root: String = CONTENT_ROOT) -> Array[FighterDefinition]:
	var roster: Array[FighterDefinition] = []
	var paths: Array[String] = []
	_collect_definitions(content_root, paths)
	paths.sort()
	var ids: Dictionary = {}
	for path: String in paths:
		var script: Script = load(path) as Script
		if script == null or not script.has_method("create"):
			continue
		var definition: FighterDefinition = script.call("create") as FighterDefinition
		if definition == null:
			push_error("Invalid fighter definition: %s" % path)
			continue
		var errors: PackedStringArray = definition.validate()
		if not errors.is_empty() or ids.has(definition.id):
			push_error("Cannot register %s: %s" % [path, "; ".join(errors) if not ids.has(definition.id) else "duplicate fighter ID"])
			continue
		ids[definition.id] = true
		roster.append(definition)
	return roster

static func by_id(fighter_id: String) -> FighterDefinition:
	for definition: FighterDefinition in discover():
		if definition.id == fighter_id:
			return definition
	return null

static func _collect_definitions(path: String, output: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		push_error("Fighter content folder is missing: %s" % path)
		return
	for file: String in directory.get_files():
		var normalized: String = file.trim_suffix(".remap")
		if normalized.ends_with(".gd") and not normalized.begins_with("_"):
			var candidate: String = path.path_join(normalized)
			if not output.has(candidate):
				output.append(candidate)
	for subfolder: String in directory.get_directories():
		if not subfolder.begins_with(".") and not subfolder.begins_with("_"):
			_collect_definitions(path.path_join(subfolder), output)
