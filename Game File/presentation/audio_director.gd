class_name AudioDirector
extends Node

var settings: SettingsStore
var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var cursor: int = 0
var last_played: Dictionary = {}
var enabled: bool = true
var sample_counts: Dictionary = {}
var impact_duck: float = 0.0
var paused_mix: bool = false

func configure(store: SettingsStore) -> void:
	settings = store
	enabled = DisplayServer.get_name() != "headless"
	if not enabled: return
	for i in 16:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	music = _loop("last_resort_music", -19)
	ambience = _loop("rooftop_ambience", -29)
	apply_volume()

func _loop(name_value: String, db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	var path := "res://assets/audio/%s.wav" % name_value
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path).duplicate()
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		player.stream = stream
		player.volume_db = db
		player.play()
	return player

func apply_volume() -> void:
	if music: music.volume_db = -19 - impact_duck - (5.0 if paused_mix else 0.0) + linear_to_db(maxf(0.0001, settings.values.music * settings.values.master))
	if ambience: ambience.volume_db = -29 - impact_duck * 0.5 - (5.0 if paused_mix else 0.0) + linear_to_db(maxf(0.0001, settings.values.effects * settings.values.master))

func update_mix(delta: float, paused: bool) -> void:
	if not enabled: return
	if paused_mix != paused:
		paused_mix = paused
		for voice: AudioStreamPlayer in voices: voice.stream_paused = paused
	if not paused: impact_duck = move_toward(impact_duck, 0.0, delta * 11.0)
	apply_volume()

func play_sound(id: String, gain: float = 0.0) -> void:
	if not enabled or settings.values.effects <= 0: return
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(id, -1000)) < 65: return
	last_played[id] = now
	var path := "res://assets/audio/%s.wav" % id
	if not ResourceLoader.exists(path): return
	# Prefer a free voice so movement foley does not cut off an impact tail.
	for offset in voices.size():
		var candidate: int = (cursor + offset) % voices.size()
		if not voices[candidate].playing:
			cursor = candidate
			break
	var voice := voices[cursor]
	cursor = (cursor + 1) % voices.size()
	voice.stream = load(path)
	voice.volume_db = -10 + gain + linear_to_db(maxf(0.0001, settings.values.effects * settings.values.master))
	var count: int = int(sample_counts.get(id, 0))
	sample_counts[id] = count + 1
	voice.pitch_scale = [0.97, 1.02, 1.0, 1.04][count % 4] if id.begins_with("hit_") or id in ["swing", "jump", "land"] else 1.0
	voice.stream_paused = paused_mix
	voice.play()

func on_event(event: String, _actor: int, _at: Vector3, details: Dictionary) -> void:
	match event:
		"hit":
			var heavy: bool = details.get("heavy", false)
			var family: String = "heavy" if heavy else "light"
			var index: int = int(sample_counts.get(family, 0))
			sample_counts[family] = index + 1
			play_sound("hit_%s_%d" % [family, index % (2 if heavy else 3) + 1], 1.0 if heavy else -1.5)
			if heavy: impact_duck = maxf(impact_duck, 3.0)
		"launch": play_sound("launch", -3)
		"jump", "land": play_sound(event, -7)
		"ko":
			play_sound(event, 1)
			impact_duck = 5.0
		"shield", "parry", "hazard_warning", "hazard_fire", "meter_ready": play_sound(event)
		"move": play_sound("ultimate" if details.get("move", "") == "ultimate" else "swing", -3 if details.get("move", "") == "ultimate" else -8)
		"shield_break": play_sound("break_prop")

func stop_all() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	for player in [music, ambience]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
