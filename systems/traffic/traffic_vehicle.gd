class_name TrafficVehicle
extends AnimatableBody3D

@export_range(45.0, 75.0) var speed_kph: float = 60.0
var distance: float = 0.0
var _path: Path3D
var _start_distance: float = 0.0


func configure(path: Path3D, start_distance: float, speed: float) -> void:
    _path = path
    _start_distance = start_distance
    speed_kph = clampf(speed, 45.0, 75.0)
    restart()


func restart() -> void:
    distance = _start_distance
    _update_pose()
    reset_physics_interpolation()


func _physics_process(delta: float) -> void:
    if _path == null or _path.curve == null:
        return
    distance = fposmod(distance + speed_kph / 3.6 * delta, _path.curve.get_baked_length())
    _update_pose()


func _update_pose() -> void:
    var length: float = _path.curve.get_baked_length()
    var point: Vector3 = _path.to_global(_path.curve.sample_baked(fposmod(distance, length), true))
    var ahead: Vector3 = _path.to_global(_path.curve.sample_baked(fposmod(distance + 0.25, length), true))
    var direction: Vector3 = ahead - point
    if direction.length_squared() > 0.00001:
        global_transform = Transform3D(Basis.looking_at(direction.normalized(), Vector3.UP), point)
