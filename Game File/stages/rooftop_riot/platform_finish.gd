extends RefCounted
## Runtime-authored platform finishes; the original hotel GLB stays intact.
const GEOMETRY = preload("res://stages/platform_geometry.gd")
const TIMBER = preload("res://stages/rooftop_riot/platform_timber.gdshader")

static func build(stage: Node3D) -> Node3D:
	var stone := _material(Color("88867a"),0.87)
	var dark := _material(Color("202b30"),0.73)
	var brass := _material(Color("a88852"),0.44,0.68)
	var light := _material(Color("e5c994"),0.54)
	var wood := ShaderMaterial.new()
	wood.shader = TIMBER
	wood.set_shader_parameter("timber_color",Color("805633"))
	var center: Node3D
	for index in 3:
		var width: float = 3.5 if index == 2 else 4.5
		var root := Node3D.new()
		root.name = "CraftedResortLift" if index == 2 else "CraftedResortTerrace%d" % index
		root.position = Vector3(0,5.5,0) if index == 2 else Vector3(-5.0 if index == 0 else 5.0,3.6,0)
		stage.add_child(root)
		_piece(root,Vector3(width,0.18,1.65),Vector3(0,-0.18,0),stone,0.025)
		_piece(root,Vector3(width-0.20,0.07,1.40),Vector3(0,-0.060,0),dark,0.009)
		for row in 7:
			for half in 2:
				var length: float = (width-0.27)*0.5
				_piece(root,Vector3(length-0.012,0.055,0.183),Vector3((half-0.5)*length,-0.0275,-0.57+row*0.19),wood,0.007)
		# Honed side coping, a bronze nosing, and a recessed slatted soffit.
		for side: float in [-1.0,1.0]:
			_piece(root,Vector3(0.095,0.085,1.52),Vector3(side*(width*0.5-0.05),-0.043,0),stone,0.012)
		_piece(root,Vector3(width-0.15,0.045,0.065),Vector3(0,-0.07,0.81),brass,0.008)
		_piece(root,Vector3(width-0.32,0.035,0.035),Vector3(0,-0.25,0.81),light,0.004)
		_piece(root,Vector3(width-0.40,0.19,1.12),Vector3(0,-0.345,0),dark,0.025)
		for rib in int(width/0.23):
			var x: float = -width*0.5+0.25+rib*0.23
			_piece(root,Vector3(0.058,0.16,0.045),Vector3(x,-0.35,0.59),brass,0.006)
		for side: float in [-1.0,1.0]:
			_piece(root,Vector3(0.13,0.24,0.44),Vector3(side*(width*0.5-0.34),-0.36,-0.24),stone,0.022)
		GEOMETRY.merge_parts(root)
		if index == 2: center = root
	# Give the main deck a stone fascia with actual recessed joints.
	var fascia := Node3D.new()
	fascia.name = "HonedResortFascia"
	stage.add_child(fascia)
	for index in 12:
		_piece(fascia,Vector3(1.47,0.27,0.075),Vector3(-8.25+index*1.5,-0.325,1.045),stone,0.017)
		_piece(fascia,Vector3(1.35,0.018,0.022),Vector3(-8.25+index*1.5,-0.20,1.087),brass,0.003)
	GEOMETRY.merge_parts(fascia)
	return center

static func _material(color: Color, roughness: float, metal: float=0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=roughness
	mat.metallic=metal
	return mat

static func _piece(parent: Node3D, size: Vector3, at: Vector3, material: Material, bevel: float) -> void:
	var node := MeshInstance3D.new()
	node.mesh=GEOMETRY.beveled_box(size,bevel,minf(0.065,size.z*0.15))
	node.material_override=material
	node.position=at
	parent.add_child(node)
