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


## Publication status check

Use the repository helper to compare local packaging versions with what is currently published in AUR and F-Droid metadata:

```bash
./commet/scripts/check_packaging_publication_status.sh

# CI-style check: exits non-zero when AUR/F-Droid are not in sync
./commet/scripts/check_packaging_publication_status.sh --strict

# Optional: skip GitHub issue-state lookups (useful in rate-limited/offline environments)
./commet/scripts/check_packaging_publication_status.sh --skip-issue-state

# Optional: include publication PR/MR links so status output includes their current state
./commet/scripts/check_packaging_publication_status.sh \
  --aur-publication-pr-url https://github.com/<owner>/<repo>/pull/<id> \
  --fdroid-publication-mr-url https://gitlab.com/fdroid/fdroiddata/-/merge_requests/<id>
```

## Clean Arch verification

To validate the package in a clean Arch environment before publishing to AUR, run:

```bash
./commet/scripts/verify_aur_package_in_arch_container.sh
```

This script uses Docker to build in `archlinux:latest`, regenerate `.SRCINFO`, verify it matches the committed file, and run `makepkg -s`.
