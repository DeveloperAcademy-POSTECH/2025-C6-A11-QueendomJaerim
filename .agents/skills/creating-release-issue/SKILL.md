---
name: creating-release-issue
description: Use when preparing a QueenCam release and the user requests the release task or release issue.
---

# Creating a Release Issue

## Overview

Create one release issue in the repository's required format. The release workflow owns branch creation, version updates, merges, back-merge, and tagging.

## Safety Contract

- Require an explicit version such as `v1.1.9` before any GitHub write.
- Do not infer the next version.
- Create only the release issue. Do not create any release or back-merge PR.
- Do not write `/start vX.Y.Z` or any other issue comment.
- Do not create a release branch, merge branches, push tags, or run workflows.
- Return an existing issue for the same version instead of creating a duplicate.

`/start` triggers `.github/workflows/release.yml`. That workflow creates `release/vX.Y.Z`, updates app/build versions and CHANGELOG, merges into `main` and `develop`, and pushes the tag.

## Workflow

### 1. Inspect

Read the repository instructions, `.github/ISSUE_TEMPLATE/release.yml`, and `.github/workflows/release.yml`.

Require a clean working tree, then update `develop`:

```bash
git status --short --branch
git switch develop
git pull --ff-only origin develop
gh issue list --state all --search '🎤 [Release] vX.Y.Z in:title'
gh pr list --state open --base develop
```

Replace `vX.Y.Z` with the confirmed version. Return a matching issue. Confirm with the user if open PRs targeting `develop` affect the release scope.

### 2. Create the Issue

Use title `🎤 [Release] vX.Y.Z` and every field from the release template:

- 개요: `vX.Y.Z 릴리즈`
- 버전: `X.Y.Z`
- 체크리스트: scope selection is checked; `/start` remains unchecked
- 릴리즈 일자
- 노션링크: `없음` when unspecified
- 비고: `없음` when unspecified
- 참조자: `cc. @Jeongin-c (PM)`

Query `gh label list --search release`. Add the exact `release` label only when it exists; otherwise create the issue without a label.

### 3. Verify and Stop

```bash
gh issue view ISSUE_NUMBER --json number,title,state,url,comments
git status --short --branch
```

Require an open issue with no comments and a clean `develop` working tree. Return the version and issue URL, then stop.

## Common Mistakes

| Mistake | Correct action |
|---|---|
| Guessing the version | Ask for it. |
| Creating a release PR | Let the workflow merge directly. |
| Creating a back-merge PR | Let the workflow merge back to `develop`. |
| Writing `/start` | Keep deployment triggering outside this skill. |
