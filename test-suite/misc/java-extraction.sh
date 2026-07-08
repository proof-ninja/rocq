#!/bin/sh
set -eu

self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$self_dir/java-extraction/run-case.sh" basic_arithmetic
"$self_dir/java-extraction/run-case.sh" list_reverse
"$self_dir/java-extraction/run-case.sh" local_fix
"$self_dir/java-extraction/run-case.sh" local_fix_mutual
