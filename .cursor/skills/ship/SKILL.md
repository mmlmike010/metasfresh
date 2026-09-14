---
name: ship
description: >-
  Commits current metasfresh demo changes, pushes a feature branch, and opens a
  pull request against the default branch. Use when the user says ship, ship it,
  or ship this.
---

# Ship

Commit the current metasfresh demo work on a feature branch and open a PR against the default branch.

The default branch is whatever `origin/HEAD` points at. In this repo that is `new_dawn_uat`. There is no `main`.

## Do this

1. Inspect `git status`, `git diff`, and recent `git log` so the commit matches repo style.
2. Create or keep the feature branch. Do not reimplement this git step by hand.

```bash
SHIP_BRANCH=cursor/<short-name> bash /Users/michaelacsamana/Documents/metasfresh/.cursor/skills/ship/scripts/ship.sh branch
```

If the current branch is the default, the script creates `SHIP_BRANCH` from current HEAD. If already on a non-default branch, it stays there.

3. Stage relevant changes. Do not include secrets (`.env`, credentials, tokens).
4. Commit with a HEREDOC message in this repo's style (why, not what). Do not amend unless the usual safety conditions are met. Do not skip hooks.
5. Push and open the PR. Do not reimplement push or `gh` by hand.

```bash
SHIP_TITLE='Short PR title' \
SHIP_BODY="$(cat <<'EOF'
## Summary
- ...

## Test plan
- ...
EOF
)" \
bash /Users/michaelacsamana/Documents/metasfresh/.cursor/skills/ship/scripts/ship.sh publish
```

6. Report the script output in the response shape below.

## What the script does

- Works in this metasfresh repo
- Resolves the default branch from `origin/HEAD` (`new_dawn_uat` today)
- Creates `SHIP_BRANCH` only when the current branch is the default
- Pushes with `-u` and opens a PR targeting that default branch
- Reuses an existing PR for the current branch when one is already open
- Refuses to run during merge, rebase, cherry-pick, or revert

## Do not

- Hard reset, force-push, or skip hooks
- Amend a commit unless the user asked, it is yours, and it has not been pushed
- Create a `Maine` or `main` branch
- Touch `metasfresh-rust`
- Commit secrets
- Push from the default branch

## Response

```markdown
Shipped.

Repo: `/Users/michaelacsamana/Documents/metasfresh`
Branch: `<feature-branch>` (`<short-sha>`)
PR: `<url>`

Default branch is still `new_dawn_uat`. Stay on the ship branch.
```

If the script exits non-zero, do not say it shipped. Report the error and the current `git status -sb`.
