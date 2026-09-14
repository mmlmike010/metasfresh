#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${LAND_REPO:-$(cd "${SCRIPT_DIR}/../../../.." && pwd)}"

if [[ ! -d "${REPO}/.git" ]]; then
  echo "error: not a git repo: ${REPO}" >&2
  exit 1
fi

cd "${REPO}"

if [[ -e .git/MERGE_HEAD || -e .git/REBASE_HEAD || -e .git/CHERRY_PICK_HEAD || -e .git/REVERT_HEAD ]]; then
  echo "error: merge, rebase, cherry-pick, or revert is in progress. finish or abort it before landing." >&2
  git status -sb
  exit 2
fi

if [[ -z "${LAND_BRANCH:-}" ]]; then
  if origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    LAND_BRANCH="${origin_head#origin/}"
  else
    LAND_BRANCH="new_dawn_uat"
  fi
fi

before_branch="$(git branch --show-current || echo "DETACHED")"
before_head="$(git rev-parse --short HEAD)"
stashed="no"
stash_ref=""

if [[ -n "$(git status --porcelain)" ]]; then
  stamp="$(date +%Y-%m-%dT%H:%M:%S)"
  git stash push -u -m "land: ${stamp} from ${before_branch}"
  stashed="yes"
  stash_ref="$(git rev-parse --short 'stash@{0}')"
fi

if git show-ref --verify --quiet "refs/heads/${LAND_BRANCH}"; then
  git switch "${LAND_BRANCH}"
elif git show-ref --verify --quiet "refs/remotes/origin/${LAND_BRANCH}"; then
  git switch -c "${LAND_BRANCH}" --track "origin/${LAND_BRANCH}"
else
  echo "error: default branch ${LAND_BRANCH} does not exist locally or on origin" >&2
  exit 1
fi

pulled="no"
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  git pull --ff-only
  pulled="yes"
fi

after_branch="$(git branch --show-current)"
after_head="$(git rev-parse --short HEAD)"
dirty="$(git status --porcelain)"

echo "landed: yes"
echo "repo: ${REPO}"
echo "from: ${before_branch} ${before_head}"
echo "on: ${after_branch} ${after_head}"
echo "pulled: ${pulled}"
echo "stashed: ${stashed}"
if [[ "${stashed}" == "yes" ]]; then
  echo "stash: ${stash_ref} (git stash pop to restore)"
fi
if [[ -n "${dirty}" ]]; then
  echo "clean: no"
  echo "${dirty}"
  exit 3
fi
echo "clean: yes"
git status -sb
