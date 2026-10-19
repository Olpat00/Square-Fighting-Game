# UNSUPERVISED: ROOFTOP RIOT — Windows development build

<!-- LIVING_ARENAS_CURRENT_BEGIN -->
## Living arenas — validated Windows build

All five arenas have animated backgrounds, including swimming sea life in Abyssal Observatory and flowing lava in Ember Foundry. Low retains essential ambient motion with reduced detail. Motion freezes during pause and resets on rematch. The previously rebuilt platforms remain in place. Exported **2026-10-04T19:39:14.0345852Z** with Godot 4.7.2; **537 runtime files** match the current source, build, still-review, motion-media and performance inventories (`F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825`).

Double-click **RooftopRiot.exe** beside its matching **RooftopRiot.pck**. Start a Fight, choose fighters and arena, assign keyboard/controllers/CPUs, then Ready. Party/Fair Fight and rematch remain available. Default rendering uses Forward+; `Launch-Mobile.cmd` chooses the separate Mobile renderer after restart. Godot and Blender are not required to play.

The packaged archive target is `RooftopRiot-Living-Arenas-Windows.zip`; workspace receipt `evidence/background_rebuild/delivery.json` records successful archive verification. The exported UI passes 108 checks and actual Windows EXE runs cover the three added arenas. Current High/Low scenery-clock and restoration checks pass; five ambient clips provide stationary-player presentation evidence. Ten 1080p High/Low four-player cases are listed in `PERFORMANCE.md`. The ten cases recorded 41 intervals above 16.667 ms out of 71,983 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers. The full matrix uses a 120 FPS render cap, with VSync disabled. It measures this explicitly controlled workload and its headroom against a 16.667 ms frame budget; it is not an uncapped stress result or a device/driver fix.

The preceding uncapped Lunar Reach High stress case lost its Vulkan device and crashed. That failure and its unclean restart remain documented in `PERFORMANCE.md`; a driver or hardware fix has not been established.

Human playtesting, physical multi-controller testing, continuous human motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant visual review of scenery fixtures and automated CPU matches do not establish competitive balance, sound-mix quality or zero clipping in every combat pose.
<!-- LIVING_ARENAS_CURRENT_END -->

<!-- LIVING_ARENAS_HISTORY_BEGIN -->
## Historical records before the living-background upgrade

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current living-background acceptance is above. Any earlier heading or text calling a result current applies only to its recorded snapshot. The preceding platform runtime, docs, tools and Windows build are preserved under `evidence/background_rebuild/baseline/`. Earlier failure histories remain retained.
<!-- LIVING_ARENAS_HISTORY_END -->

<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->
## Platform refinement — validated Windows build

Main and raised platforms have finished stone, marble, timber or steel construction across all five arenas. Exported **2026-10-04T17:42:41.6458493Z** with Godot 4.7.2; **525 runtime files** match the current source, build, visual-review and performance inventories (`5D87C1AAB5E7C45183D0AFD7AD941C8BC2456A96F0A1326730F16A60C202B7B0`).

Double-click **RooftopRiot.exe** beside its matching **RooftopRiot.pck**. Start a Fight, choose fighters and arena, assign keyboard/controllers/CPUs, then Ready. Party/Fair Fight and rematch remain available. Default rendering uses Forward+; `Launch-Mobile.cmd` chooses the separate Mobile renderer after restart. Godot and Blender are not required to play.

The packaged archive target is `RooftopRiot-Platform-Upgrade-Windows.zip`; workspace receipt `evidence/platform_refinement/delivery.json` records successful archive verification. The exported UI passes 108 checks and actual Windows EXE runs cover the three added arenas. Ten 1080p High/Low four-player cases are listed in `PERFORMANCE.md`. The ten cases recorded 1,650 intervals above 16.667 ms out of 564,786 render-interval samples. All outliers remain in the original matrix table; this is not a clean stable-60-FPS result across every case. An additional 2 unchanged-source repeat case(s) are recorded separately in PERFORMANCE.md. Repeats retain, rather than replace, the original matrix and its outliers.

Human playtesting, physical multi-controller testing, continuous motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant still review and automated CPU matches do not establish competitive balance or zero clipping in every pose.
<!-- PLATFORM_REFINEMENT_CURRENT_END -->

<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->
## Historical records before the platform refinement

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current platform acceptance is above. The pre-platform runtime, docs, tools, Windows build and map evidence are preserved under `evidence/platform_refinement/baseline/`. Earlier failure histories remain retained.
<!-- PLATFORM_REFINEMENT_HISTORY_END -->

**Five-arena Windows build — October 3.** Exported 2026-10-03T22:40:09.3475549Z with Godot 4.7.2 and verified against 515 runtime source files. The exported PCK passes 108 UI checks; the actual Windows EXE completes four-fighter smoke runs on all three new arenas. Exact hashes are in `build_manifest.json`.

Double-click **RooftopRiot.exe** and keep its matching **RooftopRiot.pck** beside it. Godot and Blender are not required to play a packaged build. This is a local, unsigned Windows development build.

## Start a match

Start a Fight opens local setup. Select fighters, assign one keyboard plus unique gamepads or CPUs, select **The Last Resort**, **Lunar Reach**, **Verdant Shrine**, **Abyssal Observatory** or **Ember Foundry** beneath the fighter cards, choose Party/Fair Fight, then Ready. New setups currently default to Lunar Reach. Rematches keep the selected arena. CPU Demo configures four CPUs. Training uses Fair Fight on any arena.

All eight fighters are unlocked: Clutch/Wes, Sunstruck/Will, Heavy Duty/Damion, Deadfall/Jaydon, Fine Print/Josh, Rugged Explorer, Urban Sentinel and Midnight Gentleman. Hero derivatives retain recognizable faces while reworking costumes, rigging and motion. Trail Line reels in a rival; Fortify Pulse braces and releases a close pulse; Shadow Step crosses a nearby rival after a visible windup. Personas and abilities are fictional.

Matches use three stocks and six minutes. Party adds the moving center lift and announced arena-themed vent hazards. Fair Fight fixes the lift and disables damaging hazards. Results offers Run It Back, Change Fighters and Main Menu.

## Controls

Keyboard defaults: **WASD** move/aim, **Space** jump, **J** light, **K** heavy (hold to charge), **L** special, **Shift** shield/dodge, **U** grab, **O** ultimate, **T** taunt, **Esc** pause. Direction + attack selects directional moves. Down + jump drops through a raised platform. Release jump early for a short hop. Remap the keyboard in Settings.

Xbox-style defaults: left stick move/aim, A jump, X light, B heavy, Y special, LB/either trigger defend, RB grab, L3 ultimate, D-pad up taunt, Start pause. Connect pads before assigning them; controller changes refresh setup. Only one keyboard profile is supported. Physical multiple-controller operation remains unverified on this workstation.

Training shows move phase, combo hits/damage, current input and move purpose/counterplay.

| Key | Training action |
|---|---|
| F1 | Reset fighters, resources and tape playhead; while recording, discard that take and start a new one. |
| F2 | Clear damage. |
| F3 | Cycle stationary/defending/jumping dummy; stop playback. |
| F4 | Show/hide authored hitboxes. |
| F5 | Fill ultimate meters. |
| F6 | Record player two using player one's controls; press again to save. Player one stays neutral during recording. |
| F7 | Loop/stop the saved player-two tape. Player one has normal control during replay. |

A tape lasts up to ten seconds. Each playback loop has a 0.75-second neutral gap and combat reset. Pause freezes the playhead. Starting another recording replaces the tape; rematch or leaving training clears it. Training keys do not repeat while held and are inactive during pause.

## Presentation and settings

The new camera moves closer during nearby exchanges and expands for launches/recoveries. Player labels separate inside safe margins. Shake and impact effects freeze on pause. Heavy contacts briefly lower the background mix; impact samples have restrained variation. Movement and attacks use more specific transitions and contact handling, while combat still runs at 60 Hz.

Low immediately reduces scenery, decorative lights/shadows, postprocessing, shader complexity, effect density and lunar terrain detail. Character texture selection applies at the next match: Low uses 1K derivatives, High uses 2K models, with the same rigs and animation sets. Resolution, fullscreen, UI scale, audio, blood, profanity, flashes, shake and rumble save locally.

The default renderer is Forward+ on Vulkan. Launch-Mobile.cmd selects the separate Mobile renderer and requires a restart. Ten 60-second 1080p four-player High/Low cases cover all five arenas. The ten cases contain 4 intervals above 16.667 ms out of 645,002 samples; the full table retains those outliers. See `PERFORMANCE.md` for CPU/GPU/frame-pacing results and `MAP_EXPANSION.md` for map sources. Weaker-PC and current Mobile performance remain unverified.

Editable project: `Game File/project.godot` in the parent workspace. Art sources: `source_art/`. Reproduction and current validation status: workspace `README.md`, `STATUS.md`, `docs/VALIDATION.md`, `docs/PROVENANCE.md` and `evidence/rebuild/`.

Human playtesting, continuous human motion/audio review and physical multiple-controller testing remain unverified. Automated checks and sampled footage do not establish competitive balance or subjective feel. Evidence, movies and editable-art paths in the included documents refer to the source workspace; the playable archive contains the game, launchers and documentation.

Original supplied models are preserved. Derivative art, animation and implementation are editable in this workspace; provenance distinguishes authored work from external motion/material sources. Source redistribution rights and likeness permissions are not independently established. The title is provisional.

Made with Godot Engine under the MIT license: [engine license and notices](https://godotengine.org/license/) and [third-party notices](https://godotengine.org/license#thirdparty). No Microsoft font files are redistributed; the UI uses installed system fonts with Godot fallback.
