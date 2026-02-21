#!/usr/bin/env bash
set -euo pipefail

strict=0
if [[ "${1:-}" == "--strict" ]]; then
  strict=1
elif [[ -n "${1:-}" ]]; then
  echo "Unknown argument: $1" >&2
  echo "Usage: $0 [--strict]" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
project_root="$repo_root/commet"
pkgbuild="$project_root/linux/aur/PKGBUILD"
pubspec="$project_root/pubspec.yaml"
app_id="chat.commet.commetapp"

aur_pkg="commet-bin"
aur_rpc_url="https://aur.archlinux.org/rpc/v5/info/${aur_pkg}"
fdroid_metadata_url="https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/${app_id}.yml"

if [[ ! -f "$pkgbuild" || ! -f "$pubspec" ]]; then
  echo "Unable to locate project files. Run this script from inside the repository checkout." >&2
  exit 1
fi

local_pkgver="$(sed -n "s/^pkgver=//p" "$pkgbuild" | head -n1)"
local_version="$(sed -n 's/^version:[[:space:]]*//p' "$pubspec" | head -n1 | cut -d'+' -f1)"

if [[ -z "$local_pkgver" || -z "$local_version" ]]; then
  echo "Unable to parse local version metadata." >&2
  exit 1
fi

echo "Local packaging status"
echo "- PKGBUILD pkgver: $local_pkgver"
echo "- pubspec version: $local_version"

aur_matches_local=0
fdroid_matches_local=0

aur_response="$(curl -fsSL "$aur_rpc_url")"
aur_version="$(echo "$aur_response" | jq -r '.results[0].Version // empty' | cut -d- -f1)"
aur_found="$(echo "$aur_response" | jq -r '.resultcount // 0')"

if [[ "$aur_found" == "0" || -z "$aur_version" ]]; then
  echo "- AUR ($aur_pkg): not currently published"
else
  echo "- AUR ($aur_pkg): $aur_version"
  if [[ "$aur_version" == "$local_pkgver" ]]; then
    echo "  -> AUR version matches local PKGBUILD"
    aur_matches_local=1
  else
    echo "  -> AUR version differs from local PKGBUILD"
  fi
fi

fdroid_tmp="$(mktemp)"
if curl -fsSL "$fdroid_metadata_url" -o "$fdroid_tmp" 2>/dev/null; then
  fdroid_current_version="$(sed -n 's/^[[:space:]]*CurrentVersion:[[:space:]]*//p' "$fdroid_tmp" | head -n1)"
  if [[ -n "$fdroid_current_version" ]]; then
    echo "- F-Droid ($app_id): metadata exists (CurrentVersion: $fdroid_current_version)"
    if [[ "$fdroid_current_version" == "$local_version" ]]; then
      echo "  -> F-Droid metadata version matches local pubspec"
      fdroid_matches_local=1
    else
      echo "  -> F-Droid metadata version differs from local pubspec"
    fi
  else
    echo "- F-Droid ($app_id): metadata exists (CurrentVersion missing)"
  fi
else
  echo "- F-Droid ($app_id): metadata not found in fdroiddata yet"
fi
rm -f "$fdroid_tmp"

echo
echo "Next-step trackers"
echo "- AUR publish/update tracker (GHI #357): https://github.com/commetchat/commet/issues/357"
echo "- F-Droid submission tracker (GHI #115): https://github.com/commetchat/commet/issues/115"

if [[ "$strict" == "1" ]]; then
  if [[ "$aur_matches_local" != "1" || "$fdroid_matches_local" != "1" ]]; then
    echo "Strict mode failed: one or more publication targets are not in sync with local versions." >&2
    exit 2
  fi
fi
