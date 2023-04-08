# Please CLI by TNG Technology Consulting

An [AI helper script to create CLI commands](https://github.com/TNG/please-cli/).

## Usage

```bash
please <command description>
```
This will call GPT to generate a Linux command based on your input.

### Examples

![Demo](resources/demo.gif)

```bash
please list all files smaller than 1MB in the current folder, \
         sort them by size and show their name and line count
💡 Command:
  find . -maxdepth 1 -type f -size -1M -exec wc -l {} + | sort -n -k1'

❗ What should I do? [use arrow keys to navigate]
> [I] Invoke   [C] Copy to clipboard   [A] Abort
```

### Parameters
- `-e` or `--explanation` will explain the command for you
- `-l` or `--legacy` will use the GPT3.5 AI model instead of GPT4 (in case you don't have API access to GPT4)
- `--debug` will display additional output
- `-a` or `--api-key` will store your API key in the local keychain
- `-v` or `--version` will show the current version
- `-h` or `--help` will show the help message

## Installation

Using Homebrew (ugrades will be available via `brew upgrade please`)

```
brew tap TNG/please
brew install please
```

Using apt (upgrades will be available via `apt upgrade please`)

```bash
curl -sS https://tng.github.io/apt-please/public_key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/please.gpg > /dev/null
echo "deb https://tng.github.io/apt-please/ ./" | sudo tee -a /etc/apt/sources.list
sudo apt-get update

sudo apt-get install please
```

Using dpkg (manual upgrades)

```bash
wget https://tng.github.io/apt-please/please.deb
sudo dpkg -i please.deb
sudo apt-get install -f
```

Just copying the script (manual upgrades)

```bash
wget https://raw.githubusercontent.com/TNG/please-cli/main/please.sh
sudo cp please.sh /usr/local/bin/please
sudo chmod +x /usr/local/bin/please

# Install jq and (if on Linux) secret-tool as well as xclip using the package manager of your choice
```

## Prerequisites

You need an OpenAI API key. You can get one here: https://beta.openai.com/. Once logged in, click your account in 
the top right corner and select "View API Keys". You can then create a new key using the "Create new secret key" button.

The API key needs to be set:
- either via an environment variable `OPENAI_API_KEY`,
- or via a keychain entry `OPENAI_API_KEY` (macOS keychain and secret-tool on Linux are supported)

The easiest way to set the API Key is to use the `please` command  itself to do so:

```bash
please -a
```

This will set the API key in the keychain of your operating system (secret-tool on Linux, macOS keychain on MacOS).

You can also set the API key via an environment variable, run

```bash
export OPENAI_API_KEY=<YOUR_API_KEY>
```

To store your API key yourself using secret-tool, run

```bash
secret-tool store --label="OPENAI_API_KEY" username "${USER}" key_name OPENAI_API_KEY apiKey "${apiKey}"
```

To store your API key using macOS keychain, run

```bash
security add-generic-password -a "${USER}" -s OPENAI_API_KEY -w "${apiKey}"
```

## License

Please CLI is published under the Apache License 2.0, see http://www.apache.org/licenses/LICENSE-2.0 for details.

Copyright 2023 TNG Technology Consulting GmbH
