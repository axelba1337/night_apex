class_name RouteFoundation
extends Node3D

const TEST_TRACK: PackedScene = preload("res://tracks/test_track/test_track.tscn")

@export var imported_map: PackedScene
@export_file("*.jpg", "*.png", "*.hdr", "*.exr") var panorama_path: String = ""

var using_debug_geometry: bool = false
var _prop_poses: Dictionary[Node3D, Transform3D] = {}


func _ready() -> void:
    if imported_map != null:
        $ImportedMapRoot.add_child(imported_map.instantiate())
    else:
        # Reuse the existing straight for system checks. This is NOT a route layout.
        using_debug_geometry = true
        var fallback: Node3D = TEST_TRACK.instantiate()
        for child: Node in fallback.get_children():
            # The demo traffic has fixed-height lanes. Keep the original ramp only
            # in TestTrack itself, not in the route-wrapper integration straight.
            if not child is StaticBody3D or child.name == "Ramp":
                fallback.remove_child(child)
                child.free()
        $CollisionRoot.add_child(fallback)
    if not panorama_path.is_empty() and ResourceLoader.exists(panorama_path):
        var environment: Environment = $WorldEnvironment.environment
        var material: PanoramaSkyMaterial = environment.sky.sky_material
        material.panorama = load(panorama_path) as Texture2D
        environment.background_mode = Environment.BG_SKY
    for prop: Node3D in $PhysicsProps.get_children():
        _prop_poses[prop] = prop.global_transform


func reset_runtime() -> void:
    for prop: Node3D in _prop_poses:
        if prop is BreakableProp:
            prop.reset_prop(_prop_poses[prop])
        elif prop is RigidBody3D:
            prop.global_transform = _prop_poses[prop]
            prop.linear_velocity = Vector3.ZERO
            prop.angular_velocity = Vector3.ZERO
            prop.sleeping = false
    # Route 02 has no TrafficRoot and no dependency on traffic scenes/scripts.
    var traffic: Node = get_node_or_null("TrafficRoot")
    if traffic != null:
        traffic.restart_traffic()
