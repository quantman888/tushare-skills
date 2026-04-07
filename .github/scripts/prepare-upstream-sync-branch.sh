#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  prepare-upstream-sync-branch.sh \
    --upstream-repo <owner/name> \
    --upstream-branch <branch> \
    --default-branch <branch> \
    --sync-branch <branch>
EOF
}

upstream_repo=""
upstream_branch=""
default_branch=""
sync_branch=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream-repo)
      upstream_repo="${2:-}"
      shift 2
      ;;
    --upstream-branch)
      upstream_branch="${2:-}"
      shift 2
      ;;
    --default-branch)
      default_branch="${2:-}"
      shift 2
      ;;
    --sync-branch)
      sync_branch="${2:-}"
      shift 2
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
done

if [[ -z "${upstream_repo}" || -z "${upstream_branch}" || -z "${default_branch}" || -z "${sync_branch}" ]]; then
  usage >&2
  exit 1
fi

upstream_url="https://github.com/${upstream_repo}.git"

if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "${upstream_url}"
else
  git remote add upstream "${upstream_url}"
fi
git remote set-url --push upstream DISABLED

git fetch --no-tags upstream "${upstream_branch}"
git fetch --no-tags origin "${default_branch}"

upstream_ref="upstream/${upstream_branch}"
default_ref="origin/${default_branch}"
upstream_sha="$(git rev-parse "${upstream_ref}")"
upstream_short_sha="$(git rev-parse --short=12 "${upstream_ref}")"
default_sha="$(git rev-parse "${default_ref}")"

changed="true"
if git merge-base --is-ancestor "${upstream_ref}" "${default_ref}"; then
  changed="false"
else
  git branch -f "${sync_branch}" "${upstream_ref}"
fi

printf 'changed=%s\n' "${changed}"
printf 'upstream_sha=%s\n' "${upstream_sha}"
printf 'upstream_short_sha=%s\n' "${upstream_short_sha}"
printf 'default_sha=%s\n' "${default_sha}"
