# VOC Page xcconfig Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 의견 보내기 URL을 xcconfig에서 관리하고 Info.plist를 거쳐 Bundle에서 읽도록 변경한다.

**Architecture:** 공통 xcconfig의 `VOC_PAGE_URL`을 Debug와 Release 빌드 구성에 연결한다. Info.plist의 `VOCPageURL`이 이 값을 치환하며, 설정 화면은 Bundle에서 문자열을 읽어 URL로 변환한다.

**Tech Stack:** Xcode build configuration, Info.plist, SwiftUI, Swift

## Global Constraints

- 새 URL은 `https://docs.google.com/forms/d/e/1FAIpQLSe9gVPqQ92Na0C1-GQ0JhjWw7kNSAauRZPii1iJ1Mf6lz8-zA/viewform?pli=1`이다.
- Swift 코드에 VOC URL을 하드코딩하지 않는다.
- Debug와 Release 모두 같은 URL 설정을 사용한다.
- 모든 변경은 단일 커밋으로 만든다.

---

### Task 1: VOC URL 구성 연결과 화면 조회

**Files:**
- Create: `QueenCam/Config/Shared.xcconfig`
- Modify: `QueenCam/QueenCam.xcodeproj/project.pbxproj`
- Modify: `QueenCam/QueenCam/Info.plist`
- Modify: `QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/SettingsMainView.swift`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: Xcode build setting `VOC_PAGE_URL`
- Produces: Info.plist 문자열 키 `VOCPageURL`, `SettingsMainView.vocPageURL: URL?`

- [ ] **Step 1: 현재 설정이 없음을 확인한다**

Run: `xcodebuild -project QueenCam/QueenCam.xcodeproj -scheme QueenCam -configuration Debug -showBuildSettings | rg 'VOC_PAGE_URL'`

Expected: 일치 항목이 없어 종료 코드 1.

- [ ] **Step 2: xcconfig와 프로젝트 연결을 추가한다**

`QueenCam/Config/Shared.xcconfig`에 다음 값을 추가한다. xcconfig에서 `//`가 주석으로 해석되지 않도록 빈 빌드 설정 치환을 사용한다.

```xcconfig
VOC_PAGE_URL = https:/$()/docs.google.com/forms/d/e/1FAIpQLSe9gVPqQ92Na0C1-GQ0JhjWw7kNSAauRZPii1iJ1Mf6lz8-zA/viewform?pli=1
```

프로젝트 파일에 xcconfig 파일 참조를 추가하고 QueenCam 타깃의 Debug와 Release `XCBuildConfiguration`에 `baseConfigurationReference`로 연결한다.

- [ ] **Step 3: Info.plist와 Swift 조회를 구현한다**

`Info.plist`에 다음 키를 추가한다.

```xml
<key>VOCPageURL</key>
<string>$(VOC_PAGE_URL)</string>
```

`SettingsMainView`의 VOC URL을 다음 Bundle 조회로 교체한다.

```swift
var vocPageURL: URL? {
  guard let urlString = Bundle.main.infoDictionary?["VOCPageURL"] as? String else {
    return nil
  }
  return URL(string: urlString)
}
```

- [ ] **Step 4: CHANGELOG를 갱신한다**

`CHANGELOG.md`의 `[Unreleased]` 아래 `Changed`에 의견 보내기 URL을 xcconfig 기반 새 Google Forms 주소로 변경했다는 항목을 추가한다.

- [ ] **Step 5: 빌드 설정과 빌드를 검증한다**

Run: `xcodebuild -project QueenCam/QueenCam.xcodeproj -scheme QueenCam -configuration Debug -showBuildSettings | rg 'VOC_PAGE_URL'`

Expected: 새 Google Forms URL이 출력된다.

Run: `xcodebuild -project QueenCam/QueenCam.xcodeproj -scheme QueenCam -configuration Release -showBuildSettings | rg 'VOC_PAGE_URL'`

Expected: 같은 URL이 출력된다.

Run: `xcodebuild -project QueenCam/QueenCam.xcodeproj -scheme QueenCam -configuration Debug -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: 단일 커밋을 생성한다**

```bash
git add QueenCam/Config/Shared.xcconfig QueenCam/QueenCam.xcodeproj/project.pbxproj QueenCam/QueenCam/Info.plist QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/SettingsMainView.swift CHANGELOG.md docs/superpowers
git commit
```

커밋 제목은 `feat: 의견 보내기 URL을 xcconfig 기반 설정으로 변경`으로 작성하고 본문 끝에 `Co-authored-by: Codex <noreply@openai.com>`를 추가한다.
