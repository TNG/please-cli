#!/usr/bin/env bats

PLEASE_EXE=$BATS_TEST_DIRNAME/../please.sh

@test "smoke test please --help" {
  result=$($PLEASE_EXE '--help')
  [ "${result:0:6}" == "Please" ]
}

@test "smoke test please --version" {
  result=$($PLEASE_EXE '--version')
  [ "${result:0:8}" == "Please v" ]
}