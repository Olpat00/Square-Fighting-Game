# Current working checkpoint

**Graphics delivery checkpoint: `1fa72ece0a4c4b4e196be1ed10854e6d569d0543`
(`1fa72ec`), September 28, 2026.** It contains the complete scene revision 3 source,
editable art, reviewed source/package captures, current export manifest and delivery
documentation. The current Windows PCK hash is
`9657C5422E42175752A6743BB95E44AFF90BC66431B50204DDE086E75142CAA6`.
This checkpoint note is saved immediately afterward as a documentation-only commit.

See root STATUS.md and GRAPHICS_UPGRADE.md for the current scene revision 3 delivery.
Source-protection commit: `341faec`. Implementation checkpoint `37ddc2b` contains the
complete five-fighter game and first visual rebuild. Checkpoint `0ffe149` saves the
subsequent texture tiers, effects, native-input fix and baseline validation evidence.
The revision 3 scene pass is compared against `0ffe149` to verify that gameplay,
sounds, HUD, character geometry and animation behavior remain unchanged.

Original source GLBs remain unchanged under `Assets/`, excluded from Git to avoid duplicating immutable high-density input binaries. Their paths and SHA-256 hashes are recorded in `evidence/preflight/source_hashes.json` and `docs/PROVENANCE.md`. Runtime derivatives and editable authored Blender sources are included in the implementation checkpoint. Exported Windows binaries and downloaded official export templates remain local under ignored `builds/` and `tools/runtime/`.

All generated scripts, scene assets, documentation, evidence reports and editable sources live in this workspace. No project assets were published or uploaded. Windows export can run without Blender installed; editing/rebuilding art uses the verified local Blender 5.2.0 LTS.
