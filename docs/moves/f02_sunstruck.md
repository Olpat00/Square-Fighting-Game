# Sunstruck — implemented move data

Ricochet trickster. Returning cap discs, theatrical spacing, and reflector routes turn the rooftop into a stage.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 8.8 m/s · Air 7.6 m/s · Weight 0.88 · Jump 12.40 m/s · Gravity 20.5 m/s².

**Passive — Encore:** Catch your returning disc 3 times to empower the next throw. Encore resets after spending it or losing a stock. One disc and one reflector at a time.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Opening Act | 6 | 6–8 | 12 | 3.0 | 2.10 | 0.034 | 12° | 0 |
| `jab2` / Double Booking | 6 | 6–8 | 12 | 3.5 | 2.50 | 0.036 | 18° | 0 |
| `jab3` / Standing Ovation | 8 | 8–12 | 20 | 6.0 | 4.20 | 0.071 | 40° | 0 |
| `tilt_side` / Guest List | 9 | 9–13 | 17 | 7.0 | 3.80 | 0.077 | 34° | 0 |
| `tilt_up` / Raise the Roof | 8 | 8–12 | 18 | 6.0 | 3.70 | 0.071 | 87° | 0 |
| `tilt_down` / Low Cover | 7 | 7–10 | 15 | 5.5 | 3.40 | 0.056 | 66° | 0 |
| `dash` / Late Entrance | 10 | 10–16 | 22 | 8.0 | 4.40 | 0.080 | 40° | 0 |
| `heavy_side` / Headliner Heel | 21 | 21–25 | 29 | 14.5 | 5.80 | 0.112 | 30° | 60 |
| `heavy_up` / Roof Raiser | 18 | 18–24 | 27 | 13.0 | 5.60 | 0.111 | 86° | 60 |
| `heavy_down` / Afterparty Sweep | 23 | 23–30 | 30 | 13.5 | 5.40 | 0.103 | 24° | 60 |
| `air_neutral` / Disco Radius | 7 | 7–16 | 17 | 6.0 | 3.50 | 0.064 | 43° | 0 |
| `air_forward` / Velvet Heel | 10 | 10–14 | 20 | 9.0 | 4.40 | 0.088 | 34° | 0 |
| `air_back` / Encore Exit | 8 | 8–11 | 19 | 10.0 | 4.90 | 0.102 | 149° | 0 |
| `air_up` / Skybox | 6 | 6–11 | 17 | 6.5 | 3.80 | 0.070 | 83° | 0 |
| `air_down` / Curtain Drop | 15 | 15–20 | 28 | 11.0 | 4.70 | 0.083 | -62° | 0 |
| `special_neutral` / Hat Trick | 12 | 12–14 | 20 | 6.0 | 3.40 | 0.053 | 35° | 0 |
| `special_side` / Velvet Rope | 13 | 13–18 | 24 | 9.0 | 4.20 | 0.078 | 32° | 0 |
| `special_up` / VIP Launch | 12 | 12–21 | 34 | 8.0 | 4.50 | 0.071 | 83° | 0 |
| `special_down` / Mirror Service | 17 | 17–17 | 26 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `ultimate` / The Main Event | 38 | 38–40, 46–48, 54–56 | 37 | 8.0 | 4.20 | 0.077 | 78° | 0 |
| `grab` / Backstage Pass | 8 | 8–10 | 24 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / Front Row | 8 | 8–8 | 17 | 7.0 | 4.80 | 0.084 | 33° | 0 |
| `throw_back` / VIP Exit | 10 | 10–10 | 20 | 8.0 | 5.20 | 0.096 | 148° | 0 |
| `throw_up` / Upper Circle | 8 | 8–8 | 19 | 6.0 | 4.20 | 0.069 | 86° | 0 |
| `throw_down` / No Re-entry | 10 | 10–10 | 18 | 6.0 | 3.20 | 0.052 | 72° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Opening Act:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Double Booking:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Standing Ovation:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Guest List:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Raise the Roof:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Low Cover:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Late Entrance:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Headliner Heel:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Roof Raiser:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Afterparty Sweep:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Disco Radius:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Velvet Heel:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Encore Exit:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Skybox:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Curtain Drop:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Hat Trick:** Throw a returning energy cap. Catching three returns empowers the next disc. Counterplay: Jump the outward route, shield its return, or pressure the catch position.
- **Velvet Rope:** Sweeping ribbon creates room before a short lateral reposition. Counterplay: Punish startup or follow the visible reposition; the move is not invulnerable.
- **VIP Launch:** Visible pyro startup propels Sunstruck upward once per airtime. Counterplay: Hit the startup or wait for the vulnerable descent.
- **Mirror Service:** Place one visible, destructible puck that redirects your disc 30 degrees upward. Counterplay: Destroy the puck, avoid its visible route, or punish the placement.
- **The Main Event:** Aim a bounded spotlight before three solar impacts strike the marked region. Counterplay: Exit the warning circle or punish the visibly stationary setup.
- **Backstage Pass:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **Front Row:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **VIP Exit:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Upper Circle:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **No Re-entry:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Side tilt → forward air against a nearby low-damage opponent; follow their drift.
- Returning Hat Trick → dash attack when the disc brings pressure from behind; the return may be dodged.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
