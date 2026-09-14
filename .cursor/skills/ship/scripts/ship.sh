#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${SHIP_REPO:-$(cd "${SCRIPT_DIR}/../../../.." && pwd)}"

usage() {
  echo "usage: ship.sh branch|publish" >&2
  exit 2
}

if [[ $# -ne 1 ]]; then
  usage
fi

cmd="$1"

if [[ ! -d "${REPO}/.git" ]]; then
  echo "error: not a git repo: ${REPO}" >&2
  exit 1
fi

cd "${REPO}"

if [[ -e .git/MERGE_HEAD || -e .git/REBASE_HEAD || -e .git/CHERRY_PICK_HEAD || -e .git/REVERT_HEAD ]]; then
  echo "error: merge, rebase, cherry-pick, or revert is in progress. finish or abort it before shipping." >&2
  git status -sb
  exit 2
fi

if origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
  DEFAULT_BRANCH="${origin_head#origin/}"
else
  DEFAULT_BRANCH="new_dawn_uat"
fi

current="$(git branch --show-current || true)"
if [[ -z "${current}" ]]; then
  echo "error: detached HEAD. checkout a branch before shipping." >&2
  exit 1
fi

case "${cmd}" in
  branch)
    if [[ "${current}" == "${DEFAULT_BRANCH}" ]]; then
      if [[ -z "${SHIP_BRANCH:-}" ]]; then
        echo "error: on default branch ${DEFAULT_BRANCH}; set SHIP_BRANCH to create a feature branch" >&2
        exit 1
      fi
      if [[ "${SHIP_BRANCH}" == "${DEFAULT_BRANCH}" || "${SHIP_BRANCH}" == "main" || "${SHIP_BRANCH}" == "Maine" ]]; then
        echo "error: SHIP_BRANCH must not be the default or main" >&2
        exit 1
      fi
      if git show-ref --verify --quiet "refs/heads/${SHIP_BRANCH}"; then
        echo "error: branch ${SHIP_BRANCH} already exists locally" >&2
        exit 1
      fi
      git switch -c "${SHIP_BRANCH}"
    else
      echo "staying on ${current} (already off ${DEFAULT_BRANCH})"
    fi
    echo "ship-branch: $(git branch --show-current)"
    echo "default: ${DEFAULT_BRANCH}"
    echo "head: $(git rev-parse --short HEAD)"
    git status -sb
    ;;
  publish)
    if [[ "${current}" == "${DEFAULT_BRANCH}" ]]; then
      echo "error: still on default branch ${DEFAULT_BRANCH}. create a feature branch and commit first." >&2
      exit 1
    fi
    if [[ -n "$(git status --porcelain)" ]]; then
      echo "error: working tree is dirty. commit or stash before publish." >&2
      git status -sb
      exit 1
    fi
    if [[ -z "${SHIP_TITLE:-}" || -z "${SHIP_BODY:-}" ]]; then
      echo "error: set SHIP_TITLE and SHIP_BODY" >&2
      exit 1
    fi
    git push -u origin HEAD
    if pr_url="$(gh pr view --json url -q .url 2>/dev/null)"; then
      echo "created: no"
      echo "pr: ${pr_url}"
    else
      pr_url="$(gh pr create --base "${DEFAULT_BRANCH}" --title "${SHIP_TITLE}" --body "${SHIP_BODY}")"
      echo "created: yes"
      echo "pr: ${pr_url}"
    fi
    echo "branch: ${current}"
    echo "head: $(git rev-parse --short HEAD)"
    echo "default: ${DEFAULT_BRANCH}"
    git status -sb
    ;;
  *)
    usage
    ;;
esac
