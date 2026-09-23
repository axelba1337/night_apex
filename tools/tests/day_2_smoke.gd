extends SceneTree
## Run with Godot --headless --path . --max-fps 60 --script res://tools/tests/day_2_smoke.gd

const SessionData = preload("res://systems/game_session/game_session.gd")

var _session: Node
var _failures: int = 0
var _checks: int = 0
var _watchdog: float = 0.0
var _countdown_events: Array[String] = []
var _checkpoint_events: Array[int] = []
var _speed_events: Array[Dictionary] = []
var _result: Dictionary = {}


func _initialize() -> void:
    _run.call_deferred()


func _process(delta: float) -> bool:
    _watchdog += delta
    if _watchdog > 180.0:
        push_error("Day 2 smoke test timed out.")
        quit(1)
    return false


func _check(condition: bool, description: String) -> void:
    _checks += 1
    if not condition:
        _failures += 1
    print("PASS: " if condition else "FAIL: ", description)


func _ticks(count: int) -> void:
    for tick in range(count):
        await physics_frame
    await process_frame


func _click(button_name: String) -> void:
    (current_scene.get_node("%" + button_name) as Button).pressed.emit()


func _change_with_button(button_name: String) -> void:
    _click(button_name)
    await scene_changed
    await process_frame


func _escape() -> void:
    var event: InputEventAction = InputEventAction.new()
    event.action = "ui_cancel"
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event = InputEventAction.new()
    event.action = "ui_cancel"
    event.pressed = false
    Input.parse_input_event(event)
    await process_frame


func _observe_race() -> void:
    _countdown_events.assign(["3"])
    _checkpoint_events.clear()
    _speed_events.clear()
    _result.clear()
    var manager: Node = current_scene.get_node("RaceManager")
    manager.countdown_changed.connect(func(text: String) -> void: _countdown_events.append(text))
    manager.checkpoint_updated.connect(func(completed: int, _total: int) -> void: _checkpoint_events.append(completed))
    manager.speed_trap_triggered.connect(func(camera_id: String, speed: float, best: float, record: bool) -> void:
        _speed_events.append({"camera_id": camera_id, "speed": speed, "best": best, "record": record})
    )
    manager.race_finished.connect(func(result: Dictionary) -> void: _result = result)


func _wait_for_go() -> void:
    var manager: Node = current_scene.get_node("RaceManager")
    for tick in range(240):
        if manager.state == manager.RaceState.RACING:
            break
        await _ticks(1)
    _check(manager.state == manager.RaceState.RACING, "Countdown reaches RACING")


func _drive_to_finish() -> void:
    var manager: Node = current_scene.get_node("RaceManager")
    var car: VehicleController = current_scene.get_node("PlayerCar")
    var tested_checkpoint_duplicate: bool = false
    var tested_trap_duplicate: bool = false
    Input.action_press("vehicle_accelerate")
    for tick in range(900):
        await _ticks(1)
        if manager.current_checkpoint == 1 and not tested_checkpoint_duplicate:
            current_scene.get_node("TestTrack/Checkpoint_01")._on_body_entered(car)
            _check(manager.current_checkpoint == 1, "Duplicate checkpoint entry is rejected")
            tested_checkpoint_duplicate = true
        if _speed_events.size() == 1 and not tested_trap_duplicate:
            current_scene.get_node("TestTrack/SpeedTrap_01")._on_body_entered(car)
            _check(_speed_events.size() == 1, "Staying in a speed trap cannot duplicate its event")
            _check(current_scene.get_node("HUD/%SpeedTrapPopup").visible, "Speed-camera event displays HUD popup")
            tested_trap_duplicate = true
        if manager.state == manager.RaceState.FINISHED:
            break
    Input.action_release("vehicle_accelerate")
    _check(manager.state == manager.RaceState.FINISHED, "Actual vehicle drive reaches finish")
    _check(_checkpoint_events == [1, 2, 3], "All three checkpoints were detected in order")
    _check(_speed_events.size() == 2 and manager.speed_trap_speeds.size() == 2, "Both physical cameras detect independently")
    _check(manager.top_speed_kph > 10.0, "Camera score comes from vehicle speed")
    _check(current_scene.get_node("ResultScreen/Root").visible, "Valid finish opens result screen")
    var final_time: float = manager.finish_time
    await _ticks(10)
    _check(manager.elapsed_time == final_time and not manager.try_finish(), "Finish time freezes and finish cannot repeat")
    print("RACE RESULT: ", _result)


func _check_restart(game_id: int) -> void:
    var manager: Node = current_scene.get_node("RaceManager")
    var car: VehicleController = current_scene.get_node("PlayerCar")
    _check(current_scene.get_instance_id() == game_id, "Restart reuses the current game scene")
    _check(not paused and manager.state == manager.RaceState.COUNTDOWN, "Restart unpauses and starts a new countdown")
    _check(manager.elapsed_time == 0.0 and manager.current_checkpoint == 0 and manager.speed_trap_speeds.is_empty() and manager.top_speed_kph == 0.0, "Restart clears timer, checkpoints, and run camera data")
    _check(not current_scene.get_node("ResultScreen/Root").visible and not current_scene.get_node("HUD/%SpeedTrapPopup").visible, "Restart hides results and popup")
    await _ticks(3)
    _check(absf(car.position.z - 45.0) < 0.05 and absf(car.position.x) < 0.05 and car.linear_velocity.length() < 1.0, "Restart resets vehicle position and velocity")


func _run() -> void:
    _session = root.get_node("GameSession")
    _check(root.has_node("GameSession"), "GameSession Autoload exists")
    _check(ProjectSettings.get_setting("application/run/main_scene") == "res://ui/menus/main_menu.tscn", "Main Menu is the project main scene")
    _check(RaceDisplay.format_time(84.386) == "01:24.386", "Timer uses MM:SS.mmm format")
    change_scene_to_file("res://ui/menus/main_menu.tscn")
    await scene_changed
    await process_frame
    _click("SettingsButton")
    _check(not current_scene.get_node("%SettingsNotice").text.is_empty(), "Main Menu Settings responds with a placeholder")
    for resolution in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
        root.size = resolution
        await process_frame
        await process_frame
        var panel: Control = current_scene.get_node("Center/Panel")
        _check(current_scene.get_viewport_rect().encloses(panel.get_global_rect()), "Menu fits resolution " + str(resolution))
    await _change_with_button("ModeButton")
    _check(current_scene.name == "ModeSelect", "GAME MODE opens Mode Select")
    await _change_with_button("BackButton")
    _check(current_scene.name == "MainMenu", "BACK returns to Main Menu")
    await _change_with_button("StartButton")
    await _change_with_button("SprintButton")
    _observe_race()
    var game_id: int = current_scene.get_instance_id()
    var manager: Node = current_scene.get_node("RaceManager")
    var car: VehicleController = current_scene.get_node("PlayerCar")
    _check(manager.mode == SessionData.GameMode.SPRINT and current_scene.get_node("HUD/%ModeLabel").text == "SPRINT RUN", "Sprint selection configures the shared game and HUD")
    _check(not manager.try_finish() and not manager.try_checkpoint(1), "Countdown rejects finish and checkpoint events")
    manager.record_speed_trap("ST_01", 99.0)
    Input.action_press("vehicle_accelerate")
    await _ticks(10)
    Input.action_release("vehicle_accelerate")
    _check(is_zero_approx(car.engine_force) and is_zero_approx(manager.elapsed_time) and manager.speed_trap_speeds.is_empty(), "Countdown blocks acceleration, scoring, and race timer")
    await _escape()
    _check(paused and current_scene.get_node("PauseMenu/Root").visible, "Esc opens Pause Menu during countdown")
    var countdown_before: int = manager.countdown
    await create_timer(0.2, true).timeout
    _check(manager.countdown == countdown_before, "Countdown stays paused")
    current_scene.get_node("PauseMenu/%SettingsButton").pressed.emit()
    _check(not current_scene.get_node("PauseMenu/%SettingsNotice").text.is_empty(), "Pause Settings responds with a placeholder")
    current_scene.get_node("PauseMenu/%ResumeButton").pressed.emit()
    _check(not paused, "Resume unpauses the tree")
    await _wait_for_go()
    _check(_countdown_events == ["3", "2", "1", "GO"], "Countdown displays 3 / 2 / 1 / GO")
    current_scene.get_node("TestTrack/Checkpoint_03")._on_body_entered(car)
    current_scene.get_node("TestTrack/FinishTrigger")._on_body_entered(car)
    _check(manager.current_checkpoint == 0 and manager.state == manager.RaceState.RACING, "Out-of-order checkpoint and early finish are rejected")
    await _drive_to_finish()
    _check(current_scene.get_node("ResultScreen/%PrimaryHeading").text == "FINISH TIME" and current_scene.get_node("ResultScreen/%SecondaryResultLabel").text == "CHECKPOINTS  3 / 3", "Sprint result prioritizes time and checkpoints")
    var session_best: float = _session.best_speed_trap_speed
    _check(_session.best_sprint_time > 0.0 and session_best > 0.0, "Session stores in-memory sprint and speed records")
    current_scene.get_node("ResultScreen/%RetryButton").pressed.emit()
    await _check_restart(game_id)
    _check(_session.best_speed_trap_speed == session_best, "Retry retains session record")
    await _wait_for_go()
    manager.record_speed_trap("ST_01", 20.0)
    await _escape()
    var time_before: float = manager.elapsed_time
    var popup_before: float = current_scene.get_node("HUD/PopupTimer").time_left
    await create_timer(0.2, true).timeout
    _check(manager.elapsed_time == time_before and is_equal_approx(current_scene.get_node("HUD/PopupTimer").time_left, popup_before), "Pause freezes race timer and popup timeout")
    await _escape()
    _check(not paused, "Esc resumes paused gameplay")
    await _ticks(160)
    _check(not current_scene.get_node("HUD/%SpeedTrapPopup").visible, "Speed popup expires after its timeout")
    await _escape()
    current_scene.get_node("PauseMenu/%RestartButton").pressed.emit()
    await _check_restart(game_id)
    await _escape()
    current_scene.get_node("PauseMenu/%MainMenuButton").pressed.emit()
    await scene_changed
    _check(not paused and current_scene.name == "MainMenu", "Pause Main Menu unpauses and navigates")
    await _change_with_button("StartButton")
    await _change_with_button("SpeedTrapButton")
    _observe_race()
    manager = current_scene.get_node("RaceManager")
    _check(manager.mode == SessionData.GameMode.SPEED_TRAP and current_scene.get_node("HUD/%ModeLabel").text == "SPEED TRAP RUN", "Speed Trap mode uses the same game with the correct HUD")
    await _wait_for_go()
    await _drive_to_finish()
    _check(current_scene.get_node("ResultScreen/%PrimaryHeading").text == "TOP SPEED" and current_scene.get_node("ResultScreen/%SecondaryResultLabel").text == "CAMERAS  2 / 2", "Speed Trap result prioritizes highest camera speed")
    _check(current_scene.get_node("ResultScreen/%PrimaryResultLabel").text == "%d KM/H" % roundi(manager.top_speed_kph), "Result displays the recorded top speed")
    current_scene.get_node("ResultScreen/%MainMenuButton").pressed.emit()
    await scene_changed
    _check(not paused and current_scene.name == "MainMenu", "Result Main Menu returns to an unpaused menu")
    print("DAY 2 SMOKE: ", _checks, " checks, ", _failures, " failures")
    quit(0 if _failures == 0 else 1)
