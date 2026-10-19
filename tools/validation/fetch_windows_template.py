"""Fetch only Windows x64 templates from the official matching release ZIP.

Uses ZIP central-directory range reads; writes project-local tools/runtime only.
No global Godot installation/configuration is changed.
"""
import io
import json
import pathlib
import urllib.request
import zipfile
import hashlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
URL = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"

class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD")) as response:
            self.url = response.url
            self.size = int(response.headers["Content-Length"])
        self.position = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.size + offset
        return self.position
    def read(self, size=-1):
        if size < 0: size = self.size - self.position
        if size == 0: return b""
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{self.position+size-1}"})
        with urllib.request.urlopen(request) as response:
            if response.status != 206:
                raise RuntimeError("Server did not honor range request; refusing full archive download")
            data = response.read()
        if len(data) != size: raise RuntimeError(f"Short range: {len(data)} vs {size}")
        self.position += len(data)
        return data

def main():
    destination = ROOT / "tools/runtime/godot-4.7.2"
    destination.mkdir(parents=True, exist_ok=True)
    report = {"source": URL, "files": []}
    with zipfile.ZipFile(RemoteZip(URL)) as archive:
        names = [n for n in archive.namelist() if n.endswith(("windows_release_x86_64.exe", "windows_debug_x86_64.exe"))]
        if len(names) != 2: raise RuntimeError(f"Unexpected template list: {names}")
        for name in names:
            target = destination / pathlib.PurePosixPath(name).name
            data = archive.read(name)  # ZIP CRC checked by zipfile.
            target.write_bytes(data)
            report["files"].append({"file": str(target.relative_to(ROOT)), "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
            print("EXTRACTED", target.name, len(data), flush=True)
    (ROOT / "evidence/preflight/windows_templates.json").write_text(json.dumps(report, indent=2))

if __name__ == "__main__": main()
