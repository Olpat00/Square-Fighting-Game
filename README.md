# UNSUPERVISED: ROOFTOP RIOT

## Clone and open the game

This repository contains the current Square Fighting Game source, editable art, tools and validation records. Install [Git LFS](https://git-lfs.com/) before cloning so the game assets download correctly:

```sh
git lfs install
git clone https://github.com/Olpat00/Square-Fighting-Game.git
cd Square-Fighting-Game
git lfs pull
```

Open `Game File/project.godot` in Godot 4.7.2 and run the project. Godot rebuilds its import cache on first open. Generated Windows builds, the engine/tool binaries, machine-specific shortcuts and the original supplied `/Assets/` archive stay local; the runtime assets are included. Historical validation records below describe their recorded builds; reproduction of the original-source hash checks also requires that local archive.

<!-- LIVING_ARENAS_CURRENT_BEGIN -->
## Living arenas — validated Windows build

All five arenas now have scene-specific moving backgrounds. The original illustrated mattes and photographs remain untouched; localized shader animation and layered 3D scenery add movement, depth and setting-specific life. The picture does not wobble as a whole. Background motion follows the authoritative stage clock, freezes during pause and resets with the match. Low keeps the main ambient motion with fewer animals, particles or secondary details. The finished platforms, collision layouts, combat timing and Party hazard behavior are retained.

| Arena | Living background |
|---|---|
| The Last Resort | Drifting skyline clouds, gliding gulls, pool ripples, foliage and subtle guest movement |
| Lunar Reach | Tracking observatory dishes, a moving survey rover, beacons, a passing orbital relay and slow Earth motion |
| Verdant Shrine | Flowing waterfalls, drifting valley mist, swaying foliage and birds crossing the valley |
| Abyssal Observatory | Swimming fish schools, pulsing jellyfish, gliding mantas, suspended particles and drifting water-light rays |
| Ember Foundry | Flowing molten spillways, animated lava, rising smoke and embers around working machinery |

Play the matching `builds/windows/RooftopRiot.exe` and `.pck`. The dedicated archive target is `builds/RooftopRiot-Living-Arenas-Windows.zip`; successful packaging writes `evidence/background_rebuild/delivery.json` and verifies every decoded ZIP entry. The preceding Platform-Upgrade archive remains unchanged.

5,097 source assertions; 25 reviewed 1080p arena views; 378 scenery assertions/70 timed, pause and reset stills across High/Low; five fully decoded 12-second/60 FPS ambient clips (1600×900) with assistant sample-frame review; five completed CPU matches/35 lifecycle checks; 108 exported-PCK UI checks/40 captures; actual Windows EXE smoke on each of the three added arenas; ten isolated 60-second four-player profiles using a 120 FPS render cap, with VSync disabled. Exported **2026-10-04T19:39:14.0345852Z** with Godot 4.7.2; **537 runtime files** match the current source, build, still-review, motion-media and performance inventories (`F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825`).

[Arena guide and reproduction](docs/MAP_EXPANSION.md) · [validation](docs/VALIDATION.md) · [current performance](docs/PERFORMANCE.md). The five clips under `evidence/background_rebuild/motion/` show stationary-player ambient presentation; they are not human playtesting or performance measurements. Human playtesting, physical multi-controller testing, continuous human motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant visual review of scenery fixtures and automated CPU matches do not establish competitive balance, sound-mix quality or zero clipping in every combat pose.
<!-- LIVING_ARENAS_CURRENT_END -->

<!-- LIVING_ARENAS_HISTORY_BEGIN -->
## Historical records before the living-background upgrade

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current living-background acceptance is above. Any earlier heading or text calling a result current applies only to its recorded snapshot. The preceding platform runtime, docs, tools and Windows build are preserved under `evidence/background_rebuild/baseline/`. Earlier failure histories remain retained.
<!-- LIVING_ARENAS_HISTORY_END -->

<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->
## Platform refinement — validated Windows build

Main decks and raised platforms on all five arenas have rebuilt surface construction. Flat face normals and chamfered geometry give the slabs distinct top, edge and underside planes. The authored landing planes, arena layouts and lift behavior are retained. Materials and detail follow each arena's setting; High and Low retain readable platform edges.

| Arena | Platform finish |
|---|---|
| The Last Resort | Timber decks, stone faces and brass edge details |
| Lunar Reach | Service panels and vent housings with a clear landing edge |
| Verdant Shrine | Jointed weathered stone with carved edge construction |
| Abyssal Observatory | Marble and brass around recessed cobalt panels |
| Ember Foundry | Steel treads, support ribs and inset vents |

Play the matching `builds/windows/RooftopRiot.exe` and `.pck`. The dedicated archive target is `builds/RooftopRiot-Platform-Upgrade-Windows.zip`; successful packaging writes `evidence/platform_refinement/delivery.json` and verifies every decoded ZIP entry. The preceding Five-Arenas archive remains unchanged.

5,097 source assertions; 25 current 1080p platform views; five completed CPU matches/35 lifecycle checks; 108 exported-PCK UI checks/40 captures; actual Windows EXE smoke on each of the three added arenas; ten isolated 60-second four-player profiles. Exported **2026-10-04T17:42:41.6458493Z** with Godot 4.7.2; **525 runtime files** match the current source, build, visual-review and performance inventories (`5D87C1AAB5E7C45183D0AFD7AD941C8BC2456A96F0A1326730F16A60C202B7B0`).

[Platform guide and reproduction](docs/MAP_EXPANSION.md) · [validation](docs/VALIDATION.md) · [current performance](docs/PERFORMANCE.md). Human playtesting, physical multi-controller testing, continuous motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant still review and automated CPU matches do not establish competitive balance or zero clipping in every pose.
<!-- PLATFORM_REFINEMENT_CURRENT_END -->

<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->
## Historical records before the platform refinement

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current platform acceptance is above. The pre-platform runtime, docs, tools, Windows build and map evidence are preserved under `evidence/platform_refinement/baseline/`. Earlier failure histories remain retained.
<!-- PLATFORM_REFINEMENT_HISTORY_END -->

A local 2.5D platform fighter in Godot: eight fighters, five arenas, 2–4 participants, damage percentages, stocks and distinct abilities. The October 3 rebuild adds articulated hero rigs and costumes, clearer movement and contact, and more readable arenas. See [rebuild plan](docs/REBUILD_PLAN.md), [presentation integration](docs/REBUILD_PRESENTATION.md) and [current status](STATUS.md).

**The five-arena Windows build is ready to play.** Verdant Shrine, Abyssal Observatory and Ember Foundry join The Last Resort and Lunar Reach, with distinct scenery, platform arrangements and Party effects. The current source passes 5,097 assertions; exported UI passes 108 checks, and the actual release EXE runs all three new maps. [Map guide and editable sources](docs/MAP_EXPANSION.md) · [measured performance](docs/PERFORMANCE.md).

Open `Game File/project.godot` with Godot 4.7.2 to run or edit the current project. Blender is needed only to rebuild editable art. Windows packages run by launching `builds/windows/RooftopRiot.exe` beside its matching `.pck`; `Launch-Mobile.cmd` selects Godot's separate Mobile renderer and requires a restart. It remains a Windows game.

All eight fighters are unlocked: Clutch/Wes, Sunstruck/Will, Heavy Duty/Damion, Deadfall/Jaydon, Fine Print/Josh, Rugged Explorer, Urban Sentinel and Midnight Gentleman. Supplied originals and recognizable facial identities are preserved. Each derivative has a 60-bone runtime rig with articulated fingers, toes, twist joints and restrained facial motion; the roster has 619 clips and refreshed model portraits. Heavy Duty's rigid armor moves separately from flexible clothing. Explorer reels rivals with Trail Line, Sentinel braces and releases Fortify Pulse, and Gentleman crosses an opponent with Shadow Step. Mirrors, one keyboard profile plus separate controllers/CPUs, results and rematch are supported.

## Play and training

Keyboard defaults: **WASD** move/aim, **Space** jump, **J** light, **K** heavy (hold to charge), **L** special, **Shift** shield/dodge, **U** grab, **O** ultimate, **T** taunt, **Esc** pause. Direction + attack selects directional moves; down + jump drops through an upper platform. Release jump early for a short hop. Settings includes keyboard remapping and gamepad controls. Additional human players need separate controllers.

Matches use three stocks and six minutes. Select **The Last Resort**, **Lunar Reach**, **Verdant Shrine**, **Abyssal Observatory** or **Ember Foundry** beneath the fighter cards; Lunar Reach remains the default for a new setup. Party has a moving center lift and announced vents; Fair Fight fixes the lift and disables damaging hazards. Rematch retains the selected arena. CPU Demo configures four CPUs.

Training shows move phase, combo hits/damage, current input, move purpose and counterplay. F1 resets, F2 clears damage, F3 cycles the dummy, F4 toggles hitboxes and F5 fills ultimate meters. **F6 records/saves player two using player one's controls while player one stays neutral. F7 loops/stops the saved recording while player one can practice against it.** Tapes last up to ten seconds, use a 0.75-second neutral gap with a combat reset between loops, and exist only for the current training match. Pause freezes the tape. Training shortcuts do not repeat while held and do not run while paused. See [full controls](docs/controls.md).

## Rebuild behavior

Runtime presentation now has per-transition animation blends, stride/contact metadata and bounded visual foot planting. Combat remains authoritative at 60 Hz, with authored hit regions independent of rendered bones. Per-move aerial steering respects explicit lunges, dives and recoveries; movement top speeds remain unchanged. CPUs retain spacing goals, prioritize recovery, punish visible missed attacks and follow confirmed jabs.

Editable curated Blender scenes are separate from rig preparation and imported motion. Export samples active animator controls, retains attachment names and preserves curated actions. Local Quaternius CC0 foundations supplement custom combat choreography; see [art sources and reproduction](docs/animation_pipeline.md).

The shared camera frames nearby exchanges more closely, expands quickly for launches/recoveries and contracts gradually. Player labels separate within safe screen margins. Camera shake and impact effects freeze with pause. Heavy impacts briefly lower the background mix; existing impact samples rotate with restrained pitch variation.

The new maps use a waterfall sanctuary, an underwater brass gallery, and a suspended volcanic forge. Distant illustrated vistas sit behind animated 3D scenery and authored play surfaces. The Last Resort uses warm sunset/cool pool contrast. Lunar Reach has quieter terrain and a clear recovery corridor beneath the platform. Low immediately reduces secondary scenery, decorative lights/shadows, postprocessing, shader work, effect density and lunar terrain detail. Character texture selection changes on the next match: Low uses 1K derivatives and High uses canonical 2K models, preserving the same animations and rigs.

## Reproduction and evidence

The current source gate passes 5,097 assertions, four settings scenarios, 36 roster pairings and 20 rematches. The exported PCK passes 108 UI checks with 40 fresh captures; the actual Windows executable completes 600 ticks with four CPU fighters and combat contacts on each new arena. Five full matches pass 35 lifecycle checks. Ten isolated 60-second profiles cover all five arenas at High/Low with four players, measuring CPU/GPU work and frame pacing at 1080p. The build and current receipts bind to the same 515-file runtime inventory. Current map evidence is in `evidence/map_expansion/`; [validation](docs/VALIDATION.md) and [performance](docs/PERFORMANCE.md) retain exact results and limits. Human playtesting, physical-controller testing, subjective audio/continuous-motion acceptance and weaker-PC performance remain unverified.

New-map normal/half-speed recordings are available for [Verdant Shrine](evidence/map_expansion/brawl/verdant_shrine/brawl.mp4), [Abyssal Observatory](evidence/map_expansion/brawl/abyssal_observatory/brawl.mp4) and [Ember Foundry](evidence/map_expansion/brawl/ember_foundry/brawl.mp4), with half-speed versions beside them. These 900-tick CPU movies use ordinary match play; their recording cost is excluded from performance measurements.

The prior fighter rebuild's historical before/after comparisons remain available for [Clutch](evidence/rebuild/comparison/f01_clutch.mp4) ([half speed](evidence/rebuild/comparison/f01_clutch_half_speed.mp4)) and [Heavy Duty](evidence/rebuild/comparison/f03_heavy_duty.mp4) ([half speed](evidence/rebuild/comparison/f03_heavy_duty_half_speed.mp4)). Both use the same scripted movement/combat phrases in the preserved baseline and rebuilt project. The [portrait roster](evidence/characters/hero_rebuild/final_portrait_roster.jpg) shows the eight updated model portraits. Historical four-CPU recordings for [The Last Resort](evidence/rebuild/brawl/rooftop_riot/brawl.mp4) and [Lunar Reach](evidence/rebuild/brawl/lunar_reach/brawl.mp4) remain beside their half-speed versions. September evidence and the prior two-arena performance matrix are historical.

Run graphical validation, profiling and capture sequentially so measurement windows stay isolated:

```powershell
$allArenas = @('rooftop_riot', 'lunar_reach', 'verdant_shrine', 'abyssal_observatory', 'ember_foundry')
$profiles = Join-Path $PWD ('evidence/map_expansion/performance/local-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& ./tools/validation/validate_all.ps1
& ./tools/validation/export_windows.ps1
& ./tools/validation/validate_windows_build.ps1
& ./tools/validation/validate_map_release.ps1
& ./tools/validation/profile_rebuild.ps1 -Arenas $allArenas -Qualities High,Low -Players 4 -Seconds 60 -Output $profiles
python ./evidence/map_expansion/update_delivery_notes.py $profiles
& ./tools/validation/package_map_expansion.ps1 -PerformanceDirectory $profiles
```

If runtime edits invalidate the saved lifecycle or visual evidence, rerun the affected review fixtures before packaging. The profile's `profile_provenance.json` binds all ten cases to the current 515-file runtime inventory, accepted art and measurement harness. Packaging checks these bindings against the exported build, writes `builds/RooftopRiot-Five-Arenas-Windows.zip`, verifies every archive entry by SHA-256 and records `evidence/map_expansion/delivery.json`. The prior `builds/RooftopRiot-Rebuild-Windows.zip` remains preserved.

The new stage and continuous-motion review fixtures live in `tools/validation/rebuild_stage_review.gd` and `rebuild_motion_review.gd`. Profile separately from capture/encoding and other graphical work. PowerShell runners accept `-Godot` for another executable location. See [validation](docs/VALIDATION.md), [known issues](docs/KNOWN_ISSUES.md), [art pipeline](docs/animation_pipeline.md), [adding a fighter](docs/ADDING_A_FIGHTER.md) and [Windows instructions](docs/WINDOWS_BUILD_README.md).

- `Assets/`: immutable supplied originals.
- `source_art/`: editable character, motion, arena, prop and material sources.
- `Game File/`: runtime source and processed assets.
- `tools/`: reproducible authoring, validation and packaging.
- `docs/` and `evidence/`: provenance, frame data, reports and genuine captures.
- `builds/windows/`: verified October 3 EXE/PCK, launchers and build manifest.

Personas and abilities are fictional. The title is provisional; supplied-model redistribution and commercial title/likeness clearance remain unverified.
