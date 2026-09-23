class_name RaceManager
extends Node

signal race_state_changed(new_state: RaceState)
signal countdown_changed(text: String)
signal race_started
signal time_updated(seconds: float)
signal checkpoint_updated(completed: int, total: int)
signal race_finished(result: Dictionary)
signal speed_trap_triggered(camera_id: String, speed_kph: float, session_best: float, new_record: bool)

enum RaceState { IDLE, COUNTDOWN, RACING, FINISHED }

var state: RaceState = RaceState.IDLE
var mode: GameSession.GameMode = GameSession.GameMode.SPRINT
var elapsed_time: float = 0.0
var current_checkpoint: int = 0
var total_checkpoints: int = 0
var finish_time: float = 0.0
var countdown: int = 3
var top_speed_kph: float = 0.0
var speed_trap_speeds: Dictionary[String, float] = {}
var total_speed_traps: int = 0

var _countdown_elapsed: float = 0.0
var _camera_ids: Array[String] = []


func configure(selected_mode: GameSession.GameMode, checkpoint_count: int, camera_ids: Array[String]) -> void:
    mode = selected_mode
    total_checkpoints = checkpoint_count
    _camera_ids = camera_ids.duplicate()
    total_speed_traps = _camera_ids.size()


func restart_race() -> void:
    _set_state(RaceState.IDLE)
    elapsed_time = 0.0
    finish_time = 0.0
    current_checkpoint = 0
    top_speed_kph = 0.0
    speed_trap_speeds.clear()
    countdown = 3
    _countdown_elapsed = 0.0
    time_updated.emit(elapsed_time)
    checkpoint_updated.emit(current_checkpoint, total_checkpoints)
    _set_state(RaceState.COUNTDOWN)
    countdown_changed.emit(str(countdown))


func _physics_process(delta: float) -> void:
    if state == RaceState.COUNTDOWN:
        _countdown_elapsed += delta
        while _countdown_elapsed >= 1.0 and state == RaceState.COUNTDOWN:
            _countdown_elapsed -= 1.0
            countdown -= 1
            if countdown > 0:
                countdown_changed.emit(str(countdown))
            else:
                countdown_changed.emit("GO")
                _set_state(RaceState.RACING)
                race_started.emit()
        return

    if state == RaceState.RACING:
        elapsed_time += delta
        time_updated.emit(elapsed_time)


func try_checkpoint(checkpoint_index: int) -> bool:
    if state != RaceState.RACING:
        return false
    if checkpoint_index != current_checkpoint + 1 or checkpoint_index > total_checkpoints:
        return false
    current_checkpoint = checkpoint_index
    checkpoint_updated.emit(current_checkpoint, total_checkpoints)
    return true


func record_speed_trap(camera_id: String, speed_kph: float) -> void:
    if state != RaceState.RACING or not _camera_ids.has(camera_id):
        return
    if not is_finite(speed_kph) or speed_kph < 0.0:
        return

    speed_trap_speeds[camera_id] = maxf(speed_trap_speeds.get(camera_id, 0.0), speed_kph)
    top_speed_kph = maxf(top_speed_kph, speed_kph)
    var new_record: bool = speed_kph > GameSession.best_speed_trap_speed
    GameSession.best_speed_trap_speed = maxf(GameSession.best_speed_trap_speed, speed_kph)
    speed_trap_triggered.emit(camera_id, speed_kph, GameSession.best_speed_trap_speed, new_record)


func try_finish() -> bool:
    if state != RaceState.RACING or current_checkpoint != total_checkpoints:
        return false

    finish_time = elapsed_time
    _set_state(RaceState.FINISHED)
    if mode == GameSession.GameMode.SPRINT:
        if GameSession.best_sprint_time == 0.0 or finish_time < GameSession.best_sprint_time:
            GameSession.best_sprint_time = finish_time
    race_finished.emit({
        "mode": mode,
        "finish_time": finish_time,
        "checkpoints": current_checkpoint,
        "total_checkpoints": total_checkpoints,
        "top_speed_kph": top_speed_kph,
        "cameras": speed_trap_speeds.size(),
        "total_cameras": total_speed_traps,
    })
    return true


func _set_state(new_state: RaceState) -> void:
    state = new_state
    race_state_changed.emit(state)
