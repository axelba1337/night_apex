class_name CarCustomization
extends Resource

## Hue wraps through 0..1. Brightness is HSV value, limited to 0.15..1.
@export_range(0.0, 1.0) var body_hue: float = 0.53:
    set(value):
        body_hue = fposmod(value, 1.0) if is_finite(value) else 0.0
        emit_changed()
@export_range(0.15, 1.0) var body_brightness: float = 0.8:
    set(value):
        body_brightness = clampf(value, 0.15, 1.0) if is_finite(value) else 0.8
        emit_changed()
@export var underglow_enabled: bool = false:
    set(value):
        underglow_enabled = value
        emit_changed()
@export var underglow_color: Color = Color(0.1, 0.8, 1.0):
    set(value):
        underglow_color = value.clamp(Color.BLACK, Color.WHITE)
        emit_changed()
@export_range(0, 4) var rim_index: int = 0:
    set(value):
        rim_index = clampi(value, 0, 4)
        emit_changed()
