# Please CLI

An AI helper script to create CLI commands.

## Usage

```bash
./please.sh <command>
```
This will call GPT to generate a Linux command based on your input.

```bash
./please.sh list all files smaller than 1MB in the current folder, sort them by size and show their name and line count
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

## Prerequisites

You need an OpenAI API key. You can get one here: https://beta.openai.com/

The API key needs to be set:
- either via an environment variable `OPENAI_API_KEY`
- via a keychain entry `OPENAI_API_KEY` (MacOS keychain and secret-tool on Linux are supported)

## License

Please CLI is published under the Apache License 2.0, see http://www.apache.org/licenses/LICENSE-2.0 for details.

