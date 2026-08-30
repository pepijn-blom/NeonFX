#!/usr/bin/env bats

load ../helpers/sandbox

setup() {
  setup_sandbox
  load_remove_if_ours
}

teardown() {
  teardown_sandbox
}

@test "remove_if_ours deletes a symlink that points at expected" {
  mkdir -p "$HOME/src" "$HOME/dest"
  echo ours >"$HOME/src/file"
  ln -s "$HOME/src/file" "$HOME/dest/file"
  remove_if_ours "$HOME/dest/file" "$HOME/src/file"
  [ ! -e "$HOME/dest/file" ]
}

@test "remove_if_ours leaves a regular file in place" {
  mkdir -p "$HOME/src" "$HOME/dest"
  echo ours >"$HOME/src/file"
  echo foreign >"$HOME/dest/file"
  remove_if_ours "$HOME/dest/file" "$HOME/src/file"
  [ -f "$HOME/dest/file" ]
  [ "$(cat "$HOME/dest/file")" = "foreign" ]
}

@test "remove_if_ours leaves a symlink pointing elsewhere" {
  mkdir -p "$HOME/src" "$HOME/other" "$HOME/dest"
  echo ours >"$HOME/src/file"
  echo other >"$HOME/other/file"
  ln -s "$HOME/other/file" "$HOME/dest/file"
  remove_if_ours "$HOME/dest/file" "$HOME/src/file"
  [ -L "$HOME/dest/file" ]
  [ "$(readlink -f "$HOME/dest/file")" = "$(readlink -f "$HOME/other/file")" ]
}
