class_name VehicleAppearance
extends Node3D

const RIMS: Array[PackedScene] = [
    preload("res://cars/shared/rims/rim_00_stock.tscn"),
    preload("res://cars/shared/rims/rim_01_bbs_rs.tscn"),
    preload("res://cars/shared/rims/rim_02_ssr_mk2.tscn"),
    preload("res://cars/shared/rims/rim_03_enkei_rpf1.tscn"),
    preload("res://cars/shared/rims/rim_04_rays_volk_te37.tscn"),
]

@export var customization: CarCustomization
@export var body_paint_target: NodePath = NodePath("../BodyVisual")

var _body_material: StandardMaterial3D
var _glow_material: StandardMaterial3D
var _rim_mounts: Array[Node3D] = []
var _applied_rim: int = -1
var _vehicle: VehicleController


func _ready() -> void:
    _vehicle = get_parent() as VehicleController
    # One material per target per car, reused for every subsequent color change.
    var body: MeshInstance3D = get_node(body_paint_target)
    var existing: StandardMaterial3D = body.get_active_material(0) as StandardMaterial3D
    _body_material = existing.duplicate() if existing != null else StandardMaterial3D.new()
    _body_material.roughness = 0.5
    body.material_override = _body_material
    var glow: MeshInstance3D = get_node("../UnderglowRoot/UnderglowMesh")
    _glow_material = glow.get_active_material(0).duplicate() as StandardMaterial3D
    glow.material_override = _glow_material
    for wheel_name: String in ["WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"]:
        _rim_mounts.append(_vehicle.get_node(wheel_name + "/RimMount"))
    customization = customization.duplicate() if customization != null else CarCustomization.new()
    customization.changed.connect(apply_customization)
    apply_customization()


func apply_customization() -> void:
    _body_material.albedo_color = Color.from_hsv(customization.body_hue, 0.75, customization.body_brightness)
    get_node("../UnderglowRoot").visible = customization.underglow_enabled
    _glow_material.albedo_color = customization.underglow_color
    _glow_material.emission = customization.underglow_color
    get_node("../UnderglowRoot/UnderglowLight").light_color = customization.underglow_color
    if _applied_rim == customization.rim_index:
        return
    _applied_rim = customization.rim_index
    for mount: Node3D in _rim_mounts:
        for old_rim: Node in mount.get_children():
            mount.remove_child(old_rim)
            old_rim.queue_free()
        mount.add_child(RIMS[_applied_rim].instantiate())


func _process(delta: float) -> void:
    # Spin only rim visuals. Never rotate VehicleWheel3D to fake a burnout.
    if _vehicle.is_burnout_active():
        _rim_mounts[2].rotate_x(-28.0 * delta)
        _rim_mounts[3].rotate_x(-28.0 * delta)
