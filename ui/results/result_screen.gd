class_name RaceResultScreen
extends CanvasLayer

signal retry_requested
signal main_menu_requested


func _ready() -> void:
    hide_screen()
    %RetryButton.pressed.connect(func() -> void: retry_requested.emit())
    %MainMenuButton.pressed.connect(func() -> void: main_menu_requested.emit())


func show_result(result: Dictionary) -> void:
    %ModeLabel.text = RaceDisplay.mode_name(result["mode"])
    if result["mode"] == GameSession.GameMode.SPRINT:
        %PrimaryHeading.text = "FINISH TIME"
        %PrimaryResultLabel.text = RaceDisplay.format_time(result["finish_time"])
        %SecondaryResultLabel.text = "CHECKPOINTS  %d / %d" % [result["checkpoints"], result["total_checkpoints"]]
    else:
        %PrimaryHeading.text = "TOP SPEED"
        %PrimaryResultLabel.text = "%d KM/H" % roundi(result["top_speed_kph"])
        %SecondaryResultLabel.text = "CAMERAS  %d / %d" % [result["cameras"], result["total_cameras"]]
    $Root.show()
    %RetryButton.grab_focus()


func hide_screen() -> void:
    $Root.hide()
