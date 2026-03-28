#!/usr/bin/env bash
# Run News Genesis in Chrome. Copy dart_defines.json.example to dart_defines.json
# and put your real GEMINI_API_KEY so dubbing / translations work.
set -euo pipefail
cd "$(dirname "$0")"
if [[ -f dart_defines.json ]]; then
  exec flutter run -d chrome --dart-define-from-file=dart_defines.json "$@"
else
  echo "No dart_defines.json — running without Gemini (dubbing disabled)."
  echo "Copy dart_defines.json.example to dart_defines.json and add your key."
  exec flutter run -d chrome "$@"
fi
