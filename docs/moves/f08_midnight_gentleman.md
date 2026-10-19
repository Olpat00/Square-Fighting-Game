# Midnight Gentleman — implemented move data

Evasive duelist. Uses bounded shadow steps to change sides and punish openings with precise close attacks.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 8.5 m/s · Air 7.3 m/s · Weight 0.93 · Jump 12.70 m/s · Gravity 20.6 m/s².

**Passive — Shadowstep:** A damaging aerial hit stores one Veil charge for 240 ticks. The next side special spends it for a longer Shadow Step. Shadow Step changes position only after visible startup, has a brief protected transition, and cannot travel beyond the arena bounds.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Polite Reminder | 5 | 5–7 | 12 | 3.0 | 2.10 | 0.033 | 17° | 0 |
| `jab2` / Second Opinion | 6 | 6–8 | 12 | 3.6 | 2.60 | 0.037 | 25° | 0 |
| `jab3` / Final Word | 8 | 8–11 | 19 | 6.0 | 4.10 | 0.069 | 39° | 0 |
| `tilt_side` / Cuff Check | 8 | 8–12 | 17 | 7.0 | 3.90 | 0.076 | 34° | 0 |
| `tilt_up` / Raised Glass | 7 | 7–11 | 18 | 6.5 | 3.80 | 0.072 | 84° | 0 |
| `tilt_down` / Low Courtesy | 7 | 7–10 | 16 | 6.0 | 3.40 | 0.057 | 65° | 0 |
| `dash` / Late Arrival | 10 | 10–15 | 21 | 8.5 | 4.50 | 0.081 | 42° | 0 |
| `heavy_side` / Black Tie Break | 20 | 20–24 | 29 | 15.0 | 5.80 | 0.112 | 32° | 60 |
| `heavy_up` / Moonlit Toast | 18 | 18–23 | 27 | 13.5 | 5.50 | 0.105 | 85° | 60 |
| `heavy_down` / Curtain Sweep | 21 | 21–27 | 29 | 14.0 | 5.40 | 0.103 | 27° | 60 |
| `air_neutral` / Evening Turn | 7 | 7–15 | 18 | 6.5 | 3.60 | 0.067 | 43° | 0 |
| `air_forward` / Velvet Cut | 10 | 10–14 | 20 | 9.5 | 4.50 | 0.090 | 34° | 0 |
| `air_back` / Parting Gift | 8 | 8–12 | 20 | 10.0 | 4.90 | 0.098 | 148° | 0 |
| `air_up` / High Society | 6 | 6–11 | 17 | 7.0 | 3.90 | 0.071 | 84° | 0 |
| `air_down` / Last Waltz | 14 | 14–19 | 26 | 11.0 | 4.70 | 0.087 | -61° | 0 |
| `special_neutral` / Dusk Arc | 14 | 14–16 | 23 | 7.5 | 3.70 | 0.060 | 35° | 0 |
| `special_side` / Shadow Step | 16 | 16–20 | 29 | 10.5 | 4.80 | 0.085 | 38° | 0 |
| `special_up` / Moonrise | 9 | 9–21 | 35 | 8.5 | 4.40 | 0.077 | 77° | 0 |
| `special_down` / Vanishing Courtesy | 10 | 10–10 | 32 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `ultimate` / Midnight Appointment | 30 | 30–35 | 40 | 9.0 | 3.80 | 0.041 | 37° | 0 |
| `grab` / Private Invitation | 8 | 8–10 | 24 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / After You | 8 | 8–8 | 18 | 8.0 | 4.90 | 0.084 | 34° | 0 |
| `throw_back` / Exit Stage Left | 10 | 10–10 | 20 | 9.0 | 5.20 | 0.097 | 148° | 0 |
| `throw_up` / To the Rafters | 8 | 8–8 | 19 | 7.0 | 4.40 | 0.070 | 84° | 0 |
| `throw_down` / Final Bow | 10 | 10–10 | 19 | 7.0 | 3.30 | 0.053 | 71° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Polite Reminder:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Second Opinion:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Final Word:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Cuff Check:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Raised Glass:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Low Courtesy:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Late Arrival:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Black Tie Break:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Moonlit Toast:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Curtain Sweep:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Evening Turn:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Velvet Cut:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Parting Gift:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **High Society:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Last Waltz:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Dusk Arc:** Send a short, straight shadow arc to check an approach. Counterplay: Jump above its line or rush the startup.
- **Shadow Step:** After a visible windup, step through a nearby rival and strike from the new position; Veil extends the step. Counterplay: Watch the destination and punish the lengthy recovery or shield its follow-up.
- **Moonrise:** Rise in a controlled arc once per airtime. Counterplay: Cover the exposed approach before the rise or the helpless descent.
- **Vanishing Courtesy:** Step backward after a visible tell, briefly avoiding attacks without dealing damage. Counterplay: Follow the retreat or punish its long recovery; grabs before the step still work.
- **Midnight Appointment:** A telegraphed duelist's lunge confirms a short finishing sequence only if it connects. Counterplay: Dodge, jump, or shield the opener; a miss spends the meter.
- **Private Invitation:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **After You:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Exit Stage Left:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **To the Rafters:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Final Bow:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Forward air → Shadow Step to change sides after a confirmed hit; watch where the rival lands.
- Down tilt → up tilt at close range; the second hit can be shielded.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
