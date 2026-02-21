# F-Droid prep notes

This folder tracks the local project requirements needed for publishing Commet in F-Droid.

## Build command

From `commet/`:

```bash
./scripts/build_fdroid_release.sh
```

This sets:

- `PLATFORM=android`
- `BUILD_MODE=release`
- `BUILD_DETAIL=fdroid`

## Submission checklist

1. Build release APK with the script above.
2. Verify app starts and login works without Google Play Services.
3. Ensure no non-free dependencies are enabled in `android/app/build.gradle`.
4. Open/update the F-Droid inclusion request with:
   - source repository URL
   - latest tag/version
   - license details (AGPL-3.0-only)
   - reproducible build notes


## Publication status check

Check whether local versions are already reflected in AUR (`commet-bin`) and F-Droid metadata (`chat.commet.commetapp`):

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

## Metadata PR helper

Generate a ready-to-edit metadata submission draft from `pubspec.yaml`:

```bash
./scripts/generate_fdroid_submission_template.sh
```

Optional: pass a built APK path to include the SHA-256 checksum in the generated
`android/fdroid/submission_template.md` file.


## End-to-end publication prep helper

Run a single command to perform local publication prep checks and regenerate the
F-Droid submission template:

```bash
./scripts/prepare_packaging_publication_bundle.sh

# Optional flags
./scripts/prepare_packaging_publication_bundle.sh --skip-aur-verify --skip-issue-state
./scripts/prepare_packaging_publication_bundle.sh --fdroid-apk build/app/outputs/flutter-apk/app-release.apk
./scripts/prepare_packaging_publication_bundle.sh \
  --aur-publication-pr-url https://github.com/<owner>/<repo>/pull/<id> \
  --fdroid-publication-mr-url https://gitlab.com/fdroid/fdroiddata/-/merge_requests/<id>
```

## Notes

Google services integration remains opt-in and disabled by default in this repository.
