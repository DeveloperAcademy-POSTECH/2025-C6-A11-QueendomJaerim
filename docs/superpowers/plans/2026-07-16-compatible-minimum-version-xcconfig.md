# Compatible Minimum Version xcconfig Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱 호환 최소 버전을 Shared.xcconfig에서 관리하고 Info.plist를 통해 Bundle에 제공한다.

**Architecture:** `Shared.xcconfig`가 호환 최소 버전의 원천이 된다. Info.plist는 빌드 설정을 치환하고 기존 `VersionUtils`는 변경 없이 Bundle 값을 읽는다.

**Tech Stack:** Xcode build configuration, Info.plist, Swift

## Global Constraints

- 호환 최소 버전 값은 `1.1.7`이다.
- 설정 이름은 `QUEENCAM_COMPATIBLE_MINIMUM_VERSION`이다.
- Info.plist 키 `QueenCamCompatibleMinimumVersion`과 `VersionUtils`의 fallback `0.0.0`은 유지한다.
- PR 대상 브랜치는 `develop`이다.

---

### Task 1: 호환 최소 버전 설정 이동

**Files:**
- Modify: `QueenCam/Config/Shared.xcconfig`
- Modify: `QueenCam/QueenCam/Info.plist`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: Xcode build setting `QUEENCAM_COMPATIBLE_MINIMUM_VERSION`
- Produces: Info.plist 키 `QueenCamCompatibleMinimumVersion`의 문자열 값

- [ ] **Step 1: 현재 빌드 설정이 없음을 확인한다**

Run: `xcodebuild -project QueenCam/QueenCam.xcodeproj -scheme QueenCam -configuration Debug -showBuildSettings | rg 'QUEENCAM_COMPATIBLE_MINIMUM_VERSION'`

Expected: 일치 항목이 없어 종료 코드 1.

- [ ] **Step 2: Shared.xcconfig에 값을 정의한다**

```xcconfig
QUEENCAM_COMPATIBLE_MINIMUM_VERSION = 1.1.7
```

- [ ] **Step 3: Info.plist 값을 빌드 설정 치환으로 변경한다**

```xml
<key>QueenCamCompatibleMinimumVersion</key>
<string>$(QUEENCAM_COMPATIBLE_MINIMUM_VERSION)</string>
```

- [ ] **Step 4: CHANGELOG를 갱신한다**

`CHANGELOG.md`의 `[Unreleased]` 아래 `Changed`에 호환 최소 버전을 xcconfig에서 관리하도록 변경했다는 항목을 추가한다.

- [ ] **Step 5: 구성과 빌드 산출물을 검증한다**

Debug와 Release에서 `xcodebuild -showBuildSettings`를 실행해 값이 `1.1.7`인지 확인한다. iOS Simulator Debug 빌드 후 앱 Info.plist의 `QueenCamCompatibleMinimumVersion`이 `1.1.7`인지 `plutil`로 확인한다.

- [ ] **Step 6: 커밋하고 PR을 생성한다**

변경 전체를 하나의 커밋으로 만들고 원격 브랜치에 푸시한 뒤 `develop` 대상 PR을 생성한다.
