class_name RaceHUD
extends CanvasLayer

var _player: VehicleController


func _ready() -> void:
    $PopupTimer.timeout.connect(func() -> void: %SpeedTrapPopup.hide())
    $CountdownTimer.timeout.connect(func() -> void: %CountdownLabel.hide())
    reset_display()


func configure(race_manager: RaceManager, player: VehicleController) -> void:
    _player = player
    %ModeLabel.text = RaceDisplay.mode_name(race_manager.mode)
    race_manager.time_updated.connect(_on_time_updated)
    race_manager.checkpoint_updated.connect(_on_checkpoint_updated)
    race_manager.countdown_changed.connect(_on_countdown_changed)
    race_manager.speed_trap_triggered.connect(_on_speed_trap_triggered)
    race_manager.race_finished.connect(_on_race_finished)


func _process(_delta: float) -> void:
    if is_instance_valid(_player):
        %SpeedLabel.text = "%d KM/H" % roundi(_player.get_speed_kph())


func reset_display() -> void:
    $PopupTimer.stop()
    $CountdownTimer.stop()
    %SpeedTrapPopup.hide()
    %CountdownLabel.hide()
    %SpeedLabel.text = "0 KM/H"
    %TimerLabel.text = "00:00.000"


func _on_time_updated(seconds: float) -> void:
    %TimerLabel.text = RaceDisplay.format_time(seconds)


func _on_checkpoint_updated(completed: int, total: int) -> void:
    %CheckpointLabel.text = "CHECKPOINT %d / %d" % [completed, total]


func _on_countdown_changed(text: String) -> void:
    $CountdownTimer.stop()
    %CountdownLabel.text = text
    %CountdownLabel.show()
    if text == "GO":
        $CountdownTimer.start()


func _on_speed_trap_triggered(camera_id: String, speed_kph: float, session_best: float, new_record: bool) -> void:
    %CameraLabel.text = "SPEED CAMERA / " + camera_id
    %TrapSpeedLabel.text = "%d KM/H" % roundi(speed_kph)
    %RecordLabel.text = "NEW RECORD" if new_record else "SESSION BEST %d KM/H" % roundi(session_best)
    %SpeedTrapPopup.show()
    $PopupTimer.start()


func _on_race_finished(_result: Dictionary) -> void:
    $PopupTimer.stop()
    $CountdownTimer.stop()
    %SpeedTrapPopup.hide()
    %CountdownLabel.hide()
