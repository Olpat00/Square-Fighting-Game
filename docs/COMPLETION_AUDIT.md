# Current graphics-goal audit

The latest user instruction is a large upgrade to actual game graphics, with no
gameplay, sound or HUD redesign, and only brief visual progress checks. A second map
is permitted but optional. Revision 3 concentrates on The Last Resort rooftop.

| Requirement | Delivered evidence |
| --- | --- |
| Upgrade the actual scene | Revised hotel/bar geometry, refined materials, water, foliage, flames and lighting; genuine source and packaged 1080p scene captures inspected |
| Preserve gameplay | Runtime diff from `0ffe149` is confined to stage art, shader presentation and fighter light layers; collision, platforms, hazard timing/damage and lift schedule checked unchanged |
| Preserve sound and HUD | Audio/UI files and all other runtime code unchanged from the baseline |
| Avoid repeated playtesting | Final previews freeze combat and exit after three stills; no match simulated |
| Editable art and runnable package | Both Blender sources, reproducible stage generation, fresh Windows EXE/PCK, current manifests and 234 release-integrity checks |

See [GRAPHICS_UPGRADE.md](GRAPHICS_UPGRADE.md) for exact artifacts, review scope and
build details. Final source checkpoint is recorded in [CHECKPOINT.md](CHECKPOINT.md).
No additional arena was required or added. There is no outstanding implementation
or packaging task for this graphics pass.

The earlier original-game audit is preserved unchanged in
[COMPLETION_AUDIT_BASELINE.md](COMPLETION_AUDIT_BASELINE.md). Its native-loop/checkpoint
gates and current-release wording describe the previous audit, not new work required
after the user's graphics-only steering. Original controller, human-feel, fixed
hands/faces and performance limits remain explicit in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
