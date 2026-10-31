#!/usr/bin/env bats

PLEASE_EXE=$BATS_TEST_DIRNAME/../please.sh

@test "accepts a positive integer override" {
  run env PLEASE_MAX_COMPLETION_TOKENS=64 "$PLEASE_EXE" --version
  [ "$status" -eq 0 ]
}

@test "rejects a non-numeric override" {
  run env PLEASE_MAX_COMPLETION_TOKENS=abc "$PLEASE_EXE" --version
  [ "$status" -eq 1 ]
  [[ "$output" == *"must be a positive integer"* ]]
}

@test "rejects zero, negative, float, padded, and JSON-literal values" {
  for value in 0 -5 1.5 064 null; do
    run env PLEASE_MAX_COMPLETION_TOKENS="$value" "$PLEASE_EXE" --version
    [ "$status" -eq 1 ]
  done
}

@test "empty value falls back to the default" {
  run env PLEASE_MAX_COMPLETION_TOKENS= "$PLEASE_EXE" --version
  [ "$status" -eq 0 ]
}

@test "sourcing with an invalid value returns 1 but does not kill the shell" {
  result=$(PLEASE_MAX_COMPLETION_TOKENS=abc bash -c "source '$PLEASE_EXE' 2>&1; echo continued=\$?")
  [[ "$result" == *"must be a positive integer"* ]]
  [[ "$result" == *"continued=1"* ]]
}

@test "explain_command payload uses the default budget" {
  source "$PLEASE_EXE"
  perform_openai_request() { message="stub"; }
  command="ls -la"
  commandDescription="list files"
  explain_command
  [[ "$payload" == *'"max_completion_tokens":1000'* ]]
}

@test "explain_command payload honors the override" {
  source "$PLEASE_EXE"
  perform_openai_request() { message="stub"; }
  max_completion_tokens=64
  command="ls -la"
  commandDescription="list files"
  explain_command
  [[ "$payload" == *'"max_completion_tokens":64'* ]]
}

@test "answer_question_about_command payload honors the override" {
  source "$PLEASE_EXE"
  perform_openai_request() { message="stub"; }
  max_completion_tokens=64
  question="what does it do?"
  qaMessages+=("{ \"role\": \"user\", \"content\": \"what does it do?\" }")
  answer_question_about_command
  [[ "$payload" == *'"max_completion_tokens":64'* ]]
}
