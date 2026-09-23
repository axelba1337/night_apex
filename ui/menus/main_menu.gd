extends Control


func _ready() -> void:
    %StartButton.pressed.connect(_open_modes)
    %ModeButton.pressed.connect(_open_modes)
    %SettingsButton.pressed.connect(_show_settings_notice)
    %QuitButton.pressed.connect(func() -> void: get_tree().quit())
    %StartButton.grab_focus()


func _open_modes() -> void:
    get_tree().change_scene_to_file("res://ui/menus/mode_select.tscn")


func _show_settings_notice() -> void:
    %SettingsNotice.text = "Settings are not available in the Day 2 prototype."
