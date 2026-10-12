#!/bin/bash
# Formats Dart and Kotlin files after Claude edits them. Never fails the edit.
f=$(cat | jq -r '.tool_input.file_path // empty')
case "$f" in
  *.dart)
    command -v dart >/dev/null && dart format "$f" >/dev/null 2>&1 ;;
  *.kt|*.kts)
    command -v ktlint >/dev/null && ktlint -F "$f" >/dev/null 2>&1 ;;
esac
exit 0
