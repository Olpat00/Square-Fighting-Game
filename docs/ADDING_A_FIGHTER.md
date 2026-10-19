# Adding a fighter

1. Preserve the original model and add a source hash/mapping record. Prepare its editable rig in `source_art/characters/<id>/` with the semantic skeleton and tested real actions described in `animation_pipeline.md`.
2. Export GLB and a model-derived portrait to `Game File/assets/characters/<id>.glb` and `Game File/assets/portraits/<id>.png`. Supply an optional `<id>_low.glb` with reduced textures and identical skin/animations for Low graphics; the builder selects that conventional path and safely falls back to the canonical GLB when absent. The shipped roster uses `tools/blender/build_runtime_texture_tiers.py` to generate and verify this tier.
3. Add a definition script under `characters/definitions/` with static `create() -> FighterDefinition`. It should use a unique stable ID, stats, descriptions, palette, passive key and a complete set of immutable MoveDefinitions. Use `_builder.gd` as an authoring helper.
4. Supply every required move/animation mapping. Shared names are not proof of correct retargeting: inspect in-engine timing, deformation, facing, scale, and hitbox alignment.
5. Reuse a mechanic key or add a focused kit under `combat/abilities/<mechanic>.gd` implementing the AbilityKit interface. The roster, selection, match, damage resolver and camera need no new fighter-specific branches.
6. Run content/input/combat scenarios, mirrored and mixed pairing smoke tests, graphical animation inspection, and actual performance checks.

Extensibility evidence: `docs/moves/content-validation.json` records temporary new-ID content discovery. The fixture was removed; no sixth placeholder was added to the shipped roster.
