#!/bin/sh
set -eu

self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$self_dir/java-extraction/run-case.sh" basic_arithmetic
"$self_dir/java-extraction/run-case.sh" list_reverse
"$self_dir/java-extraction/run-case.sh" match_failure
"$self_dir/java-extraction/run-case.sh" match_default
"$self_dir/java-extraction/run-case.sh" absurd_match
"$self_dir/java-extraction/run-case.sh" axiom
"$self_dir/java-extraction/run-case.sh" mldummy
"$self_dir/java-extraction/run-case.sh" local_fix
"$self_dir/java-extraction/run-case.sh" fix0
"$self_dir/java-extraction/run-case.sh" poly_list
"$self_dir/java-extraction/run-case.sh" poly_head
"$self_dir/java-extraction/run-case.sh" poly_receiver
"$self_dir/java-extraction/run-case.sh" type_alias
"$self_dir/java-extraction/run-case.sh" type_alias_noexpand
"$self_dir/java-extraction/run-case.sh" corelib_list
"$self_dir/java-extraction/run-case.sh" type_custom
