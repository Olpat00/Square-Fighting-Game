extends RefCounted
## Shared control preferences live on a native-base script. Godot 4.7.2 can
## free a derived script's base during GDScriptLanguage::finish when the derived
## script owns static state (upstream godotengine/godot#117975 / #117991).

const DEFAULT_KEYS: Dictionary = {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S, "jump": KEY_SPACE, "light": KEY_J, "heavy": KEY_K, "special": KEY_L, "defend": KEY_SHIFT, "grab": KEY_U, "ultimate": KEY_O, "taunt": KEY_T, "pause": KEY_ESCAPE}
static var bindings: Dictionary = DEFAULT_KEYS.duplicate()
static var loaded: bool = false
