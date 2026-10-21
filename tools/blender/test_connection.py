import bpy


OBJECT_NAME = "Codex_Test_Cube"


# Remove the previous test cube so the script can be run more than once.
existing_cube = bpy.data.objects.get(OBJECT_NAME)
if existing_cube is not None:
    bpy.data.objects.remove(existing_cube, do_unlink=True)

# Blender's default cube is 2 meters wide when size is set to 2.
bpy.ops.mesh.primitive_cube_add(size=2.0, location=(0.0, 0.0, 1.0))

test_cube = bpy.context.active_object
test_cube.name = OBJECT_NAME

print("NIGHT//APEX: Blender Python connection works.")
