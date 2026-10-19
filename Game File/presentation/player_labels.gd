class_name PlayerLabels
extends Control
## Stable screen-space identity cues; the fighter's own Label3D remains a
## fallback for standalone model/animation review scenes.

var labels: Array[Label] = []
var leader_lines: Array[Dictionary] = []
const LABEL_SIZE := Vector2(44, 24)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for slot in 4:
		var label := Label.new()
		label.text = "P%d" % (slot + 1)
		label.size = LABEL_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_outline_color", Color("0a121b"))
		label.add_theme_constant_override("outline_size", 5)
		add_child(label)
		labels.append(label)

func update_labels(fighters: Array, camera: Camera3D, active: bool) -> void:
	visible = active
	leader_lines.clear()
	for label: Label in labels: label.visible = false
	if not active:
		queue_redraw()
		return
	var bounds := Rect2(Vector2(12, 50), Vector2(maxf(size.x - 24, 1), maxf(size.y * 0.78 - 50, 1)))
	var occupied: Array[Rect2] = []
	for fighter in fighters:
		fighter.visual.marker.visible = false
		if fighter.stocks <= 0 or fighter.state in ["ko", "eliminated"]: continue
		var anchor: Vector2 = camera.unproject_position(fighter.global_position + Vector3(0, 2.28, 0))
		var placed: Rect2 = place_label(anchor, bounds, occupied)
		occupied.append(placed)
		var label: Label = labels[fighter.slot]
		label.visible = true
		label.position = placed.position
		label.modulate = fighter.player_color
		if fighter.invulnerability > 0: label.modulate.a = 0.70 + 0.30 * sin(fighter.world.tick * 0.3)
		var bottom: Vector2 = placed.position + Vector2(LABEL_SIZE.x * 0.5, LABEL_SIZE.y)
		if bottom.distance_to(anchor) > 18.0:
			leader_lines.append({"from": bottom, "to": anchor.clamp(bounds.position, bounds.end), "color": fighter.player_color})
	queue_redraw()

static func place_label(anchor: Vector2, bounds: Rect2, occupied: Array[Rect2]) -> Rect2:
	var base: Vector2 = (anchor - Vector2(LABEL_SIZE.x * 0.5, LABEL_SIZE.y + 5)).clamp(bounds.position, bounds.end - LABEL_SIZE)
	var best := Rect2(base, LABEL_SIZE)
	# Stable slot order and deterministic candidates avoid labels oscillating
	# between sides while four fighters occupy the same contact point.
	for row in [0, -1, 1, -2, 2, -3, 3, -4, 4]:
		for column in [0, -1, 1, -2, 2]:
			var offset := Vector2(column * (LABEL_SIZE.x + 5), row * (LABEL_SIZE.y + 3))
			var candidate := Rect2((base + offset).clamp(bounds.position, bounds.end - LABEL_SIZE), LABEL_SIZE)
			var overlaps: bool = false
			for other: Rect2 in occupied:
				if candidate.grow(2).intersects(other): overlaps = true
			if not overlaps: return candidate
	return best

func _draw() -> void:
	for line: Dictionary in leader_lines:
		var color: Color = line.color
		color.a = 0.5
		draw_line(line.from, line.to, color, 1.0, true)
