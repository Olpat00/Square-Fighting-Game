extends Node3D
## Distant guests of the skyline; only presentation, no physics bodies.
var gulls: Array[Dictionary] = []

func _ready() -> void:
	name = "SkylineGulls"
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("617080")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i: int in 5:
		var bird := Node3D.new()
		bird.name = "DistantGull%d" % i
		add_child(bird)
		var body := MeshInstance3D.new()
		var body_mesh := SphereMesh.new()
		body_mesh.radius = 0.023
		body_mesh.height = 0.092
		body_mesh.radial_segments = 8
		body_mesh.rings = 4
		body.mesh = body_mesh
		body.material_override = material
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bird.add_child(body)
		var wings: Array[Node3D] = []
		for side: float in [-1.0, 1.0]:
			var hinge := Node3D.new()
			bird.add_child(hinge)
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			# Small tapered gull wings spread across screen X. The raised elbow
			# and narrow tips retain a recognizable V during long gliding phases.
			var root_point := Vector3(0, 0.012, 0)
			var elbow := Vector3(side * 0.085, 0.052, 0.006)
			var tip := Vector3(side * 0.18, 0.020, 0.012)
			var trailing := Vector3(side * 0.075, -0.002, -0.005)
			for vertex: Vector3 in [root_point, elbow, trailing, elbow, tip, trailing]:
				surface.set_normal(Vector3.BACK)
				surface.add_vertex(vertex)
			var wing := MeshInstance3D.new()
			wing.mesh = surface.commit()
			wing.material_override = material
			wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			hinge.add_child(wing)
			wings.append(hinge)
		gulls.append({"node": bird, "wings": wings, "phase": i * 1.27})
	animate(0.0, false)

func animate(seconds: float, low: bool) -> void:
	for i: int in gulls.size():
		var entry: Dictionary = gulls[i]
		var phase: float = entry.phase
		var travel: float = seconds * 0.049 + phase
		var bird: Node3D = entry.node
		bird.visible = not low or i < 2
		var depth: float = -27.0 - i * 2.8
		# Account for the normal 17-degree gameplay tilt. Simply raising a
		# distant bird puts it above the view; this keeps the flock in the sky
		# band above the terrace rail without crossing the fighting silhouettes.
		var sky_band: float = 5.18 + sin(seconds * 0.12 + phase) * 0.10 + i * 0.045
		var tilt: float = deg_to_rad(MatchCamera.TILT)
		var altitude: float = (sky_band + sin(tilt) * depth) / cos(tilt)
		bird.position = Vector3(-sin(travel) * 25.0, altitude, depth)
		bird.rotation.y = PI if cos(travel) >= 0.0 else 0.0
		bird.rotation.z = sin(travel) * -0.08
		# Long glides punctuated by several wingbeats; never a bobbing flat icon.
		var flap: float = sin(seconds * 7.2 + phase) * 0.34 * smoothstep(-0.35, 0.40, sin(seconds * 0.43 + phase))
		entry.wings[0].rotation.z = -flap
		entry.wings[1].rotation.z = flap
