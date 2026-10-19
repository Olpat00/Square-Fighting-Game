# Clutch — implemented move data

Kinetic all-rounder. Clean combinations, flexible air control, and momentum-powered clutch plays.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 8.3 m/s · Air 6.9 m/s · Weight 1.00 · Jump 12.50 m/s · Gravity 21.0 m/s².

**Passive — Momentum:** Different successful attacks build up to 3 Momentum pips within 240 ticks. Neutral, side, and up specials spend one pip for an extra kinetic effect. Time Out preserves pips. Shields and repeated move IDs grant none.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Quick Check | 5 | 5–7 | 10 | 3.5 | 2.40 | 0.035 | 15° | 0 |
| `jab2` / Cross Traffic | 6 | 6–8 | 11 | 4.0 | 2.80 | 0.038 | 20° | 0 |
| `jab3` / Final Word | 7 | 7–10 | 17 | 6.5 | 4.50 | 0.072 | 35° | 0 |
| `tilt_side` / Straight Answer | 8 | 8–11 | 15 | 8.0 | 4.30 | 0.079 | 32° | 0 |
| `tilt_up` / Ceiling Check | 7 | 7–11 | 16 | 7.0 | 4.10 | 0.072 | 82° | 0 |
| `tilt_down` / Ankle Breaker | 6 | 6–9 | 14 | 6.0 | 3.80 | 0.060 | 64° | 0 |
| `dash` / Fast Break | 9 | 9–14 | 21 | 10.0 | 4.90 | 0.085 | 38° | 0 |
| `heavy_side` / Shoulder Season | 19 | 19–23 | 27 | 16.0 | 6.40 | 0.121 | 32° | 60 |
| `heavy_up` / Over the Top | 18 | 18–23 | 26 | 14.0 | 6.10 | 0.118 | 85° | 60 |
| `heavy_down` / Sweep the Series | 20 | 20–25 | 29 | 15.0 | 5.90 | 0.115 | 26° | 60 |
| `air_neutral` / Scissor Cut | 6 | 6–13 | 16 | 7.0 | 3.80 | 0.070 | 45° | 0 |
| `air_forward` / Away Game | 9 | 9–13 | 20 | 10.0 | 4.70 | 0.097 | 35° | 0 |
| `air_back` / Back Court | 7 | 7–10 | 22 | 12.0 | 5.40 | 0.113 | 150° | 0 |
| `air_up` / High Five | 6 | 6–10 | 16 | 7.0 | 4.00 | 0.074 | 82° | 0 |
| `air_down` / Down Payment | 13 | 13–17 | 27 | 12.0 | 5.00 | 0.090 | -68° | 0 |
| `special_neutral` / Overtime | 14 | 14–17 | 23 | 10.0 | 4.80 | 0.087 | 30° | 60 |
| `special_side` / Personal Foul | 11 | 11–19 | 27 | 12.0 | 5.70 | 0.095 | 34° | 0 |
| `special_up` / Second Wind | 7 | 7–18 | 32 | 9.0 | 4.80 | 0.085 | 76° | 0 |
| `special_down` / Time Out | 5 | 5–15 | 30 | 11.0 | 5.70 | 0.094 | 40° | 0 |
| `ultimate` / Clutch Time | 26 | 26–32 | 36 | 8.0 | 3.50 | 0.030 | 25° | 0 |
| `grab` / Jersey Check | 7 | 7–9 | 23 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / Home Delivery | 7 | 7–7 | 16 | 8.0 | 5.20 | 0.092 | 30° | 0 |
| `throw_back` / Reverse Call | 9 | 9–9 | 18 | 9.0 | 5.40 | 0.102 | 145° | 0 |
| `throw_up` / Raising Stakes | 8 | 8–8 | 18 | 7.0 | 4.50 | 0.072 | 85° | 0 |
| `throw_down` / Floor Seats | 9 | 9–9 | 17 | 7.0 | 3.50 | 0.057 | 68° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Quick Check:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Cross Traffic:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Final Word:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Straight Answer:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Ceiling Check:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Ankle Breaker:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Fast Break:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Shoulder Season:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Over the Top:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Sweep the Series:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Scissor Cut:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Away Game:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Back Court:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **High Five:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Down Payment:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Overtime:** Charge a short-to-medium palm blast. Momentum adds a small second ring. Counterplay: Jump the linear blast or close in during charge/recovery.
- **Personal Foul:** Step-in shoulder check. Momentum adds an end-of-dash burst. Counterplay: Shield or sidestep with a dodge, then punish the 27-tick recovery.
- **Second Wind:** Angled uppercut recovery once per airtime; Momentum modestly extends travel. Counterplay: Wait outside the rising fist and cover the helpless descent.
- **Time Out:** Planted counter: strike during ticks 5–15 triggers a kinetic shove. Counterplay: Grab the stance or wait, then punish its long recovery.
- **Clutch Time:** Telegraphed rush confirms a short combination only if its opener connects. Counterplay: Jump, shield, or dodge the opener; a miss spends the meter.
- **Jersey Check:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **Home Delivery:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Reverse Call:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Raising Stakes:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Floor Seats:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Jab 1 → Jab 2 → Jab 3 at low damage, pressing light again during confirmed links.
- Down tilt → short-hop forward air near center stage; DI and higher damage can escape.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
