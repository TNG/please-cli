#!/usr/bin/env bats

PLEASE_EXE=$BATS_TEST_DIRNAME/../please.sh

setup() {
  STUB_DIR="$(mktemp -d)"
  export STUB_DIR
}

teardown() {
  rm -rf "$STUB_DIR"
}

make_secret_tool_stub() {
  cat > "$STUB_DIR/secret-tool" <<'STUB'
#!/bin/bash
STORE="${STUB_DIR}/stored"
if [ "$1" = "store" ]; then
  cat > "$STORE"
  exit "${SC_EXIT:-0}"
fi
if [ "$1" = "lookup" ] && [ -f "$STORE" ]; then
  cat "$STORE"
fi
STUB
  chmod +x "$STUB_DIR/secret-tool"
}

# store_api_key branches on the readonly OSTYPE, so the Linux path can only
# execute on Linux. CI (ubuntu-latest) runs these; macOS dev machines skip.
requires_linux() {
  if [ "$(uname -s)" != "Linux" ]; then
    skip "store_api_key's Linux branch is only reachable on Linux"
  fi
}

@test "store_api_key succeeds and reports success when secret-tool works" {
  requires_linux
  make_secret_tool_stub
  run env STUB_DIR="$STUB_DIR" PATH="$STUB_DIR" bash -c "source '$PLEASE_EXE'; printf 'y\n\nsk-test-123\n' | store_api_key"
  [ "$status" -eq 0 ]
  [[ "$output" == *"API key stored successfully"* ]]
  [ -s "$STUB_DIR/stored" ]
}

@test "store_api_key fails clearly when secret-tool is not installed" {
  requires_linux
  run env PATH="$STUB_DIR" bash -c "source '$PLEASE_EXE'; printf 'y\n\nsk-test-123\n' | store_api_key"
  [ "$status" -eq 1 ]
  [[ "$output" == *"secret-tool is not installed"* ]]
}

@test "store_api_key fails clearly when secret-tool store fails" {
  requires_linux
  make_secret_tool_stub
  run env SC_EXIT=1 STUB_DIR="$STUB_DIR" PATH="$STUB_DIR" bash -c "source '$PLEASE_EXE'; printf 'y\n\nsk-test-123\n' | store_api_key"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not store the API key"* ]]
  [[ "$output" != *"API key stored successfully"* ]]
}
