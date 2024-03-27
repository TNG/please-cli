#!/usr/bin/env bash

set -uo pipefail

CONFIG_FILE="${HOME}/.pleaserc"
. $CONFIG_FILE 2>/dev/null

model='gpt-4'
options=("[I] Invoke" "[C] Copy to clipboard" "[Q] Ask a question" "[A] Abort" )
number_of_options=${#options[@]}
keyName="OPENAI_API_KEY"

explain=0
debug_flag=0

initialized=0
selected_option_index=-1

yellow='\e[33m'
cyan='\e[36m'
black='\e[0m'

lightbulb="\xF0\x9F\x92\xA1"
exclamation="\xE2\x9D\x97"
questionMark="\x1B[31m?\x1B[0m"
checkMark="\x1B[31m\xE2\x9C\x93\x1B[0m"

openai_invocation_url=${OPENAI_URL:-"https://api.openai.com/v1"}
openai_use_azure_endpoint=${OPENAI_URL:+1} # if OPENAI_URL is set, we assume it is an Azure endpoint
fail_msg="echo 'I do not know. Please rephrase your question.'"

declare -a qaMessages=()

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
      --debug)
        debug_flag=1
        shift
        ;;
      -a|--api-key)
        store_api_key
        exit 0
        ;;
      -H|--api-host)
        store_api_host
        exit 0
        ;;
      -m|--model)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ] && [ "${2:0:3}" == "gpt" ]; then
          model="$2"
          shift 2
        else
          echo "Error: --model requires a gpt model"
          exit 1
        fi
        ;;
      -v|--version)
        display_version
        exit 0
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
  commandDescription="$*"
}

# Write a configuration to disk
#
# Parameters:
#   config - The name of the configuration
#   value - The value to be set for the configuration
#
# Returns:
#   0 - If the configuration value was successfully written
#   1 - config_key or config_value is empty
function write_config() {
    config_key=$1
    [ -z $config_key ] && return 1
    config_value=$2
    [ -z $config_value ] && return 1

    [ -f $CONFIG_FILE ] || touch $CONFIG_FILE

    sed -i.bak -e "s/^${config_key}=.*\$/${config_key}=${config_value//\//\\/}/w /dev/stdout" $CONFIG_FILE | grep -q .
    if [ $? -ne 0 ]; then
        echo "${config_key}=${config_value}" >>$CONFIG_FILE
    fi
    rm "$CONFIG_FILE.bak" # .bak file is created for sed to be compatible with both GNU and BSD sed
}

function store_api_key() {
    echo "Do you want the script to store an API key in the local keychain? (y/n)"
    read -r answer

    if [ "$answer" != "y" ]; then
        echo "This script will need an API Key to run. Exiting..."
        exit 1
    fi

    if [ "${openai_use_azure_endpoint}" -eq 0 ]; then
        echo "The script needs to create or copy the API key. Press Enter to continue..."
        read -rs

        apiKeyUrl="https://platform.openai.com/account/api-keys"
        echo "Opening ${apiKeyUrl} in your browser..."
        open "${apiKeyUrl}" || xdg-open "${apiKeyUrl}"
    fi

    while true; do
        echo "Please enter your API key: [Press Ctrl+C to exit]"
        read -rs apiKey

        if [ -z "$apiKey" ]; then
            echo "API key cannot be empty. Please try again."
        else
            if [[ "$OSTYPE" == "darwin"* ]]; then
                security add-generic-password -a "${USER}" -s "${keyName}" -w "${apiKey}" -U
                OPENAI_API_KEY=$(security find-generic-password -a "${USER}" -s "${keyName}" -w)
            else
                echo -e "${apiKey}" | secret-tool store --label="${keyName}" username "${USER}" key_name "${keyName}"
                OPENAI_API_KEY=$(secret-tool lookup username "${USER}" key_name "${keyName}")
            fi
            echo "API key stored successfully and set as a global variable."
            break
        fi
    done
}

function store_api_host() {
  echo "Setting up Azure OpenAPI host."

  while true; do
    echo "Please enter your Endpoint: [Press Ctrl+C to exit]"
    read -r endpoint

    if [ -z "$endpoint" ]; then
      echo "Endpoint cannot be empty. Please try again."
    else
      endpoint=${endpoint%/}
      break
    fi
  done

  while true; do
    echo "Please enter your Deployment Name: [Press Ctrl+C to exit]"
    read -r deployment_id

    if [ -z "$deployment_id" ]; then
      echo "Deployment Name cannot be empty. Please try again."
    else
      break
    fi
  done

  write_config "OPENAI_URL" "${endpoint}/openai/deployments/${deployment_id}"
}

display_version() {
  echo "Please vVERSION_NUMBER"
}

display_help() {
  echo "Please - a simple script to translate your thoughts into command line commands using GPT"
  echo "Usage: $0 [options] [input]"
  echo
  echo "Options:"
  echo "  -e, --explanation    Explain the command to the user"
  echo "  -l, --legacy         Use GPT 3.5 (in case you do not have GPT4 API access)"
  echo "      --debug          Show debugging output"
  echo "  -a, --api-key        Store your API key in the local keychain"
  echo "  -H, --api-host       Store your Azure OpenAPI host"
  echo "  -m, --model          Specify the exact LLM model for the script"
  echo "  -v, --version        Display version information and exit"
  echo "  -h, --help           Display this help message and exit"
  echo
  echo "Input:"
  echo "  The remaining arguments are used as input to be turned into a CLI command."
  echo
  echo "OpenAI API Key:"
  echo "  The API key needs to be set as OPENAI_API_KEY environment variable or keychain entry. "
}


debug() {
    if [ "$debug_flag" = 1 ]; then
        echo "DEBUG: $1" >&2
    fi
}

check_key() {
  if [ -z "${OPENAI_API_KEY+x}" ]; then
    debug "OPENAI_API_KEY environment variable not set, trying to find it in keychain"
    get_key_from_keychain
  fi
}


get_key_from_keychain() {
  case "$(uname)" in
    Darwin*) # macOS
      key=$(security find-generic-password -a "${USER}" -s "${keyName}" -w)
      exitStatus=$?
      ;;
    Linux*)
      if ! command -v secret-tool &> /dev/null; then
        debug "OPENAI_API_KEY not set and secret-tool not installed. Install it with 'sudo apt install libsecret-tools'."
        exitStatus=1
      else
        key=$(secret-tool lookup username "${USER}" key_name "${keyName}")
        exitStatus=$?
      fi
      ;;
    *)
      debug "OPENAI_API_KEY not set and no supported keychain available."
      exitStatus=1
      ;;
  esac

  if [ "${exitStatus}" -ne 0 ]; then
    echo "OPENAI_API_KEY not set and unable to find it in keychain. See the README on how to persist your key."
    echo "You can get an API at https://beta.openai.com/"
    echo "Please enter your OpenAI API key now to use it this time only, or rerun 'please -a' to store it in the keychain."
    echo "Your API Key:"
    read -r key
  fi

  if [ -z "${key}" ]; then
    echo "No API key provided. Exiting."
    exit 1
  fi
  OPENAI_API_KEY="${key}"
}

get_command() {
  role="You translate the given input into a Linux command. You may not use natural language, but only a Linux shell command as an answer.
  Do not use markdown. Do not quote the whole output. If you do not know the answer, answer with \\\"${fail_msg}\\\"."

  payload=$(printf %s "$commandDescription" | jq --slurp --raw-input --compact-output '{
    model: "'"$model"'",
    messages: [{ role: "system", content: "'"$role"'" }, { role: "user", content: . }]
  }')

  debug "Sending request to OpenAI API: ${payload}"

  perform_openai_request
  command="${message}"
}

explain_command() {
  if [ "${command}" = "$fail_msg" ]; then
    explanation="There is no explanation because there was no answer."
  else
    prompt="Explain the step of the command that answers the following ${command}: ${commandDescription}\n. Be precise and succinct."

    payload=$(printf %s "$prompt" | jq --slurp --raw-input --compact-output '{
      max_tokens: 100,
      model: "'"$model"'",
      messages: [{ role: "user", content: . }]
    }')

    perform_openai_request
    explanation="${message}"
  fi
}

perform_openai_request() {
  if [ "${openai_use_azure_endpoint:-0}" -eq 1 ]; then
    endpoint="${openai_invocation_url}/chat/completions?api-version=2023-05-15"
    authorization="api-key: ${OPENAI_API_KEY}"
  else
    endpoint="${openai_invocation_url}/chat/completions"
    authorization="Authorization: Bearer ${OPENAI_API_KEY}"
  fi

  IFS=$'\n' read -r -d '' -a result < <(curl "${endpoint}" \
      -s -w "\n%{http_code}" \
      -H "Content-Type: application/json" \
      -H "${authorization}" \
      -d "${payload}" \
      --silent)
  debug "Response:\n${result[*]}"
  length="${#result[@]}"
  httpStatus="${result[$((length-1))]}"

  length="${#result[@]}"
  response_array=("${result[*]:0:$((length-1))}")
  response="${response_array[*]}"

  if [ "${httpStatus}" -ne 200 ]; then
    echo "Error: Received HTTP status ${httpStatus}"
    echo "${response}" | jq .error.message --raw-output
    exit 1
  else
    message=$(echo "${response}" | jq '.choices[0].message.content' --raw-output)
  fi
}

print_option() {
  # shellcheck disable=SC2059
  printf "${lightbulb} ${cyan}Command:${black}\n"
  echo "  ${command}"
  if [ "${explain}" -eq 1 ]; then
    echo ""
    echo "${explanation}"
  fi
}

choose_action() {
  initialized=0
  selected_option_index=-1

  echo ""
  # shellcheck disable=SC2059
  printf "${exclamation} ${yellow}What should I do? ${cyan}[use arrow keys or initials to navigate]${black}\n"

  while true; do
    display_menu

    read -rsn1 input
    # Check for arrow keys and 'Enter'
    case "$input" in
      $'\x1b')
        read -rsn1 tmp
        if [[ "$tmp" == "[" ]]; then
          read -rsn1 tmp
          case "$tmp" in
            "D") # Right arrow
              selected_option_index=$(( (selected_option_index - 1 + number_of_options) % number_of_options ))
              ;;
            "C") # Left arrow
              selected_option_index=$(( (selected_option_index + 1) % number_of_options ))
              ;;
          esac
        fi
        ;;
      i)
        selected_option_index=0
        display_menu
        break
        ;;

      c)
        selected_option_index=1
        display_menu
        break
        ;;
      q)
        selected_option_index=2
        display_menu
        break
        ;;
      a)
        selected_option_index=3
        display_menu
        break
        ;;

      "") # 'Enter' key
        if [ "$selected_option_index" -ne -1 ]; then
          break
        fi
        ;;
    esac
  done
}

display_menu() {
  if [ $initialized -eq 1 ]; then
    # Go up 1 line
    printf "\033[%dA" "1"
  else
    initialized=1
  fi

  index=0
  for option in "${options[@]}"; do
    (( index == selected_option_index )) && marker="${cyan}>${black}" || marker=" "
    # shellcheck disable=SC2059
    printf "$marker $option "
    (( ++index ))
  done
  printf "\n"
}

act_on_action() {
  if [ "$selected_option_index" -eq 0 ]; then
    echo "Executing ..."
    echo ""
    execute_command
  elif [ "$selected_option_index" -eq 1 ]; then
    echo "Copying to clipboard ..."
    copy_to_clipboard
  elif [ "$selected_option_index" -eq 2 ]; then
    ask_question
  else
    exit 0
  fi
}

execute_command() {
    save_command_in_history
    eval "${command}"
}

save_command_in_history() {
  # Get the name of the shell
  shell=$(basename "$SHELL")

  # Determine the history file based on the shell
  case "$shell" in
      bash)
          histfile="${HISTFILE:-$HOME/.bash_history}"
          ;;
      zsh)
          histfile="${HISTFILE:-$HOME/.zsh_history}"
          ;;
      fish)
          # fish doesn't use HISTFILE, but uses a fixed location
          histfile="$HOME/.local/share/fish/fish_history"
          ;;
      ksh)
          histfile="${HISTFILE:-$HOME/.sh_history}"
          ;;
      tcsh)
          histfile="${HISTFILE:-$HOME/.history}"
          ;;
      *)
          ;;
  esac

  if [ -z "$histfile" ]; then
    debug "Could not determine history file for shell ${shell}"
  else
    debug "Saving command ${command} to file ${histfile}"
    echo "${command}" >> "${histfile}"
  fi
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
        if command -v xclip &> /dev/null; then
          echo -n "${command}" | xclip -selection clipboard
        else
          echo "xclip not installed. Exiting."
          exit 1
        fi
      fi
      ;;
    *)
      echo "Unsupported operating system"
      exit 1
      ;;
  esac
}

init_questions() {
  systemPrompt="You will give answers in the context of the command \"${command}\" which is a Linux bash command related to the prompt \"${commandDescription}\". Be precise and succinct, answer in full sentences, no lists, no markdown."
  escapedPrompt=$(printf %s "${systemPrompt}" | jq -srR '@json')

  qaMessages+=("{ \"role\": \"system\", \"content\": ${escapedPrompt} }")
}

ask_question() {
  echo ""
  # shellcheck disable=SC2059
  printf "${questionMark} ${cyan}What do you want to know about this command?${black}\n"
  read -r question
  answer_question_about_command

  echo "${answer}"

  # shellcheck disable=SC2059
  printf "${checkMark} ${answer}\n"

  choose_action
  act_on_action
}

answer_question_about_command() {
  prompt="${question}"
  escapedPrompt=$(printf %s "${prompt}" | jq -srR '@json')
  qaMessages+=("{ \"role\": \"user\", \"content\": ${escapedPrompt} }")

  if [ -z "${qaMessages+x}" ]; then
    messagesJson="[]"
  else
    messagesJson='['$(join_by , "${qaMessages[@]}")']'
  fi

  payload=$(jq --null-input --compact-output --argjson messagesJson "${messagesJson}" '{
    max_tokens: 200,
    model: "'"$model"'",
    messages: $messagesJson
  }')

  perform_openai_request

  answer="${message}"
  escapedAnswer=$(printf %s "$answer" | jq -srR '@json')
  qaMessages+=("{ \"role\": \"assistant\", \"content\": ${escapedAnswer} }")
}

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

if [ $# -eq 0 ]; then
  input=("-h")
else
  input=("$@")
fi

check_args "${input[@]}"
check_key

get_command
if [ "${explain}" -eq 1 ]; then
  explain_command
fi

print_option

if test "${command}" = "${fail_msg}"; then
  exit 1
fi

init_questions
choose_action
act_on_action
