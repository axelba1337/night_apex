# STATIC//SHIFT Development Rules

## Project

STATIC//SHIFT is a small 3D arcade racing prototype.

Engine:
Godot 4.7.2 Standard

Language:
GDScript

3D authoring:
Blender

Target:
Windows PC

## Development philosophy

Prioritize:

1. Playability
2. Control
3. Readability
4. Simplicity
5. Reusable architecture

This is a 5-day prototype.

Do not overengineer systems.

## Scope

Required systems:

- VehicleController
- ChaseCamera
- RaceManager
- Checkpoint
- Timer
- Finish
- Restart
- SpeedTrap
- HUD

Optional systems must not interfere with required systems.

## Coding rules

- Use typed GDScript where practical.
- Use snake_case for files, variables and functions.
- Use PascalCase for node names and class_name declarations.
- Prefer small reusable scripts.
- Keep gameplay systems decoupled with signals where appropriate.
- Avoid giant manager classes.
- Do not introduce third-party Godot addons without explicit approval.
- Do not rewrite unrelated systems while fixing one issue.

## Scene editing

Prefer modifying GDScript over manually rewriting large .tscn files.

If scene-tree changes are needed:

- explain the required node hierarchy
- specify node names
- specify Inspector values
- avoid destructive scene rewrites

## Vehicle

The vehicle is arcade-oriented.

Priorities:

- responsive steering
- stable high-speed handling
- controllable sliding
- believable suspension

Do not implement realistic drivetrain simulation unless explicitly requested.

## Blender

Blender source files are stored under:

blender/

Do not attempt to directly modify binary .blend files.

Blender automation should be written as Python scripts under:

tools/blender/

Export runtime models as GLB into appropriate Godot asset folders.

## AI workflow

Work on one system at a time.

Before large changes:

- inspect relevant files
- explain the proposed change
- avoid unrelated refactors

After changes:

- list modified files
- explain behavior
- state how to test it

## Git

Do not create fake commits.

Suggested commit style:

feat:
fix:
refactor:
docs:
chore:
