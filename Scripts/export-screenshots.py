#!/usr/bin/env python3
"""Exports the screenshots in a UI test result bundle, using each attachment's readable name.

usage: export-screenshots.py <result.xcresult> <output-directory>

Each test's screenshots go in a folder named after the device that ran it.
"""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile


def main():
    bundle, output = sys.argv[1], pathlib.Path(sys.argv[2])
    with tempfile.TemporaryDirectory() as temporary:
        subprocess.check_call(
            ["xcrun", "xcresulttool", "export", "attachments", "--path", bundle, "--output-path", temporary]
        )
        manifest = json.loads((pathlib.Path(temporary) / "manifest.json").read_text())
        count = 0
        for test in manifest:
            for attachment in test.get("attachments", []):
                name = attachment.get("suggestedHumanReadableName", attachment["exportedFileName"])
                # Names look like "reference-light_0_<id>.png", so keep the part before the suffix.
                stem = name.split("_")[0]
                device = attachment.get("deviceName", "device").replace(" ", "-")
                target = output / device / f"{stem}{pathlib.Path(name).suffix}"
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(pathlib.Path(temporary) / attachment["exportedFileName"], target)
                count += 1
        print(f"Exported {count} attachments to {output}")


if __name__ == "__main__":
    main()
