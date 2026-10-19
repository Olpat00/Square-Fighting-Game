class_name FighterFootPlant
extends RefCounted
## Small, bounded two-bone visual correction. Never changes fighter travel or contacts.
var rig: Skeleton3D
var actor: Node3D
var profile: FighterPresentationProfile
var legs: Dictionary = {}
var anchors: Dictionary = {}
var saved_rotations: Dictionary = {}
var previous_support: int = -99
var last_correction: float = 0.0
var contact_error_before: float = 0.0
var contact_error_after: float = 0.0

func configure(skeleton: Skeleton3D, fighter: Node3D, settings: FighterPresentationProfile) -> void:
	rig = skeleton
	actor = fighter
	profile = settings
	for side: String in ["L", "R"]:
		var upper: int = rig.find_bone("thigh." + side)
		var lower: int = rig.find_bone("shin." + side)
		var foot: int = rig.find_bone("foot." + side)
		if mini(upper, mini(lower, foot)) < 0: continue
		var rest: Vector3 = rig.global_transform * rig.get_bone_global_rest(foot).origin
		legs[side] = {"upper": upper, "lower": lower, "foot": foot, "height": clampf(rest.y - actor.global_position.y, 0.035, 0.18)}

func restore() -> void:
	if not is_instance_valid(rig): return
	for bone: int in saved_rotations: rig.set_bone_pose_rotation(bone, saved_rotations[bone])
	saved_rotations.clear()

func clear() -> void:
	restore()
	anchors.clear()
	previous_support = -99
	last_correction = 0.0

func apply(clip: String, phase: float, grounded: bool, support: int, velocity: Vector3) -> void:
	last_correction = 0.0
	contact_error_before = 0.0
	contact_error_after = 0.0
	if not is_instance_valid(rig): return
	var gait: bool = clip in ["walk", "run"]
	var settling: bool = clip in ["idle", "crouch", "move_start", "move_stop", "turnaround", "land_soft", "land_hard", "shield_hold"]
	if not grounded or (not gait and not settling):
		anchors.clear()
		return
	if support != previous_support: anchors.clear()
	previous_support = support
	for side: String in legs:
		var leg: Dictionary = legs[side]
		var current: Vector3 = rig.global_transform * rig.get_bone_global_pose(leg.foot).origin
		var floor_y: float = actor.global_position.y + float(leg.height)
		var contact: bool = profile.planted(clip, side, phase) if gait else current.y <= floor_y + 0.075
		if not contact:
			anchors.erase(side)
			continue
		if not anchors.has(side): anchors[side] = current
		var target: Vector3 = anchors[side]
		target.y = floor_y # follows the authoritative support, including lifts
		target.z = current.z
		# Starting/reversing can move farther than a leg reaches; release gracefully.
		if absf(target.x - current.x) > profile.max_foot_correction:
			target.x = current.x
		anchors[side] = target
		var offset: Vector3 = (target - current).limit_length(profile.max_foot_correction)
		var weight: float = profile.foot_plant_strength
		if settling and absf(velocity.x) > 3.0: weight *= 0.65
		last_correction = maxf(last_correction, offset.length() * weight)
		var desired: Vector3 = current + offset * weight
		contact_error_before += current.distance_to(desired)
		_solve(leg, rig.global_transform.affine_inverse() * desired)
		var corrected: Vector3 = rig.global_transform * rig.get_bone_global_pose(leg.foot).origin
		contact_error_after += corrected.distance_to(desired)

func _set_global_rotation(bone: int, rotation: Quaternion) -> void:
	if not saved_rotations.has(bone): saved_rotations[bone] = rig.get_bone_pose_rotation(bone)
	var parent: int = rig.get_bone_parent(bone)
	var parent_rotation: Quaternion = rig.get_bone_global_pose(parent).basis.get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY
	rig.set_bone_pose_rotation(bone, (parent_rotation.inverse() * rotation).normalized())

func _solve(leg: Dictionary, target: Vector3) -> void:
	var upper: int = leg.upper
	var lower: int = leg.lower
	var foot: int = leg.foot
	var hip_pose: Transform3D = rig.get_bone_global_pose(upper)
	var knee_pose: Transform3D = rig.get_bone_global_pose(lower)
	var foot_pose: Transform3D = rig.get_bone_global_pose(foot)
	var ankle_rotation: Quaternion = foot_pose.basis.get_rotation_quaternion()
	var hip: Vector3 = hip_pose.origin
	var knee: Vector3 = knee_pose.origin
	var ankle: Vector3 = foot_pose.origin
	var first: float = hip.distance_to(knee)
	var second: float = knee.distance_to(ankle)
	var distance: float = hip.distance_to(target)
	if minf(first, minf(second, distance)) < 0.0001: return
	var direction: Vector3 = (target - hip).normalized()
	distance = clampf(distance, absf(first - second) + 0.001, first + second - 0.001)
	target = hip + direction * distance
	var plane: Vector3 = (knee - hip).slide(direction)
	if plane.length_squared() < 0.00001: plane = Vector3.FORWARD.slide(direction)
	if plane.length_squared() < 0.00001: return
	plane = plane.normalized()
	var along: float = (first * first - second * second + distance * distance) / (2.0 * distance)
	var bend: float = sqrt(maxf(0.0, first * first - along * along))
	var desired_knee: Vector3 = hip + direction * along + plane * bend
	var turn: Quaternion = Quaternion((knee - hip).normalized(), (desired_knee - hip).normalized())
	_set_global_rotation(upper, turn * hip_pose.basis.get_rotation_quaternion())
	knee_pose = rig.get_bone_global_pose(lower)
	foot_pose = rig.get_bone_global_pose(foot)
	turn = Quaternion((foot_pose.origin - knee_pose.origin).normalized(), (target - knee_pose.origin).normalized())
	_set_global_rotation(lower, turn * knee_pose.basis.get_rotation_quaternion())
	_set_global_rotation(foot, ankle_rotation)
