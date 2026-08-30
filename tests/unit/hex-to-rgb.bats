#!/usr/bin/env bats

load ../helpers/sandbox

setup() {
  load_hex_to_rgb
}

@test "hex_to_rgb converts #00f5ff" {
  run hex_to_rgb "#00f5ff"
  [ "$status" -eq 0 ]
  [ "$output" = "0 245 255" ]
}

@test "hex_to_rgb converts #ff0099 without a hash" {
  run hex_to_rgb "ff0099"
  [ "$status" -eq 0 ]
  [ "$output" = "255 0 153" ]
}

@test "hex_to_rgb converts #0c0018" {
  run hex_to_rgb "#0c0018"
  [ "$status" -eq 0 ]
  [ "$output" = "12 0 24" ]
}
