class_name SpeedTrap
extends Area3D

@export var camera_id: String = "ST_01"

var _race_manager: RaceManager
var _player: VehicleController
var _vehicle_inside: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    $DebugLabel.text = "SPEED CAMERA / " + camera_id


func configure(race_manager: RaceManager, player: VehicleController) -> void:
    _race_manager = race_manager
    _player = player


func reset_trigger() -> void:
    _vehicle_inside = false


func _on_body_entered(body: Node3D) -> void:
    if body != _player or _vehicle_inside or _race_manager == null:
        return
    _vehicle_inside = true
    _race_manager.record_speed_trap(camera_id, _player.get_speed_kph())


func _on_body_exited(body: Node3D) -> void:
    if body == _player:
        _vehicle_inside = false
