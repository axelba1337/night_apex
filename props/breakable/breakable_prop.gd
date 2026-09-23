class_name BreakableProp
extends RigidBody3D

signal broken

## Minimum summed contact impulse per physics step in N.s.
@export var break_impulse: float = 90.0
var is_broken: bool = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if is_broken:
        return
    var impact: float = 0.0
    for index: int in range(state.get_contact_count()):
        impact += state.get_contact_impulse(index).length()
    if impact >= break_impulse:
        break_apart()


func break_apart() -> void:
    if is_broken:
        return
    is_broken = true
    $IntactVisual.hide()
    $CollisionShape3D.set_deferred("disabled", true)
    set_deferred("freeze", true)
    broken.emit()


func reset_prop(pose: Transform3D) -> void:
    is_broken = false
    global_transform = pose
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    $IntactVisual.show()
    $CollisionShape3D.set_deferred("disabled", false)
    set_deferred("freeze", false)
