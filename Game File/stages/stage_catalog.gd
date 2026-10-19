class_name StageCatalog
extends RefCounted
## Stable arena IDs are shared by setup, rematches and capture tools.

const IDS: Array[String] = ["rooftop_riot", "lunar_reach", "verdant_shrine", "abyssal_observatory", "ember_foundry"]

const ARENAS: Dictionary = {
	"rooftop_riot": {"title": "THE LAST RESORT", "description": "Sunset terrace · 3 stocks · 6 minutes", "party": "Party · lift + announced pyro", "tagline": "SUNSET. NO SUPERVISION.", "invitation": "You're on the guest list.", "pause": "The rooftop can wait.", "ko": "HAS LEFT THE ROOFTOP", "camera": Vector3(17.5, 14.0, 25), "focus": Vector3(0, 0.3, -4)},
	"lunar_reach": {"title": "LUNAR REACH", "description": "Crater's edge · Earthrise · 3 stocks · 6 minutes", "party": "Party · orbital lift + vent bursts", "tagline": "EARTH BELOW. LIMITS GONE.", "invitation": "Welcome to Lunar Reach.", "pause": "The Moon can wait.", "ko": "IS LOST IN SPACE", "camera": Vector3(20, 12, 30), "focus": Vector3(0, 2, -4), "script": "res://stages/lunar_reach/lunar_stage.gd"},
	"verdant_shrine": {"title": "VERDANT SHRINE", "frame_crown": true, "description": "Rainforest ruins · waterfalls · high stone terraces", "party": "Party · spirit lift + spring geysers", "tagline": "ANCIENT STONE. UNTAMED RIVALS.", "invitation": "Enter the Verdant Shrine.", "pause": "The forest can wait.", "ko": "HAS FALLEN INTO THE WILDS", "camera": Vector3(18, 13, 31), "focus": Vector3(0, 3, -5), "script": "res://stages/verdant_shrine/verdant_shrine_stage.gd"},
	"abyssal_observatory": {"title": "ABYSSAL OBSERVATORY", "description": "Deep-ocean gallery · living reef · low central lift", "party": "Party · pressure lift + water jets", "tagline": "DEEP WATER. HIGH STAKES.", "invitation": "Welcome to the Abyss.", "pause": "The deep can wait.", "ko": "HAS DESCENDED INTO THE ABYSS", "camera": Vector3(17, 10, 32), "focus": Vector3(0, 2, -5), "script": "res://stages/abyssal_observatory/abyssal_stage.gd"},
	"ember_foundry": {"title": "EMBER FOUNDRY", "frame_crown": true, "description": "Volcanic forge · molten river · suspended iron bridge", "party": "Party · piston lift + forge vents", "tagline": "FORGED IN FIRE. SETTLED HERE.", "invitation": "Step into Ember Foundry.", "pause": "The forge can wait.", "ko": "HAS FALLEN INTO THE FURNACE", "camera": Vector3(18, 13, 32), "focus": Vector3(0, 2, -5), "script": "res://stages/ember_foundry/ember_stage.gd"}
}

static func info(id: String) -> Dictionary:
	return ARENAS.get(id, ARENAS.rooftop_riot)

static func title(id: String) -> String:
	return str(info(id).title)

static func description(id: String) -> String:
	return str(info(id).description)

static func party_label(id: String) -> String:
	return str(info(id).party)

static func create_stage(id: String) -> RooftopStage:
	var data := info(id)
	if data.has("script"):
		var script: Script = load(str(data.script))
		if script == null or not script.can_instantiate():
			push_error(title(id) + " could not be loaded.")
			return null
		return script.new() as RooftopStage
	return RooftopStage.new()
