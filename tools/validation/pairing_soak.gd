extends SceneTree

var world: MatchWorld
var reports: Array[Dictionary] = []
var failures: Array[String] = []
var seed_value: int = 92841

func _initialize() -> void:
	run.call_deferred()

func inspect_state(label: String) -> void:
	for fighter in world.fighters:
		if not fighter.position.is_finite() or not fighter.velocity.is_finite() or not is_finite(fighter.damage):
			failures.append(label + ": non-finite state")
		if absf(fighter.position.z) > 0.00001:
			failures.append(label + ": depth drift")
		if fighter.ultimate_meter < 0 or fighter.ultimate_meter > 100 or fighter.stocks < 0 or fighter.stocks > 3:
			failures.append(label + ": invalid resource bounds")
		if fighter.state == "attack" and fighter.move == null:
			failures.append(label + ": attack missing move")

func run() -> void:
	world = MatchWorld.new()
	root.add_child(world)
	await process_frame
	var roster := RosterRegistry.discover()
	for left in roster.size():
		for right in range(left, roster.size()):
			var slots: Array[Dictionary] = [{"fighter": roster[left].id, "device": "CPU", "difficulty": "Hard"}, {"fighter": roster[right].id, "device": "CPU", "difficulty": "Hard"}]
			world.start(slots, "Fair Fight", false, seed_value + left * 19 + right)
			world.countdown = 0
			var initial_contacts: int = world.resolver.contacts_resolved
			for tick in 3600:
				world.step()
				if tick % 120 == 0: inspect_state("%s/%s" % [roster[left].id, roster[right].id])
				if not world.running: break
			var total_damage: float = 0
			for f in world.fighters: total_damage += f.damage
			var contacts: int = world.resolver.contacts_resolved - initial_contacts
			if contacts == 0: failures.append("No contacts: %s/%s" % [roster[left].id, roster[right].id])
			reports.append({"pair": [roster[left].id, roster[right].id], "ticks": world.tick, "contacts": contacts, "kos": world.ko_log.size(), "end_damage_sum": total_damage, "seed": seed_value + left * 19 + right})
			print("PAIR ", roster[left].id, " / ", roster[right].id, " contacts=", contacts, " kos=", world.ko_log.size())
			world.clear()
			await process_frame
	var stress_slots: Array[Dictionary] = []
	for id: String in ["f01_clutch", "f06_rugged_explorer", "f07_urban_sentinel", "f08_midnight_gentleman"]:
		stress_slots.append({"fighter": id, "device": "CPU", "difficulty": "Hard"})
	world.start(stress_slots, "Party", false, 51307)
	world.countdown = 0
	for tick in 25000:
		world.step()
		if tick % 120 == 0: inspect_state("four_cpu")
		if not world.running: break
	reports.append({"four_cpu": true, "ticks": world.tick, "kos": world.ko_log.size(), "result": world.result.duplicate(true), "seed": 51307})
	if world.running: failures.append("Four-CPU match failed to end after timer + sudden death allowance")
	world.clear()
	await process_frame
	var node_baseline: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for repeat in 20:
		world.start(stress_slots, "Party", false, 200 + repeat)
		world.countdown = 0
		for tick in 240: world.step()
		world.clear()
		await process_frame
		if not world.abilities.objects.is_empty() or not world.abilities.sequences.is_empty(): failures.append("Rematch ownership cleanup failed")
	var node_final: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if node_final > node_baseline + 5: failures.append("Node count grew across cleared rematches")
	var report := {"pairings": reports, "failures": failures, "node_baseline": node_baseline, "node_final": node_final, "rematches": 20, "limitation": "Headless combat and cleanup coverage for the full roster; graphical quality, audio, physical controller operation, and rendered performance require separate review."}
	FileAccess.open(ProjectSettings.globalize_path("res://../evidence/pairing_soak.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("PAIRING_SOAK failures=", failures.size(), " nodes=", node_baseline, "->", node_final)
	for failure in failures: print("FAIL ", failure)
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
