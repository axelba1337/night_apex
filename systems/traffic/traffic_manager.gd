class_name TrafficManager
extends Node3D

const VEHICLE: PackedScene = preload("res://systems/traffic/traffic_vehicle.tscn")
const SPEEDS: Array[float] = [48.0, 58.0, 70.0]

@export var enabled: bool = true
@export_range(5, 8) var car_count: int = 6
@export var paths_root: NodePath = NodePath("../TrafficPaths")

var vehicles: Array[TrafficVehicle] = []


func _ready() -> void:
    set_enabled(enabled)


func set_enabled(value: bool) -> void:
    enabled = value
    for vehicle: TrafficVehicle in vehicles:
        vehicle.set_physics_process(false)
        vehicle.collision_layer = 0
        vehicle.hide()
        vehicle.queue_free()
    vehicles.clear()
    if not enabled:
        return
    var lanes: Array[Path3D] = []
    for node: Node in get_node(paths_root).get_children():
        if node is Path3D and node.curve != null and node.curve.get_baked_length() > 1.0:
            lanes.append(node)
    if lanes.is_empty():
        return
    for index: int in range(car_count):
        var lane: Path3D = lanes[index % lanes.size()]
        var count_on_lane: int = ceili(float(car_count - index % lanes.size()) / lanes.size())
        var slot: int = floori(float(index) / lanes.size())
        var offset: float = lane.curve.get_baked_length() * (float(slot) + 0.35) / count_on_lane
        var vehicle: TrafficVehicle = VEHICLE.instantiate()
        add_child(vehicle)
        # One speed per lane keeps the staggered spacing stable without overtaking AI.
        vehicle.configure(lane, offset, SPEEDS[(index % lanes.size()) % SPEEDS.size()])
        vehicles.append(vehicle)


func restart_traffic() -> void:
    for vehicle: TrafficVehicle in vehicles:
        vehicle.restart()
