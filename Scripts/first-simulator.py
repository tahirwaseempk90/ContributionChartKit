#!/usr/bin/env python3
"""Prints the UDID of an available simulator whose name starts with the given text.

Simulator names change with each Xcode release, so CI looks one up instead of naming a device.

usage: first-simulator.py iPhone
"""
import json
import subprocess
import sys


def main():
    prefix = sys.argv[1]
    devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", "devices", "available"]))["devices"]
    # Runtime identifiers sort oldest first, so the newest is checked first.
    for runtime in sorted(devices, reverse=True):
        for device in devices[runtime]:
            if device["name"].startswith(prefix):
                print(device["udid"])
                return
    sys.exit(f"No available simulator named {prefix}…")


if __name__ == "__main__":
    main()
