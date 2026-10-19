# Deadfall — implemented move data

Trap-setting scrapper. Layer visible triplines and rolling constructs, then improvise a route through the chaos.

Generated from the shipped definition by `export_move_data.gd`. Simulation runs at 60 ticks per second. Startup is the number of inactive ticks before first contact. Active intervals are zero-based and inclusive. Recovery begins after the last active interval. Animation IDs equal stable move IDs.

Run 7.6 m/s · Air 6.5 m/s · Weight 1.06 · Jump 12.60 m/s · Gravity 21.5 m/s².

**Passive — Fieldcraft:** A triggered armed trap grants one Quick Fix charge. The next side or up special spends it for 12% more travel. Charges never stack, and recovery remains once per airtime.

| ID / move | Startup | Active ticks | Recovery | Damage | Base KB | Growth | Angle | Charge cap |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| `jab1` / Quick Fix | 6 | 6–8 | 12 | 3.5 | 2.30 | 0.033 | 15° | 0 |
| `jab2` / Measure Twice | 7 | 7–10 | 13 | 4.5 | 2.80 | 0.037 | 22° | 0 |
| `jab3` / Cut Once | 9 | 9–13 | 20 | 7.0 | 4.50 | 0.074 | 35° | 0 |
| `tilt_side` / Backhand Estimate | 10 | 10–14 | 19 | 9.0 | 4.30 | 0.084 | 35° | 0 |
| `tilt_up` / Overhang | 8 | 8–13 | 19 | 7.5 | 4.10 | 0.076 | 80° | 0 |
| `tilt_down` / Loose Floorboard | 8 | 8–12 | 17 | 7.0 | 3.70 | 0.061 | 64° | 0 |
| `dash` / Weekend Rush | 11 | 11–16 | 24 | 10.0 | 4.80 | 0.083 | 42° | 0 |
| `heavy_side` / Full Renovation | 22 | 22–27 | 31 | 17.0 | 6.30 | 0.119 | 32° | 60 |
| `heavy_up` / Open Plan | 20 | 20–26 | 29 | 15.5 | 6.00 | 0.115 | 84° | 60 |
| `heavy_down` / Groundwork | 22 | 22–28 | 32 | 16.0 | 5.90 | 0.111 | 25° | 60 |
| `air_neutral` / Loose Hardware | 8 | 8–16 | 20 | 7.5 | 3.90 | 0.071 | 45° | 0 |
| `air_forward` / Flying Estimate | 12 | 12–17 | 24 | 11.0 | 4.90 | 0.095 | 35° | 0 |
| `air_back` / Back Door | 9 | 9–13 | 23 | 12.0 | 5.20 | 0.109 | 149° | 0 |
| `air_up` / Attic Access | 8 | 8–13 | 19 | 8.0 | 4.20 | 0.076 | 83° | 0 |
| `air_down` / Demolition Drop | 16 | 16–21 | 30 | 12.5 | 5.00 | 0.095 | -63° | 0 |
| `special_neutral` / Splinter Service | 17 | 17–19 | 26 | 9.0 | 4.20 | 0.071 | 36° | 0 |
| `special_side` / Shortcut | 13 | 13–21 | 28 | 11.0 | 5.00 | 0.088 | 59° | 0 |
| `special_up` / Branch Office | 10 | 10–23 | 33 | 8.5 | 4.50 | 0.078 | 76° | 0 |
| `special_down` / Trip Hazard | 18 | 18–18 | 27 | 8.0 | 3.50 | 0.056 | 72° | 0 |
| `ultimate` / Questionable Landscaping | 43 | 43–49 | 38 | 31.0 | 8.10 | 0.129 | 38° | 0 |
| `grab` / Cable Management | 8 | 8–10 | 25 | 0.0 | 0.00 | 0.000 | 0° | 0 |
| `throw_forward` / Curbside Pickup | 8 | 8–8 | 19 | 9.0 | 5.20 | 0.087 | 33° | 0 |
| `throw_back` / Return to Sender | 11 | 11–11 | 21 | 10.0 | 5.60 | 0.104 | 148° | 0 |
| `throw_up` / Loft Conversion | 9 | 9–9 | 20 | 8.0 | 4.80 | 0.077 | 83° | 0 |
| `throw_down` / Foundation Work | 11 | 11–11 | 20 | 8.0 | 3.60 | 0.057 | 70° | 0 |

Damage is the authored contact value before charge/passive scaling and stale-move safeguards. Multihits, captured follow-ups, and projectiles use the explicit `ability_data` in the JSON export; ultimate contact damage is not the entire sequence. Positive launch angle is up; back-air/back-throw angles point behind the fighter before facing mirroring.

## Purpose, risk, and counterplay

- **Quick Fix:** Confirmed jab-chain starter. Counterplay: Block the first strike, then punish the string's commitment.
- **Measure Twice:** Confirmed jab-chain link. Counterplay: Block the first strike, then punish the string's commitment.
- **Cut Once:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Backhand Estimate:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Overhang:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Loose Floorboard:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Weekend Rush:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Full Renovation:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Open Plan:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Groundwork:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Loose Hardware:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Flying Estimate:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Back Door:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Attic Access:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Demolition Drop:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Splinter Service:** Send a finite rolling energy log along its platform; it falls at the edge. Counterplay: Jump the ground route or occupy a different height.
- **Shortcut:** Low plank rush ends in a rising strike; Quick Fix adds modest travel. Counterplay: Shield the rush and punish its committed recovery.
- **Branch Office:** Follow a fixed rising swing arc around a temporary branch; Quick Fix extends travel. Counterplay: Cover the predictable end of the swing; the branch is not a platform.
- **Trip Hazard:** Plant a visible tripline: arms after 30 ticks, hits once, grants Quick Fix. Maximum two. Counterplay: Destroy it during arming, jump over it, or wait for expiry.
- **Questionable Landscaping:** Mark a diagonal region before dropping a huge tree construct; debris is cosmetic. Counterplay: Move outside the marked diagonal or dodge the single committed impact.
- **Cable Management:** Catch a grounded shield; choose a directional throw. Counterplay: Jump, attack first, or dodge the short grab window.
- **Curbside Pickup:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Return to Sender:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Loft Conversion:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.
- **Foundation Work:** Close-range pressure and a readable launch. Counterplay: Space outside the contact arc and punish recovery.

## Beginner sequences

These are practice sequences, not guaranteed true combos at every damage, weight, or directional influence.

- Armed Trip Hazard → side tilt while the opponent is nearby; they can destroy or jump over the setup.
- Down tilt → up air against low-damage opponents above you; DI can leave the arc.

## Exact technical data

`move_timing.json` includes hitbox offsets/radii, hitstun, hitstop, shield values, cancels, armor, invulnerability, movement intervals, effects, ownership, and special parameters. Gameplay coordinates are fighter-local +X forward/+Y up. A rehit value of zero allows only one hit per attack instance and hit group. Charge caps are ticks, and runtime definitions are immutable.
