class_name VehicleHandlingProfile
extends Resource

@export var mass: float = 1100.0
@export var engine_force_max: float = 1600.0
@export var reverse_force: float = 900.0
@export var brake_force: float = 35.0
@export var handbrake_force: float = 65.0
@export var max_steer_degrees: float = 28.0
@export var steering_response: float = 5.0
@export var high_speed_steering_factor: float = 0.35
@export var steering_fade_speed_kph: float = 100.0
@export var reset_height: float = 0.25


func apply_to(vehicle: VehicleBody3D) -> void:
    # Only assigned profiles replace the existing controller's tuning.
    for property: StringName in [&"mass", &"engine_force_max", &"reverse_force",
            &"brake_force", &"handbrake_force", &"max_steer_degrees", &"steering_response",
            &"high_speed_steering_factor", &"steering_fade_speed_kph", &"reset_height"]:
        vehicle.set(property, get(property))
