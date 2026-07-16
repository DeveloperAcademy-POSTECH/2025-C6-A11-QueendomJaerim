---
name: creating-release-issue-and-pr
description: Use when preparing or completing a QueenCam release and the user requests a release issue, a develop-to-main pull request, or a release back-merge.
---

# Creating a Release Issue and PR

## Overview

Create release issues and PRs using this repository's conventions. Keep preparation, deployment triggering, and post-release back-merge verification separate.

## Safety Contract

- Require an explicit version such as `v1.1.8` before any GitHub write.
- Do not infer the next version from `MARKETING_VERSION`, tags, issues, or PRs.
- Do not write `/start vX.Y.Z` or any issue comment unless the user explicitly requests that comment in the current turn.
- Do not merge the PR, create a release branch, push a tag, or run the release workflow.
- Stop if the working tree is dirty; preserve all existing changes.
- Return an existing matching issue or PR instead of creating a duplicate.

`/start` triggers `.github/workflows/release.yml`, which directly merges a release branch into `main` and `develop`. Treat it as a separate deployment action.

## Workflow

### 1. Inspect Before Writing

Read the repository instructions, release issue template, and release workflow first.

Run:

```bash
git status --short --branch
git branch -a --list '*develop*' '*main*'
gh issue list --state open --search '🎤 [Release] vX.Y.Z in:title'
gh pr list --state open --base main --head develop --search 'vX.Y.Z in:title'
```

Replace `vX.Y.Z` with the confirmed version. Stop and return any matching URL.

### 2. Update develop Safely

Proceed only with a clean working tree:

```bash
git switch develop
git pull --ff-only origin develop
git log --oneline origin/main..develop
git diff --stat origin/main...develop
```

Stop when `develop` has no changes relative to `origin/main`.

### 3. Create the Release Issue

Check whether the `release` label exists:

```bash
gh label list --search release
```

Create `🎤 [Release] vX.Y.Z` with every release template section. Mark scope selection complete and leave the `/start` item unchecked.

Use `--label release` only for an exact label match. Otherwise omit the label; do not create one.

### 4. Create the Release PR

Create a PR with these fixed branches:

- Head: `develop`
- Base: `main`
- Title: `🎤 [Release] vX.Y.Z`

Use `Related: #ISSUE_NUMBER`, not `Closes`, so the issue remains open. Summarize `[Unreleased]` and include:

```markdown
요청에 따라 배포 워크플로우를 실행하는 이슈 코멘트는 아직 남기지 않았습니다.

🤖 이 PR은 Codex가 작성했습니다
```

### 5. Verify Results

Run:

```bash
gh issue view ISSUE_NUMBER --json number,title,state,url,comments
gh pr view PR_NUMBER --json number,title,baseRefName,headRefName,state,url
git status --short --branch
```

Verify:

- Issue state is `OPEN`.
- Comments are empty unless explicitly authorized this turn.
- PR state is `OPEN`, base is `main`, and head is `develop`.
- Working tree remains clean on `develop`.

### 6. Handle Post-Release Back-Merge

When the user requests a release back-merge, read [references/backmerge.md](references/backmerge.md) and follow it completely. Create `release/vX.Y.Z → develop` only when the release branch is not already an ancestor of `develop`; otherwise report the existing merge commit because GitHub has no back-merge diff to accept.
