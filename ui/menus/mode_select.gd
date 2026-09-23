extends Control


func _ready() -> void:
    %SprintButton.pressed.connect(_select_mode.bind(GameSession.GameMode.SPRINT))
    %SpeedTrapButton.pressed.connect(_select_mode.bind(GameSession.GameMode.SPEED_TRAP))
    %BackButton.pressed.connect(_go_back)
    %SprintButton.grab_focus()


func _select_mode(mode: GameSession.GameMode) -> void:
    GameSession.selected_mode = mode
    get_tree().change_scene_to_file("res://game/game.tscn")


func _go_back() -> void:
    get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _go_back()
