# Scene graphics revision 3 — September 28, 2026

The current graphics request is implemented, visually inspected and exported.
The existing rooftop received the full pass; the permitted second map was optional.
This pass preserves gameplay, sounds and HUD from checkpoint `0ffe149`.

## Delivered scene

- Hotel glazing, floor spandrels, bronze reveals, warm occupied rooms and curtains.
- Slatted bar canopy, pendants, raised venue lettering, ribbed backbar and tableware.
- Refined 1K stone, timber, brass, linen and bark maps; reflective timber finish.
- Directional dusk reflections, stronger architectural shadows, dedicated fighter
  fill/rim lighting and warm bar/pool practical lights.
- Spectral pool ripples and caustics, subtle foliage movement/backlighting,
  varied anonymous guests, and floor warning/flame effects for the existing vents.

Editable stage sources are `source_art/stage/the_last_resort_modeling.blend` and
`the_last_resort.blend`. The former retains separate construction objects; the
latter contains material batches. Both are reproducible through
`tools/blender/stage_build.py`. Current stage/lift geometry totals 379,996 triangles
and 30 runtime materials. Platform coordinates are unchanged.

## Verification

Godot 4.7.2 imported the current project without logged errors. A roughly seven-second
frozen scene preview rendered three genuine 1920×1080 stills with Forward+ on the
RTX 4080 SUPER. All three source stills were inspected. The pool no longer has the
earlier regular checker reflections, hotel rooms have interior shading, and the
hazard uses a tapered flame instead of a solid orange block. Fighters remain readable
against the terrace. The architectural view explicitly uses a QA perspective camera;
ordinary gameplay keeps its side-on camera. HUD hiding is confined to the preview.

The exported PCK was then loaded by the matching editor engine for the same brief
frozen preview. All three captures completed with exit 0 and no logged errors or
warnings; its normal gameplay-angle and architectural stills were inspected.
This checks packaged graphics, not a new full-match acceptance run or execution of
an external script by the release template. No match was simulated in either preview.

`tools/validation/verify_scene_graphics.py --release` passed 234 static preservation
and file-integrity checks, including all 158 runtime source records in the build
manifest. The EXE/PCK hashes match. Source scope is confined to stage art/shaders,
scene lighting and fighter render layers. All combat, input, UI and audio files are
unchanged; stage support, collision, hazard contacts, damage, timing and lift schedule
are preserved. All five original supplied GLBs still match their recorded hashes.

Current evidence:

- `evidence/visual_overhaul/scene_revision3/final/`: reviewed source stills.
- `evidence/visual_overhaul/scene_revision3/release/`: packaged scene stills.
- `evidence/visual_overhaul/scene_revision3/source_integrity.json` and
  `release_integrity.json`: executed checks and scope.
- `source_art/stage/stage_generation.json`: refreshed art/source hashes.
- `evidence/windows_build_manifest.json`: build time and EXE/PCK/source hashes.
- `evidence/stage/revision3_*`: import, Blender, export and preview logs.

## Build and remaining limits

Launch `builds/windows/RooftopRiot.exe` with the adjacent `RooftopRiot.pck`.
The exported package is scene revision 3, built September 28 at 21:26:55 UTC.
Editable Godot project: `Game File/project.godot`.

Earlier full gameplay, UI, rematch and performance reports remain historical evidence
for the preceding visual revision. Four-fighter performance and the Mobile renderer
were not reprofiled after revision 3; the prior numbers are not new performance claims.
Full native-window checks were stopped at the user's request and are not a current
graphics acceptance gate. No new gameplay/audio/HUD work or repeated match testing
was performed for this final scene pass.

The small background guests and building interiors remain economical stylized models.
Existing fixed hands/faces, approximate foot contact, occasional overhead-label
crowding and untested physical controllers remain documented product limits.
There are no outstanding implementation or packaging tasks for this graphics pass.

To reproduce the visual review, import the project and run
`tools/validation/scene_look.gd` with the graphical Godot editor executable and an
explicit `--output=<directory>` user argument. It automatically exits after three
stills and does not save settings. Rebuild through `export_windows.ps1`; verify the
new manifest with `verify_scene_graphics.py --release`.
