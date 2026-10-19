extends SceneTree

var app: Node
var checks: Array[Dictionary] = []
var failures: int = 0
var original_bindings: Dictionary = {}
var original_settings: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, name_value: String) -> void:
	checks.append({"name": name_value, "passed": condition})
	if not condition:
		failures += 1
		print("UI_FAIL ", name_value)

func frames(count: int) -> void:
	for i in count: await process_frame

func menu_bounds_fit() -> bool:
	var bounds := Rect2(Vector2.ZERO, app.ui.root.size)
	for child: Node in app.ui.screen.get_children():
		if child is PanelContainer and not bounds.grow(1).encloses(child.get_global_rect()): return false
	for child: Node in app.ui.screen.find_children("*", "BaseButton", true, false):
		var rect: Rect2 = child.get_global_rect()
		if rect.position.x < -1 or rect.end.x > bounds.end.x + 1: return false
	return true

func reach_button(prefix: String) -> bool:
	for node: Node in app.ui.screen.find_children("*", "Button", true, false):
		if not node.text.begins_with(prefix): continue
		node.grab_focus()
		await frames(3)
		var parent: Node = node.get_parent()
		while parent != app.ui.screen:
			if parent is ScrollContainer:
				parent.ensure_control_visible(node)
				await frames(2)
			parent = parent.get_parent()
		var rect: Rect2 = node.get_global_rect()
		if not Rect2(Vector2.ZERO, app.ui.root.size).grow(1).encloses(rect): return false
		parent = node.get_parent()
		while parent != app.ui.screen:
			if parent is ScrollContainer and not parent.get_global_rect().grow(1).encloses(rect): return false
			parent = parent.get_parent()
		return true
	return false

func selectors_reachable() -> bool:
	for node: Node in app.ui.screen.find_children("*", "OptionButton", true, false):
		node.grab_focus()
		await frames(3)
		var parent: Node = node.get_parent()
		while parent != app.ui.screen:
			if parent is ScrollContainer:
				parent.ensure_control_visible(node)
				await frames(2)
			parent = parent.get_parent()
		var rect: Rect2 = node.get_global_rect()
		if not Rect2(Vector2.ZERO, app.ui.root.size).grow(1).encloses(rect): return false
		parent = node.get_parent()
		while parent != app.ui.screen:
			if parent is ScrollContainer and not parent.get_global_rect().grow(1).encloses(rect): return false
			parent = parent.get_parent()
	return true

func validate_roster_selection() -> void:
	var roster: Array[FighterDefinition] = RosterRegistry.discover()
	check(roster.size() == 8, "Shipped roster contains exactly eight real fighter definitions")
	var previous_slots: Array = app.ui.slots.duplicate(true)
	app.settings.values.ui_scale = 1.0
	app.apply_settings()
	app.ui.slots[0].device = "Keyboard"
	app.ui.slots[0].device_id = -1
	app.ui.slots[1].device = "CPU"
	app.ui.slots[1].fighter = "f01_clutch"
	app.ui.slots[2].device = "Off"
	app.ui.slots[3].device = "Off"
	for index in roster.size():
		var definition: FighterDefinition = roster[index]
		var metadata_path := "res://assets/characters/%s_presentation.json" % definition.id
		var metadata: Dictionary = {}
		if FileAccess.file_exists(metadata_path):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
			if parsed is Dictionary: metadata = parsed
		var metadata_ready: bool = metadata.has("strides") and metadata.strides.has("walk") and metadata.has("contacts") and metadata.has("effect_sockets")
		var assets_ready: bool = ResourceLoader.exists(definition.model_path) and ResourceLoader.exists(definition.portrait_path) and metadata_ready
		check(assets_ready, "%s has canonical model, portrait and exported presentation metadata" % definition.id)
		app.ui.show_setup(false)
		await frames(5)
		var choose: OptionButton
		for node: Node in app.ui.screen.find_children("*", "OptionButton", true, false):
			if node.item_count == roster.size() and node.get_item_text(0).begins_with(roster[0].display_name):
				choose = node
				break
		check(choose != null and not choose.is_item_disabled(index), "%s is enabled in the actual fighter selector" % definition.id)
		if choose == null or not assets_ready or choose.is_item_disabled(index): continue
		choose.select(index)
		choose.item_selected.emit(index)
		await frames(3)
		var portrait: TextureRect
		for child: Node in choose.get_parent().get_children():
			if child is TextureRect: portrait = child
		check(app.ui.slots[0].fighter == definition.id and portrait != null and portrait.texture != null and portrait.texture.resource_path == definition.portrait_path, "%s selection updates the slot and matching portrait path" % definition.id)
		await app.capture("integration/roster_%s_selection.png" % definition.id)
		var ready: Button
		for node: Node in app.ui.screen.find_children("*", "Button", true, false):
			if node.text.begins_with("READY"):
				ready = node
				break
		var ready_found: bool = ready != null
		if ready_found: ready.pressed.emit()
		await frames(5)
		var started: bool = ready_found and app.world.running and app.ui.screen_name == "match" and app.world.fighters.size() == 2 and app.world.fighters[0].definition.id == definition.id
		check(started, "%s starts through the actual Ready action using the selected definition" % definition.id)
		if started:
			var fighter: RiotFighter = app.world.fighters[0]
			var metadata_loaded: bool = is_equal_approx(fighter.visual.presentation_profile.stride("walk"), float(metadata.strides.walk)) and fighter.visual.presentation_profile.socket("left_hand") == str(metadata.effect_sockets.get("left_hand", ""))
			check(fighter.visual.model != null and fighter.visual.model.scene_file_path == definition.model_path and fighter.visual.animation_player != null and fighter.visual.imported_clips.has("idle") and metadata_loaded, "%s instantiates its canonical animated model and loads presentation metadata" % definition.id)
			app.world.countdown = 0
			for tick in 20: await physics_frame
			await app.capture("integration/roster_%s_match.png" % definition.id)
			app.leave_match()
			await frames(2)
	app.ui.slots.assign(previous_slots)

func validate_arena_selection() -> void:
	var previous_slots: Array = app.ui.slots.duplicate(true)
	var previous_arena: String = app.ui.selected_stage_id
	var previous_preset: String = app.ui.preset
	app.settings.values.ui_scale = 1.0
	app.apply_settings()
	app.ui.slots[0].device = "Keyboard"
	app.ui.slots[0].device_id = -1
	app.ui.slots[1].device = "CPU"
	app.ui.slots[2].device = "Off"
	app.ui.slots[3].device = "Off"
	app.ui.preset = "Party"
	for index in StageCatalog.IDS.size():
		var arena: String = StageCatalog.IDS[index]
		app.ui.show_setup(false)
		await frames(5)
		var choose: OptionButton = app.ui.screen.find_child("ArenaChoice", true, false)
		var choices_valid: bool = choose != null and choose.item_count == StageCatalog.IDS.size()
		if choices_valid:
			for item in StageCatalog.IDS.size():
				choices_valid = choices_valid and choose.get_item_text(item) == StageCatalog.title(StageCatalog.IDS[item]) and not choose.is_item_disabled(item)
		check(choices_valid, "%s appears in the complete enabled arena selector" % arena)
		if not choices_valid: continue
		choose.select(index)
		choose.item_selected.emit(index)
		await frames(5)
		check(app.ui.selected_stage_id == arena and app.world.stage_id == arena, "%s selection loads the matching live arena preview" % arena)
		await app.capture("integration/arena_%s_selection.png" % arena)
		var ready: Button
		for node: Node in app.ui.screen.find_children("*", "Button", true, false):
			if node.text.begins_with("READY"): ready = node; break
		if ready != null: ready.pressed.emit()
		await frames(5)
		var started: bool = app.world.running and app.world.stage_id == arena and app.world.fighters.size() == 2 and app.world.stage.preset == "Party"
		check(started, "%s Ready starts the selected Party arena with two assigned players" % arena)
		if not started: continue
		app.world.countdown = 0
		for tick in 20: await physics_frame
		await app.capture("integration/arena_%s_match.png" % arena)
		app.world.paused = true
		app.ui.show_pause()
		var paused_tick: int = app.world.stage.tick
		for tick in 8: await physics_frame
		check(app.world.stage.tick == paused_tick and app.ui.screen_name == "pause", "%s pause freezes moving platforms, hazards and scenery clock" % arena)
		app.resume_match()
		app.rematch()
		check(app.world.stage_id == arena and app.world.stage.preset == "Party" and app.world.fighters.size() == 2 and is_equal_approx(app.world.stage.platforms[3].y, float(app.world.stage.platforms[3].get("base_y", 5.5))), "%s rematch preserves selection and resets its authored lift height" % arena)
		app.leave_match()
		app.ui.show_setup(true)
		await frames(3)
		ready = null
		for node: Node in app.ui.screen.find_children("*", "Button", true, false):
			if node.text.begins_with("READY"): ready = node; break
		if ready != null: ready.pressed.emit()
		await frames(3)
		check(app.world.running and app.world.stage_id == arena and app.world.training and app.world.stage.preset == "Fair Fight", "%s training preserves arena and disables Party hazards" % arena)
		app.leave_match()
	app.ui.slots.assign(previous_slots)
	app.ui.selected_stage_id = previous_arena
	app.ui.preset = previous_preset
	app.preview_arena(previous_arena)

func training_tape_controls() -> void:
	# Exercise the actual main key routing while ticking the simulation manually.
	app.set_physics_process(false)
	app.world.paused = false
	var key := InputEventKey.new()
	key.keycode = KEY_F6
	key.physical_keycode = KEY_F6
	key.pressed = true
	app._input(key)
	var dummy: TrainingInputProvider = app.world.training_dummy()
	check(dummy != null and dummy.tape_mode == "recording", "F6 key routing begins a player-two recording")
	key.echo = true
	app._input(key)
	check(dummy.tape_mode == "recording", "Held training shortcut does not toggle again on keyboard echo")
	key.echo = false
	var movement := InputEventKey.new()
	movement.physical_keycode = KEY_A
	movement.pressed = true
	app._input(movement)
	for tick in 16: app.world.step()
	app.ui.update_hud()
	check(app.world.fighters[0].position.x == -3.5 and app.world.fighters[1].position.x < 3.0 and app.ui.training_label.text.contains("RECORDING P2"), "Recording routes assigned controls to P2 and exposes ownership in the HUD")
	await app.capture("integration/training_recording.png")
	movement.pressed = false
	app._input(movement)
	app._input(key)
	check(dummy.tape_mode == "idle" and dummy.tape.size() == 16, "F6 saves the current input tape")
	key.keycode = KEY_F7
	key.physical_keycode = KEY_F7
	app._input(key)
	for tick in 5: app.world.step()
	app.ui.update_hud()
	check(dummy.tape_mode == "playing" and dummy.cursor == 5 and app.ui.training_label.text.contains("REPLAY P2"), "F7 resets and replays the saved opponent input in the HUD")
	await app.capture("integration/training_replay.png")
	app.world.paused = true
	app._input(key)
	app.world.step()
	app.resume_match()
	check(dummy.tape_mode == "playing" and dummy.cursor == 5, "Pause ignores tape shortcuts and resume preserves the playhead")
	app._input(key)
	check(dummy.tape_mode == "idle" and dummy.tape.size() == 16, "F7 stops playback while retaining the saved input tape")
	app.set_physics_process(true)

func _run() -> void:
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await frames(10)
	original_settings = app.settings.values.duplicate(true)
	original_bindings = HumanInputProvider.get_keyboard_bindings()
	HumanInputProvider.reset_keyboard_bindings()
	app.settings.values.ui_scale = 1.0
	app.settings.values.graphics = "High"
	app.settings.values.resolution = "1920x1080"
	app.settings.values.fullscreen = false
	app.apply_settings()
	app.ui.show_title()
	await frames(5)
	check(app.ui.screen_name == "title", "Title creates usable screen")
	await app.capture("integration/title.png")
	app.ui.show_setup(false)
	await frames(10)
	check(app.ui.screen_name == "setup", "Character selection creates player cards")
	await app.capture("integration/selection.png")
	app.ui.show_settings()
	await frames(10)
	check(app.ui.screen_name == "settings", "Settings and remapping screen builds")
	await app.capture("integration/settings.png")
	var slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "Keyboard", "device_id": -1}, {"fighter": "f04_deadfall", "device": "CPU"}]
	app.start_match(slots, "Fair Fight", true)
	app.world.countdown = 0
	await frames(30)
	check(app.world.running and app.world.training and app.world.stage.preset == "Fair Fight", "Training starts on same arena with hazards off")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	var before: float = app.world.fighters[0].position.x
	for i in 20: await physics_frame
	key = InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = false
	Input.parse_input_event(key)
	check(app.world.fighters[0].position.x > before + 0.5, "Physical keyboard event path moves assigned player")
	app.world.training_reset()
	await frames(10)
	check(app.world.fighters[0].damage == 0 and app.world.fighters[0].ultimate_meter == 100, "Training reset works")
	await app.capture("integration/training.png")
	var trainee: RiotFighter = app.world.fighters[0]
	# Reset lands the trainee through the real landing state before accepting attacks.
	for tick in 20: app.world.step()
	key = InputEventKey.new()
	key.physical_keycode = KEY_J
	key.pressed = true
	app.world.route_input(key)
	app.world.step()
	app.world.paused = true
	app.ui.update_hud()
	check(trainee.snapshot.is_down("light") and trainee.snapshot.was_pressed("light") and app.ui.training_label.text.contains("HELD LIGHT") and app.ui.training_label.text.contains("LAST PRESS LIGHT"), "Training shows held and pressed actions from the actual fighter snapshot")
	var trained_move: MoveDefinition = trainee.definition.get_move("jab1")
	check(app.ui.training_tip_label.text.contains(trained_move.purpose) and app.ui.training_tip_label.text.contains(trained_move.counterplay), "Training shows the current move's authored purpose and counterplay")
	key.pressed = false
	app.world.route_input(key)
	app.world.paused = false
	for tick in 90: app.world.step()
	app.world.paused = true
	app.ui.update_hud()
	check(not trainee.snapshot.is_down("light") and app.ui.training_label.text.contains("HELD —") and app.ui.training_tip_label.text.contains(trained_move.counterplay), "Training clears released actions and retains the last move tip after recovery")
	app.settings.values.ui_scale = 1.25
	app.apply_settings()
	await frames(5)
	check(Rect2(Vector2.ZERO, app.ui.root.size).grow(1).encloses(app.ui.training_panel.get_global_rect()) and app.ui.training_panel.get_global_rect().grow(1).encloses(app.ui.training_tip_label.get_global_rect()), "Training input and move tips fit their panel at 1.25 text scale")
	await app.capture("integration/training_tips_scale125.png")
	await training_tape_controls()
	app.settings.values.ui_scale = 1.0
	app.apply_settings()
	app.world.paused = true
	app.ui.show_pause()
	await frames(10)
	check(app.ui.screen_name == "pause", "Pause menu opens")
	await app.capture("integration/pause.png")
	app.resume_match()
	check(not app.world.paused and app.ui.screen_name == "match", "Resume restores gameplay screen")
	app.world.finish(0, "VALIDATION RESULT")
	await frames(10)
	check(app.ui.screen_name == "results", "Result signal creates results screen")
	for frame in 130: await physics_frame
	var results_rect: Rect2 = app.ui.screen.get_child(0).get_global_rect()
	var loser_center: Vector2 = app.camera.unproject_position(app.world.fighters[1].visual.global_position + Vector3(0, 1, 0))
	check(app.world.fighters[0].visual.current_clip.ends_with("win") and app.world.fighters[1].visual.visible and app.world.fighters[1].visual.current_clip.ends_with("lose") and not results_rect.grow(20).has_point(loser_center), "Results flourish transitions to winner loop with loser torso visible outside the panel")
	await app.capture("integration/results.png")
	app.rematch()
	await frames(10)
	check(app.world.running and app.world.fighters.size() == 2 and app.world.fighters[0].stocks == 3, "Rematch rebuilds clean match")
	app.leave_match()
	app.ui.show_title()
	await frames(10)
	check(not app.world.running and app.world.fighters.is_empty() and app.ui.screen_name == "title", "Return to title clears fighters")
	app.settings.values.ui_scale = 1.25
	app.apply_settings()
	app.ui.show_title()
	await frames(8)
	check(menu_bounds_fit() and await reach_button("QUIT"), "Title at 1.25 scale fits and final action is reachable")
	await app.capture("integration/title_scale125.png")
	app.ui.show_setup(false)
	await frames(8)
	check(menu_bounds_fit() and await reach_button("READY"), "Four-player selection at 1.25 scale fits and Ready is reachable")
	check(await selectors_reachable(), "All fighter, device, difficulty, and preset selectors remain reachable at 1.25 scale")
	check(app.ui.assignment_status(0) == "READY" and app.ui.assignment_status(1) == "CPU READY" and app.ui.assignment_status(2) == "OFF", "Selection reports assigned keyboard, CPU, and disabled slots")
	app.ui.slots[2].device = "Keyboard"
	check(app.ui.assignment_status(0) == "DEVICE CONFLICT" and app.ui.assignment_status(2) == "DEVICE CONFLICT", "Duplicate keyboard assignment is visibly identified")
	app.ui.slots[2].device = "Gamepad"
	app.ui.slots[2].device_id = 65432
	check(app.ui.assignment_status(2) == "PAD UNPLUGGED", "Absent assigned controller is visibly identified")
	app.ui.slots[2].device = "Off"
	app.ui.slots[2].device_id = -1
	app.ui._refresh_setup_status()
	await app.capture("integration/selection_scale125.png")
	app.ui.show_settings()
	await frames(8)
	check(menu_bounds_fit() and await reach_button("SAVE & RETURN"), "Settings at 1.25 scale fit and Save remains reachable by scrolling")
	HumanInputProvider.set_keyboard_binding("ultimate", KEY_P)
	HumanInputProvider.set_keyboard_binding("light", KEY_K)
	app.ui._refresh_binding_cues()
	check(app.ui.remap_buttons.ultimate.text.ends_with("P") and app.ui.remap_buttons.light.text.ends_with("K") and app.ui.remap_buttons.heavy.text.ends_with("J"), "Remap labels refresh both sides of a swapped binding")
	check(app.ui.keyboard_controls_text().contains("P ULTIMATE") and app.ui.keyboard_controls_text().contains("K LIGHT"), "HUD cue text uses current keyboard bindings")
	await app.capture("integration/settings_scale125.png")
	var four_slots: Array[Dictionary] = [{"fighter": "f01_clutch", "device": "Keyboard", "device_id": -1}, {"fighter": "f04_deadfall", "device": "CPU"}, {"fighter": "f05_fine_print", "device": "CPU"}, {"fighter": "f01_clutch", "device": "CPU"}]
	app.start_match(four_slots, "Fair Fight", false)
	app.world.paused = true
	app.world.fighters[0].ultimate_meter = 100
	app.ui.update_hud()
	await frames(8)
	check(app.ui.hud_cards[0].resource.text == "ULTIMATE READY  [P]", "Live ultimate cue matches remapped keyboard key")
	var hud_fits := true
	for card: Dictionary in app.ui.hud_cards:
		var panel_rect: Rect2 = card.panel.get_global_rect()
		if not Rect2(Vector2.ZERO, app.ui.root.size).grow(1).encloses(panel_rect): hud_fits = false
		if not panel_rect.grow(1).encloses(card.resource.get_global_rect()): hud_fits = false
	check(hud_fits, "Four-player HUD at 1.25 scale stays within screen and contains resource labels")
	await app.capture("integration/four_player_scale125.png")
	app.world.finish(0, "SCALED UI VALIDATION")
	await frames(8)
	var caption_found := false
	for node: Node in app.ui.screen.find_children("*", "Label", true, false):
		if node.text == "CLUTCH PERFORMANCE": caption_found = true
	check(caption_found and not app.world.running, "Winner caption appears after authoritative match finish")
	check(not app.ui.hud.visible, "Finished-match HUD and countdown are hidden behind results")
	check(menu_bounds_fit() and await reach_button("MAIN MENU"), "Four-player results at 1.25 scale fit and final action is reachable")
	await app.capture("integration/results_scale125.png")
	app.leave_match()
	await validate_roster_selection()
	await validate_arena_selection()
	for action: String in original_bindings: HumanInputProvider.set_keyboard_binding(action, int(original_bindings[action]))
	app.settings.values = original_settings
	app.apply_settings()
	var report := {"checks": checks.size(), "failures": failures, "results": checks, "graphical": DisplayServer.get_name() != "headless"}
	FileAccess.open(app.evidence_root.path_join("ui_flow.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("UI_FLOW ", checks.size(), " checks; ", failures, " failures")
	await app.shutdown(1 if failures > 0 else 0)
