# Please CLI

An AI helper script to create CLI commands.

## Usage

```bash
./please <command>
```
This will call GPT to generate a Linux command based on your input.

```bash
./please list all files smaller than 1MB in the current folder, \
         sort them by size and show their name and line count
🔡 Command:
  find . -maxdepth 1 -type f -size -1M -exec wc -l {} + | sort -n -k1

❗ What should I do? [use arrow keys to navigate]
> Execute
  Copy to clipboard
  Cancel
```

### Parameters
- `-e` or `--explanation` will explain the command for you
- `-l` or `--legacy` will use the GPT3.5 AI model instead of GPT4 (in case you don't have API access to GPT4)
- `-h` or `--help` will show the help message
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
chmod +x /usr/local/bin/please

# Install jq and (if on Linux) secret-tool as well as xclip using the package manager of your choice
```

## Prerequisites

You need an OpenAI API key. You can get one here: https://beta.openai.com/

The API key needs to be set:
- either via an environment variable `OPENAI_API_KEY`
- via a keychain entry `OPENAI_API_KEY` (MacOS keychain and secret-tool on Linux are supported)

To set the API key via an environment variable, run

```bash
export OPENAI_API_KEY=<YOUR_API_KEY>
```

To store your API key using secret-tool, run

```bash
secret-tool store --label="OpenAI API Key" OPENAI_API_KEY <YOUR_API_KEY>
```

To store your API key using MacOS keychain, run

```bash
security add-generic-password -a <YOUR_API_KEY> -s OPENAI_API_KEY -w
```

## License

Please CLI is published under the Apache License 2.0, see http://www.apache.org/licenses/LICENSE-2.0 for details.
