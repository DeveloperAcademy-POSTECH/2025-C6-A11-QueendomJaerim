# Creating Release Issue and PR Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 이 저장소의 릴리즈 이슈와 `develop → main` PR을 안전하게 생성하는 프로젝트 로컬 스킬을 만든다.

**Architecture:** `.agents/skills` 아래 자체 완결형 스킬을 생성한다. 스킬은 Git/GitHub 상태를 검사하고 외부 변경 단계를 명시적으로 수행하되 배포 트리거 코멘트, PR 머지, 태그 생성을 기본 동작에서 제외한다.

**Tech Stack:** Agent Skills, Markdown, YAML, Git, GitHub CLI

## Global Constraints

- 스킬 이름은 `creating-release-issue-and-pr`이다.
- 실제 브랜치 이름 `develop`과 `main`을 사용한다.
- `/start vX.Y.Z` 코멘트는 해당 턴의 명시적 요청 없이는 작성하지 않는다.
- 중복 이슈와 PR을 생성하지 않는다.
- 릴리즈 브랜치가 `develop`에 미포함된 경우에만 백머지 PR을 생성한다.

---

### Task 1: 프로젝트 릴리즈 스킬 작성

**Files:**
- Create: `.agents/skills/creating-release-issue-and-pr/SKILL.md`
- Create: `.agents/skills/creating-release-issue-and-pr/agents/openai.yaml`
- Create: `.agents/skills/creating-release-issue-and-pr/references/backmerge.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: 사용자 릴리즈 버전, Git 브랜치 상태, GitHub 이슈와 PR 상태
- Produces: 릴리즈 이슈 URL과 `develop → main` PR URL

- [ ] **Step 1: 스킬 구조 부재를 확인한다**

Run: `test -f .agents/skills/creating-release-issue-and-pr/SKILL.md`

Expected: 파일이 없어 종료 코드 1.

- [ ] **Step 2: 공식 초기화 스크립트로 스킬을 생성한다**

`init_skill.py`를 사용해 `.agents/skills/creating-release-issue-and-pr`와 UI 메타데이터를 생성한다.

- [ ] **Step 3: 릴리즈 워크플로우와 안전 정책을 작성한다**

`SKILL.md`에 버전 확인, 중복 검사, 브랜치 최신화, 변경 범위 확인, 이슈 생성, PR 생성, 결과 검증 순서를 작성한다. 이슈 코멘트, PR 머지, 태그 생성을 금지하는 명시적 안전 게이트를 포함한다.

- [ ] **Step 4: CHANGELOG를 갱신한다**

`[Unreleased]`의 Added에 프로젝트 릴리즈 이슈·PR 생성 스킬 추가를 기록한다.

- [ ] **Step 5: 스킬을 검증한다**

공식 `quick_validate.py`, YAML 파싱, 필수 문구 정적 검사, `git diff --check`를 실행한다. 외부 변경을 일으키는 forward test는 실행하지 않는다.

- [ ] **Step 6: 이슈·커밋·PR을 생성한다**

작업 이슈를 생성하고, 변경을 단일 커밋으로 푸시한 뒤 해당 이슈를 닫는 `develop` 대상 PR을 생성한다.
