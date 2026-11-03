#!/bin/sh
# Runs the package's tests and reports coverage of its sources.
# usage: Scripts/coverage.sh [minimum-line-percent]
set -eu
cd "$(dirname "$0")/.."
swift test --enable-code-coverage
python3 Scripts/coverage.py "$(swift test --show-codecov-path)" --minimum "${1:-0}"
