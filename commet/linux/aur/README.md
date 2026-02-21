# AUR packaging (commet-bin)

This directory contains the packaging files used to publish Commet to the Arch User Repository as a prebuilt binary package.

## Files

- `PKGBUILD`: package definition for `commet-bin`
- `.SRCINFO`: metadata generated from the PKGBUILD for AUR upload

## Update workflow

1. Update `pkgver` in `PKGBUILD`.
2. Regenerate `.SRCINFO`:
   ```bash
   cd commet/linux/aur
   makepkg --printsrcinfo > .SRCINFO
   ```
3. Validate locally:
   ```bash
   makepkg -si
   ```

For convenience, you can also use `commet/scripts/update_aur_pkgbuild.sh` from the repository root.

## Clean Arch verification

To validate the package in a clean Arch environment before publishing to AUR, run:

```bash
./commet/scripts/verify_aur_package_in_arch_container.sh
```

This script uses Docker to build in `archlinux:latest`, regenerate `.SRCINFO`, verify it matches the committed file, and run `makepkg -s`.
