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

@test "get_command payload does not set a completion token limit" {
  source "$PLEASE_EXE"
  perform_openai_request() { message="ls -la"; }
  max_completion_tokens=64
  commandDescription="list files"
  get_command
  [ "$(printf '%s' "$payload" | jq 'has("max_completion_tokens")')" = "false" ]
  [ "$command" = "ls -la" ]
}

@test "truncated command warning does not suggest changing the explanation limit" {
  source "$PLEASE_EXE"
  curl() { printf '%s\n' '{"choices":[{"message":{"content":"ls"},"finish_reason":"length"}]}' '200'; }
  OPENAI_API_KEY=dummy
  commandDescription="list files"
  run get_command
  [ "$status" -eq 0 ]
  [[ "$output" == *"model response was cut off"* ]]
  [[ "$output" != *"PLEASE_MAX_COMPLETION_TOKENS"* ]]
}

@test "truncated explanation warning suggests changing the completion limit" {
  source "$PLEASE_EXE"
  curl() { printf '%s\n' '{"choices":[{"message":{"content":"list files"},"finish_reason":"length"}]}' '200'; }
  OPENAI_API_KEY=dummy
  command="ls"
  commandDescription="list files"
  run explain_command
  [ "$status" -eq 0 ]
  [[ "$output" == *"PLEASE_MAX_COMPLETION_TOKENS"* ]]
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
