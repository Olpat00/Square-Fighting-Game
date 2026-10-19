# Heavy Duty — implemented move data

Heavyweight grappler. Broad grabs, armored commitments, and enormous punish windows on both sides.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 6.8 m/s · Air 5.4 m/s · Weight 1.24 · Jump 12.30 m/s · Gravity 22.0 m/s².

**Passive — Commitment:** The specified heavy windup windows absorb one hit of at most 8 damage without interruption. Damage still applies. Grabs and stronger hits beat the armor.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Complaint Intake | 7 | 7–10 | 13 | 4.5 | 2.70 | 0.033 | 14° | 0 |
| `jab2` / Follow-up Call | 8 | 8–11 | 14 | 5.0 | 3.00 | 0.037 | 18° | 0 |
| `jab3` / Case Closed | 10 | 10–14 | 23 | 8.0 | 5.30 | 0.079 | 36° | 0 |
| `tilt_side` / Personal Space | 11 | 11–15 | 20 | 10.0 | 4.90 | 0.087 | 33° | 0 |
| `tilt_up` / Overhead Cost | 10 | 10–15 | 22 | 9.0 | 4.80 | 0.080 | 83° | 0 |
| `tilt_down` / Heel Inspection | 10 | 10–14 | 20 | 9.0 | 4.40 | 0.068 | 61° | 0 |
| `dash` / Express Delivery | 13 | 13–19 | 28 | 13.0 | 5.70 | 0.091 | 38° | 0 |
| `heavy_side` / Final Notice | 24 | 24–29 | 35 | 21.0 | 7.20 | 0.130 | 30° | 65 |
| `heavy_up` / Load Bearing | 23 | 23–29 | 33 | 18.5 | 7.00 | 0.128 | 86° | 65 |
| `heavy_down` / Deck Clearance | 24 | 24–31 | 36 | 19.0 | 6.70 | 0.122 | 24° | 65 |
| `air_neutral` / Wide Load | 9 | 9–18 | 24 | 10.0 | 4.70 | 0.078 | 42° | 0 |
| `air_forward` / Special Delivery | 13 | 13–18 | 29 | 14.0 | 5.70 | 0.102 | 32° | 0 |
| `air_back` / Rear Exit | 11 | 11–15 | 27 | 15.0 | 6.10 | 0.117 | 151° | 0 |
| `air_up` / Top Shelf | 10 | 10–15 | 24 | 10.0 | 4.90 | 0.085 | 84° | 0 |
| `air_down` / Dead Weight | 18 | 18–24 | 34 | 15.0 | 5.90 | 0.106 | -65° | 0 |
| `special_neutral` / Complaint Department | 22 | 22–27 | 30 | 15.0 | 5.80 | 0.089 | 40° | 0 |
| `special_side` / Please Remain Seated | 17 | 17–23 | 37 | 14.0 | 5.10 | 0.081 | 63° | 0 |
| `special_up` / Carry-On | 11 | 11–21 | 38 | 12.0 | 5.40 | 0.087 | 74° | 0 |
| `special_down` / Floor Inspection | 17 | 17–21 | 33 | 13.0 | 5.20 | 0.088 | 55° | 0 |
| `ultimate` / Folded Like Furniture | 31 | 31–36 | 43 | 12.0 | 4.00 | 0.040 | 65° | 0 |
| `grab` / Official Escort | 9 | 9–12 | 26 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / Exit Strategy | 9 | 9–9 | 22 | 12.0 | 6.20 | 0.105 | 30° | 0 |
| `throw_back` / Service Entrance | 12 | 12–12 | 24 | 14.0 | 6.60 | 0.116 | 145° | 0 |
| `throw_up` / Freight Elevator | 10 | 10–10 | 22 | 11.0 | 5.90 | 0.097 | 87° | 0 |
| `throw_down` / Damage Deposit | 12 | 12–12 | 23 | 10.0 | 3.90 | 0.058 | 74° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Complaint Intake:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Follow-up Call:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Case Closed:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Personal Space:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Overhead Cost:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Heel Inspection:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Express Delivery:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Final Notice:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Load Bearing:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Deck Clearance:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Wide Load:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Special Delivery:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Rear Exit:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Top Shelf:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Dead Weight:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Complaint Department:** Thunderous short-range clap creates heavy shield pressure. Counterplay: Back away during the windup; the shockwave has no long-range travel.
- **Please Remain Seated:** Committed rush grabs through shields into a lift-and-slam. Counterplay: Jump or dodge the grab, then punish 37 ticks of whiff recovery.
- **Carry-On:** A powerful rising clothesline with deliberately limited recovery distance. Counterplay: Respect the arm, then cover the short, vulnerable descent.
- **Floor Inspection:** Ground stomp or committed airborne elbow drop; landing produces a short shockwave. Counterplay: Jump over the shockwave; an offstage elbow drop cannot rescue its user.
- **Folded Like Furniture:** A telegraphed grab confirms an absurd wrestling slam onto a temporary chair. Counterplay: Jump away from the visible grab; the move can miss and spend all meter.
- **Official Escort:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **Exit Strategy:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Service Entrance:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Freight Elevator:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Damage Deposit:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Jab 1 → Jab 2 → Jab 3 for a close-range low-damage check.
- Down throw → up tilt against limited DI at low damage; jump away to avoid retaliation.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
