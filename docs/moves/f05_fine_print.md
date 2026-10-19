# Fine Print — implemented move data

Precision counter-striker. Crisp spacing, narrow counters, and visible citations turn predictable choices into consequences.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 7.9 m/s · Air 6.6 m/s · Weight 0.96 · Jump 12.20 m/s · Gravity 20.0 m/s².

**Passive — Citations:** Precise outer-range special hits and parries mark an opponent up to 3 times for 420 ticks. Side heavy and the ultimate consume marks for a bounded launch bonus.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Initial Notice | 5 | 5–6 | 12 | 3.0 | 2.10 | 0.031 | 12° | 0 |
| `jab2` / Second Notice | 6 | 6–8 | 13 | 4.0 | 2.70 | 0.034 | 18° | 0 |
| `jab3` / Enforcement | 8 | 8–11 | 20 | 6.5 | 4.30 | 0.074 | 33° | 0 |
| `tilt_side` / Due Process | 8 | 8–11 | 17 | 8.5 | 4.10 | 0.084 | 30° | 0 |
| `tilt_up` / Escalation | 7 | 7–10 | 18 | 7.0 | 4.00 | 0.075 | 85° | 0 |
| `tilt_down` / Fine Detail | 7 | 7–9 | 17 | 6.0 | 3.50 | 0.058 | 66° | 0 |
| `dash` / Priority Handling | 10 | 10–14 | 24 | 9.0 | 4.60 | 0.084 | 36° | 0 |
| `heavy_side` / Final Ruling | 20 | 20–23 | 31 | 16.0 | 6.10 | 0.120 | 29° | 60 |
| `heavy_up` / Higher Authority | 19 | 19–23 | 29 | 14.5 | 5.90 | 0.118 | 87° | 60 |
| `heavy_down` / Closing Statement | 21 | 21–25 | 31 | 14.5 | 5.60 | 0.111 | 24° | 60 |
| `air_neutral` / Standard Clause | 6 | 6–11 | 18 | 6.5 | 3.70 | 0.069 | 44° | 0 |
| `air_forward` / Forward Notice | 8 | 8–11 | 21 | 9.0 | 4.50 | 0.093 | 31° | 0 |
| `air_back` / Retrospective | 7 | 7–9 | 22 | 11.5 | 5.20 | 0.109 | 150° | 0 |
| `air_up` / Executive Summary | 7 | 7–10 | 19 | 7.5 | 4.10 | 0.077 | 85° | 0 |
| `air_down` / Footnote | 14 | 14–17 | 30 | 11.0 | 4.80 | 0.091 | -68° | 0 |
| `special_neutral` / Point Taken | 12 | 12–15 | 26 | 10.0 | 4.60 | 0.081 | 30° | 0 |
| `special_side` / Hostile Takeover | 14 | 14–17 | 30 | 8.0 | 3.80 | 0.061 | 30° | 0 |
| `special_up` / Corporate Ladder | 8 | 8–10, 14–16, 20–23 | 34 | 3.0 | 2.70 | 0.040 | 83° | 0 |
| `special_down` / Objection | 4 | 4–10 | 34 | 13.0 | 6.00 | 0.103 | 37° | 0 |
| `ultimate` / Terms and Conditions | 30 | 30–34 | 38 | 8.0 | 3.50 | 0.035 | 35° | 0 |
| `grab` / Receipt Required | 7 | 7–8 | 25 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / Notice Served | 7 | 7–7 | 18 | 8.0 | 5.00 | 0.089 | 30° | 0 |
| `throw_back` / Motion Denied | 9 | 9–9 | 20 | 9.0 | 5.40 | 0.103 | 150° | 0 |
| `throw_up` / Appeal Upheld | 8 | 8–8 | 19 | 7.0 | 4.50 | 0.074 | 87° | 0 |
| `throw_down` / Filed Away | 10 | 10–10 | 20 | 7.0 | 3.40 | 0.054 | 71° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Initial Notice:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Second Notice:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Enforcement:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Due Process:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Escalation:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Fine Detail:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Priority Handling:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Final Ruling:** Precise strong straight consumes up to three target citations for capped damage and launch. Counterplay: Duck out of its narrow range, shield, or punish the 31-tick recovery.
- **Higher Authority:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Closing Statement:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Standard Clause:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Forward Notice:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Retrospective:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Executive Summary:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Footnote:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Point Taken:** A narrow extending palm at a specific range; a clean outer hit adds a citation. Counterplay: Move inside the distant hitbox or jump the thin horizontal line.
- **Hostile Takeover:** Measured heel kick adds a follow-up only after confirmed contact. Counterplay: Shield or dodge the opener, then punish the committed recovery.
- **Corporate Ladder:** Three precise rising kicks recover once per airtime; the drawn steps have no collision. Counterplay: Stay outside the staircase arc and cover the helpless descent.
- **Objection:** A narrow 7-tick counter window creates a strong precise reprisal and citation. Counterplay: Delay the strike or grab; a missed objection has 34 vulnerable recovery ticks.
- **Terms and Conditions:** A bounded geometric opener confirms precise attacks; existing citations boost the final launch within a cap. Counterplay: Leave the marked rectangle or dodge the opener; missed contact receives no combo.
- **Receipt Required:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **Notice Served:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Motion Denied:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Appeal Upheld:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Filed Away:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Jab 1 → Jab 2 → Jab 3 after a close whiff; shielded hits cannot confirm links.
- Outer-range Point Taken → advancing side tilt at low damage; respect shield and DI.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
