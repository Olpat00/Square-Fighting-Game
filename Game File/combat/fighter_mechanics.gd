class_name FighterMechanics
extends RefCounted
## Passive resources belong to this fighter instance, never its definition.

var owner_fighter: RiotFighter
var pips: int = 0
var expiry: int = 0
var last_move: String = ""
var empowered: bool = false
var marks: Dictionary = {}

func configure(fighter: RiotFighter) -> void:
	owner_fighter = fighter

func reset() -> void:
	pips = 0
	expiry = 0
	last_move = ""
	empowered = false
	marks.clear()

func tick() -> void:
	if expiry > 0:
		expiry -= 1
		if expiry == 0 and owner_fighter.definition.mechanic in ["momentum", "fieldcraft", "trailblazer", "sentinel", "shadowstep"]:
			pips = 0
	for key in marks.keys():
		marks[key].remaining -= 1
		if int(marks[key].remaining) <= 0:
			marks.erase(key)

func on_move_start(move: MoveDefinition) -> void:
	empowered = false
	var supports_empowerment: bool = false
	for key: String in move.ability_data:
		if key.begins_with("empowered_"):
			supports_empowerment = true
	if owner_fighter.definition.mechanic == "momentum" and move.id.begins_with("special_") and supports_empowerment and pips > 0:
		pips -= 1
		empowered = true
	if owner_fighter.definition.mechanic == "fieldcraft" and move.id in ["special_side", "special_up"] and pips > 0:
		pips = 0
		empowered = true
	if owner_fighter.definition.mechanic == "encore" and move.id == "special_neutral" and pips >= 3:
		pips = 0
		empowered = true
	if owner_fighter.definition.mechanic == "trailblazer" and move.id in ["special_side", "special_up"] and pips > 0:
		pips = 0
		empowered = true
	if owner_fighter.definition.mechanic == "sentinel" and move.id == "special_down" and pips > 0:
		pips = 0
		empowered = true
	if owner_fighter.definition.mechanic == "shadowstep" and move.id == "special_side" and pips > 0:
		pips = 0
		empowered = true

func on_hit(move_id: String, target: RiotFighter, precise: bool = false, trap: bool = false) -> void:
	match owner_fighter.definition.mechanic:
		"momentum":
			if move_id != last_move:
				pips = mini(3, pips + 1)
				expiry = 240
			last_move = move_id
		"fieldcraft":
			if trap:
				pips = 1
				expiry = 480
		"citations":
			if precise:
				add_mark(target)
		"trailblazer":
			if move_id == "special_neutral":
				pips = 1
				expiry = 240
		"shadowstep":
			if move_id.begins_with("air_"):
				pips = 1
				expiry = 240

func on_parry(target: RiotFighter) -> void:
	if owner_fighter.definition.mechanic == "citations":
		add_mark(target)
	elif owner_fighter.definition.mechanic == "sentinel":
		pips = 1
		expiry = 300

func add_mark(target: RiotFighter) -> void:
	if target == null:
		return
	var count: int = int(marks.get(target.slot, {}).get("count", 0))
	var data: Dictionary = owner_fighter.definition.get_move("special_neutral").ability_data
	marks[target.slot] = {"count": mini(int(data.get("citation_max", 3)), count + 1), "remaining": int(data.get("citation_ticks", 420))}
	owner_fighter.world.emit_event("citation", target, target.position, {"count": mini(3, count + 1)})

func consume_marks(target: RiotFighter) -> int:
	var count: int = int(marks.get(target.slot, {}).get("count", 0))
	marks.erase(target.slot)
	return count

func catch_disc() -> void:
	if owner_fighter.definition.mechanic == "encore":
		pips = mini(3, pips + 1)
		owner_fighter.world.emit_event("encore", owner_fighter, owner_fighter.position)

func resource_text() -> String:
	match owner_fighter.definition.mechanic:
		"momentum": return "MOMENTUM  " + "●".repeat(pips) + "○".repeat(3 - pips)
		"encore": return "ENCORE  " + "●".repeat(pips) + "○".repeat(3 - pips)
		"commitment": return "COMMITMENT  " + ("ARMOR" if owner_fighter.move != null and owner_fighter.move.has_armor(owner_fighter.move_tick) and not owner_fighter.armor_spent else "READY")
		"fieldcraft": return "QUICK FIX  " + ("READY" if pips > 0 else "—")
		"citations":
			var count: int = 0
			for entry in marks.values(): count += int(entry.count)
			return "CITATIONS  %d" % count
		"trailblazer": return "ROUTE  " + ("READY" if pips > 0 else "—")
		"sentinel": return "GUARD  " + ("CHARGED" if pips > 0 else "—")
		"shadowstep": return "VEIL  " + ("EXTENDED" if pips > 0 else "—")
	return ""
