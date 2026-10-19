"""Build 1K GLB texture derivatives without changing geometry, skin or animation bytes."""
import copy
import hashlib
import io
import json
import struct
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "Game File/assets/characters"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def build(path):
    raw = path.read_bytes()
    length, kind = struct.unpack_from("<II", raw, 12)
    assert kind == 0x4E4F534A
    source = json.loads(raw[20:20 + length])
    offset = 20 + length
    bin_length, kind = struct.unpack_from("<II", raw, offset)
    assert kind == 0x004E4942
    binary = raw[offset + 8:offset + 8 + bin_length]
    result = copy.deepcopy(source)
    image_views = {image["bufferView"]: image for image in result["images"]}
    normal_views = {source["images"][source["textures"][material["normalTexture"]["index"]]["source"]]["bufferView"] for material in source["materials"] if "normalTexture" in material}
    output = bytearray()
    textures = []
    unchanged_views = 0
    for index, view in enumerate(result["bufferViews"]):
        start = view.get("byteOffset", 0)
        payload = binary[start:start + view["byteLength"]]
        if index in image_views:
            image_meta = image_views[index]
            image = Image.open(io.BytesIO(payload))
            image = image.convert("RGBA" if "A" in image.getbands() else "RGB")
            original_size = image.size
            image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
            if index in normal_views:
                pixels = np.asarray(image)
                normals = pixels[:, :, :3].astype(np.float32) / 127.5 - 1.0
                normals /= np.maximum(np.linalg.norm(normals, axis=2, keepdims=True), 1e-6)
                encoded_normals = np.clip((normals + 1.0) * 127.5, 0, 255).astype(np.uint8)
                if pixels.shape[2] == 4:
                    encoded_normals = np.concatenate((encoded_normals, pixels[:, :, 3:4]), axis=2)
                image = Image.fromarray(encoded_normals)
            encoded = io.BytesIO()
            image.save(encoded, format="PNG", optimize=True)
            payload = encoded.getvalue()
            image_meta["mimeType"] = "image/png"
            textures.append({"name": image_meta.get("name", ""), "source_size": original_size, "low_size": image.size})
        else:
            unchanged_views += 1
        output.extend(b"\x00" * (-len(output) % 4))
        view["byteOffset"] = len(output)
        view["byteLength"] = len(payload)
        output.extend(payload)
    output.extend(b"\x00" * (-len(output) % 4))
    result["buffers"][0]["byteLength"] = len(output)
    # Every accessor-backed byte range is retained, not re-exported or re-sampled.
    for index, view in enumerate(source["bufferViews"]):
        if index in image_views:
            continue
        revised = result["bufferViews"][index]
        assert binary[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]] == output[revised["byteOffset"]:revised["byteOffset"] + revised["byteLength"]]
    for key in ("accessors", "meshes", "nodes", "skins", "animations", "materials"):
        assert result.get(key) == source.get(key), key
    metadata = json.dumps(result, separators=(",", ":")).encode()
    metadata += b" " * (-len(metadata) % 4)
    glb = struct.pack("<III", 0x46546C67, 2, 28 + len(metadata) + len(output))
    glb += struct.pack("<II", len(metadata), 0x4E4F534A) + metadata
    glb += struct.pack("<II", len(output), 0x004E4942) + output
    destination = path.with_name(path.stem + "_low.glb")
    destination.write_bytes(glb)
    return {"fighter_id": path.stem, "source": str(path.relative_to(ROOT)), "output": str(destination.relative_to(ROOT)), "source_sha256": digest(raw), "low_sha256": digest(glb), "source_bytes": len(raw), "low_bytes": len(glb), "textures": textures, "unchanged_nonimage_buffer_views": unchanged_views, "mesh_skin_animation_metadata_and_bytes_identical": True}


if __name__ == "__main__":
    records = [build(ASSETS / (definition.stem + ".glb")) for definition in sorted((ROOT / "Game File/characters/definitions").glob("f0*.gd"))]
    report = ROOT / "evidence/characters/texture_tiers.json"
    report.write_text(json.dumps({"generator": "tools/blender/build_runtime_texture_tiers.py", "maximum_texture_dimension": 1024, "fighters": records}, indent=2))
    print(f"Built {len(records)} 1K fighter tiers; all mesh, skin and animation data unchanged.")
