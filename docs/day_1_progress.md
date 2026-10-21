# NIGHT//APEX Day 1 Progress

The project is now named NIGHT//APEX. The Day 1 output examples and checklist below
describe the historical build validated on 2026-09-22. They retain its original console
prefix as a record. Current scripts use the NIGHT//APEX prefix.

Scope: Day 1.3 through 1.8 only. Godot 4.7.2 Standard, GDScript, Jolt Physics, Forward+.

## Progress

| Task | Implementation | Manual Verification |
| --- | --- | --- |
| Day 1.3 Inputs | COMPLETE | PENDING |
| Day 1.4 Test Track | COMPLETE | PENDING |
| Day 1.5 Fundamentals | COMPLETE | PENDING |
| Day 1.6 Vehicle | COMPLETE | PENDING |
| Day 1.7 Chase Camera | COMPLETE | PENDING |
| Day 1.8 Game Scene | COMPLETE | PENDING |

## Fundamental nodes

| Node | Purpose |
| --- | --- |
| MeshInstance3D | Visible geometry. It does not provide collision by itself. |
| StaticBody3D | Non-moving physics body, used for the ground, ramp, and barriers. |
| CollisionShape3D | Physical collision boundary belonging to a physics body. |
| VehicleBody3D | Physics vehicle chassis. Receives engine force, brake, and steering. |
| VehicleWheel3D | Raycast-style vehicle wheel and suspension. Its ray detects ground contact. |
| Marker3D | Transform marker used for spawning or a camera target. |
| Node3D | 3D transform and container for child nodes. |

## Scene structure and Inspector starting values

The main Game node instances TestTrack, PlayerCar, and ChaseCamera. Its script only
places the car, stores its spawn transform, assigns the camera target, and prints readiness.

TestTrack contains WorldEnvironment, DirectionalLight3D, Ground, Ramp, BarrierLeft,
BarrierRight, and SpawnPoint. Each static body has MeshInstance3D and CollisionShape3D
children with matching dimensions and transforms. Materials are StandardMaterial3D.

| Object | Size in meters | Position | Rotation in degrees |
| --- | --- | --- | --- |
| Ground | 40 x 0.2 x 120 | (0, -0.1, 0) | (0, 0, 0) |
| Ramp | 4.5 x 0.25 x 8 | (-2.5, 0.5, -10) | (9, 0, 0) |
| BarrierLeft | 0.5 x 1 x 120 | (-6.25, 0.5, 0) | (0, 0, 0) |
| BarrierRight | 0.5 x 1 x 120 | (6.25, 0.5, 0) | (0, 0, 0) |
| SpawnPoint | Marker | (0, 1, 45) | (0, 0, 0) |

The ground top is Y = 0. The inner barrier faces leave a 12-meter road. Forward is -Z.
The ramp rises in that direction. Its entry edge sits just below the ground to avoid a step.

PlayerCar contains ChassisCollision, CarBodyMesh, four VehicleWheel3D nodes with
WheelMesh children, and CameraTarget. Body and collision are both 1.8 x 0.85 x 4.2 m
and sit at local Y = 0.4. Mass is 1100 kg. Custom center of mass is (0, -0.1, 0).
Continuous collision detection is enabled on the chassis.

Wheel mounts use X = +/-0.95 and Y = 0. Front Z = -1.4, rear Z = +1.4.
All four wheels rotate 180 degrees around Y to make positive engine force drive -Z.
Front wheels steer. Rear wheels provide traction. Wheel meshes are cylinders rotated
90 degrees around Z. Their suspension rays supply wheel contact, not extra rigid colliders.

| Wheel property | Starting value |
| --- | --- |
| Radius | 0.34 m |
| Rest length | 0.25 m |
| Suspension travel | 0.2 m |
| Suspension stiffness | 40.0 |
| Suspension max force | 8000.0 |
| Compression damping | 2.3 |
| Relaxation damping | 3.5 |
| Friction slip | 2.5 |
| Roll influence | 0.1 |

ChaseCamera contains SpringArm3D with a current Camera3D child. It follows the
CameraTarget marker at local Y = 0.65. Camera height is 1.8 m above that marker,
spring length is 6.5 m, and pitch is 12 degrees downward. Position response is 8.0,
heading response is 5.0. Only yaw is followed. The spring arm excludes the car's collider.
Initial placement happens at spawn. Later movement, including after reset, is smoothed.

## Vehicle tuning

These exports live on PlayerCar's vehicle_controller.gd script.

| Parameter | Starting value | Purpose |
| --- | --- | --- |
| engine_force_max | 1600.0 | Positive force per driven rear wheel. |
| reverse_force | 900.0 | Magnitude of negative reverse force. |
| brake_force | 35.0 | Normal braking applied to all wheels. |
| handbrake_force | 65.0 | Rear-wheel braking while Space is held. |
| max_steer_degrees | 28.0 | Low-speed maximum steering angle. |
| steering_response | 5.0 | Exponential steering smoothing response. |
| high_speed_steering_factor | 0.35 | Remaining steering authority at the fade speed. |
| steering_fade_speed_kph | 100.0 | Speed where steering reaches its minimum authority. |
| reverse_speed_threshold | 0.75 | Forward m/s below which S engages reverse. |
| reset_height | 0.25 | Additional world Y offset above the stored spawn on reset. |

S takes priority over W. Space cuts engine force and brakes the rear wheels without
changing grip. R clears velocity and restores the stored spawn through the physics state.
The speed helper returns linear velocity magnitude multiplied by 3.6.

## Automated validation

Validated on 2026-09-22 with Godot 4.7.2.stable.official.ed1daf0bf.
Run these PowerShell commands from the repository root:

```powershell
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 240 --fixed-fps 60
```

Both commands exited with code 0. No Godot errors or warnings were printed.
The main-scene run printed:

```text
STATIC//SHIFT: Day 1 driving prototype ready.
```

A temporary driving smoke script was also run against the actual Jolt simulation.
It was kept in the ignored Godot cache and removed after validation. No test framework
or permanent test files were added.

| Automated check | Result |
| --- | --- |
| All six actions and their exact physical key bindings | PASS |
| Car starts at the spawn transform | PASS |
| Car settles on all four wheels | PASS, chassis origin Y approximately 0.493 m |
| Positive acceleration follows -Z | PASS, approximately 26.9 km/h after 3 seconds |
| S brakes, then reverses | PASS |
| Left/right steering direction and gradual response | PASS |
| Speed-sensitive steering | PASS, approximately 27.8 degrees at rest and 9.9 at 100 km/h |
| Handbrake cuts power, brakes rear wheels, and releases | PASS |
| Reset restores spawn, clears velocities, and adds safety height | PASS |
| Camera smooths reset movement and settles at its target | PASS |
| Spring arm excludes the car | PASS |
| Car contacts, climbs, and clears ramp | PASS, chassis origin reached approximately 1.73 m |
| Both barriers stop the car | PASS |

The steering comparison isolated response with a frozen chassis and assigned velocity.
It does not claim manual high-speed handling verification.

The first accelerated smoke run passed but printed one Jolt job-system capacity warning.
Repeating the full smoke run at normal timing with `--max-fps 60` exited with code 0,
zero failed checks, and no errors or warnings. The warning did not prevent either run.

Git whitespace checks passed. SHA-256 checks confirmed that the Blender scene, its local
backup, and the Blender connection script were unchanged.

Manual Verification remains PENDING. Headless tests do not verify rendered appearance,
keyboard interaction in the game window, or subjective handling and camera feel.

## Manual test checklist

Run these in order. Release controls between checks. Use R when you need a fresh start.
For the ramp, line up on the left side at X approximately -2.5 and drive toward -Z.

- [ ] F5 starts game/game.tscn successfully
- [ ] PlayerCar appears on SpawnPoint
- [ ] Car does not initially intersect or fall through Ground
- [ ] W / Up Arrow accelerates
- [ ] S / Down Arrow brakes while moving forward
- [ ] S / Down Arrow reverses when stopped
- [ ] A / Left Arrow steers left
- [ ] D / Right Arrow steers right
- [ ] Steering becomes less aggressive at high speed
- [ ] Space activates the simple handbrake behavior
- [ ] R resets the vehicle to SpawnPoint
- [ ] Car collides with both barriers
- [ ] Car can interact with / drive onto the ramp
- [ ] ChaseCamera follows the car
- [ ] Camera movement is smoothed rather than snapping instantly
- [ ] Godot Debugger shows zero script/parser errors
- [ ] Output contains:

```text
STATIC//SHIFT: Day 1 driving prototype ready.
```

## Day 1 limitations

- Handling and camera feel still need manual playtesting and tuning.
- The test straight has open ends. R recovers the car after driving off or rolling over.
- The box ramp has a raised exit edge. It is a suspension/jump test, not a finished road.
- The primitive car and raycast wheels are prototype visuals and physics.
- The handbrake is rear braking only. It does not implement a tuned drift system.

## Repository audit

- Initial branch: main. Working tree was clean and up to date with origin/main.
- Removed the stray `s` ignore rule and restored Godot, Blender backup, build,
  captured video, OS junk, and temporary-file exclusions.
- Removed 15 completely empty top-level directories ending in `mkdir`. No files were deleted.
- The configured VS Code path does not exist. The installed Godot 4.7.2 executable is
  `D:/Godot Engine/Godot_v4.7.2-stable_win64.exe`. VS Code settings were left unchanged.
- The real Blender scene, local Blender backup, and Blender connection script are preserved.
- The Blender backup is already tracked. Ignore rules do not untrack it. After reviewing,
  run the following yourself to stop tracking it while keeping the local file:

```powershell
git rm --cached blender/route_01/route_01.blend1
```

No commits, pushes, or pull requests were created.

## Engine references

- [VehicleBody3D](https://docs.godotengine.org/en/stable/classes/class_vehiclebody3d.html)
- [VehicleWheel3D](https://docs.godotengine.org/en/stable/classes/class_vehiclewheel3d.html)
- [SpringArm3D](https://docs.godotengine.org/en/stable/classes/class_springarm3d.html)
