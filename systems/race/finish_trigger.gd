class_name FinishTrigger
extends Area3D

var _race_manager: RaceManager
var _player: VehicleController


func _ready() -> void:
    body_entered.connect(_on_body_entered)


func configure(race_manager: RaceManager, player: VehicleController) -> void:
    _race_manager = race_manager
    _player = player


func _on_body_entered(body: Node3D) -> void:
    if body == _player and _race_manager != null:
        _race_manager.try_finish()
