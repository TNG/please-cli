#!/usr/bin/env bash

set -euo pipefail

model='gpt-4'
optionExecute="Execute"
optionCopy="Copy to clipboard"
optionCancel="Cancel"

explain=0

initialized=0
menu_state=1

yellow='\e[33m'
cyan='\e[36m'
black='\e[0m'

lightbulb="\xF0\x9F\x94\xA1"
exclamation="\xE2\x9D\x97"

check_key() {
  if [ -z "${OPENAI_API_KEY+x}" ]; then
    get_key_from_keychain
  fi
}


get_key_from_keychain() {
  local keyName="OPENAI_API_KEY"
  case "$(uname)" in
    Darwin*) # macOS
      key=$(security find-generic-password -w -s "${keyName}")
      exitStatus=$?
      ;;
    Linux*)
      # You need 'secret-tool' (part of libsecret-tools package)
      # Install it on Ubuntu/Debian with: sudo apt-get install libsecret-tools
      key=$(secret-tool lookup name "${keyName}")
      exitStatus=$?
      ;;
    *)
      echo "OPENAI_API_KEY not set and unable to find it in keychain."
      exit 1
      ;;
  esac

  if [ "${exitStatus}" -ne 0 ]; then
    echo "OPENAI_API_KEY not set and unable to find it in keychain."
    exit 1
  fi

  OPENAI_API_KEY="${key}"
}

check_args() {
  while [[ $# -gt 0 ]]; do
    case "${1}" in
      -e|--explanation)
        explain=1
        shift
        ;;
      -l|--legacy)
        model="gpt-3.5-turbo"
        shift
        ;;
      -h|--help)
        display_help
        exit 0
        ;;
      *)
        break
        ;;
    esac
  done

  # Save remaining arguments to a string
  commandDescription=""
  for arg in "$@"; do
    commandDescription+="$arg "
  done
}

display_help() {
  echo "Please - a simple script to translate your thoughts into command line commands using GPT"
  echo "Usage: $0 [options] [input]"
  echo
  echo "Options:"
  echo "  -e, --explanation    Explain the command to the user"
  echo "  -l, --legacy         Use GPT 3.5 (in case you do not have GPT4 API access)"
  echo "  -h, --help           Display this help message"
  echo
  echo "Input:"
  echo "  Any remaining arguments will be used as a input to be turned into a CLI command."
}

get_command() {
  role="You translate the input given into Linux command. You may not use natural language, but only a Linux commands as answer."
  prompt="${commandDescription}"

  payload="{
    \"model\": \"${model}\",
    \"messages\": [{\"role\": \"system\", \"content\": \"${role}\"}, {\"role\": \"user\", \"content\": \"${prompt}\"}]
  }"

  command=$(perform_openai_request)
}

explain_command() {
  prompt="Explain what the command ${command} does. Don't be too verbose."

  payload="{
    \"max_tokens\": 100,
    \"model\": \"${model}\",
    \"messages\": [{\"role\": \"user\", \"content\": \"${prompt}\"}]
  }"

  explanation=$(perform_openai_request)
}

perform_openai_request() {
  response=$(curl https://api.openai.com/v1/chat/completions \
       -s -w "\n%{http_code}" \
       -H "Content-Type: application/json" \
       -H "Authorization: Bearer ${OPENAI_API_KEY}" \
       -d "${payload}" \
       --silent)
  response=(${response[@]})
  httpStatus="${response[${#response[@]}-1]}"
  result=${response[@]::${#response[@]}-1}

  if [ "${httpStatus}" -ne 200 ]; then
    >&2 echo "Error: Received HTTP status ${httpStatus}"
    exit 1
  else
    message=$(echo "${result}" | jq '.choices[0].message.content' --raw-output)
    echo "${message}"
  fi
}

print_option() {
  printf "${lightbulb}${cyan}Command:${black}\n"
  echo "  ${command}"
  if [ "${explain}" -eq 1 ]; then
    echo ""
    echo "${explanation}"
  fi
  echo ""
  printf "${exclamation} ${yellow}What should I do? ${cyan}[use arrow keys to navigate]${black}\n"
}

choose_action() {
  while true; do
    display_menu

    read -rsn1 input
    # Check for arrow keys and 'Enter'
    case "$input" in $'\x1b')
        read -rsn1 tmp
        if [[ "$tmp" == "[" ]]; then
          read -rsn1 tmp
          case "$tmp" in
            "A") # Up arrow
              menu_state=$(( $menu_state - 1 % 3 ))
              ;;
            "B") # Down arrow
              menu_state=$(( $menu_state + 1 % 3 ))
              ;;
          esac
        fi
        ;;
      "") # 'Enter' key
        break
        ;;
    esac
  done
}

display_menu() {
  if [ $initialized -eq 1 ]; then
    # Go up three lines
    printf "\033[3A"
  else
    initialized=1
  fi

  if [ $menu_state -eq 1 ]; then
    echo "> $optionExecute"
    echo "  $optionCopy"
    echo "  $optionCancel"
  elif [ $menu_state -eq 2 ]; then
    echo "  $optionExecute"
    echo "> $optionCopy"
    echo "  $optionCancel"
  else
    echo "  $optionExecute"
    echo "  $optionCopy"
    echo "> $optionCancel"
  fi
}

act_on_action() {
  if [ "$menu_state" -eq 1 ]; then
    echo "Executing ..."
    echo ""
    execute_command
  elif [ "$menu_state" -eq 2 ]; then
    echo "Copying to clipboard ..."
    copy_to_clipboard
  else
    exit 0
  fi
}

execute_command() {
    eval "${command}"
}

copy_to_clipboard() {
  case "$(uname)" in
    Darwin*) # macOS
      echo -n "${command}" | pbcopy
      ;;
    Linux*)
      if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        echo -n "${command}" | wl-copy --primary
      else
        echo -n "${command}" | xclip -selection clipboard
      fi
      ;;
    *)
      echo "Unsupported operating system"
      exit 1
      ;;
  esac
}

check_key
check_args "${@}"

get_command
if [ "${explain}" -eq 1 ]; then
  explain_command
fi

print_option
choose_action
act_on_action
