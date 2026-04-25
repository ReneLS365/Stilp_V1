#!/usr/bin/env bash
set -euo pipefail

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter is not installed or not on PATH." >&2
  echo "Install Flutter, then run this script again." >&2
  exit 1
fi

if [ ! -d "android" ]; then
  echo "Error: android/ directory is missing." >&2
  echo "Run: flutter create --platforms=android ." >&2
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build apk --release"
flutter build apk --release

echo "\nAPK built at: ${APK_PATH}"
