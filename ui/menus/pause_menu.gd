class_name RacePauseMenu
extends CanvasLayer

signal restart_requested
signal main_menu_requested

var _available: bool = true


func _ready() -> void:
    $Root.hide()
    %ResumeButton.pressed.connect(resume)
    %RestartButton.pressed.connect(_restart)
    %SettingsButton.pressed.connect(_show_settings_notice)
    %MainMenuButton.pressed.connect(_main_menu)


func _unhandled_input(event: InputEvent) -> void:
    if _available and event.is_action_pressed("ui_cancel") and not event.is_echo():
        get_viewport().set_input_as_handled()
        if $Root.visible:
            resume()
        else:
            open()


func open() -> void:
    if not _available:
        return
    %SettingsNotice.text = ""
    $Root.show()
    get_tree().paused = true
    %ResumeButton.grab_focus()


func resume() -> void:
    $Root.hide()
    get_tree().paused = false


func set_available(available: bool) -> void:
    _available = available
    if not available and $Root.visible:
        resume()


func _restart() -> void:
    resume()
    restart_requested.emit()


func _main_menu() -> void:
    resume()
    main_menu_requested.emit()


func _show_settings_notice() -> void:
    %SettingsNotice.text = "Settings are not available in the Day 2 prototype."
