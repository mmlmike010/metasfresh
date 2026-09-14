---
name: land
description: >-
  Resets the metasfresh demo workspace to the repo default branch by stashing all
  local changes (including untracked files). Use when the user says land, land me,
  go home, back on track, get back to the default branch, or wants the demo
  environment returned to a clean default-branch checkout. Do not use for landing
  or merging pull requests.
---

# Land

Put the metasfresh demo repo back on the default branch with a clean working tree.

The default branch is whatever `origin/HEAD` points at. In this repo that is `new_dawn_uat`. There is no `main`.

## Do this

1. Run the script. Do not reimplement the git steps by hand.

```bash
bash /Users/michaelacsamana/Documents/metasfresh/.cursor/skills/land/scripts/land.sh
```

2. Read the script output and report it in the response shape below.
3. Stop. Landing is git-only unless the user also asked to start or stop the app.

## What the script does

- Works in this metasfresh repo
- Resolves the land branch from `origin/HEAD` (`new_dawn_uat` today)
- Stashes tracked and untracked changes (`git stash push -u`) if the tree is dirty
- Leaves ignored files alone (`node_modules`, build output, `.env`)
- Switches to that branch and fast-forwards from upstream when it has one
- Refuses to run during merge, rebase, cherry-pick, or revert

## Do not

- Hard reset, force checkout, or `stash drop`
- Commit, push, or set upstream
- Create a `Maine` or `main` branch
- Touch `metasfresh-rust` unless the user says to land both
- Start or stop Docker as part of land
- Pop the stash unless the user asks to restore it

## If the user also wants the app

After land succeeds, follow the `start-application` skill in this repo. Land does not replace start.

## Restore later

```bash
cd /Users/michaelacsamana/Documents/metasfresh
git stash list
git stash pop
```

## Response

```markdown
Landed.

Repo: `/Users/michaelacsamana/Documents/metasfresh`
Branch: `new_dawn_uat` (`<short-sha>`)
Working tree: clean
Stash: `<stash-sha or none>`

Demo home is the default branch. Say start application if you want the stack up.
```

If the script exits non-zero, do not say it landed. Report the error and the current `git status -sb`.
