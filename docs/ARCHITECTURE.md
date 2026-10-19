# Runtime architecture and invariants

`MatchWorld` owns the 60 Hz update. It samples input snapshots, updates each fighter, collects all attack contacts, resolves defenses/damage, commits all KOs, and then evaluates the result. A render frame does not define an active attack frame. Visual animation, particles, camera, audio and UI consume state/events.

Fighter definitions and moves are shared authoring Resources. A `RiotFighter` owns its damage, stocks, shield, meter, active move, attack instance, hit registry, recovery resources, buffered input, captures and `FighterMechanics` state. Roster discovery loads definitions from the content folder. An ability kit is discovered by its mechanic key under `combat/abilities/`.

The scene uses 3D models in a fixed X/Y gameplay plane. The CharacterBody3D is an authoritative scripted controller: `RooftopStage.solve_motion` sweeps a feet point against platform top planes and a solid main-deck rectangle; decorative meshes do not supply gameplay collision. Upper platforms support descending crossings only. Drop-through stores one ignored platform ID and timeout. Genuine landings refresh air resources. Facing is an integer sign; the imported skeleton rotates with the VisualRoot and never gets negative scale.

Manual fast-fall applies only during descending free movement. Selecting a downward aerial does not accelerate its startup; special dives use their authored movement curves.

Contacts carry source/target/instance/group ownership. The resolver snapshots defensive eligibility before damage interrupts attacks, preserving simultaneous trades. One ordinary attack hits a target once; explicit re-hit intervals permit designed multihits. Invulnerability rejects contacts before shield/parry, counter, armor or damage. Grabs beat shields and counters; simultaneous mutual grabs clash. Stage hazards enter the same resolver. Knockback depends on authored strength, accumulated damage and relative weight, with bounded influence.

Local hitstop freezes fighter movement/animation/state clocks; global pause freezes the entire authoritative match. Input edges buffer independently, are consumed once and cleared on reset/pause transitions. Each human provider receives only its physical keyboard or assigned joystick events; CPUs and scripted tests produce the same snapshots.

Fixed blast bounds: X ±18m, bottom Y−8m, top Y16m. The camera cannot change KO eligibility. Timeout orders surviving stocks then lower damage. Exact ties enter a 45-second, 200%-damage sudden-death phase for tied fighters on the same arena. A repeated exact tie/double final KO resolves as a draw, not player-index priority.

Results remain in the arena with the results UI, using staged visual children rather than a full-screen cinematic. The winner plays a 70-tick final-KO flourish, then loops the victory pose; eliminated fighters become visible in their loss poses. Staging preserves committed fighter positions, stocks and KO records. Match completion clears temporary ability objects, and rematch creates fresh fighters.

Party mode has three breakable signs and two curated chair props. Nearby heavy-hit events hide one intact decoration and emit fragments through the shared 120-node effect pool. Breakup is cosmetic, disabled in Fair Fight, and restored on rematch. A resolved, unarmored launch above 16 m/s emits a separate launch-audio event; ordinary lower-knockback hits retain only their impact sound.

Training displays the first fighter's aim, state, held actions and recent press, plus the last move's authored purpose and counterplay. The display reads live snapshots and move data; it does not alter combat rules.

This is a local game architecture. No cross-platform physics determinism, rollback readiness or network support is claimed.
