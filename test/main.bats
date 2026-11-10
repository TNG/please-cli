#!/usr/bin/env bats

PLEASE_EXE=$BATS_TEST_DIRNAME/../please.sh

@test "smoke test please --help" {
  result=$($PLEASE_EXE '--help')
  [ "${result:0:6}" == "Please" ]
}

@test "smoke test please --version" {
  result=$($PLEASE_EXE '--version')
  [ "${result:0:8}" == "Please v" ]
  [[ "${result}" != *"VERSION_NUMBER"* ]]
}

@test "version fallback derives version from git tags" {
  _latest_tag=$(cd "$BATS_TEST_DIRNAME/.." && git tag --sort=v:refname | tail -n1)
  if [ -z "$_latest_tag" ]; then
    skip "No git tags available"
  fi
  _latest_tag="${_latest_tag#v}"
  result=$($PLEASE_EXE '--version')
  [ "$result" == "Please v${_latest_tag}" ]
}