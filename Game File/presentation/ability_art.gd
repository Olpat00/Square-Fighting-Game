class_name AbilityArt
extends RefCounted

# Visual geometry only. Positions, duration, collision, ownership and damage
# are owned by AbilityController. No process(), timers, randomness or TIME:
# every layer advances with the same fixed tick as its combat object.
const SURFACE = preload("res://presentation/shaders/ability_surface.gdshader")
const FILAMENT = preload("res://presentation/shaders/ability_filament.gdshader")
static var materials: Dictionary = {}
const SIGNATURE_INDEX: Dictionary = {"momentum": 0, "encore": 1, "commitment": 2, "fieldcraft": 3, "citations": 4, "trailblazer": 5, "sentinel": 6, "shadowstep": 7}

static func sequence_art(mechanic: String, color: Color, flashes: float, low: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "ConfirmedUltimate"
	root.set_meta("identity", mechanic)
	var motion := _group(root, "SequenceMotion")
	var energy: Material = _energy(color.lerp(Color("dfeced"), 0.32), flashes, 0.90)
	match mechanic:
		"momentum":
			for index: int in range(4 if low else 7):
				var a: float = index * TAU / (4.0 if low else 7.0)
				var helix := _group(motion, "PressureHelix%d" % index)
				helix.rotation.y = (index - 3) * 0.085
				_arc(helix, 0.84 + index * 0.026, a, a + 1.55, 0.047, -0.12 + index * 0.047, energy, 32, true)
				_arc(helix, 0.80 + index * 0.026, a + 0.1, a + 1.38, 0.013, 0.09, energy, 24, true)
			for index: int in range(4):
				_line(motion, Vector3(-1.28, -0.53 + index * 0.36, -0.1), Vector3(0.1, -0.40 + index * 0.26, -0.1), 0.036, energy, true)
		"commitment":
			_heavy(motion, color, flashes, low)
			motion.scale = Vector3.ONE * 2.9
			motion.rotation.x = -PI * 0.5
			var steel: Material = _surface(Color("9d9381"), 0.50, 0.43)
			for index: int in range(4 if low else 7):
				var a: float = index * TAU / (4.0 if low else 7.0)
				var flake := _diamond(root, _polar(0.78, a, 0.08), Vector3(0.085, 0.19, 0.032), steel)
				flake.rotation.z = a
				flake.set_meta("rest", flake.position)
				flake.set_meta("drift", _polar(0.50, a, 0.17))
		"citations":
			_citation(motion, color, flashes, low, true)
			motion.scale = Vector3(1.2, 1.65, 1.0)
			for index: int in range(3):
				var y: float = -0.69 + index * 0.68
				_line(root, Vector3(-0.93, y, -0.08), Vector3(0.88, y + 0.15, -0.08), 0.022, energy, true)
		"trailblazer":
			_compass(motion, color, flashes, low)
			motion.scale = Vector3.ONE * 2.9
			motion.rotation.x = -PI * 0.5
			var brass: Material = _surface(Color("b7a078"), 0.52, 0.35)
			var path: Array[Vector3] = [Vector3(-0.87, -0.68, -0.05), Vector3(-1.06, -0.1, -0.12), Vector3(-0.74, 0.45, -0.05), Vector3(-0.18, 0.94, -0.12), Vector3(0.62, 0.62, -0.1), Vector3(1.06, -0.10, -0.09)]
			_tube(root, path, 0.011, brass, 6)
			for index: int in range(path.size()):
				var marker := _diamond(root, path[index], Vector3(0.07, 0.11, 0.025), brass)
				marker.rotation.z = index * 0.6
			for index: int in range(3):
				_line(root, path[index * 2], path[index * 2 + 1], 0.021, energy, true)
		"shadowstep":
			var dark: Material = _surface(Color("353044"), 0.45, 0.27)
			for index: int in range(3 if low else 5):
				var a: float = index * TAU / (3.0 if low else 5.0)
				var blade := _group(motion, "VeilBlade%d" % index)
				blade.rotation.z = a
				blade.position.z = -0.10 + index * 0.037
				_arc(blade, 0.97, -0.42, 0.36, 0.045, 0, dark, 24)
				_arc(blade, 1.019, -0.4, 0.34, 0.023, 0.01, energy, 24, true)
				_line(blade, Vector3(0.95, -0.22, 0), Vector3(0.53, 0.22, 0), 0.018, energy, true)
	# The transparent central opening keeps the captive and attack pose readable.
	# Geometry and its procedural wisps share the sequence's combat clock.
	_field(motion, Vector2(2.1, 2.1) if mechanic not in ["commitment", "trailblazer"] else Vector2(0.94, 0.94), mechanic, color, flashes, 0.70)
	return root

static func animate_sequence(root: Node3D, sequence: Dictionary) -> void:
	var age: float = clampf(float(sequence.age) / maxi(1, int(sequence.duration)), 0, 1)
	var identity: String = str(root.get_meta("identity", ""))
	var target_position: Vector3 = sequence.target.position
	root.position = target_position + Vector3(0, 0.95, -0.06)
	root.rotation.y = PI if int(sequence.facing) < 0 else 0.0
	var motion: Node3D = root.get_node("SequenceMotion")
	if identity in ["commitment", "trailblazer"]:
		motion.position.y = float(sequence.owner.position.y) - target_position.y - 0.92
		motion.rotation.z = age * 0.30
	else:
		motion.rotation.z = age * (0.40 if identity == "shadowstep" else 0.23 if identity == "momentum" else 0.0)
		var amount: float = 0.88 + smoothstep(0, 0.70, age) * 0.12
		motion.scale = Vector3.ONE * amount if identity != "citations" else Vector3(1.2, 1.65, 1) * amount
	_animate_details(root, age)

static func polish_prop(node: Node3D, type: String) -> void:
	if type not in ["log", "tree_prop", "plank", "branch"]: return
	if node is MeshInstance3D and node.mesh != null:
		for index: int in range(node.mesh.get_surface_count()):
			var original: Material = node.get_active_material(index)
			if original == null: continue
			var label: String = original.resource_name.to_lower()
			if "bark" in label or "grain" in label:
				node.set_surface_override_material(index, _surface(Color("574838") if "endgrain" not in label else Color("a99473"), 0.0, 0.91, 4 if "endgrain" not in label else 1))
			elif "needles" in label:
				node.set_surface_override_material(index, _surface(Color("374937"), 0.0, 0.89, 3))
	for child: Node in node.get_children():
		if child is Node3D: polish_prop(child, type)

static func make(type: String, mechanic: String, ability: String, color: Color, flashes: float, low: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "AuthoredAbility"
	root.set_meta("art_identity", mechanic)
	root.set_meta("art_type", type)
	root.set_meta("art_ability", ability)
	root.set_meta("art_low", low)
	match type:
		"ring":
			match mechanic:
				"sentinel": _sentinel(root, color, flashes, low, ability == "sentinel_pulse")
				"shadowstep": _shadow(root, color, flashes, low, ability != "gentleman_arc")
				"commitment": _heavy(root, color, flashes, low)
				"trailblazer": _compass(root, color, flashes, low)
				_: _pressure(root, color, flashes, low)
		"hook": _grapnel(root, color, flashes, low)
		"trap": _trap(root, color, flashes, low)
		"precision_line": _citation(root, color, flashes, low, false)
		"geometry_impact":
			if mechanic == "sentinel": _containment(root, color, flashes, low)
			else: _citation(root, color, flashes, low, true)
		"ribbon": _solar_ribbon(root, color, flashes, low)
		"step": _paper_step(root, color, flashes, low)
		_:
			root.free()
			return null
	match type:
		"ring": _field(root, Vector2(0.98, 0.98), mechanic, color, flashes)
		"ribbon": _field(root, Vector2(1.55, 1.55), "encore", color, flashes, 0.82)
		"geometry_impact": _field(root, Vector2(2.05, 1.32), mechanic, color, flashes, 0.62)
		"precision_line":
			var beam := _field(root, Vector2(1.16, 0.48), "citations", color, flashes, 0.74)
			beam.position.x = -0.05
		"hook":
			var glint := _field(root, Vector2(0.37, 0.37), "trailblazer", color, flashes, 0.32)
			glint.position.x = 0.015
	return root

static func decorate(root: Node3D, type: String, color: Color, flashes: float, low: bool) -> void:
	# Retain the authored prop silhouettes and supplement their readable edge
	# detail. Accessories live with the prop and cannot survive its cleanup.
	var detail := Node3D.new()
	detail.name = "PropDetail"
	var gold: Material = _surface(Color("ba8d38"), 0.82, 0.27)
	var pale: Material = _energy(color.lerp(Color("fff1c1"), 0.40), flashes)
	if type == "disc":
		for radius: float in [0.22, 0.29, 0.36, 0.435]:
			_arc(detail, radius, 0, TAU, 0.007, 0.085, gold, 36)
		for index: int in range(8 if low else 16):
			var angle: float = index * TAU / (8.0 if low else 16.0)
			var ray: MeshInstance3D = _box(detail, Vector3(0.085, 0.018, 0.012), _polar(0.415, angle, 0.091), gold)
			ray.rotation.z = angle
		_arc(detail, 0.465, -0.35, 1.05, 0.022, 0.03, pale, 20, true)
		_arc(detail, 0.49, 2.80, 4.20, 0.014, -0.025, pale, 20, true)
	elif type == "reflector":
		for index: int in range(3):
			_arc(detail, 0.14 + index * 0.055, -0.05, PI + 0.05, 0.009, 0.10, pale, 24, true)
		for side: int in [-1, 1]:
			_box(detail, Vector3(0.10, 0.045, 0.22), Vector3(side * 0.36, -0.085, 0), gold)
	elif type == "plank":
		# Inlays stay below the authored board top: the sliding character's
		# shoes and the original support clearance remain exact.
		var grain: Material = _surface(Color("644529"), 0.0, 0.86, 1)
		var iron: Material = _surface(Color("5b625e"), 0.76, 0.49)
		for index: int in range(3):
			_box(detail, Vector3(1.40, 0.002, 0.012), Vector3(0, 0.047, -0.15 + index * 0.15), grain)
		for side: int in [-1, 1]:
			for edge: int in [-1, 1]:
				_box(detail, Vector3(0.025, 0.007, 0.025), Vector3(side * 0.65, 0.043, edge * 0.17), iron)
	elif type in ["log", "tree_prop", "branch"]:
		var bark: Material = _surface(Color("7d542c"), 0.0, 0.86, 1)
		var moss: Material = _surface(Color("415032"), 0.0, 0.96, 3)
		var count: int = 4 if low else 8
		for index: int in range(count):
			var a: float = index * TAU / count
			var chip := _box(detail, Vector3(0.13, 0.034, 0.052), _polar(0.50 if type == "log" else 0.28, a, 0.13), bark if index % 3 else moss)
			chip.rotation = Vector3(index * 0.3, index * 0.61, a)
			chip.set_meta("drift", Vector3(cos(a), sin(a) * 0.5 + 0.5, 0.12) * 0.2)
			chip.set_meta("rest", chip.position)
		if type == "log":
			for radius: float in [0.10, 0.17, 0.25, 0.33]:
				_arc(detail, radius, 0, TAU, 0.006, 0.338, bark, 30)
	elif type == "chair":
		var steel: Material = _surface(Color("8a969b"), 0.86, 0.25)
		for side: int in [-1, 1]:
			_box(detail, Vector3(0.035, 0.045, 0.06), Vector3(side * 0.25, 0.52, 0.19), steel)
	else:
		detail.free()
		return
	if type in ["disc", "reflector"]:
		_field(detail, Vector2(1.10, 1.10) if type == "disc" else Vector2(0.92, 0.80), "encore", color, flashes, 0.66)
	elif type in ["log", "tree_prop", "branch"]:
		# Dust and chips follow the timber instead of turning it into a glowing orb.
		var dust := _field(detail, Vector2(1.17, 0.89) if type == "log" else Vector2(0.77, 0.68), "fieldcraft", color, flashes, 0.42)
		dust.position.z = 0.17
	elif type == "plank":
		for side: int in [-1, 1]:
			_line(detail, Vector3(-0.70, 0.049, side * 0.185), Vector3(0.60, 0.049, side * 0.185), 0.014, pale, true)
	root.add_child(detail)

static func solar_zone(radius: float, color: Color, flashes: float, low: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "SolarOrchestra"
	var energy: Material = _energy(color.lerp(Color("ffe8a6"), 0.4), flashes)
	var gold: Material = _surface(Color("c59647"), 0.78, 0.28)
	# A three-dimensional broken crown and sweeping stave lines leave the
	# center clear for combat. Perimeter beams feel like real stage lighting.
	for index: int in range(6 if low else 10):
		var a: float = index * TAU / (6.0 if low else 10.0)
		var p: Vector3 = _polar(radius * 0.96, a, 0.07)
		var ray := _line(root, p, p + Vector3(0.10 * cos(a), 0.58, -0.18), 0.05, energy, true)
		ray.set_meta("sway", float(index))
		if index % 2 == 0: _note(root, p * 0.92, gold, 0.14)
	for index: int in range(3):
		_arc(root, radius * (0.76 + index * 0.085), -0.65 + index * 0.14, 2.1 + index * 0.14, 0.014, 0.09 + index * 0.09, energy, 36, true)
		_arc(root, radius * (0.80 + index * 0.06), 2.45, 4.62, 0.01, -0.12, energy, 30, true)
	_field(root, Vector2.ONE * radius * 2.12, "encore", color, flashes, 0.64)
	return root

static func animate(root: Node3D, item: Dictionary) -> void:
	var delay: int = int(item.options.get("delay", 0))
	var ticks: float = maxf(0, float(item.age) - delay)
	var duration: float = maxf(1, float(item.life) - delay)
	var age: float = clampf(ticks / duration, 0, 1)
	var art: Node3D = root.get_node_or_null("AuthoredAbility") if root.name != "AuthoredAbility" else root
	if art != null:
		var mechanic: String = str(art.get_meta("art_identity", ""))
		var spin: Node3D = art.get_node_or_null("Rotor")
		if spin != null:
			spin.rotation.z = ticks * (0.11 if mechanic == "momentum" else 0.035)
		var shell: Node3D = art.get_node_or_null("Shell")
		if shell != null:
			shell.scale = Vector3.ONE * (0.82 + 0.18 * smoothstep(0, 0.4, age))
			if item.move.ability in ["sentinel_pulse", "heavy_stomp", "heavy_clap"]:
				shell.scale = Vector3.ONE * lerpf(0.58, 1.04, smoothstep(0, 0.8, age))
		if item.type == "hook": _animate_tether(art, item, age)
		if item.type == "trap":
			var jaw: Node3D = art.get_node_or_null("Jaw")
			if jaw != null: jaw.rotation.x = lerpf(-0.65, -0.08, smoothstep(0, float(item.data.get("arming_ticks", 30)), ticks))
		# Physical flecks settle with the same authored lifetime; never spawn
		# child timers or unbounded particle emitters.
		_animate_details(art, age)
	var detail: Node3D = root.get_node_or_null("PropDetail")
	if detail != null: _animate_details(detail, age)

static func _animate_details(node: Node3D, age: float) -> void:
	for child: Node in node.get_children():
		if not child is Node3D: continue
		if child.has_meta("drift"):
			child.position = Vector3(child.get_meta("rest")) + Vector3(child.get_meta("drift")) * sin(age * PI * 0.65)
			child.scale = Vector3.ONE * (1.0 - smoothstep(0.64, 1.0, age))
		if child.has_meta("flutter"):
			child.rotation.y = sin(age * TAU + float(child.get_meta("flutter"))) * 0.45
		if child.has_meta("orbit"):
			child.rotation.z = float(child.get_meta("orbit")) + age * float(child.get_meta("orbit_speed", 1.0))
		if child.get_child_count() > 0: _animate_details(child, age)

static func _pressure(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var rotor := _group(root, "Rotor")
	var mist: Material = _energy(color.lerp(Color("dde8ec"), 0.65), flashes, 0.64)
	var fine: Material = _energy(Color(color, 0.8), flashes, 0.8)
	for index: int in range(3 if low else 5):
		var a: float = index * TAU / (3.0 if low else 5.0)
		_arc(rotor, 0.36 + index * 0.02, a, a + 1.60, 0.04, (index - 2) * 0.04, mist, 20, true)
		_arc(rotor, 0.39 + index * 0.014, a + 0.15, a + 1.42, 0.009, 0.11, fine, 20, true)
	var shell := _group(root, "Shell")
	for index: int in range(4):
		var a: float = index * TAU / 4.0 + 0.3
		var tip: Vector3 = _polar(0.30, a, 0.0)
		_line(shell, tip + Vector3(-0.42, 0.02, -0.16), tip, 0.02, mist, true)
	_wake(root, "momentum", color, flashes, low)

static func _sentinel(root: Node3D, color: Color, flashes: float, low: bool, pulse: bool) -> void:
	var shell := _group(root, "Shell")
	var alloy: Material = _surface(Color("849da6"), 0.58, 0.29)
	var dark: Material = _surface(Color("19282e"), 0.77, 0.37)
	var plasma: Material = _energy(color.lerp(Color("a9edf8"), 0.38), flashes)
	_polygon(shell, 0.405, 6, 0.017, 0.01, alloy)
	_polygon(shell, 0.445, 6, 0.012, 0.12, plasma, true)
	if pulse:
		_polygon(shell, 0.31, 6, 0.013, -0.13, plasma, true)
		for index: int in range(6):
			var a: float = index * TAU / 6
			_line(shell, _polar(0.31, a, -0.13), _polar(0.405, a, 0.01), 0.014, alloy)
	else:
		# Machined rails and a pointed containment core read as a projectile,
		# with no filled orb occluding the fighter at launch.
		for side: int in [-1, 1]:
			_box(root, Vector3(0.43, 0.04, 0.09), Vector3(-0.08, side * 0.105, 0.03), alloy)
			_line(root, Vector3(-0.42, side * 0.06, 0.06), Vector3(0.39, 0, 0.06), 0.038, plasma, true)
		_diamond(root, Vector3(0.18, 0, 0.02), Vector3(0.48, 0.12, 0.09), dark)
	if not low:
		for index: int in range(6):
			var a: float = index * TAU / 6 + PI / 6
			var plate := _box(shell, Vector3(0.09, 0.055, 0.045), _polar(0.40, a, 0.08), alloy)
			plate.rotation.z = a + PI * 0.5
	var circuit := _group(root, "CircuitHalo")
	circuit.set_meta("orbit", 0.0)
	circuit.set_meta("orbit_speed", -0.65)
	for index: int in range(6):
		var a: float = index * TAU / 6
		_arc(circuit, 0.465, a + 0.07, a + 0.30, 0.019, -0.04, plasma, 6, true)
	if not pulse: _wake(root, "sentinel", color, flashes, low)

static func _shadow(root: Node3D, color: Color, flashes: float, low: bool, portal: bool) -> void:
	var rotor := _group(root, "Rotor")
	var obsidian: Material = _surface(Color("363041"), 0.46, 0.25)
	var edge: Material = _energy(color.lerp(Color("cebbef"), 0.28), flashes, 0.78)
	# A solid black crescent with a razor edge: dark mass carries the shape,
	# so this remains visible even with flashes disabled.
	_arc(rotor, 0.34, -1.53, 1.53, 0.075, 0.02, obsidian, 32)
	_arc(rotor, 0.421, -1.48, 1.48, 0.013, 0.025, edge, 32, true)
	_arc(rotor, 0.285, -1.25, 1.25, 0.012, 0.075, edge, 24, true)
	if portal:
		_arc(rotor, 0.38, 1.90, 4.40, 0.037, -0.08, obsidian, 28)
		_arc(rotor, 0.41, 1.96, 4.25, 0.009, -0.05, edge, 28, true)
	for index: int in range(3 if low else 6):
		var a: float = -1.20 + index * 0.47
		var shard := _diamond(rotor, _polar(0.46, a, index * -0.026), Vector3(0.07, 0.15, 0.023), obsidian)
		shard.rotation.z = a - 0.5
		shard.set_meta("rest", shard.position)
		shard.set_meta("drift", Vector3(-0.17, sin(a) * 0.16, 0.12))
	var silk := _group(root, "VeilSilk")
	silk.set_meta("orbit", 0.25)
	silk.set_meta("orbit_speed", -1.2)
	for index: int in range(2 if low else 4):
		_arc(silk, 0.32 + index * 0.033, -2.5 + index * 0.24, -0.20 + index * 0.16, 0.018 + index * 0.004, -0.04 - index * 0.02, edge, 28, true)

static func _heavy(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var shell := _group(root, "Shell")
	var dust: Material = _energy(Color("c8b6a2"), flashes, 0.34)
	var steel: Material = _surface(Color("5e605e"), 0.65, 0.42)
	var stone: Material = _surface(Color("8d8170"), 0.0, 0.91, 3)
	for index: int in range(5 if low else 9):
		var a: float = index * TAU / (5.0 if low else 9.0)
		_arc(shell, 0.41, a, a + 0.47, 0.018, 0.04, dust, 8, true)
		var fragment := _box(shell, Vector3(0.105, 0.051, 0.047), _polar(0.36, a, 0.04), stone if index % 2 else steel)
		fragment.rotation = Vector3(a * 0.8, a, a * 0.5)
		fragment.set_meta("rest", fragment.position)
		fragment.set_meta("drift", _polar(0.09, a, 0.06))
	for index: int in range(3):
		_arc(shell, 0.24 + index * 0.073, 0.18, TAU - 0.25, 0.008, index * -0.04, dust, 32, true)
	for index: int in range(5 if low else 8):
		var a: float = index * TAU / (5.0 if low else 8.0)
		var fissure: Array[Vector3] = [_polar(0.20, a, 0.05), _polar(0.28, a + 0.12, 0.05), _polar(0.37, a + 0.04, 0.05), _polar(0.46, a + 0.10, 0.05)]
		for segment: int in range(3):
			_line(shell, fissure[segment], fissure[segment + 1], 0.007, _energy(Color("f0c397"), flashes, 0.55), true)

static func _compass(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var brass: Material = _surface(Color("b38a51"), 0.76, 0.30)
	var ink: Material = _energy(color.lerp(Color("e6cd8c"), 0.4), flashes, 0.55)
	var shell := _group(root, "Shell")
	_arc(shell, 0.38, 0, TAU, 0.014, 0.015, brass, 36)
	for index: int in range(4 if low else 8):
		var a: float = index * TAU / (4.0 if low else 8.0)
		var pointer := _diamond(shell, _polar(0.26, a, 0.02), Vector3(0.22, 0.065, 0.028), brass)
		pointer.rotation.z = a
		_line(shell, _polar(0.40, a, 0.02), _polar(0.48, a, 0.02), 0.012, ink, true)
	var dial := _group(root, "NavigationDial")
	dial.set_meta("orbit", 0.12)
	dial.set_meta("orbit_speed", 0.75)
	for index: int in range(12 if low else 24):
		var a: float = index * TAU / (12.0 if low else 24.0)
		_line(dial, _polar(0.407, a, 0.025), _polar(0.44 if index % 3 else 0.47, a, 0.025), 0.005, ink, true)

static func _grapnel(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var steel: Material = _surface(Color("b5c3c6"), 0.67, 0.27)
	var brass: Material = _surface(Color("bba16a"), 0.64, 0.31)
	var head := _group(root, "GrapnelHead")
	head.scale = Vector3.ONE * 0.62
	_tube(head, [Vector3(-0.26, 0, 0), Vector3(0.18, 0, 0)], 0.028, steel, 8)
	var point := CylinderMesh.new()
	point.top_radius = 0.0
	point.bottom_radius = 0.045
	point.height = 0.14
	point.radial_segments = 12
	var point_node := _add(head, point, Vector3(0.23, 0, 0), steel)
	point_node.rotation.z = -PI * 0.5
	for side: int in [-1, 1]:
		var points: Array[Vector3] = []
		for index: int in range(9 if low else 17):
			var t: float = index / (8.0 if low else 16.0)
			points.append(Vector3(0.10, 0, 0).bezier_interpolate(Vector3(-0.01, side * 0.27, 0.02), Vector3(-0.38, side * 0.26, 0.035), Vector3(-0.25, side * 0.065, 0.035), t))
		_tube(head, points, 0.023, steel, 8 if low else 10, true)
		# A narrow illuminated glint follows the real bevel, not a halo.
		if not low: _line(head, Vector3(-0.19, side * 0.195, 0.048), Vector3(-0.27, side * 0.14, 0.048), 0.009, _energy(Color("d9e7e5"), flashes, 0.20), true)
	for index: int in range(3):
		var collar := CylinderMesh.new()
		collar.top_radius = 0.042
		collar.bottom_radius = 0.042
		collar.height = 0.018
		collar.radial_segments = 12
		var collar_node := _add(head, collar, Vector3(-0.17 + index * 0.057, 0, 0), brass)
		collar_node.rotation.z = PI * 0.5
	var tether := MeshInstance3D.new()
	tether.name = "Tether"
	tether.mesh = ImmediateMesh.new()
	tether.material_override = _surface(Color("b8ad93"), 0.0, 0.91, 1)
	tether.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tether)
	if not low: _line(root, Vector3(-0.26, 0, 0), Vector3(0.18, 0, 0), 0.008, _energy(color, flashes, 0.18), true)

static func _animate_tether(art: Node3D, item: Dictionary, age: float) -> void:
	var rope: MeshInstance3D = art.get_node_or_null("Tether")
	if rope == null: return
	var mesh: ImmediateMesh = rope.mesh as ImmediateMesh
	mesh.clear_surfaces()
	var owner_position: Vector3 = item.owner.position + Vector3(item.owner.facing * 0.58, 1.49, 0.015)
	var presentation: Node = item.owner.visual.attack_presentation
	if is_instance_valid(presentation) and is_instance_valid(presentation.rig):
		var hand_index: int = int(presentation.bones.get("hand.L", -1))
		if hand_index >= 0:
			owner_position = presentation.rig.global_transform * presentation.rig.get_bone_global_pose(hand_index).origin
	var local_end: Vector3 = art.to_local(owner_position)
	var start := Vector3(-0.16, 0, 0.015)
	var length_value: float = start.distance_to(local_end)
	if length_value < 0.08: return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = 10 if bool(art.get_meta("art_low", false)) else 18
	for index: int in range(count):
		var t0: float = float(index) / count
		var t1: float = float(index + 1) / count
		var p0: Vector3 = start.lerp(local_end, t0) + Vector3(0, -sin(t0 * PI) * minf(0.40, length_value * 0.07) * (1.0 - age * 0.25), 0)
		var p1: Vector3 = start.lerp(local_end, t1) + Vector3(0, -sin(t1 * PI) * minf(0.40, length_value * 0.07) * (1.0 - age * 0.25), 0)
		_quad_strip(mesh, p0, p1, 0.0055)
	mesh.surface_end()

static func _trap(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var steel: Material = _surface(Color("626962"), 0.80, 0.50)
	var rust: Material = _surface(Color("57452f"), 0.36, 0.82)
	_box(root, Vector3(0.62, 0.07, 0.38), Vector3(0, -0.09, 0), rust)
	_box(root, Vector3(0.23, 0.018, 0.25), Vector3(0, -0.043, 0), steel)
	var jaw := _group(root, "Jaw")
	for side: int in [-1, 1]:
		_box(jaw, Vector3(0.58, 0.045, 0.035), Vector3(0, -0.02, side * 0.19), steel)
		for index: int in range(4 if low else 7):
			var x: float = -0.25 + float(index) / (3.0 if low else 6.0) * 0.50
			var tooth := _diamond(jaw, Vector3(x, 0.056, side * 0.16), Vector3(0.045, 0.15, 0.05), steel)
			tooth.rotation.x = side * 0.26
		_box(root, Vector3(0.07, 0.06, 0.48), Vector3(side * 0.32, -0.07, 0), steel)
	_arc(root, 0.34, -0.12, PI + 0.12, 0.011, 0.21, _energy(color, flashes, 0.28), 22, true)

static func _citation(root: Node3D, color: Color, flashes: float, low: bool, ultimate: bool) -> void:
	var gold: Material = _surface(Color("b6a575"), 0.80, 0.25)
	var light: Material = _energy(color.lerp(Color("eff8ee"), 0.44), flashes, 0.9)
	var paper: Material = _surface(Color("dddac8"), 0.05, 0.88, 2)
	if not ultimate:
		_line(root, Vector3(-1.4, 0.345, 0), Vector3(0.53, 0, 0), 0.028, light, true)
		_line(root, Vector3(-0.63, 0.19, -0.03), Vector3(0.55, 0, -0.03), 0.011, gold)
		for y: float in [-0.11, 0.11]: _line(root, Vector3(-0.53, y, 0.02), Vector3(0.53, y, 0.02), 0.011, light, true)
		_line(root, Vector3(0.53, -0.11, 0.02), Vector3(0.53, 0.11, 0.02), 0.015, gold)
	else:
		for index: int in range(3):
			var y: float = (index - 1) * 0.20
			_line(root, Vector3(-0.98, -0.44 + y, index * 0.025), Vector3(0.98, 0.44 + y, index * 0.025), 0.028 if index == 1 else 0.012, light, true)
		for x: int in [-1, 1]:
			for y: int in [-1, 1]:
				_line(root, Vector3(x * 0.98, y * 0.62, 0.02), Vector3(x * 0.70, y * 0.62, 0.02), 0.009, gold)
				_line(root, Vector3(x * 0.98, y * 0.62, 0.02), Vector3(x * 0.98, y * 0.37, 0.02), 0.009, gold)
	for index: int in range(2 if low else 5):
		var position_value := Vector3(-0.65 + index * 0.28, (-1.0 if index % 2 else 1.0) * (0.40 if ultimate else 0.16), 0.12 + index * 0.02)
		var leaf := _group(root, "Citation%d" % index)
		leaf.position = position_value
		leaf.rotation.z = -0.2 + index * 0.11
		leaf.set_meta("flutter", float(index))
		_box(leaf, Vector3(0.14, 0.19, 0.005), Vector3.ZERO, paper)
		for line_index: int in range(3):
			_box(leaf, Vector3(0.089 - line_index * 0.014, 0.006, 0.004), Vector3(-0.006, 0.045 - line_index * 0.028, 0.006), gold)

static func _containment(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var alloy: Material = _surface(Color("849ca6"), 0.59, 0.32)
	var plasma: Material = _energy(color.lerp(Color("d3f8ff"), 0.35), flashes, 0.83)
	for side: int in [-1, 1]:
		_box(root, Vector3(0.030, 1.18, 0.075), Vector3(side * 0.91, 0, -0.025), alloy)
		for y: float in [-0.55, 0.55]:
			_box(root, Vector3(0.27, 0.024, 0.08), Vector3(side * 0.80, y, 0), alloy)
			_line(root, Vector3(side * 0.87, y, 0.065), Vector3(side * 0.64, y, 0.065), 0.017, plasma, true)
	for index: int in range(2 if low else 4):
		var x: float = -0.64 + index * (1.28 / (1.0 if low else 3.0))
		_line(root, Vector3(x, -0.61, 0.065), Vector3(x + 0.08, 0.61, 0.065), 0.022, plasma, true)
	_polygon(root, 0.39, 6, 0.012, 0.10, plasma, true)

static func _solar_ribbon(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var gold: Material = _surface(Color("c29c4f"), 0.86, 0.24)
	var light: Material = _energy(color.lerp(Color("fff1cc"), 0.5), flashes)
	# Curved brass ribbon with five engraved musical stave filaments.
	_arc(root, 0.71, -1.42, 1.42, 0.045, 0.04, gold, 36)
	for index: int in range(3 if low else 5):
		_arc(root, 0.60 + index * 0.045, -1.48 + index * 0.03, 1.38, 0.012, -0.035 + index * 0.045, light, 32, true)
	_note(root, _polar(0.70, 0.35, 0.13), gold, 0.14)
	if not low: _note(root, _polar(0.68, -0.74, 0.13), gold, 0.11)
	var corona := _group(root, "SolarCorona")
	corona.set_meta("orbit", -0.14)
	corona.set_meta("orbit_speed", 0.85)
	for index: int in range(3 if low else 5):
		var a: float = -1.35 + index * 0.55
		_arc(corona, 0.76, a, a + 0.36, 0.037, -0.02, light, 12, true)

static func _paper_step(root: Node3D, color: Color, flashes: float, low: bool) -> void:
	var paper: Material = _surface(Color("dad8c7"), 0.05, 0.79, 2)
	var gold: Material = _surface(Color("b9a47c"), 0.78, 0.29)
	_box(root, Vector3(0.80, 0.018, 0.32), Vector3.ZERO, paper)
	_box(root, Vector3(0.73, 0.008, 0.014), Vector3(0, 0.014, 0.13), gold)
	for index: int in range(2 if low else 4):
		_box(root, Vector3(0.47 - index * 0.045, 0.008, 0.006), Vector3(-0.045, 0.014, -0.075 + index * 0.047), gold)
	_line(root, Vector3(-0.42, 0.03, 0.17), Vector3(0.42, 0.03, 0.17), 0.009, _energy(color, flashes, 0.6), true)

static func _surface(color: Color, metal: float, rough: float, kind: int = 0) -> Material:
	var key: String = "surface:%s:%s:%s:%d" % [color.to_html(), metal, rough, kind]
	if materials.has(key): return materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = SURFACE
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("metalness", metal)
	mat.set_shader_parameter("roughness_value", rough)
	mat.set_shader_parameter("surface_kind", kind)
	mat.set_shader_parameter("grain_strength", 0.56 if kind == 4 else 0.26 if kind in [1, 3] else 0.10)
	materials[key] = mat
	return mat

static func _energy(color: Color, flashes: float, strength: float = 1.0) -> Material:
	var key: String = "energy:%s:%s:%s" % [color.to_html(), flashes, strength]
	if materials.has(key): return materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = FILAMENT
	mat.set_shader_parameter("effect_color", color)
	mat.set_shader_parameter("brightness", lerpf(0.56, 1.75, flashes) * strength)
	mat.set_shader_parameter("taper", true)
	materials[key] = mat
	return mat

static func _field(root: Node3D, size_value: Vector2, mechanic: String, color: Color, flashes: float, strength: float = 1.0) -> MeshInstance3D:
	# A single soft sheet supplies volume behind the physical bevels. The shader
	# cuts its middle out; its full quad is never visible. Cached materials share
	# only style, while each object receives independent fixed-tick age uniforms.
	var index: int = int(SIGNATURE_INDEX.get(mechanic, 0))
	var key: String = "field:%s:%s:%s:%s" % [index, color.to_html(), flashes, strength]
	if not materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = FILAMENT
		material.set_shader_parameter("effect_color", color)
		material.set_shader_parameter("brightness", lerpf(0.48, 1.8, flashes) * strength)
		material.set_shader_parameter("field_mode", true)
		material.set_shader_parameter("signature", index)
		materials[key] = material
	var quad := QuadMesh.new()
	quad.size = size_value
	var sheet: MeshInstance3D = _add(root, quad, Vector3(0, 0, -0.075), materials[key])
	sheet.name = "SignatureAtmosphere"
	return sheet

static func _wake(root: Node3D, mechanic: String, color: Color, flashes: float, low: bool) -> void:
	var mat: Material = _energy(color.lerp(Color("e4f9ff"), 0.32), flashes, 0.70)
	var count: int = 3 if low else 5
	# Curved, tapered streamers occupy the rear hemisphere of the projectile.
	# Their vertices are static; shader flow moves with normalized object age.
	for index: int in range(count):
		var lane: float = float(index) / maxf(1, count - 1) * 2.0 - 1.0
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for step: int in range(12):
			var t0: float = float(step) / 12.0
			var t1: float = float(step + 1) / 12.0
			var p0 := Vector3(lerpf(-0.45, 0.12, t0), lane * (0.06 + t0 * 0.21) + sin(t0 * PI) * lane * 0.08, -0.045 - index * 0.013)
			var p1 := Vector3(lerpf(-0.45, 0.12, t1), lane * (0.06 + t1 * 0.21) + sin(t1 * PI) * lane * 0.08, -0.045 - index * 0.013)
			_quad_strip(mesh, p0, p1, 0.025 if mechanic == "momentum" else 0.018, t0, t1)
		mesh.surface_end()
		_add(root, mesh, Vector3.ZERO, mat)

static func _group(root: Node3D, name_value: String) -> Node3D:
	var group := Node3D.new()
	group.name = name_value
	root.add_child(group)
	return group

static func _box(root: Node3D, size_value: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	return _add(root, mesh, at, material)

static func _diamond(root: Node3D, at: Vector3, size_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size_value
	return _add(root, mesh, at, material)

static func _add(root: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
	return node

static func _line(root: Node3D, start: Vector3, end: Vector3, width: float, material: Material, soft: bool = false) -> MeshInstance3D:
	if soft:
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_quad_strip(mesh, start, end, width)
		mesh.surface_end()
		return _add(root, mesh, Vector3.ZERO, material)
	var node: MeshInstance3D = _box(root, Vector3(start.distance_to(end), width * 2.0, width), (start + end) * 0.5, material)
	node.rotation.z = atan2(end.y - start.y, end.x - start.x)
	return node

static func _tube(root: Node3D, points: Array[Vector3], radius: float, material: Material, sides: int, tapered: bool = false) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(points.size() - 1):
		var t0: Vector3 = (points[index + 1] - points[maxi(0, index - 1)]).normalized()
		var t1: Vector3 = (points[mini(points.size() - 1, index + 2)] - points[index]).normalized()
		var u0: Vector3 = t0.cross(Vector3.FORWARD).normalized()
		var u1: Vector3 = t1.cross(Vector3.FORWARD).normalized()
		var v0: Vector3 = u0.cross(t0).normalized()
		var v1: Vector3 = u1.cross(t1).normalized()
		var r0: float = radius * (1.0 - 0.93 * pow(float(index) / (points.size() - 1), 3.0)) if tapered else radius
		var r1: float = radius * (1.0 - 0.93 * pow(float(index + 1) / (points.size() - 1), 3.0)) if tapered else radius
		for side: int in range(sides):
			var a: float = side * TAU / sides
			var b: float = (side + 1) * TAU / sides
			var n0: Vector3 = u0 * cos(a) + v0 * sin(a)
			var n1: Vector3 = u0 * cos(b) + v0 * sin(b)
			var n2: Vector3 = u1 * cos(b) + v1 * sin(b)
			var n3: Vector3 = u1 * cos(a) + v1 * sin(a)
			var normals: Array[Vector3] = [n0, n1, n2, n0, n2, n3]
			var vertices: Array[Vector3] = [points[index] + n0 * r0, points[index] + n1 * r0, points[index + 1] + n2 * r1, points[index] + n0 * r0, points[index + 1] + n2 * r1, points[index + 1] + n3 * r1]
			for vertex: int in range(6):
				mesh.surface_set_normal(normals[vertex])
				mesh.surface_add_vertex(vertices[vertex])
	mesh.surface_end()
	return _add(root, mesh, Vector3.ZERO, material)

static func _arc(root: Node3D, radius: float, start: float, end: float, width: float, depth: float, material: Material, segments: int = 32, soft: bool = false) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(segments):
		var a: float = lerpf(start, end, float(index) / segments)
		var b: float = lerpf(start, end, float(index + 1) / segments)
		# A shallow helical depth gives arc ribbons perspective and highlights.
		var depth_a: float = depth + sin(a * 2.0) * (0.04 if soft else 0.013)
		var depth_b: float = depth + sin(b * 2.0) * (0.04 if soft else 0.013)
		# Shared radial boundaries form a continuous bevel. Independent strips
		# left tiny bright cracks between the dark crescent's segments.
		var vertices: Array[Vector3] = [_polar(radius - width, a, depth_a), _polar(radius + width, a, depth_a), _polar(radius + width, b, depth_b), _polar(radius - width, a, depth_a), _polar(radius + width, b, depth_b), _polar(radius - width, b, depth_b)]
		var u0: float = float(index) / segments
		var u1: float = float(index + 1) / segments
		var uv: Array[Vector2] = [Vector2(u0, 0), Vector2(u0, 1), Vector2(u1, 1), Vector2(u0, 0), Vector2(u1, 1), Vector2(u1, 0)]
		for vertex: int in range(6):
			mesh.surface_set_normal(Vector3.BACK)
			mesh.surface_set_uv(uv[vertex])
			mesh.surface_add_vertex(vertices[vertex])
	mesh.surface_end()
	return _add(root, mesh, Vector3.ZERO, material)

static func _polygon(root: Node3D, radius: float, sides: int, width: float, depth: float, material: Material, soft: bool = false) -> void:
	for index: int in range(sides):
		_line(root, _polar(radius, index * TAU / sides, depth), _polar(radius, (index + 1) * TAU / sides, depth), width, material, soft)

static func _quad_strip(mesh: ImmediateMesh, start: Vector3, end: Vector3, width: float, u0: float = 0.0, u1: float = 1.0) -> void:
	var side := Vector3(-(end.y - start.y), end.x - start.x, 0).normalized() * width
	if side.length_squared() < 0.0000001: side = Vector3(0, width, 0)
	var vertices: Array[Vector3] = [start - side, start + side, end + side, start - side, end + side, end - side]
	var uv: Array[Vector2] = [Vector2(u0, 0), Vector2(u0, 1), Vector2(u1, 1), Vector2(u0, 0), Vector2(u1, 1), Vector2(u1, 0)]
	for index: int in range(6):
		mesh.surface_set_normal(Vector3.BACK)
		mesh.surface_set_uv(uv[index])
		mesh.surface_add_vertex(vertices[index])

static func _note(root: Node3D, at: Vector3, material: Material, size_value: float) -> void:
	var note := _group(root, "Note")
	note.position = at
	var oval: MeshInstance3D = _box(note, Vector3(size_value * 0.62, size_value * 0.38, 0.018), Vector3.ZERO, material)
	oval.rotation.z = 0.35
	_box(note, Vector3(size_value * 0.09, size_value * 1.2, 0.013), Vector3(size_value * 0.24, size_value * 0.49, 0), material)
	_line(note, Vector3(size_value * 0.24, size_value * 1.08, 0), Vector3(size_value * 0.65, size_value * 0.86, 0), size_value * 0.07, material)

static func _polar(radius: float, angle: float, depth: float) -> Vector3:
	return Vector3(cos(angle) * radius, sin(angle) * radius, depth)
