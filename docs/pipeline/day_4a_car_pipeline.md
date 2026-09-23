# Day 4A starter-car pipeline

The two car scenes are independent primitive scaffolds using the existing vehicle controller.
They are not finished car models or accurate reproductions of the references.

## References and files

- [Mazda Astina / 323F reference](https://sketchfab.com/3d-models/1990-mazda-astina-323f-e7f80ea3e2b94c9884a94b8313813cb5)
- [Mitsubishi Galant reference](https://sketchfab.com/3d-models/mitsubishi-galant-02ef2354c82d4c7dad83a262ec5bcc6b)

Both reference pages returned HTTP 403 during implementation. Their geometry was not
downloaded, extracted, copied, converted, or redistributed. No Galant year/generation is
assumed. View the references manually for silhouette, roofline, wheelbase, glass, front,
and rear proportions. Create your own low-poly geometry.

| Car | Blender source to create | Runtime GLB to export | Existing scaffold |
| --- | --- | --- | --- |
| Mazda | blender/vehicles/mazda_astina_323f.blend | cars/mazda_astina_323f/models/mazda_astina_323f.glb | cars/mazda_astina_323f/mazda_astina_323f.tscn |
| Galant | blender/vehicles/mitsubishi_galant.blend | cars/mitsubishi_galant/models/mitsubishi_galant.glb | cars/mitsubishi_galant/mitsubishi_galant.tscn |

No Blender or GLB files were generated. Create the vehicle source directory when you save
your first actual model. Existing Blender sources remain untouched.

## 1. Model a replacement body

1. Set Blender to Metric, Unit Scale 1.0. Start with simple body volumes.
2. Work from top, front, and side orthographic views. Establish wheel centers before details.
3. Match the broad silhouette yourself. Do not trace or reuse downloaded model topology.
4. Keep glass, tires, rims, and lamps separate from painted bodywork.
5. Name the painted mesh BodyPaint. Assign it a material named BodyPaintMaterial.
6. Prefer one paint material on that mesh. The current customization target uses a material
   override for the whole target mesh, so glass must not share that target mesh.
7. Keep object scales at 1. Apply unintended rotation/scale before export.
8. Export selected runtime meshes as GLB with +Y Up conversion. In Godot verify that the
   nose faces -Z. Correct only the visual import transform if it faces the wrong direction.

The current Mazda placeholder is 1.8 x 0.85 x 4.2 m. The Galant placeholder is
1.82 x 0.85 x 4.5 m. These are prototype dimensions, not verified historical specifications.

## 2. Replace the visual without replacing physics

Each starter scene instances the shared PlayerCar scene. It supplies a handling profile,
BodyVisual, UnderglowRoot, and Appearance component. The original CarBodyMesh is hidden.

1. Open the starter scene and instance the imported body under a visual-only Node3D.
2. Hide/remove the placeholder BodyVisual from that starter scene as appropriate.
3. On Appearance, set Body Paint Target to the imported BodyPaint MeshInstance3D.
4. Align the imported visual with the chassis and wheel centers.
5. Keep ChassisCollision, the four VehicleWheel3D nodes, and CameraTarget intact.
6. If dimensions change substantially, adjust the chassis collision deliberately and retest.
7. Do not import duplicate physics bodies from the GLB into the existing VehicleBody3D.

The appearance component duplicates the paint material once per car and reuses it for
later edits. It also owns one underglow material per car. Editing colors does not rebuild
the vehicle or continuously duplicate materials.

## 3. Wheel and rim placement

Current mounts are at X = +/-0.95, Y = 0, front Z = -1.4, rear Z = +1.4.
Wheel radius is 0.34 m, rest length is 0.25 m, and suspension travel is 0.2 m.
Keep the existing 180-degree wheel yaw, which makes positive drive force follow -Z.

The rim's axle runs along local X. RimMount is a child of each VehicleWheel3D.
It sits 0.16 m toward the outside of the tire. Left wheels use local +X and right wheels
use local -X because of the existing wheel orientation.

| Index | Intended style | Replaceable scene |
| --- | --- | --- |
| 0 | OEM Stock | cars/shared/rims/rim_00_stock.tscn |
| 1 | BBS RS-style | cars/shared/rims/rim_01_bbs_rs.tscn |
| 2 | SSR MK-II-style | cars/shared/rims/rim_02_ssr_mk2.tscn |
| 3 | Enkei RPF1-style | cars/shared/rims/rim_03_enkei_rpf1.tscn |
| 4 | RAYS Volk Racing TE37-style | cars/shared/rims/rim_04_rays_volk_te37.tscn |

These are simple torus/spoke placeholders, not branded or copied geometry. Replace their
visual children with your own rim exports. Keep the root Node3D and its origin centered
on the wheel axle. Selection changes all four rims and clamps to 0-4. Wheel physics stays intact.

## 4. Handling profiles

The starter roots assign VehicleHandlingProfile resources. The generic PlayerCar has
no profile and retains its existing mass and tuning. Burnout is the only new input behavior.

| Setting | Generic, no profile | Mazda | Galant |
| --- | --- | --- | --- |
| Mass | 1100 | 1050 | 1280 |
| Engine force | 1600 | 1500 | 2000 |
| Reverse force | 900 | 900 | 900 |
| Brake force | 35 | 35 | 35 |
| Handbrake force | 65 | 65 | 65 |
| Max steer degrees | 28 | 31 | 25 |
| Steering response | 5 | 5.8 | 4.3 |
| High-speed steering factor | 0.35 | 0.40 | 0.32 |
| Steering fade km/h | 100 | 90 | 105 |
| Reset height | 0.25 | 0.25 | 0.25 |

Profiles apply on vehicle startup. Edit the matching resource and restart the scene to
test changes. These values express arcade handling intent, not historical simulation.

## 5. Programmatic customization

There is no garage UI. Change the resource on the running Appearance component:

```gdscript
var appearance: VehicleAppearance = $PlayerCar/Appearance
appearance.customization.body_hue = 0.08
appearance.customization.body_brightness = 0.85
appearance.customization.underglow_enabled = true
appearance.customization.underglow_color = Color(1.0, 0.2, 0.05)
appearance.customization.rim_index = 4
```

Hue wraps through 0-1. Brightness is HSV value clamped to 0.15-1, with fixed saturation
0.75. Rim index clamps to 0-4. The per-car resource emits change notifications, so these
property edits immediately update visuals. Edit the existing resource rather than replacing
the resource reference after startup.

Underglow changes both the emissive strip and its OmniLight3D. The light uses energy 0.8,
range 2.8 m, and no shadows. No bloom or post-processing was added.

## 6. Headlights

Both cars inherit two SpotLight3D nodes from the shared headlights scene. They face -Z
with a 5-degree downward pitch, warm halogen-style color, 45 m range, 45-degree angle,
and energy 2.5. Player shadows start enabled. Turn them off if the target PC needs it.

Headlights sit ahead of the collision/body volume. The Galant's Headlights root has an
extra -0.15 m Z offset to clear its longer placeholder body. Reposition both lights when
replacing the body, and check that the new body does not shadow its own beam.

Traffic lights use range 25 m, energy 1.0, and no shadows.

## 7. Burnout and smoke

After GO, hold W/Up plus Space while grounded and below 18 km/h. The controller supplies
engine force, reduces rear grip, and applies holding brakes. S/Down still has priority
over throttle. Above the threshold, Space uses the previous rear-wheel handbrake behavior.

```text
burnout_max_speed_kph = 18.0
burnout_engine_multiplier = 1.1
burnout_rear_grip_factor = 0.18
burnout_hold_brake_force = 60.0
```

Original rear grip is cached per wheel and restored on release, reset, or control disable.
Two persistent GPUParticles3D instances emit during burnout. They use 28 particles each,
1.2-second lifetime, procedural soft alpha, upward motion, growth, and fade. No external
smoke texture is required. Smoke transforms follow the rear contact positions without
rotating with the tire. The rim visuals spin, while wheel physics remains unchanged.

Future effects can consume the existing interfaces:

```gdscript
car.is_burnout_active()
car.get_rear_wheel_world_positions()
car.burnout_changed.connect(on_burnout_changed)
```

Skidmark rendering, tire temperature/wear, RPM simulation, and slide-smoke heuristics are absent.

## 8. Test a starter in the game

1. Open game/game.tscn. Select Game and assign Player Scene to the desired starter scene.
2. Run the game. Both routes use that same player selection and the existing race systems.
3. Wait for GO, then verify steering, braking, reverse, reset, and pause/retry.
4. Change Hue, Brightness, underglow, and all five rim indices programmatically.
5. Hold W + Space at rest. Verify smoke, slow creep, and rear-wheel visual rotation.
6. Release Space. Verify smoke stops and grip returns.
7. Accelerate beyond 18 km/h. Verify Space still acts as the normal handbrake.
8. Repeat for the other starter. Restore the generic PlayerCar assignment if desired.

The focused smoke test verifies these interfaces and the physics state headlessly. Final
paint, smoke appearance, lighting, rim styling, and handling feel still need manual review.
