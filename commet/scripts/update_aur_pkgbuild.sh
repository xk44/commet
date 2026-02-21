#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

version="$1"
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
aur_dir="$repo_root/commet/linux/aur"
pkgbuild="$aur_dir/PKGBUILD"

sed -i "s/^pkgver=.*/pkgver=$version/" "$pkgbuild"
sed -i "s|releases/download/v[^/]*/commet-linux-portable-x64.tar.gz|releases/download/v${version}/commet-linux-portable-x64.tar.gz|" "$pkgbuild"

(
  cd "$aur_dir"
  makepkg --printsrcinfo > .SRCINFO
)

echo "Updated AUR packaging to version $version"
