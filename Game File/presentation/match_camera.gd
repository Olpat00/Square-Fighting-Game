class_name MatchCamera
extends RefCounted
## Presentation framing in the fight plane. No world position is changed here.

const TILT: float = 17.0
const DISTANCE: float = 32.0
const SAFE_LEFT: float = 0.08
const SAFE_RIGHT: float = 0.92
const SAFE_TOP: float = 0.10
const SAFE_BOTTOM: float = 0.77
var focus := Vector2(0.0, 2.4)
var height: float = 15.0
var shake_seconds: float = 0.0
var initialized: bool = false

func reset() -> void:
	initialized = false
	shake_seconds = 0.0

func present_results(camera: Camera3D) -> void:
	# Results stage visual children on either side of the central UI panel.
	# Their combat roots remain at the final hit, sometimes beyond a blast zone.
	# Cut to the staged composition at the same time as those presentation poses.
	focus = Vector2(0, 2.5)
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / maxf(1.0, viewport_size.y)
	# Keep the horizontal placement beside the panel when the window changes.
	height = maxf(6.0, (14.0 * 16.0 / 9.0) / maxf(0.5, aspect))
	shake_seconds = 0.0
	initialized = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.rotation_degrees = Vector3(-TILT, 0, 0)
	camera.position = Vector3(focus.x, focus.y + DISTANCE * tan(deg_to_rad(TILT)), DISTANCE)
	camera.size = height
	camera.h_offset = 0.0
	camera.v_offset = 0.0

func framing(points: Array[Vector3], aspect: float, player_count: int) -> Dictionary:
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	var cosine: float = cos(deg_to_rad(TILT))
	for point: Vector3 in points:
		minimum = minimum.min(Vector2(point.x - 0.85, (point.y - 0.30) * cosine))
		maximum = maximum.max(Vector2(point.x + 0.85, (point.y + 2.50) * cosine))
	if points.is_empty(): return {"focus": Vector2(0, 2.4), "height": 14.0}
	var span: Vector2 = maximum - minimum
	var minimum_height: float = 9.6 if player_count <= 2 else 11.8
	var needed: float = maxf(span.x / (maxf(aspect, 0.5) * (SAFE_RIGHT - SAFE_LEFT)), span.y / (SAFE_BOTTOM - SAFE_TOP))
	needed = clampf(needed, minimum_height, 46.0)
	# The HUD occupies the lower portion of the view. Fit the fight into the
	# remaining rectangle, including fighters below the ledge during recovery.
	var center: Vector2 = (minimum + maximum) * 0.5
	center.y -= (0.5 - (SAFE_TOP + SAFE_BOTTOM) * 0.5) * needed
	center.y /= cosine
	return {"focus": center, "height": needed, "bounds": Rect2(minimum, span)}

func update(camera: Camera3D, points: Array[Vector3], player_count: int, delta: float, paused: bool, impulse: float, shake_amount: float) -> void:
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var desired: Dictionary = framing(points, viewport_size.x / maxf(1.0, viewport_size.y), player_count)
	if not initialized:
		focus = desired.focus
		height = desired.height
		initialized = true
	elif not paused:
		var offset: Vector2 = desired.focus - focus
		# Small idle sways must not continually move the stage under the fighter.
		var target: Vector2 = focus + Vector2(signf(offset.x) * maxf(0, absf(offset.x) - 0.30), signf(offset.y) * maxf(0, absf(offset.y) - 0.16))
		focus = focus.lerp(target, 1.0 - exp(-delta * 7.0))
		var zoom_speed: float = 12.0 if float(desired.height) > height else 1.6
		height = lerpf(height, desired.height, 1.0 - exp(-delta * zoom_speed))
		# Smooth zoom inside the comfortable frame, but never crop a fast launch
		# or low recovery while the focus is still catching up. These outer limits
		# leave a small visual buffer beyond the normal framing rectangle.
		if desired.has("bounds"):
			var bounds: Rect2 = desired.bounds
			var aspect: float = viewport_size.x / maxf(1.0, viewport_size.y)
			var projected_focus_y: float = focus.y * cos(deg_to_rad(TILT))
			var horizontal_need: float = maxf(bounds.end.x - focus.x, focus.x - bounds.position.x) / (aspect * 0.465)
			var vertical_need: float = maxf((bounds.end.y - projected_focus_y) / 0.46, (projected_focus_y - bounds.position.y) / 0.30)
			height = maxf(height, minf(46.0, maxf(horizontal_need, vertical_need)))
	if not paused: shake_seconds += delta
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.rotation_degrees = Vector3(-TILT, 0, 0)
	camera.position = Vector3(focus.x, focus.y + DISTANCE * tan(deg_to_rad(TILT)), DISTANCE)
	camera.size = height
	# Continuous-time oscillation has the same response at 30, 60 and 144 FPS.
	# Pause freezes the whole camera, including the current shake displacement.
	if not paused:
		camera.h_offset = (sin(shake_seconds * 71.0) * 0.72 + sin(shake_seconds * 109.0) * 0.28) * impulse * shake_amount
		camera.v_offset = sin(shake_seconds * 83.0 + 0.4) * impulse * shake_amount * 0.38
