#!/usr/bin/env python3
"""Summarises `swift test --enable-code-coverage` output for the package's own sources.

usage: coverage.py <coverage.json> [--minimum PERCENT]

Prints line, function, and region coverage for each file, and lists uncovered lines. Exits
with a failure if line coverage falls below the minimum.
"""
import argparse
import json
import pathlib
import sys

SOURCE_MARKER = "/Sources/ContributionChart/"


def uncovered_lines(file_data):
    """Lines inside regions that never ran, from llvm-cov's [line, col, count, ...] segments."""
    segments = file_data["segments"]
    lines = set()
    for current, following in zip(segments, segments[1:]):
        line, _, count, has_count, *_ = current
        if has_count and count == 0:
            # A segment that ends at the start of a line does not cover that line.
            last = following[0] - 1 if following[1] == 1 else following[0]
            lines.update(range(line, last + 1))
    return sorted(lines)


def compress(lines):
    """Turns [1, 2, 3, 7] into '1-3, 7'."""
    ranges = []
    for line in lines:
        if ranges and line == ranges[-1][1] + 1:
            ranges[-1][1] = line
        else:
            ranges.append([line, line])
    return ", ".join(f"{a}-{b}" if a != b else str(a) for a, b in ranges)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=pathlib.Path)
    parser.add_argument("--minimum", type=float, default=0)
    args = parser.parse_args()

    data = json.loads(args.report.read_text())["data"][0]
    files = sorted(
        (f for f in data["files"] if SOURCE_MARKER in f["filename"]),
        key=lambda f: f["filename"],
    )
    if not files:
        sys.exit(f"No files under {SOURCE_MARKER} found in {args.report}")

    totals = {"lines": [0, 0], "functions": [0, 0], "regions": [0, 0]}
    print(f"{'File':<50}{'Lines':>9}{'Functions':>11}{'Regions':>9}")
    for file in files:
        name = file["filename"].split(SOURCE_MARKER)[1]
        summary = file["summary"]
        cells = []
        for kind, total in totals.items():
            total[0] += summary[kind]["covered"]
            total[1] += summary[kind]["count"]
            cells.append(summary[kind]["percent"])
        print(f"{name:<50}{cells[0]:>8.1f}%{cells[1]:>10.1f}%{cells[2]:>8.1f}%")

    percent = {kind: 100 * covered / count if count else 100 for kind, (covered, count) in totals.items()}
    print(f"{'TOTAL':<50}{percent['lines']:>8.2f}%{percent['functions']:>10.2f}%{percent['regions']:>8.2f}%")
    print(
        f"Covered {totals['lines'][0]}/{totals['lines'][1]} lines, "
        f"{totals['functions'][0]}/{totals['functions'][1]} functions, "
        f"{totals['regions'][0]}/{totals['regions'][1]} regions."
    )

    missing = [(f["filename"].split(SOURCE_MARKER)[1], uncovered_lines(f)) for f in files]
    missing = [(name, lines) for name, lines in missing if lines]
    if missing:
        print("\nUncovered lines:")
        for name, lines in missing:
            print(f"  {name}: {compress(lines)}")

    if percent["lines"] < args.minimum:
        sys.exit(f"\nLine coverage {percent['lines']:.2f}% is below the required {args.minimum:.2f}%.")


if __name__ == "__main__":
    main()
