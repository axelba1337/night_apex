class_name RaceDisplay
extends RefCounted


static func format_time(seconds: float) -> String:
    var milliseconds: int = maxi(0, int(seconds * 1000.0))
    var minutes: int = int(milliseconds / 60000.0)
    var whole_seconds: int = int(milliseconds / 1000.0) % 60
    return "%02d:%02d.%03d" % [minutes, whole_seconds, milliseconds % 1000]


static func mode_name(mode: GameSession.GameMode) -> String:
    return "SPRINT RUN" if mode == GameSession.GameMode.SPRINT else "SPEED TRAP RUN"
