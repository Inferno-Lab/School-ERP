#!/usr/bin/env bash
# Analyzer (errors and warnings only) plus the whole test suite. Run before every commit.
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(dart analyze lib test 2>&1 || true)
echo "$out" | tail -n 1
if echo "$out" | grep -E "^\s*(error|warning) -" ; then echo "analyze: fix the above"; exit 1; fi
flutter test
