#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
project_root="$repo_root/commet"
fdroid_dir="$project_root/android/fdroid"
pubspec="$project_root/pubspec.yaml"
default_apk="$project_root/build/app/outputs/flutter-apk/app-release.apk"
output_path="$fdroid_dir/submission_template.md"

if [[ ! -f "$pubspec" ]]; then
  echo "Unable to find pubspec.yaml at $pubspec" >&2
  exit 1
fi

version="$(sed -n 's/^version:[[:space:]]*//p' "$pubspec" | head -n1)"
if [[ -z "$version" ]]; then
  echo "Unable to determine app version from pubspec.yaml" >&2
  exit 1
fi

apk_path="${1:-$default_apk}"
apk_sha_note="APK SHA-256: not provided (build the APK and re-run this script with its path)."

if [[ -f "$apk_path" ]]; then
  apk_sha="$(sha256sum "$apk_path" | awk '{print $1}')"
  apk_sha_note="APK SHA-256: $apk_sha"
fi

cat > "$output_path" <<TEMPLATE
# F-Droid metadata update template

Use this text when opening/updating the upstream F-Droid metadata PR/issue.

- Repository: https://github.com/commetchat/commet
- License: AGPL-3.0-only
- Latest version: $version
- Android build command:
  - \
    ./scripts/build_fdroid_release.sh
- Reproducibility notes:
  - Flutter release build
  - Dart defines: PLATFORM=android, BUILD_MODE=release, BUILD_DETAIL=fdroid
- $apk_sha_note

## Additional reviewer notes

- Google services integration remains opt-in and disabled by default in this repo.
- Verify app startup/login flow on a Google-free Android test environment.
TEMPLATE

echo "Wrote F-Droid submission template to $output_path"
