# NIGHT//APEX Day 2 Progress

Day 2 adds one shared racing loop for Sprint Run and Speed Trap Run.
Implementation is complete. All Day 2 manual verification remains PENDING.

## Status

| System | Implementation | Manual Verification |
| --- | --- | --- |
| GameSession Autoload | COMPLETE | PENDING |
| Main Menu | COMPLETE | PENDING |
| Mode Select | COMPLETE | PENDING |
| RaceManager | COMPLETE | PENDING |
| Countdown | COMPLETE | PENDING |
| Timer | COMPLETE | PENDING |
| Ordered checkpoints | COMPLETE | PENDING |
| Finish validation | COMPLETE | PENDING |
| SpeedTrap | COMPLETE | PENDING |
| HUD | COMPLETE | PENDING |
| Pause | COMPLETE | PENDING |
| Restart | COMPLETE | PENDING |
| Result Screen | COMPLETE | PENDING |
| Sprint mode | COMPLETE | PENDING |
| Speed Trap mode | COMPLETE | PENDING |
| Game scene integration | COMPLETE | PENDING |
| Main Menu startup | COMPLETE | PENDING |

## Interrupted-work audit

The resumed working tree contained two modified tracked files and fourteen new files.
All existing work was inspected and retained.

| Area at resume | Initial status | Remaining work completed |
| --- | --- | --- |
| Trigger scenes and test-track placements | COMPLETE at file level | Wired to the player and manager, then tested in actual driving. |
| Vehicle integration hooks and display helpers | COMPLETE at file level | Connected control gating and respawn to the race lifecycle. |
| Session script | PARTIAL | Registered GameSession as an Autoload. |
| Race manager, countdown, timer, scoring | PARTIAL | Configured totals and connected state and UI signals. |
| Checkpoint, finish, speed-trap behavior | PARTIAL | Connected scene references and verified ordering and duplicate rejection. |
| Main Menu, Mode Select, HUD, Pause, Result scripts | PARTIAL | Added their missing Control-node scenes and shared placeholder theme. |
| Both modes and restart flow | PARTIAL | Connected scene navigation and in-place race restart. |
| Game integration, main-scene setting, documentation, validation | MISSING | Implemented and validated. |

Day 1 ran successfully before the original Day 2 changes. The user reports Day 1
manual verification is complete. The historical Day 1 document was not rewritten.

## Ownership and scene structure

```text
GameSession (Autoload, session data only)

MainMenu -> ModeSelect -> Game
                         |-- TestTrack
                         |-- PlayerCar
                         |-- ChaseCamera
                         |-- RaceManager
                         |-- HUD
                         |-- PauseMenu
                         `-- ResultScreen
```

- GameSession stores selected mode and in-memory session records. It contains no race logic.
- RaceManager owns IDLE, COUNTDOWN, RACING, and FINISHED states, elapsed time,
  checkpoint order, camera scores, and the result data. UI updates use signals.
- Each trigger receives its manager and player references from game.gd. Only that
  PlayerCar can activate it. Checkpoints reject duplicate or out-of-order entries.
- Finish requires RACING state and all three checkpoints. Final elapsed time is frozen.
- Cameras record vehicle velocity magnitude in km/h. Re-entering a camera can update
  its best speed, but staying inside cannot fire repeatedly. Camera counts use unique IDs.
- Sprint results prioritize finish time. Speed Trap results prioritize the highest
  valid camera reading, not the highest speed anywhere on the track.
- HUD reads speed through the existing vehicle helper. Time uses MM:SS.mmm.
- PauseMenu processes while paused. Race physics, timer, countdown, and popup timers pause.
- ResultScreen is shared by both modes and receives a result dictionary.

## Restart and Day 1 preservation

Retry and Pause > Restart reuse the current game scene. They unpause the tree,
hide results and popup, reset trigger activation, clear run data, request a vehicle
respawn, and begin a fresh 3 / 2 / 1 / GO countdown. Session records remain in memory.

Only two public integration methods and an input guard were added to the Day 1 vehicle:

```gdscript
func set_controls_enabled(enabled: bool) -> void
func reset_to_spawn() -> void
```

All handling exports, steering, braking, handbrake, suspension, wheel configuration,
and chase-camera behavior remain unchanged. Input is gated during countdown and results.
The car settles under physics during countdown and brakes after finishing. Controls
return at GO. R retains its Day 1 vehicle-only reset behavior. Use Pause > Restart
or Result > Retry to restart the entire race.

The existing ground, ramp, barriers, lighting, and spawn geometry were preserved.
Blender files and the Blender connection script were not modified. No commits or pushes
were made, and no addons were installed.

## Trigger placement and Inspector values

All detection volumes are 12 m wide, 6 m high, and 2 m deep. Their centers use
X = 0 and Y = 2.5. They cover the road width and allow room for suspension movement.
Detection uses collision mask 1 and collision layer 0. Colored overhead beams and
labels are debug markers, not solid obstacles.

| Node | Z position | Inspector identifier |
| --- | --- | --- |
| SpawnPoint, unchanged | +45 | Existing spawn |
| Checkpoint_01 | +30 | checkpoint_index = 1 |
| SpeedTrap_01 | +18 | camera_id = ST_01 |
| Checkpoint_02 | +5 | checkpoint_index = 2 |
| SpeedTrap_02 | -22 | camera_id = ST_02 |
| Checkpoint_03 | -35 | checkpoint_index = 3 |
| FinishTrigger | -48 | Finish |

Driving straight along the center reaches every required trigger. The existing ramp
remains on the left side near Z = -10.

## UI asset audit

The assets/ui directory was absent during both audits. No custom images were available.
Nothing was classified USED or REFERENCE ONLY because no relevant files existed.

| Expected reference or runtime location | Status |
| --- | --- |
| assets/ui/mockups/main_menu_reference.png | MISSING |
| assets/ui/mockups/mode_select_reference.png | MISSING |
| assets/ui/mockups/hud_reference.png | MISSING |
| assets/ui/mockups/pause_menu_reference.png | MISSING |
| assets/ui/mockups/result_sprint_reference.png | MISSING |
| assets/ui/mockups/result_speed_trap_reference.png | MISSING |
| assets/ui/mockups/speed_trap_popup_reference.png | MISSING |
| assets/ui/logo/ | MISSING |
| assets/ui/panels/ | MISSING |
| assets/ui/buttons/ | MISSING |
| assets/ui/icons/ | MISSING |
| assets/ui/overlays/ | MISSING |

Interfaces use functional Control, PanelContainer, VBoxContainer, Button, and Label
nodes with a small shared Theme. No full-screen mockup is displayed. All UI scenes
remain editable and easy to reskin when assets arrive.

The reference viewport is 1920 x 1080, with a 1280 x 720 initial window and the
existing canvas_items stretch mode. Menu cards use a centered container. HUD corners
and center elements use anchors. Pause and result overlays fill the viewport.

Starting visual values to adjust against future mockups:

- Menu card minimum width: 840 reference pixels.
- Shared panel padding: 32 horizontal and 28 vertical pixels.
- HUD edge margins: 48 reference pixels.
- Speed popup: 2.5 seconds. GO label: 0.75 seconds.
- Typography, colors, spacing, logo placement, and result hierarchy are placeholders.

## Automated validation

Engine: Godot 4.7.2.stable.official.ed1daf0bf.
Run from the repository root in PowerShell:

```powershell
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 120 --max-fps 60
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://game/game.tscn --quit-after 300 --max-fps 60
& 'D:\Godot Engine\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --max-fps 60 --script res://tools/tests/day_2_smoke.gd
```

Editor/import, Main Menu startup, and direct game startup passed with exit code 0.
The final smoke run passed with no script errors, resource errors, or warnings:

```text
DAY 2 SMOKE: 60 checks, 0 failures
```

The smoke script drives the real vehicle through both modes. It checks scene navigation,
countdown, control gating, checkpoint order, finish rejection, both cameras, duplicate
rejection, popup timeout, pause/resume, in-place retry/restart, session records, and results.
It also checks menu bounds at 1280 x 720, 1600 x 900, and 1920 x 1080.

Both automated straight-line runs completed in approximately 9.37 seconds, with three
checkpoints and two cameras. The highest camera reading was approximately 49.85 km/h.
These are test observations, not target scores.

The standalone smoke runner initially loaded race classes before Autoload initialization.
Its loading order was corrected. The final commands above do not produce those errors.

Headless tests do not establish final visual appearance, keyboard usability in a rendered
window, or subjective handling. Manual Verification remains PENDING.

## Manual Day 2 test checklist

- [ ] F5 opens Main Menu
- [ ] Main Menu uses custom design/assets or correct placeholders
- [ ] START GAME opens Mode Select
- [ ] GAME MODE opens Mode Select
- [ ] Sprint Run can be selected
- [ ] Speed Trap Run can be selected
- [ ] Selected mode appears correctly on HUD
- [ ] Game starts with 3 -> 2 -> 1 -> GO
- [ ] Car cannot finish before race starts
- [ ] Timer starts only after GO
- [ ] Speedometer updates while driving
- [ ] Checkpoint 1 is accepted
- [ ] Skipping a checkpoint is rejected
- [ ] Checkpoint count updates correctly
- [ ] SpeedTrap_01 detects speed
- [ ] Speed trap popup appears
- [ ] Speed trap popup disappears after a short delay
- [ ] SpeedTrap_02 detects independently
- [ ] Finish is rejected if checkpoints were skipped
- [ ] Finish succeeds after all checkpoints
- [ ] Sprint result shows finish time
- [ ] Speed Trap result shows highest speed
- [ ] Retry restarts cleanly
- [ ] Esc opens Pause Menu
- [ ] Resume works
- [ ] Restart works from Pause Menu
- [ ] Main Menu works from Pause Menu
- [ ] Main Menu works from Result Screen
- [ ] No duplicate checkpoint triggers
- [ ] No duplicate speed trap triggers from staying inside trigger
- [ ] Debugger reports zero script/parser errors

Shortest normal test: F5, Start Game, Sprint Run, wait for GO, hold W along the center
until finish, Retry, Esc, Resume, Esc, Restart, Esc, Main Menu, Game Mode, Speed Trap
Run, drive to finish, Main Menu. Check Settings and Back on the relevant screens.

## Actual Day 2 limitations

- Custom artwork is missing. Current visuals are temporary placeholders.
- Settings buttons show a notice only.
- Records last only for the current application session. There are no save files.
- The same short Day 1 straight serves both modes and has open ends.
- Trigger volumes accept entry from either direction, but checkpoint order is enforced.
- R respawns the vehicle without clearing race progress or elapsed time.

## Reference

Pause behavior follows Godot's process modes:
[Pausing games](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html).
