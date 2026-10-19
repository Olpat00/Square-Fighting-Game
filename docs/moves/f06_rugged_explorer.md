# Rugged Explorer — implemented move data

Grappling pathfinder. A compact grappling hook pulls rivals into his close-range routes. Hook hits prepare one faster traversal special.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 8.2 m/s · Air 7.0 m/s · Weight 1.01 · Jump 12.80 m/s · Gravity 21.0 m/s².

**Passive — Trailblazer:** A damaging Trail Line hook pulls its target toward the Explorer and grants one Route charge for 240 ticks. The next side or up special spends the charge for 12% more travel. Shields stop the hook; only one hook can be active.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Trail Tap | 6 | 6–8 | 12 | 3.2 | 2.20 | 0.034 | 18° | 0 |
| `jab2` / Compass Check | 7 | 7–9 | 13 | 3.8 | 2.70 | 0.039 | 25° | 0 |
| `jab3` / Summit Strike | 9 | 9–12 | 20 | 6.5 | 4.30 | 0.072 | 39° | 0 |
| `tilt_side` / Ridge Sweep | 9 | 9–13 | 19 | 8.0 | 4.10 | 0.080 | 34° | 0 |
| `tilt_up` / Cliff Reach | 8 | 8–12 | 19 | 7.0 | 3.90 | 0.074 | 82° | 0 |
| `tilt_down` / Low Traverse | 8 | 8–11 | 17 | 6.5 | 3.50 | 0.059 | 64° | 0 |
| `dash` / Trail Charge | 11 | 11–16 | 23 | 9.0 | 4.70 | 0.084 | 41° | 0 |
| `heavy_side` / Rockbreaker | 21 | 21–25 | 30 | 16.0 | 6.00 | 0.116 | 32° | 60 |
| `heavy_up` / Peak Finder | 19 | 19–24 | 28 | 14.0 | 5.70 | 0.109 | 84° | 60 |
| `heavy_down` / Fault Line | 22 | 22–28 | 31 | 14.5 | 5.70 | 0.106 | 25° | 60 |
| `air_neutral` / Rope Circle | 8 | 8–15 | 19 | 7.0 | 3.70 | 0.069 | 44° | 0 |
| `air_forward` / Trail Kick | 11 | 11–15 | 22 | 10.0 | 4.70 | 0.093 | 35° | 0 |
| `air_back` / Backtrack | 9 | 9–13 | 21 | 10.5 | 5.00 | 0.101 | 147° | 0 |
| `air_up` / Skyward Route | 7 | 7–12 | 18 | 7.5 | 4.00 | 0.073 | 84° | 0 |
| `air_down` / Falling Pick | 15 | 15–20 | 27 | 11.5 | 4.80 | 0.091 | -60° | 0 |
| `special_neutral` / Trail Line | 15 | 15–17 | 25 | 6.5 | 2.40 | 0.042 | 30° | 0 |
| `special_side` / Trail Rush | 13 | 13–20 | 28 | 11.0 | 5.10 | 0.088 | 39° | 0 |
| `special_up` / Summit Ascent | 10 | 10–21 | 35 | 9.0 | 4.60 | 0.079 | 76° | 0 |
| `special_down` / Anchor Stance | 10 | 10–15 | 30 | 9.0 | 4.10 | 0.077 | 55° | 0 |
| `ultimate` / Uncharted Finish | 29 | 29–34 | 39 | 10.0 | 4.10 | 0.049 | 35° | 0 |
| `grab` / Handhold | 8 | 8–10 | 24 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / Over the Ridge | 8 | 8–8 | 18 | 8.0 | 5.00 | 0.084 | 34° | 0 |
| `throw_back` / Wrong Turn | 10 | 10–10 | 20 | 9.0 | 5.30 | 0.099 | 147° | 0 |
| `throw_up` / High Pass | 8 | 8–8 | 19 | 7.0 | 4.40 | 0.072 | 84° | 0 |
| `throw_down` / Ground Route | 10 | 10–10 | 19 | 7.0 | 3.40 | 0.055 | 71° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Trail Tap:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Compass Check:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Summit Strike:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Ridge Sweep:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Cliff Reach:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Low Traverse:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Trail Charge:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Rockbreaker:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Peak Finder:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Fault Line:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Rope Circle:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Trail Kick:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Backtrack:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Skyward Route:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Falling Pick:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Trail Line:** Fire one short-range hook. A damaging hit reels the rival toward the Explorer and primes Route. Counterplay: Shield or dodge the narrow hook; its 25-tick recovery is vulnerable.
- **Trail Rush:** Rush along a committed ground route; a stored Route charge extends the travel. Counterplay: Jump or shield the line, then punish the long ending.
- **Summit Ascent:** A rising climb recovers once per airtime; Route lengthens the arc slightly. Counterplay: Cover the predictable upper end or the helpless descent.
- **Anchor Stance:** Plant a low strike with brief light-hit armor during its commitment. Counterplay: Grab, use a stronger hit, or wait for the 30-tick recovery.
- **Uncharted Finish:** A visible forward lunge confirms a grapple-and-slam sequence only on contact. Counterplay: Jump, shield, or dodge the opener; a whiff still spends the meter.
- **Handhold:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **Over the Ridge:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Wrong Turn:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **High Pass:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Ground Route:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Trail Line → side tilt when a hooked rival lands nearby; shielding the hook stops the pull.
- Down tilt → up air at low damage; follow the rival's drift.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
