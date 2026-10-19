# Three-arena expansion — October 3, 2026

<!-- LIVING_ARENAS_CURRENT_BEGIN -->
## Living backgrounds — all five arenas

All five arenas now have scene-specific moving backgrounds. The original illustrated mattes and photographs remain untouched; localized shader animation and layered 3D scenery add movement, depth and setting-specific life. The picture does not wobble as a whole. Background motion follows the authoritative stage clock, freezes during pause and resets with the match. Low keeps the main ambient motion with fewer animals, particles or secondary details. The finished platforms, collision layouts, combat timing and Party hazard behavior are retained.

| Arena | Living background |
|---|---|
| The Last Resort | Drifting skyline clouds, gliding gulls, pool ripples, foliage and subtle guest movement |
| Lunar Reach | Tracking observatory dishes, a moving survey rover, beacons, a passing orbital relay and slow Earth motion |
| Verdant Shrine | Flowing waterfalls, drifting valley mist, swaying foliage and birds crossing the valley |
| Abyssal Observatory | Swimming fish schools, pulsing jellyfish, gliding mantas, suspended particles and drifting water-light rays |
| Ember Foundry | Flowing molten spillways, animated lava, rising smoke and embers around working machinery |

Editable motion and shaders live under `Game File/stages/`, with shared distant-art integration in `arena_backdrop.gd` and its shader. Arena scripts own their 3D scenery, movement paths, detail counts and clock updates. The original distant-art bitmap files retain their map-expansion provenance; this pass creates no replacement image or character assets. Every original baseline PNG/JPEG and the supplied fighter originals are checked directly against their preserved hashes.

Exported **2026-10-04T19:39:14.0345852Z** with Godot 4.7.2; **537 runtime files** match the current source, build, still-review, motion-media and performance inventories (`F27D1FA730C48897031F76F245F4B28D50B6DFA35BC3D4C7E249666CDF1E8825`). 5,097 source assertions; 25 reviewed 1080p arena views; 378 scenery assertions/70 timed, pause and reset stills across High/Low; five fully decoded 12-second/60 FPS ambient clips (1600×900) with assistant sample-frame review; five completed CPU matches/35 lifecycle checks; 108 exported-PCK UI checks/40 captures; actual Windows EXE smoke on each of the three added arenas; ten isolated 60-second four-player profiles using a 120 FPS render cap, with VSync disabled.

Current still hashes and findings: `evidence/background_rebuild/visualreview.json`. Clock/pause/reset evidence: `evidence/background_rebuild/review_motion/living_background_review.json`. Reviewed media: `evidence/background_rebuild/motion/movie_receipt.json`, with `motion/<arena>/ambient.mp4` for each arena. These are normal-speed 12-second/60 FPS stationary-player ambient fixtures at actual measured 1600×900, fully decoded with 0/2/5/10-second sample-frame inspection. They are not human gameplay or performance recordings.

Pre-background runtime, docs, tools and Windows build: `evidence/background_rebuild/baseline/`; baseline receipt: `evidence/background_rebuild/baseline.json`; invariant audit: `evidence/background_rebuild/preservation.json`. The prior `builds/RooftopRiot-Platform-Upgrade-Windows.zip` retains SHA-256 `7D3B36F762AC219ABACDBC02D277326A4EB98B8CBB2EE37B0F8B2387BEEABB70`. Prior platform/map/fighter evidence remains historical.

### Reproduction

Run graphical still review, ambient movie captures, lifecycle, export, Windows validation and profiling sequentially. Freeze runtime sources before final captures/receipts. The notes generator requires current 25-view acceptance, scenery restoration and media receipts, original preservation, and matching source/build/profile hashes before it writes docs. The strict packager then creates `builds/RooftopRiot-Living-Arenas-Windows.zip` and `evidence/background_rebuild/delivery.json`; visual/media acceptance is independently checked and bound in the final background delivery audit.

```powershell
$godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe'
$project = Join-Path $PWD 'Game File'
$allArenas = @('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')
$review = Join-Path $PWD 'evidence/background_rebuild/review_reproduced'
$motionReview = Join-Path $PWD 'evidence/background_rebuild/review_motion_reproduced'
$profiles = Join-Path $PWD ('evidence/background_rebuild/performance/local-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& ./tools/validation/validate_all.ps1 -Godot $godot
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_stage_review.gd') -- "--output=$review"
# Inspect all 25 captures and record exact hashes/current runtime in visualreview.json.
& $godot --path $project --script (Join-Path $PWD 'tools/validation/living_background_review.gd') -- "--output=$motionReview"
# Review timed/pause/reset samples and bind the current motion report in visualreview.json.
python ./evidence/background_rebuild/record_movies.py --resume
# The runner trims 720 scenery frames, measures actual dimensions, fully decodes,
# and writes a pending receipt. Inspect all 0/2/5/10-second samples before marking
# movies/samples reviewed and promoting movie_receipt.json to passed. No upscaling.
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_match_flow.gd') -- "--evidence-root=$(Join-Path $PWD 'evidence/rebuild')"
& ./tools/validation/export_windows.ps1 -Godot $godot
& ./tools/validation/validate_windows_build.ps1 -Godot $godot
& ./tools/validation/validate_map_release.ps1
& ./tools/validation/profile_rebuild.ps1 -Arenas $allArenas -Qualities High,Low -Players 4 -Seconds 60 -RenderCap 120 -Output $profiles
python ./evidence/background_rebuild/update_delivery_notes.py $profiles
# Add any completed unchanged-source repeats as further directory arguments:
# python ./evidence/background_rebuild/update_delivery_notes.py $profiles $repeatObservatory $repeatFoundry
& ./tools/validation/package_map_expansion.ps1 -PerformanceDirectory $profiles `
  -ArchivePath (Join-Path $PWD 'builds/RooftopRiot-Living-Arenas-Windows.zip') `
  -DeliveryReceiptPath (Join-Path $PWD 'evidence/background_rebuild/delivery.json')
```

Human playtesting, physical multi-controller testing, continuous human motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant visual review of scenery fixtures and automated CPU matches do not establish competitive balance, sound-mix quality or zero clipping in every combat pose.
<!-- LIVING_ARENAS_CURRENT_END -->

<!-- LIVING_ARENAS_HISTORY_BEGIN -->
## Historical records before the living-background upgrade

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current living-background acceptance is above. Any earlier heading or text calling a result current applies only to its recorded snapshot. The preceding platform runtime, docs, tools and Windows build are preserved under `evidence/background_rebuild/baseline/`. Earlier failure histories remain retained.
<!-- LIVING_ARENAS_HISTORY_END -->

<!-- PLATFORM_REFINEMENT_CURRENT_BEGIN -->
## Platform refinement — all five arenas

Main decks and raised platforms on all five arenas have rebuilt surface construction. Flat face normals and chamfered geometry give the slabs distinct top, edge and underside planes. The authored landing planes, arena layouts and lift behavior are retained. Materials and detail follow each arena's setting; High and Low retain readable platform edges.

| Arena | Platform finish |
|---|---|
| The Last Resort | Timber decks, stone faces and brass edge details |
| Lunar Reach | Service panels and vent housings with a clear landing edge |
| Verdant Shrine | Jointed weathered stone with carved edge construction |
| Abyssal Observatory | Marble and brass around recessed cobalt panels |
| Ember Foundry | Steel treads, support ribs and inset vents |

The shared editable slab builder is `Game File/stages/platform_geometry.gd`; per-arena construction lives under `Game File/stages/`. Platform material shaders remain editable source files in those arena folders. No new generated bitmap artwork or character rebuild is part of this pass. Distant illustrated vistas retain their original map-expansion provenance.

Exported **2026-10-04T17:42:41.6458493Z** with Godot 4.7.2; **525 runtime files** match the current source, build, visual-review and performance inventories (`5D87C1AAB5E7C45183D0AFD7AD941C8BC2456A96F0A1326730F16A60C202B7B0`). 5,097 source assertions; 25 current 1080p platform views; five completed CPU matches/35 lifecycle checks; 108 exported-PCK UI checks/40 captures; actual Windows EXE smoke on each of the three added arenas; ten isolated 60-second four-player profiles.

Current still hashes and findings: `evidence/platform_refinement/visualreview.json`. Pre-platform runtime, docs, tools, build and evidence: `evidence/platform_refinement/baseline/`; preservation receipt: `evidence/platform_refinement/baseline.json`. The prior `builds/RooftopRiot-Five-Arenas-Windows.zip` retains SHA-256 `7DF9A8AA9BCF41CA60A8A4C6244BF31AE07297FAD68E9D6ADACC8D0B0D60C9B3`. Prior map movies remain historical evidence of that earlier build.

### Reproduction

Run graphical review, lifecycle, export, Windows validation and profiling sequentially. Freeze runtime sources before final captures/receipts. The notes generator requires current 25-view acceptance and matching source/build/profile hashes before it writes docs; the strict packager then creates `builds/RooftopRiot-Platform-Upgrade-Windows.zip` and `evidence/platform_refinement/delivery.json`.

```powershell
$godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe'
$project = Join-Path $PWD 'Game File'
$allArenas = @('rooftop_riot','lunar_reach','verdant_shrine','abyssal_observatory','ember_foundry')
$review = Join-Path $PWD 'evidence/platform_refinement/review_reproduced'
$profiles = Join-Path $PWD ('evidence/platform_refinement/performance/local-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& ./tools/validation/validate_all.ps1 -Godot $godot
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_stage_review.gd') -- "--output=$review"
# Inspect all 25 captures and record exact hashes/current runtime in visualreview.json.
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_match_flow.gd') -- "--evidence-root=$(Join-Path $PWD 'evidence/rebuild')"
& ./tools/validation/export_windows.ps1 -Godot $godot
& ./tools/validation/validate_windows_build.ps1 -Godot $godot
& ./tools/validation/validate_map_release.ps1
& ./tools/validation/profile_rebuild.ps1 -Arenas $allArenas -Qualities High,Low -Players 4 -Seconds 60 -Output $profiles
python ./evidence/platform_refinement/update_delivery_notes.py $profiles
# Add any completed unchanged-source repeats as further directory arguments:
# python ./evidence/platform_refinement/update_delivery_notes.py $profiles $repeatObservatory $repeatFoundry
& ./tools/validation/package_map_expansion.ps1 -PerformanceDirectory $profiles `
  -ArchivePath (Join-Path $PWD 'builds/RooftopRiot-Platform-Upgrade-Windows.zip') `
  -DeliveryReceiptPath (Join-Path $PWD 'evidence/platform_refinement/delivery.json')
```

Human playtesting, physical multi-controller testing, continuous motion/audio acceptance, weaker-PC performance and current Mobile-renderer performance remain unverified. Assistant still review and automated CPU matches do not establish competitive balance or zero clipping in every pose.
<!-- PLATFORM_REFINEMENT_CURRENT_END -->

<!-- PLATFORM_REFINEMENT_HISTORY_BEGIN -->
## Historical records before the platform refinement

The retained notes below describe earlier build snapshots. Their screenshots, movies, runtime counts, metrics and package names are historical; current platform acceptance is above. The pre-platform runtime, docs, tools, Windows build and map evidence are preserved under `evidence/platform_refinement/baseline/`. Earlier failure histories remain retained.
<!-- PLATFORM_REFINEMENT_HISTORY_END -->

Verdant Shrine, Abyssal Observatory and Ember Foundry add three different settings and platform arrangements to the existing Last Resort and Lunar Reach. All five arenas use the same fighters, local two-to-four-player inputs, damage/stock rules and authoritative 60 Hz combat. Both Fair Fight and Party are available through the existing arena selection.

## Arena layouts and identity

Coordinates below use the game's meter-scale world units. The four top planes alone determine platform collision. Background cliffs, animals, gears and illustrated architecture have no collision or damage.

| Arena | Main deck | Side platforms | Center platform | Presentation and Party hazard |
| --- | --- | --- | --- | --- |
| **Verdant Shrine** (`verdant_shrine`) | Width 20; y=0 | Width 4; x=±5.8; y=3.25 | Width 4; y=6.2; Party amplitude 0.65; sine divisor 180 ticks | Moss-stone terraces over a turquoise jungle canyon, ancient carvings and waterfalls. Gold warning rings precede turquoise spirit geysers. |
| **Abyssal Observatory** (`abyssal_observatory`) | Width 19.2; y=0 | Width 3.6; x=±5.8; y=4.2 | Width 4.2; y=2.5; Party amplitude 0.65; sine divisor 720 ticks | Marble, brass and cobalt gallery beneath the ocean, reef ruins and marine life. Pressure-release jets use clear floor warnings. |
| **Ember Foundry** (`ember_foundry`) | Width 18.4; y=0 | Width 3.6; x=±5.6; y=2.9 | Width 3.2; y=6.4; Party amplitude 0.9; sine divisor 174 ticks | Steel/obsidian bridge over a volcanic forge, with copper vessels and moving bronze gears. Announced furnace vents burst from the deck. |

The lift formula is `base_y + sin(tick / period_ticks) * amplitude`; the divisor is not the complete oscillation period. Fair Fight keeps the center at its base height and disables hazards. Party uses the established deterministic 540-tick hazard cycle: 72 warning ticks followed by 24 active ticks, at a seeded choice of x=−8 or x=8. The existing hazard hit carries 7 damage and an upward launch. Hazard appearance varies by arena without changing that rule.

Stage edges, the solid deck underside, ledge recovery and CPU navigation read the selected deck dimensions. Reset restores the authored lift height and all scenery clocks. High and Low use identical collision planes. The camera and label layout remain shared across all arenas.

## Authored 3D and generated distant art

The foreground art is editable Godot geometry, materials and shaders. It is rebuilt deterministically when the stage instantiates; these arenas require no hidden Blender export or external model download. The distant vista is a separate generated PNG framed by `Game File/stages/arena_backdrop.gd`. Actual game captures are under `evidence/map_expansion/`; the generated matte images are scenery assets, not screenshots or validation evidence.

| Arena | Editable source | Live scenery | Static distant matte |
| --- | --- | --- | --- |
| Verdant Shrine | `Game File/stages/verdant_shrine/verdant_shrine_stage.gd` and adjacent shaders | Folded foliage, pollen, restrained mist and a small lagoon shimmer; moss-stone terraces, roots and spirit wells | Jungle cliffs, carved guardians, temples, broad waterfalls and the lagoon panorama |
| Abyssal Observatory | `Game File/stages/abyssal_observatory/abyssal_stage.gd` and adjacent shaders | Manta rays, jellyfish, silver shoals, marble caustics, water shafts and pressure effects | Distant humpback, reef towers, submerged ruins and far marine life |
| Ember Foundry | `Game File/stages/ember_foundry/ember_stage.gd` and adjacent shaders | Counter-rotating gears, hydraulic crown, embers, molten crucible pools and vent effects; banded vessels and chain links | Cavern architecture, distant furnaces, illustrated machinery, lavafalls and the deep molten river |

Animated scenery derives from the stage tick rather than the wall clock, so pause stops it with combat. Low reduces actual scenery and shader work: Shrine cuts foliage instances and removes pollen, hanging detail, lights and shimmer; Observatory reduces fish counts and removes coral detail, extra jellyfish, shafts and marble caustics; Foundry cuts embers and hides incidental gears, vessels and rivets. Common expensive lighting and post-processing are also reduced. Returning to High restores the authored details.

All three 1672×941 background PNGs were generated on **October 3, 2026** with OpenAI's built-in `image_gen.imagegen` tool. No model version was supplied. [The artwork manifest](../source_art/environment/arena_artwork_manifest.json) records labeled artistic-intent summaries, original saved paths, exact SHA-256 hashes, dimensions and byte-for-byte runtime copy verification. Intent summaries are explicitly not verbatim prompt transcripts. Each arena's asset folder also contains `CREDITS.md`. Exact reconstruction reuses the preserved PNG; a new generation request is not deterministic.

## Preservation

Before the expansion, the runtime project, tools, docs, existing Windows build/archive and dirty-work records were copied to `C:/Users/dayw9/Desktop/Codex/Games/Godot/Fighting Game Map Expansion Backup 20261003-174209`. The generated `.godot` cache was excluded. [The backup receipt](../evidence/map_expansion/backup.json) records the archive hash. Supplied `Assets/` and curated character sources remain in their existing locations; this map work does not regenerate them.

The artwork-manifest creation independently rehashed all eight supplied original character GLBs against the retained preservation records: all eight match. Existing character source permissions remain as described in [PROVENANCE.md](PROVENANCE.md); the new map art does not change those records.

## Reproduction and review

Run these commands from the workspace root in PowerShell. The checked-in tools use the local Godot 4.7.2 executable by default. Import and headless validation regenerate cache and test evidence, not the preserved image originals.

```powershell
$godot = 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe'
$project = Join-Path $PWD 'Game File'
$newArenas = @('verdant_shrine', 'abyssal_observatory', 'ember_foundry')

& $godot --headless --path $project --editor --import --quit
& .\tools\validation\validate_all.ps1 -Godot $godot

$review = Join-Path $PWD 'evidence/map_expansion/review_reproduced'
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_stage_review.gd') -- "--output=$review" '--arenas=verdant_shrine,abyssal_observatory,ember_foundry'

& .\tools\validation\capture_brawl.ps1 -Arenas $newArenas -Output (Join-Path $PWD 'evidence/map_expansion/brawl_reproduced')
$allArenas = @('rooftop_riot', 'lunar_reach') + $newArenas
$profiles = Join-Path $PWD 'evidence/map_expansion/performance_reproduced'
& .\tools\validation\profile_rebuild.ps1 -Arenas $allArenas -Qualities High,Low -Players 4 -Seconds 60 -Output $profiles

& .\tools\validation\export_windows.ps1 -Godot $godot
& .\tools\validation\validate_windows_build.ps1 -Godot $godot
& .\tools\validation\validate_map_release.ps1
& $godot --path $project --script (Join-Path $PWD 'tools/validation/rebuild_match_flow.gd') -- "--evidence-root=$(Join-Path $PWD 'evidence/rebuild')"
& .\tools\validation\package_map_expansion.ps1 -PerformanceDirectory $profiles
```

Run profiling alone, after captures and other graphical jobs finish. Movie writing and screenshots include readback/encoding overhead and must not be used as performance measurements. The profiling harness measures render intervals and CPU/GPU work separately; the exported Windows executable receives its own validation after export.

## Historical pre-platform validation status

The current full-source gate passes 5,097 assertions, including 120 stage, 181 presentation and 86 animation checks. All five complete matches pass 35 lifecycle checks. Exported-PCK UI passes 108 checks; the actual EXE passes three new-arena smoke runs. Fifteen final stills were reviewed, and normal/half-speed four-player movies were captured and fully decoded. Ten isolated one-minute 1080p High/Low four-player cases bind to the same unchanged source and assets.

See [VALIDATION.md](VALIDATION.md) and [PERFORMANCE.md](PERFORMANCE.md) for current evidence, exact metrics and limits. The verified playable package is `builds/RooftopRiot-Five-Arenas-Windows.zip`; editable arena code and original matte PNGs remain in this workspace. The prior build/archive are preserved. Human playtesting, physical controllers and weaker-PC performance remain unverified.
