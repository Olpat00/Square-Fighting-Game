class_name GameUI
extends CanvasLayer

const INK := Color("0c141d")
const PANEL := Color("182630")
const CREAM := Color("fff5e5")
const MUTE := Color("a5b6bd")
const GOLD := Color("e9c38c")
const CYAN := Color("83d5d2")
const PLAYER_COLORS := [Color("71dad8"), Color("ff997b"), Color("d6e692"), Color("ccaef0")]
var display_font: SystemFont
var app: Node
var root: Control
var screen: Control
var hud: Control
var hud_cards: Array[Dictionary] = []
var timer_label: Label
var announcement: Label
var training_label: Label
var training_tip_label: Label
var training_panel: PanelContainer
var training_last_move: MoveDefinition
var training_pressed_actions := PackedStringArray()
var training_pressed_until: int = 0
var slots: Array[Dictionary] = []
var preset: String = "Party"
var selected_stage_id: String = "lunar_reach"
var setup_training: bool = false
var remap_action: String = ""
var remap_button: Button
var remap_buttons: Dictionary = {}
var controls_label: Label
var setup_statuses: Array[Label] = []
var screen_name: String = ""
var feedback_label: Label
var feedback_until: int = 0

func configure(application: Node) -> void:
	app = application
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray(["Bahnschrift", "Arial"])
	display_font.font_weight = 700
	theme.default_font = font
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_stylebox("normal", "Button", style(Color("20303b"), Color("40515a"), 1))
	theme.set_stylebox("hover", "Button", style(Color("35464c"), GOLD, 1))
	theme.set_stylebox("focus", "Button", style(Color.TRANSPARENT, GOLD, 2))
	theme.set_stylebox("pressed", "Button", style(Color("44534f"), GOLD, 1))
	theme.set_stylebox("normal", "OptionButton", style(Color("14212a"), Color("3d515b"), 1))
	theme.set_stylebox("hover", "OptionButton", style(Color("283c45"), GOLD, 1))
	theme.set_stylebox("focus", "OptionButton", style(Color.TRANSPARENT, GOLD, 2))
	theme.set_color("font_color", "OptionButton", CREAM)
	theme.set_stylebox("panel", "PopupMenu", style(INK, Color("526068"), 1))
	theme.set_stylebox("scroll", "VScrollBar", meter_style(Color("17232c")))
	theme.set_stylebox("grabber", "VScrollBar", meter_style(Color("52646d")))
	theme.set_stylebox("grabber_highlight", "VScrollBar", meter_style(GOLD))
	theme.set_stylebox("grabber_pressed", "VScrollBar", meter_style(GOLD))
	root.theme = theme
	apply_scale()
	for i in 4:
		slots.append({"fighter": ["f01_clutch", "f04_deadfall", "f05_fine_print", "f01_clutch"][i], "device": "Keyboard" if i == 0 else "CPU" if i == 1 else "Off", "device_id": -1, "difficulty": "Normal"})
	Input.joy_connection_changed.connect(func(_device: int, _connected: bool) -> void: _refresh_setup_status())

func style(background: Color, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(5)
	box.content_margin_left = 17
	box.content_margin_right = 17
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func meter_style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(2)
	return box

func display(text_value: String, size_value: int, color: Color = CREAM) -> Label:
	var node := label(text_value, size_value, color)
	node.add_theme_font_override("font", display_font)
	return node

func primary(node: Button) -> Button:
	node.add_theme_font_override("font", display_font)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_color_override("font_focus_color", INK)
	node.add_theme_color_override("font_hover_color", INK)
	node.add_theme_color_override("font_pressed_color", INK)
	node.add_theme_stylebox_override("normal", style(GOLD))
	node.add_theme_stylebox_override("hover", style(Color("ffe0aa")))
	node.add_theme_stylebox_override("pressed", style(Color("cfa874")))
	var focus_style := style(Color.TRANSPARENT, CREAM, 2)
	focus_style.shadow_color = Color(GOLD, .3)
	focus_style.shadow_size = 4
	node.add_theme_stylebox_override("focus", focus_style)
	return node

func scrim(parent: Control, from_color: Color, to_color: Color, vertical: bool = false) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([from_color, to_color])
	if not vertical:
		gradient.offsets = PackedFloat32Array([0.0, 0.43, 0.72, 1.0])
		gradient.colors = PackedColorArray([from_color, from_color.lerp(to_color, .38), to_color, to_color])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill_to = Vector2(0, 1) if vertical else Vector2(1, 0)
	var image := TextureRect.new()
	image.texture = texture
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

func rule_line(parent: Node, color: Color = Color("50606a")) -> void:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func ability_icon(fighter_id: String, color: Color, extent: float = 28) -> Control:
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(_draw_ability.bind(icon, fighter_id, color))
	return icon

func _draw_ability(icon: Control, fighter_id: String, color: Color) -> void:
	var s: float = minf(icon.size.x, icon.size.y)
	var c := Vector2(s, s) * 0.5
	match fighter_id:
		"f01_clutch":
			icon.draw_colored_polygon(PackedVector2Array([Vector2(.56,.08)*s, Vector2(.22,.53)*s, Vector2(.47,.53)*s, Vector2(.36,.92)*s, Vector2(.82,.38)*s, Vector2(.57,.38)*s]), color)
		"f02_sunstruck":
			icon.draw_arc(c, s * .21, 0, TAU, 24, color, 2, true)
			for i in 8:
				var direction := Vector2.from_angle(i * TAU / 8.0)
				icon.draw_line(c + direction * s * .33, c + direction * s * .44, color, 2, true)
		"f03_heavy_duty":
			icon.draw_line(Vector2(.15,.5)*s, Vector2(.85,.5)*s, color, 3, true)
			for x: float in [.2, .8]: icon.draw_rect(Rect2(Vector2(x-.08,.22)*s, Vector2(.16,.56)*s), color)
		"f04_deadfall":
			icon.draw_line(Vector2(.47,.1)*s, Vector2(.47,.9)*s, color, 3, true)
			icon.draw_polyline(PackedVector2Array([Vector2(.16,.27)*s, Vector2(.47,.52)*s, Vector2(.84,.25)*s]), color, 2, true)
			icon.draw_line(Vector2(.47,.72)*s, Vector2(.76,.55)*s, color, 2, true)
		"f06_rugged_explorer":
			icon.draw_arc(c, s * .29, PI * .12, PI * 1.9, 24, color, 2, true)
			icon.draw_line(Vector2(.22,.72)*s, Vector2(.77,.27)*s, color, 2, true)
			icon.draw_circle(Vector2(.78,.24)*s, s * .07, color)
		"f07_urban_sentinel":
			icon.draw_colored_polygon(PackedVector2Array([Vector2(.5,.1)*s, Vector2(.83,.25)*s, Vector2(.77,.66)*s, Vector2(.5,.91)*s, Vector2(.23,.66)*s, Vector2(.17,.25)*s]), Color(color, .22))
			icon.draw_polyline(PackedVector2Array([Vector2(.5,.1)*s, Vector2(.83,.25)*s, Vector2(.77,.66)*s, Vector2(.5,.91)*s, Vector2(.23,.66)*s, Vector2(.17,.25)*s, Vector2(.5,.1)*s]), color, 2, true)
		"f08_midnight_gentleman":
			icon.draw_arc(c, s * .37, -PI * .65, PI * .65, 24, color, 2, true)
			icon.draw_circle(c + Vector2(.08, 0) * s, s * .12, color)
		_:
			icon.draw_rect(Rect2(Vector2(.24,.1)*s, Vector2(.55,.8)*s), color, false, 2)
			icon.draw_polyline(PackedVector2Array([Vector2(.33,.54)*s, Vector2(.46,.68)*s, Vector2(.7,.36)*s]), color, 2, true)

func headshot(definition: FighterDefinition) -> Texture2D:
	if not ResourceLoader.exists(definition.portrait_path): return null
	var source: Texture2D = load(definition.portrait_path)
	# Canonical studio portraits keep the face in the upper half.
	var crop := AtlasTexture.new()
	crop.atlas = source
	var dimensions := source.get_size()
	crop.region = Rect2(Vector2(dimensions.x * .22, dimensions.y * .065), Vector2(dimensions.x * .56, dimensions.x * .56))
	return crop

func selection_summary(definition: FighterDefinition) -> String:
	if definition == null: return ""
	# Keep the invitation concise; the full authored mechanic remains in the tooltip.
	var summaries: Dictionary = {
		"momentum": "Mix up your attacks to build Momentum. Spend it on neutral, side, or up specials for an extra kinetic effect.",
		"encore": "Catch your returning disc three times to supercharge the next throw. Bank shots off your reflector.",
		"commitment": "Commit to heavy swings. Brief armor absorbs one light hit; grabs and harder hits still stop you.",
		"fieldcraft": "Set traps, force mistakes. A sprung trap powers up the travel of your next side or up special.",
		"citations": "Land precise specials and parries. Stack Citations, then cash them in with side heavy or your ultimate.",
		"trailblazer": "Land the grapple to reel an opponent into your range. Use the terrain and your quick recovery to keep pursuing.",
		"sentinel": "Fortify to absorb a hit and release a close pulse. Keep opponents in front of your guard.",
		"shadowstep": "Slip through your opponent with Shadow Step, then turn around for a punish. Your position is the weapon."
	}
	return str(summaries.get(definition.mechanic, definition.passive_description))

func clear_screen(id: String) -> void:
	screen_name = id
	remap_action = ""
	remap_buttons.clear()
	if is_instance_valid(screen):
		root.remove_child(screen)
		screen.queue_free()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)
	_focus_first.call_deferred()

func _focus_first() -> void:
	if not is_instance_valid(screen) or screen_name == "match": return
	var buttons := screen.find_children("*", "Button", true, false)
	if not buttons.is_empty(): buttons[0].grab_focus()

func label(text_value: String, size_value: int = 20, color: Color = CREAM) -> Label:
	var node := Label.new()
	node.text = text_value
	node.set_meta("base_font_size", size_value)
	node.add_theme_font_size_override("font_size", roundi(size_value * _ui_scale()))
	node.add_theme_color_override("font_color", color)
	return node

func button(text_value: String, action: Callable, min_width: float = 160) -> Button:
	var node := Button.new()
	node.text = text_value
	node.custom_minimum_size = Vector2(min_width, 47)
	node.pressed.connect(func() -> void: app.audio.play_sound("menu_confirm", -4); action.call())
	node.mouse_entered.connect(func() -> void: app.audio.play_sound("menu_move", -10))
	return node

func _ui_scale() -> float:
	return clampf(float(app.settings.values.get("ui_scale", 1.0)), 0.8, 1.25)

func apply_scale() -> void:
	if not is_instance_valid(root): return
	root.theme.default_font_size = roundi(17 * _ui_scale())
	for node: Node in root.find_children("*", "Control", true, false):
		if node.has_meta("base_font_size"):
			node.add_theme_font_size_override("font_size", roundi(float(node.get_meta("base_font_size")) * _ui_scale()))
	if is_instance_valid(hud):
		for entry: Dictionary in hud_cards:
			entry.panel.anchor_top = 0.942 - 0.115 * _ui_scale()
		_refresh_binding_cues()

func keyboard_key(action: String) -> String:
	return OS.get_keycode_string(int(HumanInputProvider.get_keyboard_bindings().get(action, 0))).to_upper()

func keyboard_controls_text() -> String:
	var direction := "/".join([keyboard_key("up"), keyboard_key("left"), keyboard_key("down"), keyboard_key("right")])
	var cues := PackedStringArray(["%s MOVE" % direction])
	for action: String in ["jump", "light", "heavy", "special", "defend", "grab", "ultimate", "taunt", "pause"]:
		cues.append("%s %s" % [keyboard_key(action), action.to_upper()])
	return "  ·  ".join(cues)

func ultimate_cue(fighter: RiotFighter) -> String:
	if fighter.provider is HumanInputProvider:
		return "ULTIMATE READY  [%s]" % ("L3" if fighter.provider.device_id >= 0 else keyboard_key("ultimate"))
	return "ULTIMATE READY"

func _refresh_binding_cues() -> void:
	if is_instance_valid(controls_label): controls_label.text = keyboard_controls_text()
	for action: String in remap_buttons:
		if is_instance_valid(remap_buttons[action]):
			remap_buttons[action].text = "%s   %s" % [action.to_upper(), keyboard_key(action)]

func panel(parent: Node, left: float, top: float, right: float, bottom: float, opacity: float = 0.95) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.anchor_left = left
	p.anchor_top = top
	p.anchor_right = right
	p.anchor_bottom = bottom
	var panel_style := style(Color(INK, opacity), Color("38464f"), 1)
	panel_style.shadow_color = Color(0, 0, 0, 0.22)
	panel_style.shadow_size = 14
	panel_style.shadow_offset = Vector2(0, 6)
	p.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(p)
	return p

func vbox(parent: Node, spacing: int = 12) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", spacing)
	if parent is PanelContainer:
		# Panels keep their viewport bounds when larger text needs more room.
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.follow_focus = true
		parent.add_child(scroll)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(box)
	else:
		parent.add_child(box)
	return box

func fit_choice(choice: OptionButton) -> void:
	choice.fit_to_longest_item = false
	choice.clip_text = true
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func assignment_status(index: int) -> String:
	var slot: Dictionary = slots[index]
	if setup_training and index == 1: return "CPU READY"
	if slot.device == "Off": return "OFF"
	if not ResourceLoader.exists("res://assets/characters/%s.glb" % str(slot.fighter)): return "MAPPING PENDING"
	if slot.device == "CPU": return "CPU READY"
	if slot.device == "Gamepad" and not Input.get_connected_joypads().has(int(slot.device_id)): return "PAD UNPLUGGED"
	for other_index in (2 if setup_training else 4):
		if other_index == index or (setup_training and other_index == 1): continue
		var other: Dictionary = slots[other_index]
		if other.device == "Off" or other.device == "CPU": continue
		if slot.device == "Keyboard" and other.device == "Keyboard": return "DEVICE CONFLICT"
		if slot.device == "Gamepad" and other.device == "Gamepad" and int(slot.device_id) == int(other.device_id): return "DEVICE CONFLICT"
	return "READY"

func _refresh_setup_status() -> void:
	if screen_name != "setup": return
	for index in setup_statuses.size():
		if not is_instance_valid(setup_statuses[index]): continue
		var status: String = assignment_status(index)
		setup_statuses[index].text = status
		setup_statuses[index].modulate = CYAN if status.ends_with("READY") else MUTE if status == "OFF" else Color("ff9f84")

func hbox(parent: Node, spacing: int = 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", spacing)
	parent.add_child(box)
	return box

func show_title() -> void:
	clear_screen("title")
	if hud: hud.visible = false
	scrim(screen, Color(INK, .97), Color(INK, 0))
	var p := panel(screen, 0.057, 0.09, 0.45, 0.91, 0)
	p.add_theme_stylebox_override("panel", style(Color.TRANSPARENT))
	var box := vbox(p, 9)
	box.add_child(label("TWO WORLDS   /   NO SUPERVISION", 13, GOLD))
	var brand := display("UNSUPERVISED", 20, CREAM)
	brand.custom_minimum_size.y = 35
	box.add_child(brand)
	var title := display("ROOFTOP\nRIOT", 83)
	title.add_theme_constant_override("line_spacing", -13)
	box.add_child(title)
	var desc := label("Eight fighters. Two worlds.\nOne spectacularly bad idea.", 18, MUTE)
	desc.custom_minimum_size.y = 66
	box.add_child(desc)
	var start := primary(button("START A FIGHT   →", func() -> void: show_setup(false), 300))
	start.custom_minimum_size.y = 54
	start.alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(start)
	var training := button("TRAINING", func() -> void: show_setup(true))
	training.alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(training)
	var settings := button("SETTINGS & CONTROLS", show_settings)
	settings.alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(settings)
	var quit_button := button("QUIT", func() -> void: app.shutdown())
	quit_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(quit_button)
	for action: Button in [start, training, settings, quit_button]:
		action.custom_minimum_size.x = 345
		action.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(label("2–4 PLAYERS   ·   LOCAL MULTIPLAYER   ·   %d ARENAS" % StageCatalog.IDS.size(), 11, MUTE))
	var venue := VBoxContainer.new()
	venue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	venue.anchor_left = .73
	venue.anchor_top = .08
	venue.anchor_right = .94
	venue.anchor_bottom = .2
	screen.add_child(venue)
	var location := label(str(StageCatalog.info(app.world.stage_id).tagline), 12, GOLD)
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	venue.add_child(location)
	var invitation := display(str(StageCatalog.info(app.world.stage_id).invitation), 23)
	invitation.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	invitation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	venue.add_child(invitation)

func show_setup(training_mode: bool) -> void:
	setup_training = training_mode
	app.preview_arena(selected_stage_id)
	var roster := RosterRegistry.discover()
	clear_screen("setup")
	setup_statuses.clear()
	scrim(screen, Color(INK, .87), Color(INK, .45), true)
	var p := panel(screen, 0.035, 0.035, 0.965, 0.965, .70)
	p.add_theme_stylebox_override("panel", style(Color(INK, .62)))
	var box := vbox(p, 11)
	var heading := hbox(box)
	var title := display("The training room" if training_mode else "Make an entrance.", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(label("GUEST LIST   /   %d FIGHTERS INVITED" % roster.size(), 12, GOLD))
	box.add_child(label("Choose your fighter, controller and arena. Make the whole world watch.", 16, MUTE))
	var cards := hbox(box, 18)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in (2 if training_mode else 4):
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_style := style(Color(PANEL, .96))
		card_style.border_color = PLAYER_COLORS[i]
		card_style.border_width_top = 3
		card_style.content_margin_left = 14
		card_style.content_margin_right = 14
		card.add_theme_stylebox_override("panel", card_style)
		cards.add_child(card)
		var content := vbox(card, 8)
		var slot_header := hbox(content)
		var player := display("P%d" % (i + 1), 18, PLAYER_COLORS[i])
		player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_header.add_child(player)
		var status := label("", 11)
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_header.add_child(status)
		setup_statuses.append(status)
		var def := RosterRegistry.by_id(slots[i].fighter)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(150, 200)
		portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if def and ResourceLoader.exists(def.portrait_path): portrait.texture = load(def.portrait_path)
		content.add_child(portrait)
		var choose := OptionButton.new()
		fit_choice(choose)
		choose.add_theme_font_override("font", display_font)
		choose.add_theme_font_size_override("font_size", roundi(22 * _ui_scale()))
		choose.set_meta("base_font_size", 22)
		for f in roster:
			choose.add_item(f.display_name if ResourceLoader.exists(f.model_path) else f.display_name + " · mapping pending")
			choose.set_item_disabled(choose.item_count - 1, not ResourceLoader.exists(f.model_path))
		for j in roster.size():
			if roster[j].id == slots[i].fighter: choose.select(j)
		content.add_child(choose)
		var ability_row := hbox(content, 8)
		var icon := ability_icon(def.id if def else "", GOLD)
		ability_row.add_child(icon)
		var archetype := label(def.archetype if def else "", 14, GOLD)
		archetype.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		archetype.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		archetype.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ability_row.add_child(archetype)
		var text := label(selection_summary(def), 14, MUTE)
		text.tooltip_text = def.passive_description if def else ""
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.y = 72
		content.add_child(text)
		choose.item_selected.connect(func(index: int) -> void:
			var selected: FighterDefinition = roster[index]
			slots[i].fighter = selected.id
			archetype.text = selected.archetype
			text.text = selection_summary(selected)
			text.tooltip_text = selected.passive_description
			for connection: Dictionary in icon.draw.get_connections(): icon.draw.disconnect(connection.callable)
			icon.draw.connect(_draw_ability.bind(icon, selected.id, GOLD))
			icon.queue_redraw()
			portrait.texture = load(selected.portrait_path) if ResourceLoader.exists(selected.portrait_path) else null
			_refresh_setup_status())
		var device := OptionButton.new()
		fit_choice(device)
		var devices: Array[Dictionary] = [{"label": "Keyboard", "id": -1}, {"label": "CPU", "id": -2}, {"label": "Off", "id": -3}]
		for joy in Input.get_connected_joypads(): devices.append({"label": "Pad %d · %s" % [joy + 1, Input.get_joy_name(joy)], "id": joy})
		if slots[i].device == "Gamepad" and not Input.get_connected_joypads().has(int(slots[i].device_id)):
			devices.append({"label": "Pad %d · disconnected" % (int(slots[i].device_id) + 1), "id": slots[i].device_id})
		for d in devices: device.add_item(d.label)
		device.select(0 if slots[i].device == "Keyboard" else 1 if slots[i].device == "CPU" else 2 if slots[i].device == "Off" else 0)
		if slots[i].device == "Gamepad":
			for j in devices.size():
				if devices[j].id == slots[i].device_id: device.select(j)
		device.item_selected.connect(func(index: int) -> void:
			slots[i].device = "Keyboard" if devices[index].id == -1 else "CPU" if devices[index].id == -2 else "Off" if devices[index].id == -3 else "Gamepad"
			slots[i].device_id = devices[index].id
			_refresh_setup_status())
		content.add_child(device)
		var difficulty := OptionButton.new()
		fit_choice(difficulty)
		for level in ["Easy", "Normal", "Hard"]: difficulty.add_item(level)
		difficulty.select(["Easy", "Normal", "Hard"].find(slots[i].difficulty))
		difficulty.item_selected.connect(func(index: int) -> void: slots[i].difficulty = ["Easy", "Normal", "Hard"][index])
		content.add_child(difficulty)
	_refresh_setup_status()
	var arena_row := hbox(box, 24)
	var arena_column := vbox(arena_row, 4)
	arena_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var arena_choice := OptionButton.new()
	arena_choice.name = "ArenaChoice"
	fit_choice(arena_choice)
	for id: String in StageCatalog.IDS: arena_choice.add_item(StageCatalog.title(id))
	arena_choice.select(StageCatalog.IDS.find(selected_stage_id))
	arena_choice.custom_minimum_size = Vector2(290, 40)
	arena_column.add_child(arena_choice)
	var arena_text := label(StageCatalog.description(selected_stage_id), 13, MUTE)
	arena_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_column.add_child(arena_text)
	var rule := OptionButton.new()
	rule.add_item(StageCatalog.party_label(selected_stage_id))
	rule.add_item("Fair Fight · fixed platforms")
	rule.select(1 if training_mode or preset == "Fair Fight" else 0)
	rule.disabled = training_mode
	rule.item_selected.connect(func(index: int) -> void: preset = "Party" if index == 0 else "Fair Fight")
	arena_choice.item_selected.connect(func(index: int) -> void:
		selected_stage_id = StageCatalog.IDS[index]
		arena_text.text = StageCatalog.description(selected_stage_id)
		rule.set_item_text(0, StageCatalog.party_label(selected_stage_id))
		app.preview_arena(selected_stage_id))
	arena_row.add_child(rule)
	var error := label("", 16, Color("ff9f84"))
	box.add_child(error)
	var actions := hbox(box)
	actions.add_child(button("← BACK", show_title))
	actions.add_child(button("CPU DEMO", func() -> void:
		for i in 4: slots[i].device = "CPU"
		show_setup(false)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	actions.add_child(primary(button("READY — LET'S GO  →", func() -> void:
		var active: Array[Dictionary] = []
		var used: Dictionary = {}
		for i in (2 if setup_training else 4):
			var slot: Dictionary = slots[i].duplicate()
			if setup_training and i == 1: slot.device = "CPU"
			if slot.device == "Off": continue
			if slot.device == "Gamepad" and not Input.get_connected_joypads().has(int(slot.device_id)):
				error.text = "Reconnect the assigned controller, or choose another device."
				return
			if slot.device != "CPU":
				var key := str(slot.device_id)
				if used.has(key):
					error.text = "Assign each keyboard or controller to just one player."
					return
				used[key] = true
			active.append(slot)
		if active.size() < 2:
			error.text = "Choose at least two active players. CPU opponents are welcome."
			return
		app.start_match(active, "Fair Fight" if setup_training else preset, setup_training, selected_stage_id), 290)))

func show_hud() -> void:
	clear_screen("match")
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hud: hud.queue_free()
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(hud)
	hud_cards.clear()
	var count: int = app.world.fighters.size()
	for i in count:
		var fighter: RiotFighter = app.world.fighters[i]
		var width_value: float = 0.215 if count >= 3 else 0.245
		var left: float = 0.035 + i * (0.93 - width_value) / maxf(1, count - 1)
		var p := panel(hud, left, 0.942 - 0.115 * _ui_scale(), left + width_value, 0.942)
		var hud_style := style(Color(INK, .90))
		hud_style.border_color = fighter.player_color
		hud_style.border_width_top = 3
		hud_style.content_margin_left = 10
		hud_style.content_margin_right = 12
		hud_style.content_margin_top = 8
		hud_style.content_margin_bottom = 8
		p.add_theme_stylebox_override("panel", hud_style)
		var row := hbox(p, 12)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(84, 86)
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = headshot(fighter.definition)
		row.add_child(portrait)
		var box := vbox(row, 0)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := display("P%d   %s" % [i + 1, fighter.definition.display_name], 16, fighter.player_color)
		name_label.clip_text = true
		box.add_child(name_label)
		var score := hbox(box, 12)
		var damage_label := display("0%", 46)
		damage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score.add_child(damage_label)
		var stocks_label := label("● ● ●", 12, GOLD)
		stocks_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		score.add_child(stocks_label)
		var meter := ProgressBar.new()
		meter.custom_minimum_size.y = 4
		meter.show_percentage = false
		meter.add_theme_stylebox_override("fill", meter_style(fighter.player_color))
		meter.add_theme_stylebox_override("background", meter_style(Color("344550")))
		box.add_child(meter)
		var resource_label := label("", 11, MUTE)
		resource_label.clip_text = true
		box.add_child(resource_label)
		hud_cards.append({"panel": p, "damage": damage_label, "stocks": stocks_label, "meter": meter, "resource": resource_label})
	timer_label = display("6:00", 30)
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	timer_label.offset_left = -100
	timer_label.offset_right = 100
	timer_label.offset_top = 19
	timer_label.offset_bottom = 62
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, .7))
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(timer_label)
	announcement = display("", 72, GOLD)
	announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	announcement.offset_top = 135
	announcement.add_theme_color_override("font_shadow_color", Color(INK, .85))
	announcement.add_theme_constant_override("shadow_offset_y", 4)
	announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(announcement)
	feedback_label = display("", 22, GOLD)
	feedback_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	feedback_label.offset_left = -370
	feedback_label.offset_right = 370
	feedback_label.offset_top = 82
	feedback_label.offset_bottom = 119
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(feedback_label)
	var controls_background := ColorRect.new()
	controls_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_background.anchor_top = 0.954
	controls_background.color = Color(INK, 0.87)
	controls_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls_background)
	controls_label = label(keyboard_controls_text(), 11, MUTE)
	controls_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_label.anchor_top = 0.964
	controls_label.offset_left = 35
	controls_label.offset_right = -35
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls_label)
	if app.world.training:
		training_last_move = null
		training_pressed_actions.clear()
		training_pressed_until = 0
		training_panel = panel(hud, 0.025, 0.04, 0.37, 0.46, .85)
		var box := vbox(training_panel, 7)
		box.add_child(display("The training room", 20, CREAM))
		var shortcuts := label("F1 reset · F2 damage · F3 dummy · F4 hitboxes\nF5 ultimate · F6 record/save P2 · F7 loop/stop\nRecord: your controls move P2; P1 stays neutral.\n10s max · 0.75s loop gap · pause freezes tape", 11, MUTE)
		shortcuts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(shortcuts)
		rule_line(box)
		training_label = label("", 13)
		training_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(training_label)
		training_tip_label = label("", 12, MUTE)
		training_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(training_tip_label)

func update_hud() -> void:
	if not is_instance_valid(hud) or not hud.visible: return
	if is_instance_valid(feedback_label) and Time.get_ticks_msec() > feedback_until:
		feedback_label.text = ""
	for i in mini(hud_cards.size(), app.world.fighters.size()):
		var fighter: RiotFighter = app.world.fighters[i]
		hud_cards[i].damage.text = "%d%%" % fighter.damage if fighter.stocks > 0 else "OUT"
		hud_cards[i].damage.modulate = Color("ff856e") if fighter.damage > 100 else CREAM
		hud_cards[i].stocks.text = "● ".repeat(fighter.stocks) + "○ ".repeat(3 - fighter.stocks)
		hud_cards[i].meter.value = fighter.ultimate_meter
		hud_cards[i].resource.text = ultimate_cue(fighter) if fighter.ultimate_meter >= 100 else fighter.mechanics.resource_text()
	var seconds: int = (app.world.sudden_timer if app.world.sudden_death else app.world.time_left) / 60
	timer_label.text = "TRAINING" if app.world.training else "%d:%02d" % [seconds / 60, seconds % 60]
	announcement.text = ("SUDDEN DEATH\n" if app.world.sudden_death else "") + str(ceili(app.world.countdown / 60.0)) if app.world.countdown > 0 else ""
	if app.world.training and is_instance_valid(training_label) and not app.world.fighters.is_empty():
		var f: RiotFighter = app.world.fighters[0]
		var dummy: TrainingInputProvider = app.world.training_dummy()
		if dummy != null and dummy.tape_mode == "recording": f = app.world.fighters[1]
		var held := PackedStringArray()
		var pressed := PackedStringArray()
		if f.snapshot:
			for action: String in InputProvider.ACTIONS:
				if f.snapshot.is_down(action): held.append(action.to_upper())
				if f.snapshot.was_pressed(action): pressed.append(action.to_upper())
		if not pressed.is_empty():
			training_pressed_actions = pressed
			training_pressed_until = Time.get_ticks_msec() + 650
		if Time.get_ticks_msec() > training_pressed_until: training_pressed_actions.clear()
		training_label.text = "AIM %s  ·  %s\nHELD %s  ·  LAST PRESS %s" % [str(f.snapshot.move) if f.snapshot else "—", f.state.to_upper(), " + ".join(held) if not held.is_empty() else "—", " + ".join(training_pressed_actions) if not training_pressed_actions.is_empty() else "—"]
		var phase: String = f.state.to_upper()
		if f.move != null and f.state == "attack":
			phase = "STARTUP" if f.move_tick < f.move.startup else "ACTIVE" if f.move.is_active(f.move_tick) else "BETWEEN HITS" if f.move_tick <= f.move.active_windows.back().y else "RECOVERY"
			phase += " %d / %d" % [f.move_tick + 1, f.move.total_ticks()]
		training_label.text += "\n%s · COMBO %d HITS / %.1f%%\n%s" % [phase, app.world.training_combo_hits, app.world.training_combo_damage, dummy.status_text() if dummy != null else "DUMMY"]
		if f.move != null: training_last_move = f.move
		if training_last_move != null:
			training_tip_label.text = "%s\nUSE  %s\nCOUNTER  %s" % [training_last_move.display_name.to_upper(), training_last_move.purpose, training_last_move.counterplay]
		else:
			var special_key: String = "Y" if f.provider is HumanInputProvider and f.provider.device_id >= 0 else keyboard_key("special")
			training_tip_label.text = "Try an attack to see its purpose and counterplay.\nDirection + %s for specials · up + %s recovers." % [special_key, special_key]

func feedback(text_value: String, duration_ms: int = 1600) -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = text_value
		feedback_until = Time.get_ticks_msec() + duration_ms

func show_pause(message: String = "INTERMISSION") -> void:
	clear_screen("pause")
	scrim(screen, Color(INK, .58), Color(INK, .35), true)
	var box := vbox(panel(screen, 0.33, 0.22, 0.67, 0.76))
	box.add_child(label("AFTER HOURS   /   INTERMISSION", 11, GOLD))
	box.add_child(display("Take a breather." if message == "INTERMISSION" else message, 31))
	box.add_child(label(str(StageCatalog.info(app.world.stage_id).pause), 17, MUTE))
	box.add_child(primary(button("RESUME", func() -> void: app.resume_match())))
	box.add_child(button("REMATCH", func() -> void: app.rematch()))
	box.add_child(button("SETTINGS & CONTROLS", show_settings))
	box.add_child(button("GUEST LIST", func() -> void: app.leave_match(); show_setup(false)))
	box.add_child(button("MAIN MENU", func() -> void: app.leave_match(); show_title()))

func show_results(result: Dictionary) -> void:
	clear_screen("results")
	if is_instance_valid(hud): hud.visible = false
	var box := vbox(panel(screen, 0.30, 0.19, 0.70, 0.80, .92), 16)
	box.add_child(label("THE PARTY HAS A WINNER", 12, GOLD))
	var winner: int = result.winner
	box.add_child(display(app.world.fighters[winner].definition.display_name if winner >= 0 else "Draw", 49, CREAM))
	if winner >= 0:
		var caption := display(app.world.fighters[winner].definition.final_ko_caption, 21, GOLD)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(caption)
	box.add_child(label(str(result.reason), 17, MUTE))
	rule_line(box)
	for f: RiotFighter in app.world.fighters:
		box.add_child(label("P%d   %s    ·    %d stocks   /   %d%%" % [f.slot + 1, f.definition.display_name, f.stocks, f.damage], 16, f.player_color))
	box.add_child(primary(button("RUN IT BACK  →", func() -> void: app.rematch())))
	box.add_child(button("CHANGE FIGHTERS", func() -> void: app.leave_match(); show_setup(false)))
	box.add_child(button("MAIN MENU", func() -> void: app.leave_match(); show_title()))

func show_settings() -> void:
	clear_screen("settings")
	remap_buttons.clear()
	scrim(screen, Color(INK, .8), Color(INK, .6), true)
	var box := vbox(panel(screen, 0.12, 0.055, 0.88, 0.95), 10)
	box.add_child(label("THE LAST RESORT   /   YOUR PREFERENCES", 11, GOLD))
	box.add_child(display("House rules", 36))
	var columns := hbox(box, 35)
	var options := vbox(columns, 8)
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in ["master", "music", "effects", "shake", "flashes", "rumble", "ui_scale"]:
		var row := hbox(options)
		var text := label(key.replace("_", " ").capitalize(), 19)
		text.custom_minimum_size.x = 130
		row.add_child(text)
		var slider := HSlider.new()
		slider.min_value = 0.8 if key == "ui_scale" else 0
		slider.max_value = 1.25 if key == "ui_scale" else 1
		slider.step = 0.05
		slider.value = app.settings.values[key]
		slider.custom_minimum_size.x = 220
		slider.value_changed.connect(func(value: float) -> void:
			app.settings.values[key] = value
			app.audio.apply_volume())
		row.add_child(slider)
	for key in ["blood", "profanity", "fullscreen"]:
		var toggle := CheckButton.new()
		toggle.text = key.capitalize()
		toggle.button_pressed = app.settings.values[key]
		toggle.toggled.connect(func(value: bool) -> void: app.settings.values[key] = value)
		options.add_child(toggle)
	for pair in [["resolution", ["1280x720", "1600x900", "1920x1080"]], ["graphics", ["High", "Low"]]]:
		var choice := OptionButton.new()
		for value in pair[1]: choice.add_item(str(value))
		choice.select(pair[1].find(app.settings.values[pair[0]]))
		choice.item_selected.connect(func(index: int) -> void: app.settings.values[pair[0]] = pair[1][index])
		options.add_child(choice)
	options.add_child(label("Low: reduced lighting; 1K fighters from next match.\nSeparate Mobile renderer launcher requires restart.", 13, MUTE))
	var bindings := vbox(columns, 4)
	bindings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bindings.add_child(display("Keyboard · click to remap", 18, GOLD))
	for action in ["left", "right", "up", "down", "jump", "light", "heavy", "special", "defend", "grab", "ultimate", "taunt", "pause"]:
		var keycode: int = int(HumanInputProvider.get_keyboard_bindings().get(action, 0))
		var b := button("%-10s   %s" % [action.to_upper(), OS.get_keycode_string(keycode)], func() -> void: pass, 220)
		b.custom_minimum_size.y = 31
		b.set_meta("base_font_size", 14)
		b.add_theme_font_size_override("font_size", roundi(14 * _ui_scale()))
		remap_buttons[action] = b
		b.pressed.connect(func() -> void:
			remap_action = action
			remap_button = b
			b.text = "PRESS A KEY…")
		bindings.add_child(b)
	box.add_child(label("GAMEPAD  Left stick: move/aim · A: jump · X: light · B: heavy · Y: special\nLB/trigger: defend · RB: grab · L3: ultimate · D-pad up: taunt · Start: pause", 16, MUTE))
	box.add_child(primary(button("SAVE & RETURN", func() -> void:
		app.settings.save_settings()
		HumanInputProvider.save_keyboard_bindings()
		app.apply_settings()
		if app.world.running: show_pause()
		else: show_title())))

func capture_remap(event: InputEvent) -> bool:
	if remap_action.is_empty() or not event is InputEventKey or not event.pressed: return false
	HumanInputProvider.set_keyboard_binding(remap_action, HumanInputProvider.event_keycode(event))
	remap_action = ""
	_refresh_binding_cues()
	return true
