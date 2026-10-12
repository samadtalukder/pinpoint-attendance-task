#!/bin/bash
# Blocks edits to signing and local config files.
FILE_PATH=$(cat | jq -r '.tool_input.file_path // empty')
FILE_PATH="${FILE_PATH//\\//}"

for p in ".jks" "key.properties" "local.properties" ".env" ".git/"; do
  if [[ "$FILE_PATH" == *"$p"* ]]; then
    echo "Blocked: $FILE_PATH is protected ($p)" >&2
    exit 2
  fi
done
exit 0
