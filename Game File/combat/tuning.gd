class_name CombatTuning
extends RefCounted

const TICK_RATE: int = 60
const DT: float = 1.0 / TICK_RATE
const INPUT_BUFFER: int = 6
const COYOTE_TICKS: int = 4
const SOFT_LANDING_TICKS: int = 3
const HARD_LANDING_TICKS: int = 5
const RESPAWN_TICKS: int = 100
const RESPAWN_INVULNERABILITY: int = 120
const STOCKS: int = 3
const MATCH_TICKS: int = 360 * TICK_RATE
const BLAST_LEFT: float = -18.0
const BLAST_RIGHT: float = 18.0
const BLAST_BOTTOM: float = -8.0
const BLAST_TOP: float = 16.0
const HURT_RADIUS: float = 0.42
const HURT_HEIGHT: float = 1.65
const SHIELD_REGEN_DELAY: int = 90
const PARRY_WINDOW: int = 4
const MAX_CHARGE: int = 75

static func beyond_blast(p: Vector3) -> bool:
	return p.x < BLAST_LEFT or p.x > BLAST_RIGHT or p.y < BLAST_BOTTOM or p.y > BLAST_TOP

static func knockback(base: float, growth: float, percent: float, weight: float) -> float:
	return minf(42.0, (base + percent * growth) / maxf(0.6, weight))
