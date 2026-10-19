extends SceneTree
## Graphical Godot check for the newly imported fighter GLBs.

const ROSTER: Array[String] = ["f06_rugged_explorer", "f07_urban_sentinel", "f08_midnight_gentleman"]
const CONTACT_TICKS: Dictionary = {
    "f06_rugged_explorer": {"special_neutral": 15, "special_side": 13, "special_up": 10, "special_down": 10, "ultimate": 29},
    "f07_urban_sentinel": {"special_neutral": 17, "special_side": 15, "special_up": 11, "special_down": 18, "ultimate": 40},
    "f08_midnight_gentleman": {"special_neutral": 14, "special_side": 16, "special_up": 9, "special_down": 10, "ultimate": 30},
}

var output: String
var stage: Node3D
var camera: Camera3D
var models: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var report: Dictionary = {"engine": Engine.get_version_info(), "fighters": [], "captures": []}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    output = ProjectSettings.globalize_path("res://../evidence/characters/engine/new")
    DirAccess.make_dir_recursive_absolute(output)
    report["rendering_method"] = RenderingServer.get_current_rendering_method()
    stage = Node3D.new()
    root.add_child(stage)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.035, 0.055, 0.085)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.7, 0.8, 1.0)
    environment.environment.ambient_light_energy = 0.45
    stage.add_child(environment)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-45, -30, 0)
    key.light_energy = 1.0
    key.shadow_enabled = true
    stage.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-35, 145, 0)
    fill.light_color = Color(0.45, 0.7, 1.0)
    fill.light_energy = 0.38
    stage.add_child(fill)
    var floor_mesh := MeshInstance3D.new()
    var floor_box := BoxMesh.new()
    floor_box.size = Vector3(10, 0.08, 6)
    floor_mesh.mesh = floor_box
    floor_mesh.position.y = -0.05
    var floor_material := StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.075, 0.10, 0.15)
    floor_material.roughness = 0.85
    floor_mesh.material_override = floor_material
    stage.add_child(floor_mesh)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.25
    camera.position = Vector3(0, 2.5, 8)
    stage.add_child(camera)
    camera.look_at(Vector3(0, 1.0, 0))
    camera.current = true

    for index in range(ROSTER.size()):
        var fid: String = ROSTER[index]
        var packed := load("res://assets/characters/%s.glb" % fid) as PackedScene
        if packed == null:
            report["fighters"].append({"id": fid, "error": "missing GLB import"})
            continue
        var model := packed.instantiate() as Node3D
        stage.add_child(model)
        model.position.x = float(index - 1) * 1.45
        models.append(model)
        var found := model.find_children("*", "AnimationPlayer", true, false)
        var player := found[0] as AnimationPlayer if not found.is_empty() else null
        if player == null:
            report["fighters"].append({"id": fid, "error": "missing AnimationPlayer"})
            continue
        players.append(player)
        var skels := model.find_children("*", "Skeleton3D", true, false)
        var min_y := INF
        var max_y := -INF
        for node in model.find_children("*", "MeshInstance3D", true, false):
            var mesh := node as MeshInstance3D
            var bounds := mesh.get_aabb()
            for corner in range(8):
                var point := bounds.position + Vector3(
                    bounds.size.x if (corner & 1) != 0 else 0.0,
                    bounds.size.y if (corner & 2) != 0 else 0.0,
                    bounds.size.z if (corner & 4) != 0 else 0.0)
                var world_point := mesh.global_transform * point
                min_y = minf(min_y, world_point.y)
                max_y = maxf(max_y, world_point.y)
        report["fighters"].append({
            "id": fid, "skin_count": skels.size(), "clip_count": player.get_animation_list().size(),
            "rest_feet_y": min_y, "rest_top_y": max_y,
            "local_forward_after_gameplay_yaw": model.transform.basis.rotated(Vector3.UP, PI / 2.0) * Vector3(0, 0, 1),
        })
        var label := Label3D.new()
        label.text = fid.trim_prefix("f06_").trim_prefix("f07_").trim_prefix("f08_").replace("_", " ")
        label.font_size = 23
        label.pixel_size = 0.006
        label.no_depth_test = true
        label.position = Vector3(model.position.x, 0.02, 0.48)
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        stage.add_child(label)

    for action: String in ["idle", "special_neutral", "special_side", "special_up", "special_down", "ultimate", "qa_shoulder_raise", "qa_knee_bend"]:
        for index in range(players.size()):
            var player := players[index]
            if not player.has_animation(action):
                report["fighters"][index]["missing_action"] = action
                continue
            player.play(action)
            var clip := player.get_animation(action)
            var tick := int(CONTACT_TICKS[ROSTER[index]].get(action, 0))
            var time := clip.length * 0.5 if action.begins_with("qa_") else minf(clip.length, float(tick) / 60.0)
            player.seek(time, true)
            player.pause()
        await _capture(action)
    for model in models:
        model.rotation_degrees.y = 90
    for player in players:
        player.play("idle")
        player.seek(0.0, true)
        player.pause()
    await _capture("gameplay_facing")
    var file := FileAccess.open(output.path_join("new_fighters.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "\t"))
    print("NEW_CHARACTER_ENGINE_CHECK_COMPLETE ", output)
    quit(0)

func _capture(label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var path := output.path_join(label + ".png")
    var error := root.get_texture().get_image().save_png(path)
    report["captures"].append({"label": label, "path": path, "error": error})
