#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter is not installed or not on PATH." >&2
  echo "Install Flutter, then run this script again." >&2
  exit 1
fi

if [ ! -d "ios" ]; then
  echo "Error: ios/ directory is missing." >&2
  echo "Run: flutter create --platforms=ios ." >&2
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build ios --release"
flutter build ios --release

cat <<'NEXT_STEPS'

Build step completed.

Next local macOS/Xcode steps:
1) Open ios/Runner.xcworkspace in Xcode.
2) Configure Runner > Signing & Capabilities (Team + bundle id).
3) Product > Archive.
4) Organizer > Distribute App.
5) Upload to App Store Connect for TestFlight (recommended),
   or choose Ad Hoc distribution if your process requires it.
NEXT_STEPS
