# Future iOS work (not shipped or device-validated)

Input snapshots separate gameplay from keyboard/controllers; a touch provider can be added without replacing combat. The UI uses scalable containers, effects are capped, and no runtime Blender dependency exists. Windows Mobile-renderer evidence is a renderer compatibility check only, not an iPhone/iPad performance result.

Still required: touch layout and accessibility testing; safe areas and aspect-ratio QA; Metal renderer/device testing; memory/thermal/battery profiling on real phones; scalable texture/mesh tiers; app lifecycle/background input behavior; signing, provisioning and distribution review.

Godot 4.7's current [iOS export documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html) requires macOS with Xcode, matching export templates, a team identifier and unique bundle identifier. None of the macOS/Xcode/device/export/signing work has been performed here. Verify Apple requirements again when that work starts.

The [Godot renderer comparison](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html) describes Mobile as a separate renderer with fewer features; this project switches via a fresh process/launcher. A Windows renderer run does not establish equivalent appearance or speed on mobile hardware.
