"""Offline 4x3 cubemap-cross to 2:1 panorama conversion. Requires Pillow for JPEG I/O.

Default cross, viewed from inside the cube:
        +Y
    -X  +Z  +X  -Z
        -Y

Panorama center looks toward +Z, the right quarter toward +X, and the top toward +Y.
Edit FACE_LAYOUT to correct source-specific tile order, rotations, or mirroring.
The real source orientation must still be checked visually in Godot.
"""

import argparse
from dataclasses import dataclass
import math
from pathlib import Path
import sys


REPO_ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Face:
    column: int
    row: int
    clockwise_turns: int = 0
    flip_u: bool = False
    flip_v: bool = False


FACE_LAYOUT = {
    "+Y": Face(1, 0),
    "-X": Face(0, 1),
    "+Z": Face(1, 1),
    "+X": Face(2, 1),
    "-Z": Face(3, 1),
    "-Y": Face(1, 2),
}


def direction_to_face(x, y, z):
    """Return a face name and normalized left-to-right, top-to-bottom coordinates."""
    ax, ay, az = abs(x), abs(y), abs(z)
    if max(ax, ay, az) == 0:
        raise ValueError("A direction cannot be zero.")
    if ay >= ax and ay >= az:
        name, u, v = ("+Y", x / ay, z / ay) if y > 0 else ("-Y", x / ay, -z / ay)
    elif ax >= az:
        name, u, v = ("+X", -z / ax, -y / ax) if x > 0 else ("-X", z / ax, -y / ax)
    else:
        name, u, v = ("+Z", x / az, -y / az) if z > 0 else ("-Z", -x / az, -y / az)
    return name, (u + 1) * 0.5, (v + 1) * 0.5


def orient_uv(u, v, face):
    for _ in range(face.clockwise_turns % 4):
        u, v = v, 1 - u
    return (1 - u if face.flip_u else u), (1 - v if face.flip_v else v)


def bilinear_sample(pixels, size, u, v):
    """Clamp within one face. Never interpolate into a blank cross tile."""
    px = min(1.0, max(0.0, u)) * (size - 1)
    py = min(1.0, max(0.0, v)) * (size - 1)
    x0, y0 = int(px), int(py)
    x1, y1 = min(x0 + 1, size - 1), min(y0 + 1, size - 1)
    tx, ty = px - x0, py - y0
    a, b, c, d = pixels[x0, y0], pixels[x1, y0], pixels[x0, y1], pixels[x1, y1]
    return tuple(round((a[i] * (1 - tx) + b[i] * tx) * (1 - ty)
                       + (c[i] * (1 - tx) + d[i] * tx) * ty) for i in range(3))


def convert(source_path, output_path, width=1536, overwrite=False):
    source_path, output_path = Path(source_path).resolve(), Path(output_path).resolve()
    if source_path == output_path:
        raise ValueError("Source and output must be different files.")
    if not source_path.is_file():
        raise FileNotFoundError(f"Missing source: {source_path}")
    if output_path.exists() and not overwrite:
        raise FileExistsError(f"Output exists. Use --overwrite explicitly: {output_path}")
    if width < 4 or width % 2:
        raise ValueError("Output width must be an even integer of at least 4.")
    try:
        from PIL import Image
    except ImportError as error:
        raise RuntimeError("Pillow is required. Install it separately. This tool never accesses the network.") from error

    with Image.open(source_path) as source:
        if source.width % 4 or source.height % 3 or source.width // 4 != source.height // 3:
            raise ValueError("Expected a 4x3 cross with square faces, e.g. 1536x1152.")
        size = source.width // 4
        if size < 2:
            raise ValueError("Each face must be at least 2x2 pixels.")
        rgb = source.convert("RGB")
        faces = {name: rgb.crop((face.column * size, face.row * size,
                                (face.column + 1) * size, (face.row + 1) * size))
                 for name, face in FACE_LAYOUT.items()}
    pixels = {name: face.load() for name, face in faces.items()}
    height = width // 2
    longitudes = [((column + 0.5) / width - 0.5) * math.tau for column in range(width)]
    horizontal = [(math.sin(angle), math.cos(angle)) for angle in longitudes]
    output_pixels = []
    for row in range(height):
        latitude = (0.5 - (row + 0.5) / height) * math.pi
        y, radius = math.sin(latitude), math.cos(latitude)
        for sx, sz in horizontal:
            name, u, v = direction_to_face(sx * radius, y, sz * radius)
            u, v = orient_uv(u, v, FACE_LAYOUT[name])
            output_pixels.append(bilinear_sample(pixels[name], size, u, v))
    panorama = Image.new("RGB", (width, height))
    panorama.putdata(output_pixels)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    panorama.save(output_path, quality=95, subsampling=0)
    print(output_path)


def self_test():
    # In-memory math checks only. No placeholder artwork or files are generated.
    for direction, expected in [((1, 0, 0), "+X"), ((-1, 0, 0), "-X"),
                                ((0, 1, 0), "+Y"), ((0, -1, 0), "-Y"),
                                ((0, 0, 1), "+Z"), ((0, 0, -1), "-Z")]:
        assert direction_to_face(*direction) == (expected, 0.5, 0.5)
    samples = {(0, 0): (0, 0, 0), (1, 0): (100, 0, 0),
               (0, 1): (0, 100, 0), (1, 1): (100, 100, 100)}
    assert bilinear_sample(samples, 2, 0.5, 0.5) == (50, 50, 25)
    assert bilinear_sample(samples, 2, -1, 2) == (0, 100, 0)
    assert orient_uv(0.25, 0.75, Face(0, 0, 1)) == (0.75, 0.75)
    assert orient_uv(0.25, 0.75, Face(0, 0, 0, True, True)) == (0.75, 0.25)
    # Both sides of the equirectangular seam must sample the back face.
    assert direction_to_face(0.00001, 0, -1)[0] == "-Z"
    assert direction_to_face(-0.00001, 0, -1)[0] == "-Z"
    print("SKYBOX MATH: 12 checks passed. No files generated.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--width", type=int, default=1536)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if (args.input is None) != (args.output is None):
        parser.error("Provide both --input and --output, or neither to process both routes.")
    pairs = [(args.input, args.output)] if args.input is not None else [
        (REPO_ROOT / f"assets/skyboxes/source/{name}_cross.jpg",
         REPO_ROOT / f"assets/skyboxes/panoramas/{name}_panorama.jpg")
        for name in ["route_01_urban", "route_02_rally"]
    ]
    failed = False
    for source, output in pairs:
        try:
            convert(source, output, args.width, args.overwrite)
        except (OSError, ValueError, RuntimeError) as error:
            print(error, file=sys.stderr)
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
