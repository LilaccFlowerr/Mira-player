#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${MACOS_P12_BASE64:-}" || -z "${MACOS_SIGN_IDENTITY:-}" ]]; then
  echo 'Unsigned development build'
  exit 0
fi
keychain="${RUNNER_TEMP:-/tmp}/mira-sign.keychain-db"
p12="${RUNNER_TEMP:-/tmp}/mira-sign.p12"
password="$(openssl rand -hex 24)"
cleanup() { security delete-keychain "$keychain" >/dev/null 2>&1 || true; rm -f "$p12"; }
trap cleanup EXIT
printf '%s' "$MACOS_P12_BASE64" | base64 --decode > "$p12"
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$p12" -P "$MACOS_P12_PASSWORD" -A -t cert -f pkcs12 -k "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" "$HOME/Library/Keychains/login.keychain-db"
security set-key-partition-list -S apple-tool:,apple: -s -k "$password" "$keychain" >/dev/null
macdeployqt stage/mira.app "-qmldir=$PWD/qml" "-sign-for-notarization=$MACOS_SIGN_IDENTITY"
codesign --verify --deep --strict stage/mira.app
if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  ditto -c -k --keepParent stage/mira.app "${RUNNER_TEMP}/mira-notary.zip"
  xcrun notarytool submit "${RUNNER_TEMP}/mira-notary.zip" --apple-id "$APPLE_ID" --password "$APPLE_APP_PASSWORD" --team-id "$APPLE_TEAM_ID" --wait
  xcrun stapler staple stage/mira.app
fi
