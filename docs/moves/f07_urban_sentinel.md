# Urban Sentinel — implemented move data

Defensive zone holder. Holds a line with guarded strikes, a short pulse, and a telegraphed lockdown zone.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 7.3 m/s · Air 6.2 m/s · Weight 1.13 · Jump 12.10 m/s · Gravity 22.0 m/s².

**Passive — Sentinel:** A successful parry stores one Guard charge for 300 ticks. Down special spends it to enlarge and strengthen its close pulse. The down-special windup has one-hit armor against attacks of at most 8 damage; grabs and stronger attacks interrupt it.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Watch Tap | 6 | 6–8 | 12 | 3.4 | 2.30 | 0.034 | 17° | 0 |
| `jab2` / Guard Check | 7 | 7–9 | 13 | 4.1 | 2.80 | 0.039 | 23° | 0 |
| `jab3` / Clear the Line | 9 | 9–13 | 21 | 7.0 | 4.50 | 0.073 | 42° | 0 |
| `tilt_side` / Barrier Hand | 9 | 9–13 | 18 | 8.0 | 4.20 | 0.079 | 34° | 0 |
| `tilt_up` / High Alert | 9 | 9–13 | 19 | 7.5 | 4.00 | 0.075 | 83° | 0 |
| `tilt_down` / Street Sweep | 8 | 8–12 | 18 | 7.0 | 3.70 | 0.063 | 62° | 0 |
| `dash` / Patrol Break | 12 | 12–17 | 24 | 9.5 | 4.80 | 0.085 | 42° | 0 |
| `heavy_side` / Security Breach | 22 | 22–27 | 31 | 17.0 | 6.30 | 0.119 | 31° | 60 |
| `heavy_up` / Roof Watch | 20 | 20–26 | 30 | 15.5 | 6.00 | 0.115 | 84° | 60 |
| `heavy_down` / Roadblock | 23 | 23–29 | 32 | 16.0 | 5.90 | 0.110 | 27° | 60 |
| `air_neutral` / Perimeter | 8 | 8–16 | 20 | 7.5 | 4.00 | 0.071 | 45° | 0 |
| `air_forward` / Air Patrol | 12 | 12–17 | 23 | 11.0 | 5.00 | 0.094 | 34° | 0 |
| `air_back` / Rear Guard | 10 | 10–14 | 22 | 11.5 | 5.20 | 0.104 | 149° | 0 |
| `air_up` / Overwatch | 8 | 8–13 | 19 | 8.5 | 4.40 | 0.078 | 84° | 0 |
| `air_down` / Checkpoint Drop | 16 | 16–21 | 29 | 12.0 | 5.00 | 0.094 | -62° | 0 |
| `special_neutral` / Warning Shot | 17 | 17–19 | 25 | 8.0 | 3.80 | 0.061 | 34° | 0 |
| `special_side` / Containment Drive | 15 | 15–22 | 30 | 12.0 | 5.20 | 0.089 | 41° | 0 |
| `special_up` / High Ground | 11 | 11–22 | 37 | 10.0 | 4.90 | 0.081 | 76° | 0 |
| `special_down` / Fortify Pulse | 18 | 18–22 | 32 | 8.5 | 4.60 | 0.082 | 62° | 0 |
| `ultimate` / Lockdown Protocol | 40 | 40–46 | 40 | 29.0 | 7.60 | 0.123 | 39° | 0 |
| `grab` / Detain | 8 | 8–10 | 25 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / Move Along | 8 | 8–8 | 19 | 9.0 | 5.20 | 0.087 | 34° | 0 |
| `throw_back` / Clear Out | 11 | 11–11 | 21 | 10.0 | 5.60 | 0.103 | 149° | 0 |
| `throw_up` / Upper Perimeter | 9 | 9–9 | 20 | 8.0 | 4.80 | 0.077 | 84° | 0 |
| `throw_down` / Hold Position | 11 | 11–11 | 20 | 8.0 | 3.60 | 0.058 | 72° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Watch Tap:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Guard Check:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Clear the Line:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Barrier Hand:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **High Alert:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Street Sweep:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Patrol Break:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Security Breach:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Roof Watch:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Roadblock:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Perimeter:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Air Patrol:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Rear Guard:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Overwatch:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Checkpoint Drop:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Warning Shot:** Send one medium-range pulse straight ahead to hold space. Counterplay: Jump the straight shot or close in during its startup.
- **Containment Drive:** A deliberate advancing shoulder strike with brief light-hit armor. Counterplay: Grab, hit hard, or jump the predictable forward lane.
- **High Ground:** A guarded vertical ascent recovers once per airtime. Counterplay: Wait outside the rising shoulder and intercept the short descent.
- **Fortify Pulse:** Brace through one light strike, then release a close pulse; Guard charge improves it. Counterplay: Grab or use a strong hit during the brace, or back out of pulse range.
- **Lockdown Protocol:** Mark a wide rectangle in front of the Sentinel before one powerful pulse. Counterplay: Leave the visible zone or punish the stationary setup before it fires.
- **Detain:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **Move Along:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Clear Out:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Upper Perimeter:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Hold Position:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Shield a close attack → Fortify Pulse to push the rival away; the pulse is short range.
- Side tilt → forward air near an edge; the rival can drift out.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
