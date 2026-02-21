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

## Notes

Google services integration remains opt-in and disabled by default in this repository.
