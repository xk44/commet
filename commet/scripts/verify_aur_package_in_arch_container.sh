#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
aur_dir="$repo_root/commet/linux/aur"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to run AUR validation in a clean Arch container" >&2
  exit 1
fi

docker run --rm \
  -v "$aur_dir":/pkg:ro \
  archlinux:latest \
  bash -lc '
    set -euo pipefail
    pacman -Sy --noconfirm --needed base-devel git curl sudo
    useradd -m builder
    echo "builder ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/builder
    cp -R /pkg /tmp/pkg
    chown -R builder:builder /tmp/pkg
    su - builder -c "cd /tmp/pkg && makepkg --printsrcinfo > /tmp/pkg/.SRCINFO.generated"
    su - builder -c "cd /tmp/pkg && diff -u .SRCINFO .SRCINFO.generated"
    su - builder -c "cd /tmp/pkg && makepkg -s --noconfirm"
  '

echo "AUR packaging validation succeeded in a clean Arch container"
