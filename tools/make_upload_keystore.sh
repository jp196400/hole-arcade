#!/bin/sh
# Create the Play upload key ONCE, on your own machine. Do not commit it.
# Do not run this inside GitHub Actions. The private key must not be an artifact.
#
# Required environment variables:
#   ANDROID_KEYSTORE_PASSWORD
#   ANDROID_KEY_PASSWORD   (use the same value; Godot 4.3 has one release password field)
#
# Usage:
#   ANDROID_KEYSTORE_PASSWORD='...' ANDROID_KEY_PASSWORD='...' ./tools/make_upload_keystore.sh
set -eu
out="${1:-hole-arcade-upload.keystore}"
alias_name="${2:-holearcade}"
if [ -z "${ANDROID_KEYSTORE_PASSWORD:-}" ] || [ -z "${ANDROID_KEY_PASSWORD:-}" ]; then
  echo "Set ANDROID_KEYSTORE_PASSWORD and ANDROID_KEY_PASSWORD first." >&2
  exit 1
fi
if [ "$ANDROID_KEYSTORE_PASSWORD" != "$ANDROID_KEY_PASSWORD" ]; then
  echo "Use the same password for the store and the key. Godot 4.3 stores one release password." >&2
  exit 1
fi
if [ -e "$out" ]; then
  echo "Refusing to overwrite $out" >&2
  exit 1
fi
keytool -genkeypair -v \
  -keystore "$out" \
  -alias "$alias_name" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$ANDROID_KEYSTORE_PASSWORD" \
  -keypass "$ANDROID_KEY_PASSWORD" \
  -dname "CN=Hole Arcade, OU=Hole Arcade, O=Hole Arcade, L=Unknown, ST=Unknown, C=US"
echo "Created $out"
echo "Add these GitHub Actions secrets on jp196400/hole-arcade (Settings, Secrets and variables, Actions):"
echo "  ANDROID_KEYSTORE_BASE64   (base64, one line, of $out)"
echo "  ANDROID_KEYSTORE_PASSWORD"
echo "  ANDROID_KEY_ALIAS=$alias_name"
echo "  ANDROID_KEY_PASSWORD"
echo "Keep a backup of $out. Play App Signing can reset an upload key, but losing it blocks updates until Google approves a reset."
