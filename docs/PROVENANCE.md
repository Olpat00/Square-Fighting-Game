# Project provenance

Source record for **UNSUPERVISED: ROOFTOP RIOT**, including all five arenas, current effects and High/Low character derivatives. This records origin and reproduction; it does not select a project-wide license, certify final visual quality, or establish commercial clearance for the title, people, clothing marks, models, or textures.

## October 3 three-arena expansion

**Verdant Shrine**, **Abyssal Observatory** and **Ember Foundry** combine original locally authored Godot foreground geometry/shaders with separately generated distant matte images. Editable code lives under `Game File/stages/verdant_shrine/`, `stages/abyssal_observatory/` and `stages/ember_foundry/`. The shared `stages/arena_backdrop.gd` frames the matte behind the live geometry. Platform collision, moving scenery, hazards and the illustrated distant scene are distinct; no illustrated surface adds collision.

The three `Game File/assets/arenas/<arena_id>/backdrop.png` files were generated for this project on **2026-10-03** using OpenAI's built-in **image_gen.imagegen** tool. The tool did not supply a model version, and none is inferred. These are scenery assets, not running-game screenshots. The supplied original character models were not used as image-generation inputs or modified by this arena work.

`source_art/environment/arena_artwork_manifest.json` records original saved PNG paths, exact runtime SHA-256 hashes, 1672×941 dimensions and labeled **prompt intent summaries rather than verbatim prompts**. The three runtime files are verified byte-identical copies of their generated originals. Those runtime PNGs are sufficient to reproduce the scenery; external user-profile generation paths are provenance references, not build dependencies. Each corresponding asset folder contains `CREDITS.md`. Re-requesting a generated image is nondeterministic; preserve the PNG for exact reproduction.

The matte supplies Shrine's jungle/temple/waterfall vista, Observatory's distant whale and submerged ruins, and Foundry's cavern/lavafall/forge architecture. Local 3D scenery adds Shrine foliage and pollen, Observatory live manta rays/jellyfish/shoals and caustics, and Foundry moving gears/embers/crucible pools, along with each arena's platforms and announced hazards. See [MAP_EXPANSION.md](MAP_EXPANSION.md) for the authored layouts, live/static distinction, reproduction commands and validation status.

The pre-expansion runtime, tools, docs, Windows build/archive and dirty-work records are preserved in `C:/Users/dayw9/Desktop/Codex/Games/Godot/Fighting Game Map Expansion Backup 20261003-174209`; `evidence/map_expansion/backup.json` records its scope. Manifest creation independently rehashed the eight supplied original GLBs against their preserved hashes and confirmed all eight unchanged. The new art origin record does not replace the existing character-source permission records below.

## User-supplied character sources

Eight original textured GLBs were supplied by the user and preserved unchanged. The three September 28 additions came from `D:/Meshy Assets/The Boys/` and were copied byte for byte into `Assets/` for reproducible local authoring. Their model/texture licenses and redistribution permissions are **unverified**. Filenames containing `Meshy_AI` are source filenames, not evidence of an account tier, license grant, or permission to distribute. The project did not upload these files to an external generation service.

Paths below are relative to the recorded source root `C:\Users\dayw9\Desktop\Codex\Games\Godot\Fighting Game\`. Full original paths and SHA-256 values are also recorded in `evidence/preflight/source_hashes.json`.

| Original path | Project mapping | Original SHA-256 |
| --- | --- | --- |
| `Assets/Wes/Meshy_AI_Colts_Quarter_Zip_Stu_0920200835_texture.glb` | Wes → Clutch, `f01_clutch` | `A6B5F4A2D86D268ED54FB380AF0FA836249C48F547779A9EB1C269592A9AAC0B` |
| `Assets/Jaydon/Meshy_AI_Casual_Confidence_0920200803_texture.glb` | Jaydon → Deadfall, `f04_deadfall` | `79E0611F7830DBABF076E7ED7903FFC04B440DC7FEFD0A858BB1CCCAEFD91F01` |
| `Assets/Josh/Meshy_AI_Casual_Confidence_0920200745_texture.glb` | Josh → Fine Print, `f05_fine_print` | `BD0DC51B3D1DD0AE6F94CAF90FA1FFD5D2E47F071DE5270B7ABD5F7C7E377086` |
| `Assets/Damion/Meshy_AI_Roman_Warrior_0920200819_texture.glb` | Damion → Heavy Duty, `f03_heavy_duty`; user confirmed 2026-09-22 | `25D03E6FA3471CC6EA6F1B92F48720A1B65099FDA06966331B5C9B287937CA77` |
| `Assets/Will/Meshy_AI_Tropical_Street_Fight_0920200858_texture.glb` | Will → Sunstruck, `f02_sunstruck`; user confirmed 2026-09-22 | `BDC32EC43AA35428B8199F4F874271EB99B39D6110B6CA66F699ADE66BBB2D78` |
| `Assets/Rugged Explorer/Meshy_AI_Rugged_Explorer_0928211551_texture.glb` | Rugged Explorer, `f06_rugged_explorer` | `85F57A04762E492D5D15B72ABDAC5511B1864F57F116C2DC06BF1E03085F3CCB` |
| `Assets/Urban Sentinel/Meshy_AI_Urban_Sentinel_0928211602_texture.glb` | Urban Sentinel, `f07_urban_sentinel` | `48C7A46E2176BD8452147F43E76215B4B091F0A13CB82CF524E5E770A7D0E4E6` |
| `Assets/Midnight Gentleman/Meshy_AI_Midnight_Gentleman_0928211534_texture.glb` | Midnight Gentleman, `f08_midnight_gentleman` | `FABDABFCEAEC509885B3724AF79756CD9964A182333BFD052C9EEF3CF0E6E563` |

The first five identity mappings are confirmed. The user explicitly resolved the two formerly ambiguous slots on 2026-09-22: Will is Sunstruck and Damion is Heavy Duty, preserving their supplied tropical clothing and armor respectively. `docs/confirmed_character_mapping.json` records that confirmation. The three new labels follow the filenames supplied on September 28; no real-person identity is inferred for them. Earlier `source_damion` and `source_will` assets remain neutral preparation history; canonical export/validation status is tracked in `docs/VALIDATION.md`. Identity confirmation does not establish source-model or texture redistribution permissions.

## Work authored for this project

### October 2 hero rebuild

The approved rebuild permits redesigned derivative bodies, clothing, hands and
rigs while retaining the recognizable cast. The immutable eight supplied GLBs
are still byte-for-byte preserved (`evidence/rebuild/originals_preserved.json`).
Earlier statements about unchanged derivative geometry below describe earlier
releases, not the hero rebuild.

Motion now combines locally authored choreography and locally retargeted source
motion from Quaternius's **Universal Animation Library, Standard free edition**.
The author's download includes the CC0 1.0 Universal license. The original
archive, license and FBX/GLB files are retained in `source_art/motion/quaternius/`;
per-character build reports identify actual source clips and blend weights.
Sources: https://quaternius.com/packs/universalanimationlibrary.html and
https://quaternius.itch.io/universal-animation-library. No paid tier was acquired
and no supplied character assets were uploaded. The mannequin is not a fighter.

Curated character scenes, added control/deformation rigs, fitted costume parts,
hand topology and contact/timing cleanup are authored locally in Blender.
The authoring/export workflow preserves curated sources; see
`docs/animation_pipeline.md` for the current commands and validation.

### Earlier releases

| Material | Origin and editable source |
| --- | --- |
| Character derivatives | Original geometry and textures retained in optimized derivatives. New skeletons, skin binding, and keyed actions authored locally in Blender through `tools/blender/characters_pipeline.py`; editable files in `source_art/characters/`. The September 22 material refresh restores the supplied per-pixel surface maps through `tools/blender/characters_materials.py`; it does not replace the original albedo with generated clothing. Motion is programmatically authored, not sourced motion capture. The source model/texture permissions above still apply. |
| Low character texture tier | `tools/blender/build_runtime_texture_tiers.py` derives eight `<fighter_id>_low.glb` assets from the canonical GLBs. Albedo, normal and packed roughness/metallic images are reduced from 2K to 1K, with normal averages renormalized; geometry, skin and animation buffers/metadata are preserved. `evidence/characters/texture_tiers.json` records hashes/dimensions. These remain derivatives of the supplied textures, not newly licensed artwork. Low selects them at the next match; High uses the canonical 2K assets. |
| Character portraits | Chest-up 768×768 images rendered locally in Blender from the corresponding prepared canonical character, through `tools/blender/characters_portraits.py`. Each character folder contains its editable `portrait_studio.blend`; output is `Game File/assets/portraits/<fighter_id>.png`. Original studio lighting/composition; no generated replacement face or body. |
| The Last Resort arena | Original locally modeled architecture, signs, props, palms, pool, and anonymous guests. `tools/blender/stage_build.py` and `source_art/stage/` produce `Game File/assets/stage/`. Architectural revision 3 adds a detailed hotel facade, slatted canopy, pendants, tableware and varied guests; editable construction and batched Blender files are retained. Earlier nearby city studies remain hidden in the editable source and excluded from runtime. No external model or texture library supplied these Blender assets; the separately generated distant matte is recorded below. |
| Stage PBR material maps | 21 original 1024×1024 PNGs authored numerically by `texture_set()` in `tools/blender/stage_build.py`: base color, roughness and tangent-space normal maps for slate, travertine (`stone`), two teak variants (`wood`, `wood2`), brass, linen and palm bark. Revision 3 refines stone pores and timber grain. Sources live in `source_art/stage/textures/`, are packed into the editable Blender files and embedded in the runtime GLBs. They are procedural project artwork, not downloaded scans or library textures. |
| Distant city/sky matte | Original image generated for this project with the built-in `image_gen` tool on 2026-09-22, from the recorded fictional-city prompt. Runtime texture: `Game File/assets/environment/dusk_city.png`. It is a background asset used behind the modeled rooftop, not a game screenshot or validation capture. Full source filename, prompt and integrity details follow below. |
| Signature ability props | Eight original locally modeled props and materials from `tools/blender/props_build.py`, with editable `source_art/props/signature_props.blend` and runtime exports in `Game File/assets/props/`. |
| Party terrace chair | Original slim teak frame, slatted back, linen seat and brass feet authored by `tools/blender/stage_party_chair.py`, with editable `source_art/stage/party_chair.blend` and `Game File/assets/stage/party_chair.glb`. Reuses the original stage material maps above. This cosmetic breakable decoration is separate from Heavy Duty's temporary ability chair. |
| Runtime shaders and effects | Original procedural shader/code artwork under `Game File/presentation/shaders/`, `presentation/effects_director.gd`, `combat/ability_controller.gd` and `stages/rooftop_riot/`: pool water, impacts, soft dust, shields/markers, bounded debris and the current ability contours/filaments. No commercial game effect textures or external effect packs are used. Final selected ability-energy frames were independently reviewed in `evidence/visual_overhaul/FINAL_VISUAL_REVIEW.md`; this origin record itself is not an acceptance result. |
| Audio and music | All 23 runtime WAVs synthesized locally from oscillators and deterministic noise by `tools/generate_audio.py`, seed `80223`. Includes original music, ambience, impacts, movement, defense, UI, and event sounds. No sampled recordings, cloned voice, or external music assets. See `docs/audio_provenance.md` and `Game File/assets/audio/audio_manifest.json` for details and hashes. |
| Game implementation | Game code, move data, combat logic, UI layout, procedural presentation effects, and validation tools authored for this project from the supplied brief. Source lives in `Game File/`, `tools/`, and `docs/moves/`. This record assigns no license to that work. |

Character source integrity and derivative structure are recorded in `evidence/characters/export_validation.json`; the authored environment/prop sources include their own manifests and reproduction instructions.

The September 28 scene revision also authors spectral water ripples/caustics,
foliage wind/backlighting, lit hotel rooms and procedural warning/flame shaders in
`Game File/stages/rooftop_riot/`. These use mathematical patterns and engine PBR
lighting, with no newly generated or downloaded image. Source and runtime hashes
are recorded in `source_art/stage/stage_generation.json`. The later three-fighter
integration adds character derivatives, animations, moves and combat code without
altering those scene assets.

## Generated background record

`source_art/environment/dusk_city_generation.json` records the complete prompt, tool, date, purpose, source and runtime paths. The source image is:

`C:/Users/dayw9/.codex/generated_images/01a0c072-1ef6-7440-a8d0-03c589b4b92d/exec-86f9b441-10b0-4154-a1fd-67c4e777fbc7.png`

The prompt requests a fictional city at golden/blue hour, layered skyline and clouds, with no recognizable landmarks, lettering, UI, people or foreground terrace. The generated source and `Game File/assets/environment/dusk_city.png` have the same verified SHA-256: `2E9B3CA0E1166D804E3EA28915884D9302874FDBBBD6A4C1CFDCE3EE9DD3F9A9`. The runtime copy is the generated asset itself; genuine visual-validation images are separately captured from Godot into `evidence/`.

## September 29 lunar arena and combat presentation

`Game File/stages/lunar_reach/` contains original procedural 3D terrain, fractured rock instances, aerospace architecture and shaders. These are locally authored geometry and material code, not downloaded model packs or scanned geometry. `Game File/presentation/ability_art.gd`, `fighter_attack_presentation.gd`, the new attack/impact shaders and revised effects director are original procedural visual artwork; supplied character faces, clothing, textures and keyed rigs remain unchanged.

The Earth texture `Game File/assets/lunar_reach/earth_blue_marble.jpg` is NASA Blue Marble imagery; source and attribution are recorded in that folder's `CREDITS.md`. The lunar horizon image `crater_horizon.png` was generated with the built-in image_gen tool on September 29, 2026. Its complete prompt, original saved path and runtime path are recorded in `crater_horizon_generation.json` alongside it. The generated horizon is a scenery asset, not a game screenshot. All images in `evidence/lunar_upgrade/` are separately captured running-game views, except that no generated imagery is labeled as verification.

## Fonts and software

The redesigned runtime UI creates two Godot `SystemFont` resources: body text requests `Segoe UI` with `Arial` fallback; display text requests `Bahnschrift` with `Arial` fallback and weight 700. Fonts resolve from the player's system; no font files are bundled in `Game File/`. Blender's bundled Bfont was used for modeled arena signage and preview labels; signage is exported as mesh geometry, and prop preview labels are excluded from runtime exports.

**Godot Engine 4.7.2** supplies the game runtime and is distributed under the MIT license. Godot's official license page states that a link in game documentation or credits is an acceptable way to provide its license notice; the engine's third-party component notices are also linked there. Attribution: [Godot Engine license and copyright notices](https://godotengine.org/license/). The engine license does not establish permission for the supplied character content.

**Blender 5.2.0** was used for local authoring and export. Blender itself is not shipped with the game and is not a runtime dependency. Its software licensing is described on the [official Blender license page](https://www.blender.org/about/license/). Using Blender does not resolve the permissions of imported source assets.

Official software license pages were checked on 2026-09-20. This provenance record is separate from the release's engine/component notice packaging and from any future project license decision.
