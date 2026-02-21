#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
project_root="$repo_root/commet"

skip_aur_verify=0
skip_issue_state=0
fdroid_apk_path=""
aur_publication_pr_url="${COMMET_AUR_PUBLICATION_PR_URL:-}"
fdroid_publication_mr_url="${COMMET_FDROID_PUBLICATION_MR_URL:-}"

usage() {
  cat <<USAGE
Usage: $0 [--skip-aur-verify] [--skip-issue-state] [--fdroid-apk <path>] [--aur-publication-pr-url <url>] [--fdroid-publication-mr-url <url>]

Runs local publication-prep steps for pending packaging tasks:
- Checks local version status vs AUR + F-Droid metadata.
- Optionally verifies AUR package build/install in a clean Arch container.
- Regenerates android/fdroid/submission_template.md (optionally with APK checksum).
- Optionally checks publication PR/MR links when provided.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-aur-verify)
      skip_aur_verify=1
      ;;
    --skip-issue-state)
      skip_issue_state=1
      ;;
    --fdroid-apk)
      fdroid_apk_path="${2:-}"
      if [[ -z "$fdroid_apk_path" ]]; then
        echo "--fdroid-apk requires a path argument" >&2
        exit 1
      fi
      shift
      ;;
    --aur-publication-pr-url)
      aur_publication_pr_url="${2:-}"
      if [[ -z "$aur_publication_pr_url" ]]; then
        echo "--aur-publication-pr-url requires a URL argument" >&2
        exit 1
      fi
      shift
      ;;
    --fdroid-publication-mr-url)
      fdroid_publication_mr_url="${2:-}"
      if [[ -z "$fdroid_publication_mr_url" ]]; then
        echo "--fdroid-publication-mr-url requires a URL argument" >&2
        exit 1
      fi
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

echo "==> Checking publication status (AUR + F-Droid metadata)"
status_args=()
if [[ "$skip_issue_state" == "1" ]]; then
  status_args+=("--skip-issue-state")
fi
if [[ -n "$aur_publication_pr_url" ]]; then
  status_args+=("--aur-publication-pr-url" "$aur_publication_pr_url")
fi
if [[ -n "$fdroid_publication_mr_url" ]]; then
  status_args+=("--fdroid-publication-mr-url" "$fdroid_publication_mr_url")
fi
"$project_root/scripts/check_packaging_publication_status.sh" "${status_args[@]}"

if [[ "$skip_aur_verify" == "1" ]]; then
  echo
  echo "==> Skipping clean-Arch AUR package verification (--skip-aur-verify)"
else
  echo
  echo "==> Verifying AUR package build/install in clean Arch container"
  "$project_root/scripts/verify_aur_package_in_arch_container.sh"
fi

echo
echo "==> Regenerating F-Droid submission template"
if [[ -n "$fdroid_apk_path" ]]; then
  "$project_root/scripts/generate_fdroid_submission_template.sh" "$fdroid_apk_path"
else
  "$project_root/scripts/generate_fdroid_submission_template.sh"
fi

echo
echo "Packaging publication prep bundle completed."
