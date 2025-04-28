#!/usr/bin/env bats

setup() {
  TESTDIR=$(mktemp -d) || { echo "Failed to create temporary directory"; exit 1; }
}

teardown() {
  if [[ -d "$TESTDIR" ]]; then
    rm -rf "$TESTDIR"
  fi
}

@test "Shows help with -h" {
  run bash ./nmsize.sh -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "Shows version with -V" {
  run bash ./nmsize.sh -V
  [ "$status" -eq 0 ]
  [[ "$output" == *"nmsize v"* ]]
}

@test "Fails on invalid directory" {
  run bash ./nmsize.sh /not/a/dir
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid directory"* ]]
}

@test "Finds node_modules and reports size" {
  mkdir -p "$TESTDIR/project/node_modules"
  dd if=/dev/zero of="$TESTDIR/project/node_modules/file" bs=1K count=10 >/dev/null 2>&1
  run bash ./nmsize.sh "$TESTDIR/project"
  [ "$status" -eq 0 ]
  [[ "$output" == *"node_modules"* ]]
  [[ "$output" == *"TOTAL"* ]]
}

@test "Ignores hidden directories by default" {
  mkdir -p "$TESTDIR/.hidden/node_modules"
  run bash ./nmsize.sh "$TESTDIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *".hidden/node_modules"* ]]
}

@test "Can include hidden directories with --ignore-dots false" {
  mkdir -p "$TESTDIR/.hidden/node_modules"
  run bash ./nmsize.sh "$TESTDIR" --ignore-dots false
  [ "$status" -eq 0 ]
  [[ "$output" == *".hidden/node_modules"* ]]
}

@test "Sorts by size descending with -s desc" {
  mkdir -p "$TESTDIR/a/node_modules" "$TESTDIR/b/node_modules"
  dd if=/dev/zero of="$TESTDIR/a/node_modules/file" bs=1K count=5 >/dev/null 2>&1
  dd if=/dev/zero of="$TESTDIR/b/node_modules/file" bs=1K count=10 >/dev/null 2>&1
  run bash ./nmsize.sh "$TESTDIR" -s desc
  [ "$status" -eq 0 ]
  [[ "$output" == *"b/node_modules"* ]]
}

@test "Sorts by size ascending with -s asc" {
  mkdir -p "$TESTDIR/a/node_modules" "$TESTDIR/b/node_modules"
  dd if=/dev/zero of="$TESTDIR/a/node_modules/file" bs=1K count=5 >/dev/null 2>&1
  dd if=/dev/zero of="$TESTDIR/b/node_modules/file" bs=1K count=10 >/dev/null 2>&1
  run bash ./nmsize.sh "$TESTDIR" -s asc
  [ "$status" -eq 0 ]
  first_a=$(echo "$output" | grep -n "a/node_modules" | cut -d':' -f1)
  first_b=$(echo "$output" | grep -n "b/node_modules" | cut -d':' -f1)
  [ "$first_a" -lt "$first_b" ]
}

@test "Sorts alphabetically with -s alpha" {
  mkdir -p "$TESTDIR/aaa/node_modules" "$TESTDIR/bbb/node_modules"
  touch "$TESTDIR/aaa/node_modules/file" "$TESTDIR/bbb/node_modules/file"
  run bash ./nmsize.sh "$TESTDIR" -s alpha
  [ "$status" -eq 0 ]
  first_aaa=$(echo "$output" | grep -n "aaa/node_modules" | cut -d':' -f1)
  first_bbb=$(echo "$output" | grep -n "bbb/node_modules" | cut -d':' -f1)
  [ "$first_aaa" -lt "$first_bbb" ]
}

@test "Limits output with -l option" {
  mkdir -p "$TESTDIR/a/node_modules" "$TESTDIR/b/node_modules" "$TESTDIR/c/node_modules"
  touch "$TESTDIR/a/node_modules/file" "$TESTDIR/b/node_modules/file" "$TESTDIR/c/node_modules/file"
  run bash ./nmsize.sh "$TESTDIR" -l 2
  [ "$status" -eq 0 ]
  count=$(echo "$output" | grep -E "^[^│]+│" | grep -c "node_modules")
  [ "$count" -le 2 ]
}

@test "Respects max depth with -d option" {
  mkdir -p "$TESTDIR/shallow/node_modules" "$TESTDIR/deep/subdir/node_modules"
  touch "$TESTDIR/shallow/node_modules/file" "$TESTDIR/deep/subdir/node_modules/file"
  run bash ./nmsize.sh "$TESTDIR" -d 2
  [ "$status" -eq 0 ]
  [[ "$output" == *"shallow/node_modules"* ]]
  [[ "$output" != *"deep/subdir/node_modules"* ]]
}

@test "Ignores patterns with -i option" {
  mkdir -p "$TESTDIR/include/node_modules" "$TESTDIR/vendor/node_modules"
  touch "$TESTDIR/include/node_modules/file" "$TESTDIR/vendor/node_modules/file"
  run bash ./nmsize.sh "$TESTDIR" -i vendor
  [ "$status" -eq 0 ]
  [[ "$output" == *"include/node_modules"* ]]
  [[ "$output" != *"vendor/node_modules"* ]]
}

@test "Can use multiple ignore patterns" {
  mkdir -p "$TESTDIR/keep/node_modules" "$TESTDIR/skip1/node_modules" "$TESTDIR/skip2/node_modules"
  touch "$TESTDIR/keep/node_modules/file" "$TESTDIR/skip1/node_modules/file" "$TESTDIR/skip2/node_modules/file" 
  run bash ./nmsize.sh "$TESTDIR" -i skip1 -i skip2
  [ "$status" -eq 0 ]
  [[ "$output" == *"keep/node_modules"* ]]
  [[ "$output" != *"skip1/node_modules"* ]]
  [[ "$output" != *"skip2/node_modules"* ]]
}

@test "Errors on invalid sort option" {
  run bash ./nmsize.sh -s invalid
  [ "$status" -ne 0 ]
  [[ "$output" == *"Error: sort option must be 'alpha', 'desc' or 'asc'"* ]]
}

@test "Handles deeply nested node_modules" {
  mkdir -p "$TESTDIR/a/b/c/d/e/node_modules"
  touch "$TESTDIR/a/b/c/d/e/node_modules/file"
  run bash ./nmsize.sh "$TESTDIR" -d 10
  [ "$status" -eq 0 ]
  [[ "$output" == *"a/b/c/d/e/node_modules"* ]]
}

@test "Works with long option format" {
  mkdir -p "$TESTDIR/project/node_modules"
  touch "$TESTDIR/project/node_modules/file"
  run bash ./nmsize.sh --depth 3 --sort alpha --limit 5 "$TESTDIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"node_modules"* ]]
}
