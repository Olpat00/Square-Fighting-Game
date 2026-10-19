# Controls

One keyboard player plus separate gamepads supports local matches. Each gamepad is assigned to one player slot. CPU players use the same actions and combat restrictions. Directions describe the gameplay plane: left/right and up/down; there is no depth movement.

| Action | Keyboard default | Gamepad default (Xbox labels) |
|---|---|---|
| Move / aim | W A S D | Left stick |
| Jump | Space | A |
| Light | J | X |
| Heavy / charge | K | B |
| Special | L | Y |
| Shield / dodge | Left Shift | LB or either trigger |
| Grab / throw | U | RB |
| Ultimate | O | Click left stick |
| Taunt | T | D-pad up |
| Pause | Escape | Start / Menu |

Release jump early for a short hop. Jump again in the air for the remaining aerial jump. Hold down during descending free movement to fast-fall. Downward attack input preserves the attack's startup; special dives control their own descent. Down + jump drops through the currently supported raised platform. It does not remove main-deck collision.

Light with no direction starts a jab string. Press light again after a confirmed jab to continue its chain. Up/side/down + light produces a grounded directional attack; side light at running speed becomes a dash attack. In the air, light or heavy selects neutral, forward, back, up, or down aerial according to the stick direction and facing.

Hold heavy to charge, then release; the move automatically releases at its cap. Neutral/side, up, and down select the three heavies. Specials use neutral, side, up, or down direction. Clutch can charge neutral special. Every up special consumes the current airtime's recovery; landing or respawning refreshes it.

Defend while neutral and grounded raises shield. A precisely timed shield can parry. Defend with horizontal direction rolls; defend with a vertical direction performs a spot dodge. In the air, defend performs the single aerial dodge. Dodges have vulnerable startup and recovery. Directional input after a successful grab selects a throw; light or grab throws forward. Alternate presses of taunt select the two authored taunts. Ultimate requires 100 meter, spends it on use, and can miss.

The supplied move sheets in `docs/moves/` list actual frame data, purpose, counterplay, and introductory sequences. Startup and recovery use 60 Hz simulation ticks, not rendering frames.

Training shows your aim direction, current state, held actions, most recent press, and move phase (startup, active, between hits, or recovery). Combo hits and damage come from resolved damaging contacts; shields do not count, and a gap where the defender can act starts a new combo. After an attack, its purpose and counterplay remain visible for reference. Training uses Fair Fight rules.

| Training shortcut | Behavior |
|---|---|
| F1 | Reset fighters, damage, resources, stale-move penalties, and the current tape playhead. During recording, discard the unfinished take and start a fresh recording. |
| F2 | Clear damage percentages without resetting position. |
| F3 | Cycle stationary, defending, and jumping dummy behavior; stop tape playback. |
| F4 | Toggle authored hitbox display. |
| F5 | Fill ultimate meters. |
| F6 | Reset and begin recording player two using player one's assigned keyboard or gamepad. Player one stays neutral. Press again to save. |
| F7 | Reset and replay the saved player-two tape in a loop; press again to stop. During recording, save the current take and begin replay. Player one has normal control during replay. |

One tape is held in memory for the current training match, capped at ten seconds (600 simulation ticks). Starting another recording replaces it. Replay preserves held buttons and ordinary press/release edges, including a complete tap between simulation ticks. Every loop has a 45-tick neutral gap, then resets fighters and combat state before playing again. Pause freezes the playhead; resuming continues from the same point. Stock loss does not rewind the tape. F1 restarts an active recording or rewinds an active replay; F3 keeps the saved tape available for F7. Tapes are cleared on rematch or leaving training.

## Input settings and device behavior

Keyboard bindings are stored locally in `user://controls.cfg`. Remapping onto another action's key swaps the two keys so neither action becomes inaccessible. Missing, corrupt, or conflicting saved bindings restore the complete defaults. Physical keycodes preserve positional bindings across keyboard layouts. One keyboard profile is supported; multiple independent shared-keyboard players are not advertised.

Gamepads are identified by their Godot device ID. Digital events are filtered by device before state changes, and axes are read only from that device. The analog deadzone is 0.22. A disconnected pad releases its held actions and clears pending press edges. The match host handles slot reassignment or pause UI. There is no automatic fallback that transfers one player's inputs into another slot.

Easy, Normal, and Hard CPUs have 18–26, 10–14, and 5–8 tick decision intervals respectively, with different mistake rates and defensive choices. They receive no movement, damage, weight, armor, or meter bonuses. They observe current positions and visible action states, prioritize returning to the arena, jump toward platform waypoints, and react to announced hazard warnings. They retain short spacing and target-selection goals, punish visible recovery, and continue jab strings after confirmed hits. Randomness is independently seeded for reproducible tests.

## Integration contract

- `InputSnapshot`: `move: Vector2` (+Y is up), bool dictionaries `held`, `pressed`, `released`; methods `is_down(action)`, `was_pressed(action)`, `was_released(action)`.
- `InputProvider.sample(fighter, world)` returns one snapshot per authoritative tick. A future touch source can implement this interface.
- `HumanInputProvider.new(-1)` selects keyboard. A nonnegative ID selects a unique gamepad. Forward native `_input(event)` to each human provider with `handle_event(event)` and call `reset()` on focus/pause/KO/reset transitions to discard stale state.
- Human bindings: static `get_keyboard_bindings()`, `set_keyboard_binding(action, physical_keycode)`, `reset_keyboard_bindings()`, `save_keyboard_bindings()`, `load_keyboard_bindings()`.
- `CpuInputProvider.new("Normal", seed)` creates a CPU. `dummy_mode` accepts empty string for combat, `stationary`, `defending`, or `jumping` for training. Optional stage method `is_hazard_warning_at(x)` allows warning avoidance.
- `ScriptedInputProvider.new(entries)` consumes tick ranges `{from,to,move,actions}` and derives ordinary edges for scenario tests. `reset()` rewinds its schedule.
- `TrainingInputProvider` extends the CPU provider for player two. `begin_recording()`, `begin_playback()`, `stop_tape()`, and `rewind()` control its tape. Ordinary provider `reset()` releases CPU input state without rewinding an active tape; explicit training reset restarts an active recording or rewinds playback. F7 stops recording before resetting so its saved take survives. MatchWorld samples player one before the recording dummy, then neutralizes player one's snapshot and action buffer.

Provider validation: `Godot --headless --path "Game File" --script res://input/validate_input.gd`. The report distinguishes synthetic input isolation checks from physical gamepad play validation.
