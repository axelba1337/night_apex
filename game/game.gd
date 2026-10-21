extends Node3D

const ROUTES: Array[PackedScene] = [
    preload("res://tracks/route_01/route_01.tscn"),
    preload("res://tracks/route_02/route_02.tscn"),
]
const TEST_TRACK: PackedScene = preload("res://tracks/test_track/test_track.tscn")

@export var player_scene: PackedScene = preload("res://cars/player/player_car.tscn")

var _route: Node3D
var _spawn_point: Marker3D
var _player_car: VehicleController
@onready var _chase_camera: ChaseCamera = $ChaseCamera
@onready var _race_manager: RaceManager = $RaceManager
@onready var _hud: RaceHUD = $HUD
@onready var _pause_menu: RacePauseMenu = $PauseMenu
@onready var _result_screen: RaceResultScreen = $ResultScreen

var _checkpoints: Array[RaceCheckpoint] = []
var _speed_traps: Array[SpeedTrap] = []


func _ready() -> void:
    var route_scene: PackedScene = ROUTES[clampi(GameSession.selected_route, 0, ROUTES.size() - 1)]
    # Keep the original Day 2 straight available for regression tests and debugging.
    if OS.get_cmdline_user_args().has("--test-track"):
        route_scene = TEST_TRACK
    _route = route_scene.instantiate()
    add_child(_route)
    _spawn_point = _route.get_node("SpawnPoint")
    _player_car = player_scene.instantiate()
    _player_car.name = "PlayerCar"
    add_child(_player_car)
    _player_car.global_transform = _spawn_point.global_transform
    _player_car.set_respawn_transform(_spawn_point.global_transform)
    _chase_camera.set_target(_player_car)
    var camera_ids: Array[String] = []
    for child: Node in _route.find_children("*", "", true, false):
        if child is RaceCheckpoint:
            child.configure(_race_manager, _player_car)
            _checkpoints.append(child)
        elif child is SpeedTrap:
            child.configure(_race_manager, _player_car)
            _speed_traps.append(child)
            camera_ids.append(child.camera_id)
        elif child is FinishTrigger:
            child.configure(_race_manager, _player_car)

    _race_manager.configure(GameSession.selected_mode, _checkpoints.size(), camera_ids)
    _race_manager.race_state_changed.connect(_on_race_state_changed)
    _race_manager.race_finished.connect(_result_screen.show_result)
    _hud.configure(_race_manager, _player_car)
    _pause_menu.restart_requested.connect(restart_race)
    _pause_menu.main_menu_requested.connect(_go_to_main_menu)
    _result_screen.retry_requested.connect(restart_race)
    _result_screen.main_menu_requested.connect(_go_to_main_menu)
    restart_race()
    print("NIGHT//APEX: Day 2 race loop ready.")


func restart_race() -> void:
    get_tree().paused = false
    _result_screen.hide_screen()
    _hud.reset_display()
    for checkpoint: RaceCheckpoint in _checkpoints:
        checkpoint.reset_trigger()
    for speed_trap: SpeedTrap in _speed_traps:
        speed_trap.reset_trigger()
    _player_car.reset_to_spawn()
    if _route is RouteFoundation:
        _route.reset_runtime()
    _race_manager.restart_race()


func _on_race_state_changed(new_state: RaceManager.RaceState) -> void:
    _player_car.set_controls_enabled(new_state == RaceManager.RaceState.RACING)
    _pause_menu.set_available(new_state != RaceManager.RaceState.FINISHED)


func _go_to_main_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
