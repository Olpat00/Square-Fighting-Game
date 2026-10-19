# Verified toolchain

- Windows 11 Home 64-bit, OS 10.0.26200.
- Godot `4.7.2.stable.official.ed1daf0bf`, executable `D:/Game Engines/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- Blender `5.2.0 LTS`, executable `D:/New folder/blender.exe`.
- Bundled Python `C:/Users/dayw9/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
- Graphical Godot probe: Vulkan 1.4.341 / Forward+ / NVIDIA GeForce RTX 4080 SUPER / Windows display server. Separate headless editor/import pass succeeded.
- Blender background Python probe succeeded with `bpy.app.version_string` and data access.
- Export templates directory was empty at preflight. No upgrade or global configuration change performed.

Successful command forms (run from repository root):
```
& 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'Game File' --editor --import --quit
& 'D:\Game Engines\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'Game File' --script '../tools/validation/preflight.gd' --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x720
& 'D:\New folder\blender.exe' --background --factory-startup --python-expr "import bpy; print('BLENDER_PYTHON_OK', bpy.app.version_string, len(bpy.data.objects))"
```

Version-specific API references consulted: [Godot 4.7 CharacterBody3D](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html), [Godot 4.7 Windows export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html), [Blender 5.2 Action](https://docs.blender.org/api/5.2/bpy.types.Action.html). Engine-executed probes and script tests are authoritative where remote documentation is unavailable.
