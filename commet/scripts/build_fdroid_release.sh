#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"

flutter build apk \
  --release \
  --dart-define PLATFORM=android \
  --dart-define BUILD_MODE=release \
  --dart-define BUILD_DETAIL=fdroid

echo "Built APK at: $project_root/build/app/outputs/flutter-apk/app-release.apk"
