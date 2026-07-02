#!/bin/sh
set -eu

case_name=${1:?"usage: $0 <case>"}

self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test_suite_dir=$(CDPATH= cd -- "$self_dir/../.." && pwd)

case_file="misc/java-extraction/$case_name.v"
expected_dir="misc/java-extraction/$case_name"
generated_dir="misc/java-extraction/_generated/$case_name"
classes_dir="misc/java-extraction/_classes/$case_name"
case_base="misc/java-extraction/$case_name"

cd "$test_suite_dir"

if [ ! -f "$case_file" ]; then
  printf 'missing Java extraction case: %s\n' "$case_file" >&2
  exit 1
fi

if [ ! -d "$expected_dir" ]; then
  printf 'missing Java extraction expected directory: %s\n' "$expected_dir" >&2
  exit 1
fi

cleanup() {
  rm -rf "$generated_dir" "$classes_dir"
  rmdir "misc/java-extraction/_generated" "misc/java-extraction/_classes" 2>/dev/null || true
  rm -f "$case_base.vo" "$case_base.vos" "$case_base.vok" \
        "$case_base.glob" "misc/java-extraction/.$case_name.aux"
}

run_coqc() {
  if [ "${coqc:-}" ]; then
    # The test-suite Makefile exports coqc as a shell command, including flags.
    eval "$coqc \"\$case_file\""
  elif [ -x "../_build/install/default/bin/rocq" ] &&
       [ -f "../_build/install/default/lib/coq/theories/Init/Prelude.vo" ]; then
    "../_build/install/default/bin/rocq" c -q -R prerequisite TestSuite "$case_file"
  else
    printf 'missing built Rocq; run through test-suite Makefile after building this checkout\n' >&2
    exit 1
  fi
}

check_generated_files() {
  found_expected=false
  for expected in "$expected_dir"/*.java.expected; do
    if [ ! -f "$expected" ]; then
      continue
    fi
    found_expected=true
    generated="$generated_dir/$(basename "$expected" .expected)"
    if [ ! -f "$generated" ]; then
      printf 'missing generated Java file: %s\n' "$generated" >&2
      exit 1
    fi
    diff -u "$expected" "$generated"
  done

  if [ "$found_expected" = false ]; then
    printf 'no expected Java files found in: %s\n' "$expected_dir" >&2
    exit 1
  fi

  found_generated=false
  for generated in "$generated_dir"/*.java; do
    if [ ! -f "$generated" ]; then
      continue
    fi
    found_generated=true
    expected="$expected_dir/$(basename "$generated").expected"
    if [ ! -f "$expected" ]; then
      printf 'missing expected Java file: %s\n' "$expected" >&2
      exit 1
    fi
  done

  if [ "$found_generated" = false ]; then
    printf 'no generated Java files found in: %s\n' "$generated_dir" >&2
    exit 1
  fi
}

driver_classes() {
  for source in "$expected_dir"/*.java; do
    if [ ! -f "$source" ]; then
      continue
    fi
    if grep -q 'public static void main' "$source"; then
      basename "$source" .java
    fi
  done
}

compile_and_run_generated_files() {
  for generated in "$generated_dir"/*.java; do
    class_output="$classes_dir/$(basename "$generated" .java)"
    mkdir -p "$class_output"
    set -- "$generated"
    for source in "$expected_dir"/*.java; do
      if [ -f "$source" ]; then
        set -- "$@" "$source"
      fi
    done
    javac -d "$class_output" "$@"
    for driver in $(driver_classes); do
      java -cp "$class_output" "$driver"
    done
  done
}

trap cleanup EXIT INT TERM

cleanup
mkdir -p "$generated_dir" "$classes_dir"

run_coqc

check_generated_files
compile_and_run_generated_files

cleanup
