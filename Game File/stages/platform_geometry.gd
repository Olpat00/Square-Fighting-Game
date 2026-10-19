extends RefCounted
## Small authored chamfers with independent planar normals. A planar cap must
## never share averaged normals with its side walls: that makes stone/metal
## platforms look inflated. Coordinates and UVs use meters, not unit-box scale.

static func beveled_box(size: Vector3, edge: float = 0.04, corner: float = 0.10) -> ArrayMesh:
	var half := size * 0.5
	var bevel: float = clampf(edge, 0.001, minf(half.y * 0.85, minf(half.x, half.z) * 0.40))
	var cut: float = clampf(corner, bevel + 0.001, minf(half.x, half.z) * 0.80)
	var upper := _ring(half.x - bevel, half.z - bevel, half.y, maxf(0.001, cut - bevel))
	var shoulder := _ring(half.x, half.z, half.y - bevel, cut)
	var heel := _ring(half.x, half.z, -half.y + bevel, cut)
	var lower := _ring(half.x - bevel, half.z - bevel, -half.y, maxf(0.001, cut - bevel))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var next: int = (i + 1) % 8
		_triangle(surface, Vector3(0, half.y, 0), upper[i], upper[next], Vector3.UP)
		_triangle(surface, Vector3(0, -half.y, 0), lower[next], lower[i], Vector3.DOWN)
		_quad(surface, upper[i], shoulder[i], upper[next], shoulder[next])
		_quad(surface, shoulder[i], heel[i], shoulder[next], heel[next])
		_quad(surface, heel[i], lower[i], heel[next], lower[next])
	surface.index()
	return surface.commit()

static func _ring(x: float, z: float, y: float, cut: float) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(-x + cut,y,-z), Vector3(x - cut,y,-z),
		Vector3(x,y,-z + cut), Vector3(x,y,z - cut),
		Vector3(x - cut,y,z), Vector3(-x + cut,y,z),
		Vector3(-x,y,z - cut), Vector3(-x,y,-z + cut)])

static func merge_parts(parent: Node3D) -> void:
	# Only use for static direct children with one surface and no external
	# references. The moving platform parent remains the animation anchor.
	var groups: Dictionary = {}
	for child in parent.get_children():
		if not child is MeshInstance3D: continue
		var part := child as MeshInstance3D
		var material: Material = part.material_override
		if material == null or part.mesh.get_surface_count() != 1: continue
		var key: int = material.get_instance_id()
		if not groups.has(key):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = {"surface": surface, "material": material}
		var surface: SurfaceTool = groups[key].surface
		surface.append_from(part.mesh,0,part.transform)
		parent.remove_child(part)
		part.free()
	for key in groups:
		var surface: SurfaceTool = groups[key].surface
		surface.index()
		var node := MeshInstance3D.new()
		node.name = "CraftedPlatformSurface"
		node.mesh = surface.commit()
		node.material_override = groups[key].material
		parent.add_child(node)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal: Vector3 = -(b - a).cross(c - a).normalized()
	_triangle(surface, a, b, c, normal)
	_triangle(surface, c, b, d, normal)

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	for point: Vector3 in [a,b,c]:
		surface.set_normal(normal)
		if absf(normal.y) >= maxf(absf(normal.x), absf(normal.z)):
			surface.set_uv(Vector2(point.x, point.z))
		elif absf(normal.z) >= absf(normal.x):
			surface.set_uv(Vector2(point.x, point.y))
		else:
			surface.set_uv(Vector2(point.z, point.y))
		surface.add_vertex(point)
