extends Node3D

@onready var _spawn_point: Marker3D = $TestTrack/SpawnPoint
@onready var _player_car: VehicleController = $PlayerCar
@onready var _chase_camera: ChaseCamera = $ChaseCamera


func _ready() -> void:
    _player_car.global_transform = _spawn_point.global_transform
    _player_car.set_respawn_transform(_spawn_point.global_transform)
    _chase_camera.set_target(_player_car)
    print("STATIC//SHIFT: Day 1 driving prototype ready.")
