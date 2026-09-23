class_name RaceCheckpoint
extends Area3D

@export var checkpoint_index: int = 1

var _race_manager: RaceManager
var _player: VehicleController
var _activated: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    $DebugLabel.text = "CHECKPOINT %02d" % checkpoint_index


func configure(race_manager: RaceManager, player: VehicleController) -> void:
    _race_manager = race_manager
    _player = player


func reset_trigger() -> void:
    _activated = false


func _on_body_entered(body: Node3D) -> void:
    if body != _player or _activated or _race_manager == null:
        return
    _activated = _race_manager.try_checkpoint(checkpoint_index)
