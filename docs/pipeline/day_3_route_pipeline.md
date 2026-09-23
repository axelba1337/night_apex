# Day 3 route pipeline

The wrappers are technical scenes. The missing route sketches prevent layout tracing.
Current wrapper geometry reuses the existing test straight and barriers, without its ramp.
It does not represent either custom route, its target length, or its elevation.
The original TestTrack, including its ramp, remains unchanged.

## Files and targets

| Route | Blender source | Sketch | Runtime export |
| --- | --- | --- | --- |
| 01 | blender/route_01/route_01.blend | assets/references/routes/route_01_layout.png | tracks/route_01/models/route_01.glb |
| 02 | blender/route_02/route_02.blend | assets/references/routes/route_02_layout.png | tracks/route_02/models/route_02.glb |

The existing Route 01 Blender file was preserved. Create the Route 02 source yourself
in Blender. No fake Blender or GLB files were generated. Create the runtime models
directories when exporting actual geometry.

| Target | Route 01 | Route 02 |
| --- | --- | --- |
| Length | 2.0-2.4 km | 1.3-1.7 km |
| Normal road width | 10 m | 6 m |
| Tight sections | 8 m | 5 m |
| Wider sections | 12-14 m | 7-8 m |
| Elevation | As the supplied sketch requires | 30-60 m overall difference |
| Moving traffic | Two authored lanes | None |

## 1. Prepare Blender and the references

1. Save a working copy of Route 01 before editing it. Start a separate Route 02 file.
2. Set Scene Properties > Units > Metric, with Unit Scale 1.0. One unit represents one meter.
3. Create the collections below. Keep references and authoring guides separate from exports.
4. Press Numpad 7 for top orthographic view. Use View > Viewpoint > Top without a numpad.
5. Use Shift+A > Image > Reference and load the matching supplied sketch.
6. Put the image in REFS. Lower its opacity and disable selection in the Outliner.
7. Scale the reference using a known road-width guide. A sketch is not a surveyed map.
8. Trace the user's sketch. Use circuit-flow and environmental references to interpret
   corners and scenery, not to substitute a real road or circuit layout.

```text
ROUTE_01 or ROUTE_02
  REFS
  ROAD
  BARRIERS
  BUILDINGS
  PROPS
  LIGHT_POLES
  COLLISION_GUIDES
  TRAFFIC_PATHS
  CHECKPOINT_MARKERS
  DECORATION
```

Route 02 may omit TRAFFIC_PATHS or leave it empty. Do not populate it with traffic.

## 2. Trace a road centerline

1. In Object Mode add Curve > Bezier. Name it RoadCenterline and move it to ROAD.
2. Work from top view. In Edit Mode move control points onto the sketch's road center.
3. Select an endpoint and press E to extend. Use as few points as each bend needs.
4. Adjust handles for smooth entry and exit. Avoid abrupt tangent changes.
5. Keep the start at the intended spawn end. Do not close a point-to-point sprint.
6. Keep objects at scale 1. Apply object scale before building the road modifiers.

## 3. Build road strips with Array and Curve

1. Make one straight road segment, 2 m long along local X. Width runs along local Y.
2. Set its initial width to 10 m for Route 01 or 6 m for Route 02. Give it modest thickness.
3. Place the segment origin and curve origin together. Keep the segment at the curve start.
4. Apply the segment's scale. Its length along X must be correct before adding Array.
5. Add Array first. Use Fit Curve, choose RoadCenterline, and use Relative Offset X = 1.
6. Enable Merge for adjacent endpoints if the mesh topology supports it.
7. Add Curve after Array. Choose RoadCenterline and deformation axis +X.
8. Check one bend before extending the full road. Wrong origins or axes cause offsets/twists.
9. Use separate road strips or sections for width changes. Avoid overlapping collision seams.
10. Keep an editable source. Apply modifiers only on an export copy if needed.

Check measured route length in the exported scene or along the centerline. A viewport
silhouette alone does not establish the target distance.

## 4. Edit Route 02 elevation

1. Finish the top-view shape first. Change the curve to 3D if necessary.
2. In side view, select centerline points and move them along Blender Z.
3. Spread the 30-60 m elevation difference across several sections. Avoid sudden crests.
4. Check handle heights and curve tilt. Bank only where it improves readability.
5. Add retaining walls on exposed edges. Leave room for the vehicle, guardrail, and camera.
6. Test slope transitions with the actual vehicle before placing detailed village scenery.

## 5. Add roadside structure

Route 01: warehouses, industrial fences/walls, lay-bys, bridge approaches, elevated-road
supports, and restrained toll-like infrastructure. Use Surabaya, SIER, and PIER atmosphere
as environmental direction. Do not copy their exact public-road layouts.

Route 02: Indonesian houses, warung, toko kecil, utility poles, roadside walls, vegetation,
guardrails, and small village clusters. Keep distant houses simple and omit interiors.

Use separate barrier and guardrail strips. Place simple building blocks behind them.
Check corner sightlines before adding signs or vegetation.

## 6. Distribute physical props

| Route | Immovable structure | Movable / breakable objects |
| --- | --- | --- |
| 01 | Concrete barriers, guardrails, industrial fences, tunnel walls | Barrels, cones, plastic barricades, bins, pallets, crates, roadwork signs |
| 02 | Guardrails, retaining walls, house collision blocks, roadside walls | Crates, barrels, wooden fence sections, bins, small signs, village clutter |

Use the reusable Godot scenes under props/static, props/physics, and props/breakable.
Keep most movable objects outside the ideal racing line. Place each centered primitive
at half its height above the ground. Dynamic masses range from 3 kg cones to 22 kg barrels.
Do not export a decorative copy and leave its Godot physical replacement directly on top.

Breakable props use summed contact impulse, default 90 N.s per physics step. Their intact
visual and collision turn off once. They reset on retry. Debris/fracture is intentionally absent.

## 7. Plan Route 01 traffic paths

1. Reserve lane centerlines beside the racing line where the road permits.
2. Add TrafficLane_A and TrafficLane_B as Path3D children of TrafficPaths in the wrapper.
3. Edit Curve3D points to follow the finished road, including road height and bridges.
4. Keep car centers approximately 0.6 m above the road for the current traffic body.
5. Make each loop continuous in position and direction. Return paths must also stay on road.
6. Replace both compact demo loops before using the final map. They are only test-straight paths.
7. TrafficRoot > Enabled sets the startup state. For live toggling, call its set_enabled(false)
   or set_enabled(true) method. Car Count defaults to 6 and supports 5-8.
8. Demo lanes use 48 and 58 km/h. Each lane shares one speed to preserve spacing.
9. Traffic is an immovable path-driven collider. It does not avoid obstacles or switch lanes.
10. Route 02 must not receive TrafficRoot, TrafficPaths, or moving traffic instances.

## 8. Export GLB

1. Select only runtime road, structures, and necessary collision guides.
2. Exclude REFS, authoring cameras, authoring lights, and marker guides.
3. Apply unintended rotation/scale. Keep consistent meter units.
4. File > Export > glTF 2.0. Choose glTF Binary (.glb) and Selected Objects.
5. Keep the exporter's +Y Up conversion enabled. Verify forward orientation in Godot.
6. Export to the runtime path in the table. Export actual meshes, never rename a Blender file to GLB.
7. Keep materials simple. Use shared materials and 512/1024 textures where sufficient.

## 9. Import and integrate in Godot

1. Let Godot import the GLB. Inspect its origin, scale, road normals, and collisions.
2. Open the matching route wrapper. Assign the GLB PackedScene to its Imported Map property.
3. The wrapper instances it under ImportedMapRoot. Its debug TestTrack geometry is then omitted.
4. Add simple static collision bodies under CollisionRoot where the GLB does not provide them.
5. Reposition SpawnPoint, all four checkpoint areas, speed traps, and FinishTrigger.
6. Align each Area3D with the road. Resize its BoxShape3D to cover the local road width/height.
7. Give checkpoints sequential indices 1-4 and keep each camera ID unique.
8. Check gameplay from start to finish before detailing scenery.
9. Both routes use the same game scene, player, RaceManager, HUD, and result system.

Do not modify the imported GLB directly. Keep gameplay nodes in the wrapper.

## 10. Collision strategy

Roads, barriers, guardrails, tunnel/retaining walls, nearby major buildings, and large
structures need collision. Use boxes/capsules/convex shapes where possible. Only curved
road surfaces that need their actual shape should use static trimesh collision.

For separate Blender road-collision guides, the suffix below makes Godot import a static
collision-only object. Keep the road visual separate:

```text
RoadCollision-colonly
```

Do not use concave trimesh collision on movable rigid bodies. Do not add collision to
distant scenery or tiny decorative detail. See [Godot's import suffix reference](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html).

## 11. Skybox conversion and lighting

Required inputs are 4x3 horizontal-cross images, expected size 1536 x 1152:

```text
assets/skyboxes/source/route_01_urban_cross.jpg
assets/skyboxes/source/route_02_rally_cross.jpg
```

Install Pillow separately in the Python environment. The converter itself has no network
access or dependency installation. Then run from the repository root:

```powershell
python tools/skybox/convert_cross_to_equirect.py --self-test
python tools/skybox/convert_cross_to_equirect.py
```

It writes 1536 x 768 JPEG panoramas to:

```text
assets/skyboxes/panoramas/route_01_urban_panorama.jpg
assets/skyboxes/panoramas/route_02_rally_panorama.jpg
```

The editable FACE_LAYOUT table documents tile locations, quarter-turns, and flips. The
default is +Y above the row -X / +Z / +X / -Z, with -Y below +Z. Sampling is bilinear.
Existing outputs require explicit --overwrite. Sources are never overwritten.

After Godot imports the output, the wrapper assigns its panorama to PanoramaSkyMaterial
and switches the Environment to Sky automatically. Without it, the wrapper uses a dark
solid background with the Sky resource structurally ready. A cross image is never assigned
directly to PanoramaSkyMaterial. Check the horizon, moon, stars, and seams manually.

Route 01 starts at sky energy 0.35 and ambient energy 0.22. Route 02 uses 0.22 and 0.12.
Suggested later ranges: 01 sky 0.25-0.45, ambient 0.15-0.30. 02 sky 0.15-0.30,
ambient 0.08-0.20. Headlights/streetlights should dominate the ambient illumination.

Instance props/static/streetlight.tscn around important Route 01 sections. Route 02 lamps
belong mainly near settlements/intersections. The 6 m poles use warm yellow light and
disable shadows initially. Player lights allow shadows, while traffic lights do not.

## 12. Optimization and final order

Use approximately 80k-150k visible triangles for Route 01 and 60k-110k for Route 02 as
guidance. Reuse props, keep material counts low, omit interiors, and simplify distant
buildings. Fog can hide distance later. Do not add thousands of lights or small colliders.

Order: supply sketches, trace roads, set widths/elevation, test collision, place gameplay
markers, author Route 01 traffic, distribute props, export sky panoramas, tune night lighting,
then add visual detail. Do not treat the current integration straight as a completed custom map.
