class_name ChaseCamera
extends Node3D

@export var position_response: float = 8.0
@export var heading_response: float = 5.0
@export var camera_height: float = 1.8
@export var camera_distance: float = 6.5
@export var pitch_degrees: float = 12.0

@onready var _spring_arm: SpringArm3D = $SpringArm3D

var _target: Node3D
var _camera_target: Node3D


func _ready() -> void:
    _spring_arm.spring_length = camera_distance
    _spring_arm.rotation.x = deg_to_rad(-pitch_degrees)


func _physics_process(delta: float) -> void:
    if not is_instance_valid(_target):
        return

    var desired_position: Vector3 = _camera_target.global_position + Vector3.UP * camera_height
    global_position = global_position.lerp(desired_position, 1.0 - exp(-position_response * delta))
    rotation.y = lerp_angle(rotation.y, _get_target_heading(), 1.0 - exp(-heading_response * delta))


func set_target(new_target: Node3D) -> void:
    var first_target: bool = not is_instance_valid(_target)
    _target = new_target
    _spring_arm.clear_excluded_objects()
    if not is_instance_valid(_target):
        return

    _camera_target = _target.get_node_or_null("CameraTarget") as Node3D
    if _camera_target == null:
        _camera_target = _target

    # The spring arm should react to the track, not the car it is following.
    if _target is CollisionObject3D:
        _spring_arm.add_excluded_object((_target as CollisionObject3D).get_rid())

    # Start behind the spawn point. All subsequent following is smoothed.
    if first_target:
        global_position = _camera_target.global_position + Vector3.UP * camera_height
        rotation.y = _get_target_heading()


func _get_target_heading() -> float:
    # Follow yaw only so suspension pitch and body roll do not tilt the horizon.
    var forward: Vector3 = -_target.global_basis.z
    if Vector2(forward.x, forward.z).length_squared() < 0.001:
        return rotation.y
    return atan2(-forward.x, -forward.z)
