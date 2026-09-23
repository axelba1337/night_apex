# STATIC//SHIFT Day 3 / Day 4A progress

Technical foundations implemented locally on 2026-09-23. Custom map layouts and sky
panoramas remain pending because their source references are absent. No final artistic
maps, cars, or rims were generated. All manual verification remains PENDING.

## Repository audit

The current local Day 2 implementation was authoritative. At task start, five tracked
files were modified and the Day 2 systems, UI, documentation, and smoke test were untracked.
Those changes were preserved. The baseline Day 2 smoke test passed 60 checks before changes.

The working chase camera, original TestTrack geometry/collision, project settings, and
Day 2 race/UI scripts were preserved. GameSession gained route selection. Game composition
now instances the selected route and supports an Inspector-assigned Player Scene. The
controller gained optional profiles and the requested burnout behavior. No-profile handling
values remain unchanged. The base car gained headlights, rim mounts, and tire-smoke nodes.

No Blender source or backup was edited. No commits, pushes, PRs, or addons were created.

## Reference audit

| Expected file | Status |
| --- | --- |
| assets/references/routes/route_01_layout.png | MISSING |
| assets/references/routes/route_02_layout.png | MISSING |
| assets/skyboxes/source/route_01_urban_cross.jpg | MISSING |
| assets/skyboxes/source/route_02_rally_cross.jpg | MISSING |

The two Sketchfab car pages returned HTTP 403. No reference geometry was downloaded.
The Mazda/Galant labels describe intended starter concepts, not verified model accuracy.

## Day 3 status

| System | Implementation | Manual Verification | Scope / limitation |
| --- | --- | --- | --- |
| Route 01 wrapper | COMPLETE | PENDING | Four checkpoints, two cameras, spawn, finish, map/collision/prop/traffic roots. |
| Route 02 wrapper | COMPLETE | PENDING | Four checkpoints, one camera, spawn, finish, map/collision/prop roots. |
| Route selection | COMPLETE | PENDING | Two enum values, shared game and race systems. Route 01 defaults. |
| Custom route layouts | BLOCKED | PENDING | Both sketches are absent. No invented layout or GLB. |
| Static props | COMPLETE | PENDING | Seven simple scenes including the streetlight. |
| Movable props | COMPLETE | PENDING | Six rigid-body scenes with light arcade masses. |
| Breakable props | COMPLETE | PENDING | Three scenes, summed contact-impulse threshold, one-shot break, reset support. |
| Route 01 traffic | COMPLETE | PENDING | Six deterministic demo cars, two closed paths, toggle, reset, collision. Final-map paths await authored geometry. |
| Skybox conversion utility | PARTIAL | PENDING | Offline converter and math tests implemented. JPEG conversion awaits source files and Pillow. |
| Route 01 panorama | BLOCKED | PENDING | Source absent. No fake output generated. |
| Route 02 panorama | BLOCKED | PENDING | Source absent. No fake output generated. |
| WorldEnvironment | PARTIAL | PENDING | Separate panorama-ready resources, auto-assignment when outputs exist, dark fallback now. |
| Streetlight foundation | COMPLETE | PENDING | Warm lights, shadows off, four Route 01 demo lamps and one Route 02 lamp. |

Route 02 has NO MOVING TRAFFIC, no TrafficRoot, no TrafficPaths, and no direct traffic
scene/script resource dependency. Both wrappers currently reuse only the TestTrack road
and barriers as a runtime integration surface. Its ramp remains in the original TestTrack.

The wrappers do not satisfy the final route length, sketch shape, scenery, or Route 02
elevation targets yet. Their current markers and traffic loops are explicitly demo placements.

## Day 4A status

| System | Implementation | Manual Verification |
| --- | --- | --- |
| Mazda scaffold | COMPLETE | PENDING |
| Galant scaffold | COMPLETE | PENDING |
| Handling profiles | COMPLETE | PENDING |
| Body Hue | COMPLETE | PENDING |
| Body Brightness | COMPLETE | PENDING |
| Underglow toggle and color | COMPLETE | PENDING |
| Five visual rim choices | COMPLETE | PENDING |
| Player and traffic headlights | COMPLETE | PENDING |
| Burnout | COMPLETE | PENDING |
| Tire smoke | COMPLETE | PENDING |
| Future skidmark state interface | COMPLETE | PENDING |

The car/rim geometry is primitive scaffolding. Final artistic modeling is outside this task.

## Usage and starting values

Default route selection is in systems/game_session/game_session.gd. To test the second
route, temporarily change the selected_route initializer, or set it before loading Game:

```gdscript
GameSession.selected_route = GameSession.RouteId.ROUTE_02
get_tree().change_scene_to_file("res://game/game.tscn")
```

Both modes use the selected route. Game > Player Scene accepts either starter PackedScene.
The shipped default remains the generic PlayerCar to preserve the baseline handling.

TrafficRoot > Enabled sets the startup state. For a live change, call the traffic manager's
set_enabled(false) or set_enabled(true) method. Default count is 6, with supported counts
5-8. Demo lane speeds are 48 and 58 km/h, within the 45-75 km/h supported range. Cars in a
lane share their speed to preserve spacing. Traffic uses path-driven AnimatableBody3D
colliders. It does not yield, avoid obstacles, change lanes, or get pushed off its path.

Route 01 uses sky energy 0.35 and ambient energy 0.22. Route 02 uses 0.22 and 0.12.
Missing panoramas use a dark solid background. When the expected output is imported,
the route assigns PanoramaSkyMaterial.panorama and enables Sky background mode.

Player headlights: warm color, 45 m range, 45-degree cone, energy 2.5, shadows enabled.
Traffic headlights: 25 m range, energy 1.0, shadows disabled. Streetlights use warm yellow
light, 14 m range, energy 3.0, and no shadows.

Mazda: 1050 kg, engine force 1500, max steering 31 degrees, response 5.8.
Galant: 1280 kg, engine force 2000, max steering 25 degrees, response 4.3.
The full tuning table and customization calls are in the car pipeline guide.

Burnout: W/Up + Space, grounded, speed at or below 18 km/h. Engine multiplier 1.1,
rear-grip factor 0.18, holding brake 60. Original grip returns after release/reset/control
disable. Above the threshold, the existing handbrake behavior remains active.

## Automated validation

Godot 4.7.2.stable.official.ed1daf0bf was used. Run from the repository root:

```powershell
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 120 --max-fps 60
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://game/game.tscn --quit-after 240 --max-fps 60
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --max-fps 60 --script res://tools/tests/day_2_smoke.gd -- --test-track
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --max-fps 60 --script res://tools/tests/day_3_day_4a_smoke.gd
python tools/skybox/convert_cross_to_equirect.py --self-test
```

Final automated results:

```text
DAY 2 SMOKE: 60 checks, 0 failures
DAY 3 / 4A SMOKE: 95 checks, 0 failures
SKYBOX MATH: 12 checks passed. No files generated.
```

Godot editor/import and runtime checks passed without parser/resource errors or warnings.
The new smoke test loads both wrappers, completes their race loops, tests traffic separately,
checks every prop scene, physically pushes a barrel, breaks a crate with a car, collides with
traffic, and exercises both cars' customization and burnout. Wrapper race-completion checks
disable traffic to isolate race progression. Traffic movement/collision have separate checks.

The initial crate test exposed per-contact threshold sensitivity. Summing contact impulses
and using a sufficiently strong approach resolved it. The final test also verifies that resting
contacts do not break the crate and that breaking cannot repeat.

Two-second burnout creep measured approximately 0.085 m for Mazda and 0.089 m for Galant.
Both restored grip and stopped smoke after release. These are test observations, not tuning promises.

Actual panorama conversion returned a clear missing-source error and produced no files.
Pillow is not installed in the available Python 3.14 environment. JPEG I/O and actual sky
orientation are therefore unverified. The converter performs no network access or installation.

Headless checks verify particle configuration/state, not rendered smoke or lighting quality.

## Manual Blender order

1. Supply both route sketches and the two original cross images at the documented paths.
2. Follow the route pipeline: collections, reference scale, centerlines, Array/Curve roads.
3. Set widths and Route 02 elevation, then export simple road collision and test it.
4. Place gameplay markers, author Route 01 traffic lanes, and distribute props.
5. Convert/import the real sky panoramas and tune warm night lighting.
6. Independently model both starter bodies and five rim visuals.
7. Export GLBs, replace visual targets, and retest customization and burnout.

Detailed guides:

- [Day 3 route pipeline](pipeline/day_3_route_pipeline.md)
- [Day 4A car pipeline](pipeline/day_4a_car_pipeline.md)

## Manual Godot order

1. F5, choose either mode, wait for GO, and complete the default Route 01 integration straight.
2. Verify traffic paths and lights. Test startup with TrafficRoot > Enabled off and on.
   For live toggling, call TrafficRoot.set_enabled(false), then set_enabled(true).
3. Test props, checkpoints, camera scores, pause, retry, and results.
4. Select Route 02 before entering Game. Verify four checkpoints, one camera, and no traffic.
5. Assign Mazda to Game > Player Scene. Test customization, headlights, and W + Space burnout.
6. Repeat for Galant. Release Space, reset, and restart to check grip/smoke restoration.
7. Run the explicit TestTrack debug option for the unchanged Day 1 ramp/physics.
8. Verify sky orientation only after actual panorama outputs exist.

## Manual checklist

### Routes

- [ ] Route 01 loads
- [ ] Route 02 loads
- [ ] TestTrack still loads
- [ ] selected_route correctly changes route
- [ ] player spawns correctly on Route 01
- [ ] player spawns correctly on Route 02

### Props

- [ ] static barrier cannot move
- [ ] barrel can be pushed
- [ ] cone can be hit/moved
- [ ] barricade can move
- [ ] breakable crate breaks above threshold
- [ ] breakable prop does not repeatedly break

### Traffic

- [ ] Route 01 traffic follows path
- [ ] traffic is not random
- [ ] traffic loops correctly
- [ ] traffic speeds appear moderate
- [ ] PlayerCar can interact/collide with traffic
- [ ] Route 02 contains no moving traffic

### Sky / lighting

- [ ] Route 01 panorama displays correctly
- [ ] Route 02 panorama displays correctly
- [ ] neither sky is mirrored/upside-down
- [ ] Route 01 remains visibly nighttime
- [ ] Route 02 remains visibly nighttime
- [ ] player headlights illuminate road
- [ ] traffic headlights work on Route 01
- [ ] yellow streetlights have warm sodium-like appearance

### Cars

- [ ] Mazda scene loads
- [ ] Galant scene loads
- [ ] Mazda handling profile applies
- [ ] Galant handling profile applies

### Customization

- [ ] Hue changes body color
- [ ] Brightness changes body brightness
- [ ] underglow toggles
- [ ] underglow color changes
- [ ] rim 0 stock loads
- [ ] rim 1 BBS RS-style loads
- [ ] rim 2 SSR MK-II-style loads
- [ ] rim 3 Enkei RPF1-style loads
- [ ] rim 4 RAYS Volk Racing TE37-style loads

### Burnout

- [ ] W + Space below threshold starts burnout
- [ ] burnout does not completely kill throttle
- [ ] rear tires emit smoke
- [ ] car remains approximately stationary / creeps
- [ ] releasing Space stops burnout
- [ ] rear grip returns to normal
- [ ] normal high-speed Space still acts as handbrake

### Debug

- [ ] zero GDScript parser errors
- [ ] zero missing-resource errors

## Known limitations

- Missing sketches/GLBs mean both wrappers currently use a short debug straight, not custom routes.
- Missing sky sources and Pillow prevent panorama conversion and orientation verification.
- Car reference pages could not be inspected. Body and rim geometry remain primitive placeholders.
- Traffic is an unyielding path-driven collider and needs final-map lane authoring.
- Breaking hides the intact object. There is no debris, fracture, or deformation.
- No garage/route-selection UI, persistence, skidmarks, advanced audio, or post-processing was added.
- Visual appearance and final handling need manual testing. All manual statuses remain PENDING.

## File audit for this task

Created paths, including Godot-generated script UID sidecars:

```text
cars/mazda_astina_323f/mazda_astina_323f.tscn
cars/mitsubishi_galant/mitsubishi_galant.tscn
cars/shared/car_customization.gd
cars/shared/car_customization.gd.uid
cars/shared/effects/tire_smoke.tscn
cars/shared/headlights.tscn
cars/shared/profiles/mazda_astina_323f.tres
cars/shared/profiles/mitsubishi_galant.tres
cars/shared/rims/rim_00_stock.tscn
cars/shared/rims/rim_01_bbs_rs.tscn
cars/shared/rims/rim_02_ssr_mk2.tscn
cars/shared/rims/rim_03_enkei_rpf1.tscn
cars/shared/rims/rim_04_rays_volk_te37.tscn
cars/shared/underglow.tscn
cars/shared/vehicle_appearance.gd
cars/shared/vehicle_appearance.gd.uid
cars/shared/vehicle_handling_profile.gd
cars/shared/vehicle_handling_profile.gd.uid
docs/day_3_day_4a_progress.md
docs/pipeline/day_3_route_pipeline.md
docs/pipeline/day_4a_car_pipeline.md
props/breakable/breakable_prop.gd
props/breakable/breakable_prop.gd.uid
props/breakable/roadside_sign.tscn
props/breakable/wooden_crate.tscn
props/breakable/wooden_fence.tscn
props/physics/oil_barrel.tscn
props/physics/plastic_barricade.tscn
props/physics/small_crate.tscn
props/physics/traffic_cone.tscn
props/physics/trash_bin.tscn
props/physics/wooden_pallet.tscn
props/static/building_block.tscn
props/static/concrete_barrier.tscn
props/static/guardrail.tscn
props/static/large_road_sign.tscn
props/static/retaining_wall.tscn
props/static/streetlight.tscn
props/static/tunnel_wall.tscn
systems/traffic/traffic_manager.gd
systems/traffic/traffic_manager.gd.uid
systems/traffic/traffic_vehicle.gd
systems/traffic/traffic_vehicle.gd.uid
systems/traffic/traffic_vehicle.tscn
tools/skybox/convert_cross_to_equirect.py
tools/tests/day_3_day_4a_smoke.gd
tracks/route_01/route_01.tscn
tracks/route_02/route_02.tscn
tracks/route_foundation.gd
tracks/route_foundation.gd.uid
```

Existing paths changed in this task:

```text
cars/player/player_car.tscn
cars/player/vehicle_controller.gd
game/game.gd
game/game.tscn
systems/game_session/game_session.gd
```

GameSession already existed as an untracked Day 2 file. The pre-existing modifications
to project.godot and tracks/test_track/test_track.tscn were not changed in this task.
All other pre-existing Day 2 untracked files remain preserved.
