# F-Droid metadata update template

Use this text when opening/updating the upstream F-Droid metadata PR/issue.

- Repository: https://github.com/commetchat/commet
- License: AGPL-3.0-only
- Latest version: 0.4.0+749
- Android build command:
  -     ./scripts/build_fdroid_release.sh
- Reproducibility notes:
  - Flutter release build
  - Dart defines: PLATFORM=android, BUILD_MODE=release, BUILD_DETAIL=fdroid
- APK SHA-256: not provided (build the APK and re-run this script with its path).

## Additional reviewer notes

- Google services integration remains opt-in and disabled by default in this repo.
- Verify app startup/login flow on a Google-free Android test environment.
