#!/usr/bin/env bash
# Writes ios/Config/Secrets.xcconfig from CI secrets (docs/CONTRACTS.md §2).
# Values that are unset keep the defaults from Secrets.example.xcconfig. Never prints values.
set -euo pipefail

out=ios/Config/Secrets.xcconfig
: > "$out"

# xcconfig treats "//" as a comment start; escape it as "/$()/".
esc() { printf '%s' "$1" | sed 's#//#/$()/#g'; }

[ -n "${ONEPASS_SERVER_URL:-}" ] && echo "ONEPASS_SERVER_URL = $(esc "$ONEPASS_SERVER_URL")" >> "$out"
[ -n "${ONEPASS_APP_TOKEN:-}" ] && echo "ONEPASS_APP_TOKEN = $(esc "$ONEPASS_APP_TOKEN")" >> "$out"
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then
  echo "GOOGLE_CLIENT_ID_PREFIX = ${GOOGLE_CLIENT_ID%.apps.googleusercontent.com}" >> "$out"
fi
[ -n "${MICROSOFT_CLIENT_ID:-}" ] && echo "MICROSOFT_CLIENT_ID = $MICROSOFT_CLIENT_ID" >> "$out"
[ -n "${REVENUECAT_API_KEY:-}" ] && echo "REVENUECAT_API_KEY = $REVENUECAT_API_KEY" >> "$out"

echo "Secrets.xcconfig keys: $(cut -d' ' -f1 "$out" | tr '\n' ' ')"
