# Release Back-Merge

Use the release branch as the head and `develop` as the base, matching PR #404.

## 1. Inspect

```bash
git fetch origin --prune --tags
git branch -r --list 'origin/release/vX.Y.Z' 'origin/develop'
gh pr list --state all --base develop --head 'release/vX.Y.Z'
git merge-base --is-ancestor 'origin/release/vX.Y.Z' origin/develop
```

Stop if the release branch is missing. Return an existing matching PR instead of creating a duplicate.

If `merge-base --is-ancestor` exits 0, the release is already back-merged. Find and report the containing merge commit; do not create an empty branch, no-op commit, or duplicate PR.

## 2. Create the PR When Needed

When ancestry exits 1, confirm a real diff:

```bash
git log --oneline 'origin/develop..origin/release/vX.Y.Z'
git diff --stat 'origin/develop...origin/release/vX.Y.Z'
```

Create the PR only when release commits or file changes remain:

- Head: `release/vX.Y.Z`
- Base: `develop`
- Title: `[Chore] Merge back vX.Y.Z`
- Body: version summary, release issue reference, changed build/version and CHANGELOG, validation checklist, and `🤖 이 PR은 Codex가 작성했습니다`

Do not merge the PR.

## 3. Verify

Confirm the PR is open with base `develop` and head `release/vX.Y.Z`. Report the PR URL or the existing direct-merge commit.
