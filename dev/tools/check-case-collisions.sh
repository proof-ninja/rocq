#!/usr/bin/env bash

# Usage: check-case-collisions.sh
# Detect tracked paths (files or directories) that differ only in case.
# Such paths cannot be checked out on case-insensitive file systems
# (macOS, Windows), so this check stands in for building on them.
# Exit status: 1 if any collision is found, 0 otherwise.

set -euo pipefail
export LC_ALL=C

cd "$(git rev-parse --show-toplevel)"

# Tracked files plus every ancestor directory, so that e.g. Foo/a and foo/b
# are reported as a collision of Foo and foo.
paths=$(git ls-files -z | tr '\0' '\n' | awk '{
  print
  n = split($0, parts, "/")
  dir = parts[1]
  for (i = 2; i <= n; i++) { print dir; dir = dir "/" parts[i] }
}' | sort -u)

clashes=$(printf '%s\n' "$paths" | tr '[:upper:]' '[:lower:]' | sort | uniq -d)

if [ -n "$clashes" ]; then
  echo "Tracked paths differing only in case:"
  printf '%s\n' "$paths" | awk 'NR == FNR { clash[$0]; next } tolower($0) in clash' \
    <(printf '%s\n' "$clashes") -
  exit 1
fi
