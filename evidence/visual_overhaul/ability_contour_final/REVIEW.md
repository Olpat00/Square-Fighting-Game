# Ability energy contour review — 2026-09-28

The former opaque cyan/crimson hoops, thick yellow ultimate arches, and large lavender rectangle/X were replaced in the running game. The new visuals use narrow luminous cores, soft low-opacity halos, broken inner filaments, restrained solar rays, and Fine Print's continuous geometric boundary with corner accents and parallel directional cuts. Heavy Duty's grounded wave follows the floor plane. Zone graphics stop at the solid deck within its horizontal span; offstage portions and danger below one-way platforms remain visible.

These changes affect only presentation meshes, shaders, transforms, and uniforms. The authoritative object centers/radii, contacts, move windows, damage, ownership, interruption, and expiry remain unchanged. Normalized visual age follows each existing object's clock, including attached-effect hitstop. No particle-pool behavior or model source was changed. Shader brightness follows the saved flash setting when an effect is created; an existing short-lived effect keeps that creation-time brightness if the setting changes while paused.

## Actual graphical evidence

All captures are unmodified screenshots of `main.tscn`, with actual scripted input and resolved moves. There are **58 screenshots and 151 successful trigger checks**, with no trigger failures, shader errors, runtime errors, or warnings. Engine: Godot 4.7.2 stable, RTX 4080 SUPER, Vulkan. Screenshots are 1920×1080. These tests are presentation fixtures, not performance measurements or manual play tests.

| Directory | Renderer / flash level | View | Captures | Trigger checks |
| --- | --- | --- | ---: | ---: |
| `forward_gameplay_flash0` | Forward+ / 0 | Ordinary gameplay camera, size 11.7 | 16 | 38 |
| `forward_gameplay_flash1` | Forward+ / 1 | Ordinary gameplay camera, size 11.7 | 16 | 38 |
| `mobile_gameplay_flash0` | Mobile / 0 | Ordinary gameplay camera, size 11.7 | 16 | 38 |
| `neutral` | Forward+ / 0.45 | Same-angle closer inspection | 6 | 18 |
| `stomp` | Forward+ / 0.45 | Same-angle closer inspection | 3 | 12 |
| `ribbon` | Forward+ / 0.45 | Same-angle closer inspection | 1 | 7 |

Inspected full-size frames show that Clutch and Heavy's clap retain their circular extent with transparent centers; the grounded stomp stays on the deck instead of crossing the facade; Sunstruck's region remains readable with flashes reduced; and Fine Print's complete warning boundary remains visible at gameplay scale in both renderers. Faces and player labels remain visible. The independent visual reviewer requested strengthening Fine Print's continuous outline after an earlier closeup pass; these final captures include that correction. That reviewer then inspected 12 final full-size Forward+ frames and found no remaining actionable defect, confirming readable continuous Fine Print bounds and resolution of the below-deck effect problem. Earlier `ability_contour_v1` frames are intermediate evidence.

## Reproduction

From the workspace, substitute the absolute Godot executable and absolute output/log paths:

```powershell
& $godot --path 'Game File' --script '../tools/validation/ability_visual_review.gd' --log-file $absoluteLog -- --case=ultimate --flashes=0 "--output=$absoluteOutput"
```

Use `--flashes=1` for the full-intensity set. Add `--rendering-method mobile` before `--script` for the Mobile set. The gameplay-camera subclass retains the real camera and modifies only the in-memory flash value. Its report inherits the parent's generic reproduction text; use the subclass command above to reproduce its exact framing.

For closer neutral/stomp/ribbon inspection, use `presentation_scenarios.gd` and respectively `--case=special_neutral`, `--case=f03_heavy_duty_special_down`, or `--case=f02_sunstruck_special_side`.

Headless regression commands are `--headless --path 'Game File' --script '../tools/validation/ability_scenarios.gd'` and the equivalent `presentation_state.gd`. Logs are `../ability_contour_headless.log` and `../ability_contour_state.log`.

The final focused headless repeat passed **193/193 ability checks** and **88/88 presentation checks** without errors or warnings. The latter includes the coordinator's newly added Low-tier texture checks. The project's later `validate_all` aggregate remains the authoritative whole-project regression report.

## Reviewed runtime source hashes

| File | SHA-256 |
| --- | --- |
| `Game File/combat/ability_controller.gd` | `CE734089C05F3FBE15EF3AE449FFFABA4DA4487BADB12B775D6E3942DDD85C8F` |
| `Game File/presentation/shaders/ability_contour.gdshader` | `78C0D3EEA7632D6D6B3E9939275FB96852C658DB0FEF3F9A666D15413797B927` |
| `Game File/presentation/shaders/ability_filament.gdshader` | `C9247C92582347FB75331EEA2403469A5946906EBA8A8A3CAE7788DA4E185F7C` |

The shader artwork is original code-native geometry and shading. No generated image, external effect asset, or screenshot editing was used for these ability effects.
