# Original signature ability props

Eight original Blender-authored props are exported to `Game File/assets/props/`.
`signature_props.blend` contains the editable model library. Objects are parented
under named roots and arranged for review; runtime GLBs were exported at their
untranslated local origins. The saved Blender camera produces `props_preview.png`.

Reproduce with Blender 5.2:

```powershell
& 'D:\New folder\blender.exe' --background --python tools/blender/props_build.py
& 'D:\New folder\5.2\python\bin\python.exe' tools/blender/props_validate.py
```

All mesh geometry and materials were created locally for this project. No images,
external model files, or external services were used. Blender's bundled Bfont is
used only for review labels, which are excluded from the runtime exports.

Each GLB is a visual-only scene with authored materials. Retain those materials
when instantiating; a blanket emissive material override would remove the wood,
steel, paper and reflector detail. Forward is Godot +X and up is +Y. No collision,
camera, light or animation is embedded in a runtime prop.

| GLB stem | Origin and orientation | Approximate size X × Y × Z (m) |
|---|---|---|
| `solar_disc` | Center; disc face in XY; cap bill points +X | 0.93 × 0.87 × 0.22 |
| `reflector` | Ground; mirrored plate rises 15° toward +X; route arrow rises 30° | 0.78 × 0.50 × 0.80 |
| `log` | Center; rolling axis along Z | 0.97 × 0.98 × 0.72 |
| `plank` | Bottom center; long axis X | 1.80 × 0.16 × 0.48 |
| `branch` | Central suspension point; long axis X | 2.47 × 0.66 × 0.32 |
| `chair` | Ground; seated facing +X | 0.70 × 1.08 × 0.62 |
| `tree` | Root; upright long axis +Y | 1.27 × 5.61 × 0.90 |
| `clipboard` | Bottom grip; printed face toward +Z | 0.46 × 0.61 × 0.09 |

`props_manifest.json` records exact bounds, triangle counts, material batch counts,
and file sizes from the actual export. `validation.json` independently checks the
binary GLB structure and bounds. The branch includes a short rope attachment; its
remaining rope span belongs to runtime presentation. The tree is intentionally
slender, with a clear taper and pine boughs, so the falling-trunk attack stays legible.

No runtime ability script was modified by this asset-authoring task. Integration
and in-engine attack alignment are separate validation steps.
