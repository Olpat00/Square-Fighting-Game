class_name CombatDebugOverlay
extends Control

var app: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if app == null or not app.world.running: return
	for f: RiotFighter in app.world.fighters:
		if f.stocks <= 0 or f.state == "ko": continue
		var p: Vector2 = app.camera.unproject_position(f.position + Vector3(0, 1, 0))
		var rect := get_viewport_rect().grow(-45)
		if not rect.has_point(p):
			var marker := Vector2(clampf(p.x, 45, rect.end.x), clampf(p.y, 80, rect.end.y - 150))
			draw_circle(marker, 14, f.player_color)
			draw_line(marker, marker + (p - marker).normalized() * 20, f.player_color, 3)
		var citation_anchor: Vector2 = app.camera.unproject_position(f.position + Vector3(0, 2.6, 0))
		var row: int = 0
		for citation in marks_for_target(f):
			var origin: Vector2 = citation_anchor + Vector2(-28, -row * 16)
			draw_rect(Rect2(origin - Vector2(4, 12), Vector2(67, 17)), Color("10212de6"))
			draw_string(ThemeDB.fallback_font, origin, "P%d" % (int(citation.source) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, citation.color)
			for pip in int(citation.count):
				draw_rect(Rect2(origin + Vector2(24 + pip * 10, -9), Vector2(7, 9)), citation.color)
			row += 1
		if not app.debug_hitboxes: continue
		var top: Vector2 = app.camera.unproject_position(f.position + Vector3(0, 1.65, 0))
		var bottom: Vector2 = app.camera.unproject_position(f.position)
		var radius: float = p.distance_to(app.camera.unproject_position(f.position + Vector3(CombatTuning.HURT_RADIUS, 1, 0)))
		draw_rect(Rect2(Vector2(p.x - radius, top.y), Vector2(radius * 2, bottom.y - top.y)), Color(0.2, 0.9, 0.9, 0.18), true)
		draw_rect(Rect2(Vector2(p.x - radius, top.y), Vector2(radius * 2, bottom.y - top.y)), Color.CYAN, false, 1)
		if f.move != null and f.state == "attack" and f.move.is_active(f.move_tick):
			var hit: Vector2 = f.attack_center()
			var center: Vector2 = app.camera.unproject_position(Vector3(hit.x, hit.y, 0))
			var edge: Vector2 = app.camera.unproject_position(Vector3(hit.x + f.move.hit_radius, hit.y, 0))
			draw_circle(center, center.distance_to(edge), Color(1, 0.25, 0.1, 0.3))

func marks_for_target(target: RiotFighter) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for source: RiotFighter in app.world.fighters:
		if source.stocks <= 0: continue
		var mark: Dictionary = source.mechanics.marks.get(target.slot, {})
		if not mark.is_empty() and int(mark.remaining) > 0:
			rows.append({"source": source.slot, "color": source.player_color, "count": mini(3, int(mark.count))})
	return rows
