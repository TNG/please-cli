#!/usr/bin/env bats

load $BATS_TEST_DIRNAME/../please.sh

@test "strip inline reasoning block" {
  input="<think>thinking here</think>echo 'hello world'"
  result=$(strip_reasoning "$input")
  [ "$result" == "echo 'hello world'" ]
}

@test "strip multiline reasoning block" {
  input="<think>
thinking here
more thinking
</think>
ls -la"
  result=$(strip_reasoning "$input")
  [ "$result" == "ls -la" ]
}