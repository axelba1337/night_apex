extends SceneTree

var _checks: int = 0
var _failures: int = 0
var _elapsed: float = 0.0


func _initialize() -> void:
    _run.call_deferred()


func _process(delta: float) -> bool:
    _elapsed += delta
    if _elapsed > 180.0:
        push_error("Day 3 / 4A smoke test timed out.")
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


func _release_inputs() -> void:
    for action: String in ["vehicle_accelerate", "vehicle_brake", "vehicle_left", "vehicle_right", "vehicle_handbrake"]:
        Input.action_release(action)


func _check_routes() -> void:
    var session: Node = root.get_node("GameSession")
    _check(session.selected_route == session.RouteId.ROUTE_01, "Route 01 is the session default")
    for route_id: int in [0, 1]:
        session.selected_route = route_id
        change_scene_to_file("res://game/game.tscn")
        await scene_changed
        var route: Node3D = current_scene.get_node("Route01" if route_id == 0 else "Route02")
        var manager: Node = current_scene.get_node("RaceManager")
        _check(manager.total_checkpoints == 4 and manager.total_speed_traps == (2 if route_id == 0 else 1), "Selected route supplies nested checkpoints and cameras")
        _check(route.using_debug_geometry, "Missing GLB uses the existing test straight, not a fabricated route")
        _check(current_scene.get_node("PlayerCar").global_position.is_equal_approx(route.get_node("SpawnPoint").global_position), "Player starts at selected route spawn")
        _check(route.get_node("WorldEnvironment").environment.sky.sky_material is PanoramaSkyMaterial, "Route has its own panorama-ready environment")
        if route_id == 0:
            var traffic: Node = route.get_node("TrafficRoot")
            _check(traffic.vehicles.size() == 6, "Route 01 has six staggered traffic vehicles")
            var vehicle: Node3D = traffic.vehicles[0]
            var previous: Vector3 = vehicle.global_position
            await _ticks(30)
            _check(vehicle.global_position.distance_to(previous) > 1.0, "Traffic advances along its lane")
            var curve: Curve3D = route.get_node("TrafficPaths/TrafficLane_A").curve
            vehicle.distance = curve.get_baked_length() - 0.01
            await _ticks(2)
            _check(vehicle.distance < 2.0, "Traffic wraps its closed lane")
            var ahead: Vector3 = curve.sample_baked(vehicle.distance + 0.25, true) - curve.sample_baked(vehicle.distance, true)
            _check((-vehicle.global_basis.z).dot(ahead.normalized()) > 0.9, "Traffic faces travel direction")
            _check(vehicle.get_node("HeadlightLeft").spot_range < 35.0 and not vehicle.get_node("HeadlightLeft").shadow_enabled, "Traffic headlights are warm, short-range, and shadow-free")
            traffic.set_enabled(false)
            await _ticks(2)
            _check(traffic.vehicles.is_empty() and traffic.get_child_count() == 0, "Disabling traffic removes all vehicles and colliders")
            traffic.set_enabled(true)
            _check(traffic.vehicles.size() == 6, "Traffic can be re-enabled")
            traffic.set_enabled(false)
        else:
            _check(not route.has_node("TrafficRoot") and route.find_children("*", "Path3D", true, false).is_empty(), "Route 02 has no moving traffic or traffic paths")
        await _ticks(190)
        Input.action_press("vehicle_accelerate")
        for tick in range(900):
            await _ticks(1)
            if manager.state == manager.RaceState.FINISHED:
                break
        _release_inputs()
        _check(manager.state == manager.RaceState.FINISHED and manager.current_checkpoint == 4, "Selected wrapper completes the shared race loop")
        _check(manager.speed_trap_speeds.size() == manager.total_speed_traps, "Selected wrapper records all its cameras")
        current_scene.restart_race()
        await _ticks(3)
        _check(manager.current_checkpoint == 0 and manager.elapsed_time == 0.0, "Wrapper restart clears race and trigger state")
    unload_current_scene()
    await process_frame


func _check_car(path: String, expected_mass: float) -> void:
    var car: VehicleController = load(path).instantiate()
    car.position = Vector3(0, 1, 45)
    root.add_child(car)
    _check(car.mass == expected_mass, "Assigned handling profile applies to " + car.name)
    var appearance: Node = car.get_node("Appearance")
    var settings: CarCustomization = appearance.customization
    var paint: StandardMaterial3D = car.get_node("BodyVisual").material_override
    var paint_id: int = paint.get_instance_id()
    settings.body_hue = 0.25
    settings.body_brightness = 0.6
    _check(paint.albedo_color.is_equal_approx(Color.from_hsv(0.25, 0.75, 0.6)), "Hue and brightness update the body-paint target")
    settings.body_brightness = -1.0
    _check(settings.body_brightness == 0.15, "Brightness clamps to safe values")
    settings.underglow_enabled = true
    settings.underglow_color = Color(1, 0.2, 0.1)
    _check(car.get_node("UnderglowRoot").visible and car.get_node("UnderglowRoot/UnderglowLight").light_color == settings.underglow_color, "Underglow toggles and changes emitted light color")
    _check(car.get_node("UnderglowRoot/UnderglowMesh").material_override.emission == settings.underglow_color, "Underglow emissive material uses the same color")
    settings.underglow_enabled = false
    _check(not car.get_node("UnderglowRoot").visible, "Underglow disables")
    var wheel_names: Array[String] = ["WheelFrontLeft", "WheelFrontRight", "WheelRearLeft", "WheelRearRight"]
    var wheel_ids: Array[int] = []
    for wheel_name: String in wheel_names:
        wheel_ids.append(car.get_node(wheel_name).get_instance_id())
    for rim: int in range(5):
        settings.rim_index = rim
        var valid: bool = true
        for index: int in range(4):
            var wheel: VehicleWheel3D = car.get_node(wheel_names[index])
            valid = valid and wheel.get_node("RimMount").get_child_count() == 1 and wheel.get_instance_id() == wheel_ids[index]
            valid = valid and is_equal_approx(wheel.wheel_radius, 0.34) and is_equal_approx(wheel.wheel_rest_length, 0.25)
        _check(valid, "Rim %d updates all visuals without changing wheel physics" % rim)
    settings.rim_index = 99
    _check(settings.rim_index == 4, "Oversized rim index clamps to 4")
    settings.rim_index = -2
    _check(settings.rim_index == 0, "Negative rim index clamps to 0")
    _check(car.get_node("BodyVisual").material_override.get_instance_id() == paint_id, "Repeated customization reuses one body material")
    _check(car.get_node("Headlights/HeadlightLeft").spot_range == 45.0, "Player headlights load with 45-meter range")
    await _ticks(120)
    var rear: VehicleWheel3D = car.get_node("WheelRearLeft")
    var original_grip: float = rear.wheel_friction_slip
    var start: Vector3 = car.global_position
    Input.action_press("vehicle_accelerate")
    Input.action_press("vehicle_handbrake")
    await _ticks(120)
    _check(car.is_burnout_active() and car.engine_force > 0.0, "W + Space activates powered burnout")
    _check(rear.wheel_friction_slip < original_grip, "Burnout temporarily lowers rear grip")
    _check(car.get_node("WheelRearLeft/TireSmokeLeft").emitting and car.get_node("WheelRearRight/TireSmokeRight").emitting, "Both rear tires emit smoke")
    var creep: float = Vector2(car.global_position.x - start.x, car.global_position.z - start.z).length()
    print("BURNOUT: ", car.name, " creep=", creep, " m speed=", car.get_speed_kph(), " km/h")
    _check(creep < 2.0 and car.get_speed_kph() < 5.0, "Burnout holds the car approximately in place")
    Input.action_release("vehicle_handbrake")
    await _ticks(2)
    _check(not car.is_burnout_active() and rear.wheel_friction_slip == original_grip, "Releasing Space restores original grip")
    _check(not car.get_node("WheelRearLeft/TireSmokeLeft").emitting, "Smoke stops when burnout ends")
    Input.action_press("vehicle_handbrake")
    await _ticks(2)
    car.set_controls_enabled(false)
    _check(not car.is_burnout_active() and rear.wheel_friction_slip == original_grip, "Countdown/result control gating also restores grip")
    car.set_controls_enabled(true)
    car.linear_velocity = Vector3(0, 0, -10)
    await _ticks(2)
    _check(not car.is_burnout_active() and car.engine_force == 0.0 and rear.brake == car.handbrake_force, "High-speed Space preserves the normal handbrake")
    _release_inputs()
    car.queue_free()
    await _ticks(2)


func _check_props_and_collision() -> void:
    for folder: String in ["static", "physics", "breakable"]:
        var directory: DirAccess = DirAccess.open("res://props/" + folder)
        for file: String in directory.get_files():
            if file.ends_with(".tscn"):
                var scene: PackedScene = load("res://props/" + folder + "/" + file)
                var prop: Node = scene.instantiate()
                _check(prop is PhysicsBody3D and prop.has_node("CollisionShape3D"), "Prop loads with collision: " + file)
                prop.free()
    for prop_path: String in ["res://props/physics/oil_barrel.tscn", "res://props/breakable/wooden_crate.tscn", "res://systems/traffic/traffic_vehicle.tscn"]:
        var prop: Node3D = load(prop_path).instantiate()
        prop.position = Vector3(0, 0.6, 15 if prop is BreakableProp else 35)
        root.add_child(prop)
        var car: VehicleController = load("res://cars/player/player_car.tscn").instantiate()
        car.position = Vector3(0, 1, 45)
        root.add_child(car)
        _check(car.mass == 1100.0 and car.engine_force_max == 1600.0 and car.max_steer_degrees == 28.0, "Unassigned profile preserves original handling")
        await _ticks(90)
        if prop is BreakableProp:
            _check(not prop.is_broken, "Breakable crate survives settling and resting contacts")
        Input.action_press("vehicle_accelerate")
        await _ticks(360 if prop is BreakableProp else 210)
        _release_inputs()
        if prop is BreakableProp:
            _check(prop.is_broken and not prop.get_node("IntactVisual").visible, "Actual car impact breaks the crate above its impulse threshold")
            var repeated: Array[int] = []
            prop.broken.connect(func() -> void: repeated.append(1))
            prop.break_apart()
            _check(repeated.is_empty(), "Broken prop cannot repeatedly emit broken")
            prop.reset_prop(Transform3D(Basis.IDENTITY, Vector3(4, 0.4, 30)))
            await _ticks(2)
            _check(not prop.is_broken and prop.get_node("IntactVisual").visible, "Breakable prop resets intact for retry")
        elif prop is RigidBody3D:
            _check(prop.position.distance_to(Vector3(0, 0.45, 35)) > 1.0, "Actual car impact pushes the barrel")
        else:
            _check(car.position.z > 37.0 and car.position.z < 43.0, "Player collides with traffic vehicle's physical body")
        prop.queue_free()
        car.queue_free()
        await _ticks(3)


func _run() -> void:
    await _check_routes()
    var stage: Node3D = load("res://tracks/test_track/test_track.tscn").instantiate()
    root.add_child(stage)
    _check(stage.has_node("Ground") and stage.has_node("Ramp"), "Original TestTrack remains loadable")
    await _check_car("res://cars/mazda_astina_323f/mazda_astina_323f.tscn", 1050.0)
    await _check_car("res://cars/mitsubishi_galant/mitsubishi_galant.tscn", 1280.0)
    await _check_props_and_collision()
    stage.queue_free()
    await process_frame
    print("DAY 3 / 4A SMOKE: ", _checks, " checks, ", _failures, " failures")
    quit(0 if _failures == 0 else 1)
