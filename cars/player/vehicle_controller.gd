class_name VehicleController
extends VehicleBody3D

@export var engine_force_max: float = 1600.0
@export var reverse_force: float = 900.0
@export var brake_force: float = 35.0
@export var handbrake_force: float = 65.0
@export_range(1.0, 45.0, 0.5) var max_steer_degrees: float = 28.0
@export_range(0.1, 20.0, 0.1) var steering_response: float = 5.0
@export_range(0.1, 1.0, 0.05) var high_speed_steering_factor: float = 0.35
@export_range(1.0, 200.0, 1.0) var steering_fade_speed_kph: float = 100.0
@export var reverse_speed_threshold: float = 0.75 # Forward meters per second.
@export var reset_height: float = 0.25

@onready var _rear_left: VehicleWheel3D = $WheelRearLeft
@onready var _rear_right: VehicleWheel3D = $WheelRearRight

var _respawn_transform: Transform3D = Transform3D.IDENTITY
var _reset_requested: bool = false


func _ready() -> void:
    _respawn_transform = global_transform


func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("vehicle_reset"):
        _reset_requested = true
        sleeping = false

    if _reset_requested:
        engine_force = 0.0
        brake = 0.0
        steering = 0.0
        return

    var throttle: float = Input.get_action_strength("vehicle_accelerate")
    var brake_input: float = Input.get_action_strength("vehicle_brake")
    var handbrake_pressed: bool = Input.is_action_pressed("vehicle_handbrake")
    var forward_speed: float = linear_velocity.dot(-global_basis.z)

    engine_force = 0.0
    brake = 0.0

    # S brakes forward motion, then becomes reverse near a standstill.
    if brake_input > 0.0:
        if forward_speed > reverse_speed_threshold:
            brake = brake_force * brake_input
        else:
            engine_force = -reverse_force * brake_input
    elif throttle > 0.0:
        engine_force = engine_force_max * throttle

    # Positive steering turns left with this scene's -Z-facing wheels.
    var steer_input: float = Input.get_axis("vehicle_right", "vehicle_left")
    var speed_fraction: float = clampf(get_speed_kph() / steering_fade_speed_kph, 0.0, 1.0)
    var steer_factor: float = lerpf(1.0, high_speed_steering_factor, speed_fraction)
    var target_steering: float = steer_input * deg_to_rad(max_steer_degrees) * steer_factor
    steering = lerpf(steering, target_steering, 1.0 - exp(-steering_response * delta))

    # Cut power and brake only the rear wheels. Normal grip returns unchanged.
    if handbrake_pressed:
        engine_force = 0.0
        _rear_left.brake = maxf(brake, handbrake_force)
        _rear_right.brake = maxf(brake, handbrake_force)

    if throttle > 0.0 or brake_input > 0.0 or handbrake_pressed:
        sleeping = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if not _reset_requested:
        return

    # Teleport through the physics state so the old simulation pose cannot win.
    var reset_transform: Transform3D = _respawn_transform
    reset_transform.origin += Vector3.UP * reset_height
    state.transform = reset_transform
    state.linear_velocity = Vector3.ZERO
    state.angular_velocity = Vector3.ZERO
    state.sleeping = false
    reset_physics_interpolation()
    _reset_requested = false


func set_respawn_transform(new_transform: Transform3D) -> void:
    _respawn_transform = new_transform


func get_speed_kph() -> float:
    return linear_velocity.length() * 3.6
