#!/usr/bin/env bash
set -euo pipefail

strict=0
check_issue_state=1

aur_publication_pr_url="${COMMET_AUR_PUBLICATION_PR_URL:-}"
fdroid_publication_mr_url="${COMMET_FDROID_PUBLICATION_MR_URL:-}"

usage() {
  cat <<USAGE
Usage: $0 [--strict] [--skip-issue-state] [--aur-publication-pr-url <url>] [--fdroid-publication-mr-url <url>]

Environment variable equivalents:
  COMMET_AUR_PUBLICATION_PR_URL
  COMMET_FDROID_PUBLICATION_MR_URL
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      strict=1
      ;;
    --skip-issue-state)
      check_issue_state=0
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

if [[ "$check_issue_state" == "1" ]]; then
  issue_api_root="https://api.github.com/repos/commetchat/commet/issues"
  for issue in 357 115; do
    if issue_response="$(curl -fsSL "$issue_api_root/$issue" 2>/dev/null)"; then
      issue_state="$(echo "$issue_response" | jq -r '.state // "unknown"')"
      issue_title="$(echo "$issue_response" | jq -r '.title // "(no title)"')"
      echo "- GHI #$issue status: $issue_state ($issue_title)"
    else
      echo "- GHI #$issue status: unavailable (GitHub API request failed)"
    fi
  done
fi

if [[ "$strict" == "1" ]]; then
  if [[ "$aur_matches_local" != "1" || "$fdroid_matches_local" != "1" ]]; then
    echo "Strict mode failed: one or more publication targets are not in sync with local versions." >&2
    exit 2
  fi
fi

extract_github_pr_ref() {
  local url="$1"
  if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}"
    return 0
  fi

  return 1
}

extract_gitlab_project_and_mr() {
  local url="$1"
  if [[ "$url" =~ ^https://gitlab\.com/(.+)/-/merge_requests/([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

echo
echo "Optional publication PR/MR trackers"
if [[ -n "$aur_publication_pr_url" ]]; then
  if pr_ref="$(extract_github_pr_ref "$aur_publication_pr_url")"; then
    IFS='/' read -r pr_owner pr_repo pr_number <<<"$pr_ref"
    pr_api_url="https://api.github.com/repos/${pr_owner}/${pr_repo}/pulls/${pr_number}"
    if pr_response="$(curl -fsSL "$pr_api_url" 2>/dev/null)"; then
      pr_state="$(echo "$pr_response" | jq -r '.state // "unknown"')"
      pr_title="$(echo "$pr_response" | jq -r '.title // "(no title)"')"
      pr_merged="$(echo "$pr_response" | jq -r '.merged // false')"
      if [[ "$pr_merged" == "true" ]]; then
        pr_state="merged"
      fi
      echo "- AUR publication PR: $pr_state ($pr_title)"
      echo "  $aur_publication_pr_url"
    else
      echo "- AUR publication PR: unavailable (GitHub API request failed)"
      echo "  $aur_publication_pr_url"
    fi
  else
    echo "- AUR publication PR: skipped (unsupported URL format)"
    echo "  $aur_publication_pr_url"
  fi
else
  echo "- AUR publication PR: not configured"
fi

if [[ -n "$fdroid_publication_mr_url" ]]; then
  if mr_ref="$(extract_gitlab_project_and_mr "$fdroid_publication_mr_url")"; then
    IFS='|' read -r mr_project mr_iid <<<"$mr_ref"
    project_encoded="$(printf '%s' "$mr_project" | sed 's#/#%2F#g')"
    mr_api_url="https://gitlab.com/api/v4/projects/${project_encoded}/merge_requests/${mr_iid}"
    if mr_response="$(curl -fsSL "$mr_api_url" 2>/dev/null)"; then
      mr_state="$(echo "$mr_response" | jq -r '.state // "unknown"')"
      mr_title="$(echo "$mr_response" | jq -r '.title // "(no title)"')"
      echo "- F-Droid metadata MR: $mr_state ($mr_title)"
      echo "  $fdroid_publication_mr_url"
    else
      echo "- F-Droid metadata MR: unavailable (GitLab API request failed)"
      echo "  $fdroid_publication_mr_url"
    fi
  else
    echo "- F-Droid metadata MR: skipped (unsupported URL format)"
    echo "  $fdroid_publication_mr_url"
  fi
else
  echo "- F-Droid metadata MR: not configured"
fi
