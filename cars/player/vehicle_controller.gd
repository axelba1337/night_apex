class_name VehicleController
extends VehicleBody3D

signal burnout_changed(active: bool)

@export var handling_profile: VehicleHandlingProfile
@export var burnout_max_speed_kph: float = 18.0
@export var burnout_engine_multiplier: float = 1.1
@export_range(0.01, 1.0) var burnout_rear_grip_factor: float = 0.18
@export var burnout_hold_brake_force: float = 60.0

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
var _controls_enabled: bool = true
var _burnout_active: bool = false
var _rear_grip: Vector2
var _smoke: Array[GPUParticles3D] = []


func _ready() -> void:
    if handling_profile != null:
        handling_profile.apply_to(self)
    _rear_grip = Vector2(_rear_left.wheel_friction_slip, _rear_right.wheel_friction_slip)
    for smoke_path: String in ["WheelRearLeft/TireSmokeLeft", "WheelRearRight/TireSmokeRight"]:
        var particles: GPUParticles3D = get_node_or_null(smoke_path) as GPUParticles3D
        if particles != null:
            _smoke.append(particles)
    _respawn_transform = global_transform


func _physics_process(delta: float) -> void:
    if _controls_enabled and Input.is_action_just_pressed("vehicle_reset"):
        _reset_requested = true
        sleeping = false

    if _reset_requested:
        _set_burnout_active(false)
        engine_force = 0.0
        brake = 0.0
        steering = 0.0
        return

    if not _controls_enabled:
        _set_burnout_active(false)
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

    var grounded: bool = _rear_left.is_in_contact() or _rear_right.is_in_contact()
    _set_burnout_active(throttle > 0.0 and brake_input == 0.0 and handbrake_pressed
        and get_speed_kph() <= burnout_max_speed_kph and grounded)
    if _burnout_active:
        # The front brakes hold the chassis while the driven rear wheels lose grip.
        # VehicleBody3D prioritizes driven-wheel force over its brake value.
        brake = burnout_hold_brake_force
        engine_force = engine_force_max * throttle * burnout_engine_multiplier
    elif handbrake_pressed:
        # Preserve the existing high-speed and throttle-free handbrake behavior.
        engine_force = 0.0
        _rear_left.brake = maxf(brake, handbrake_force)
        _rear_right.brake = maxf(brake, handbrake_force)

    if throttle > 0.0 or brake_input > 0.0 or handbrake_pressed:
        sleeping = false
    _update_smoke_positions()


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


func set_controls_enabled(enabled: bool) -> void:
    if not enabled:
        _set_burnout_active(false)
    _controls_enabled = enabled
    engine_force = 0.0
    brake = 0.0 if enabled else brake_force
    steering = 0.0


func reset_to_spawn() -> void:
    _set_burnout_active(false)
    _reset_requested = true
    sleeping = false


func is_burnout_active() -> bool:
    return _burnout_active


func get_rear_wheel_world_positions() -> PackedVector3Array:
    return PackedVector3Array([_rear_left.global_position, _rear_right.global_position])


func _set_burnout_active(active: bool) -> void:
    if _burnout_active == active:
        return
    _burnout_active = active
    _rear_left.wheel_friction_slip = _rear_grip.x * (burnout_rear_grip_factor if active else 1.0)
    _rear_right.wheel_friction_slip = _rear_grip.y * (burnout_rear_grip_factor if active else 1.0)
    for particles: GPUParticles3D in _smoke:
        particles.emitting = active
    burnout_changed.emit(active)


func _update_smoke_positions() -> void:
    var wheels: Array[VehicleWheel3D] = [_rear_left, _rear_right]
    for index: int in range(_smoke.size()):
        _smoke[index].global_position = wheels[index].global_position + Vector3.DOWN * wheels[index].wheel_radius
        _smoke[index].global_basis = Basis.IDENTITY
