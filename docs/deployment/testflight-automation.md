# TestFlight 자동 업로드 안내

## 현재 상태

**Archive, 코드 서명, App Store Connect 인증, 애플의 IPA 검사까지 실제 실행으로 검증했다. 실제 파일 전송만 아직 확인되지 않았다.**

| 단계 | 검증 |
| --- | --- |
| 의존성 설치, 컴파일 | 확인 |
| 코드 서명, IPA 생성 | 확인 |
| App Store Connect 인증 (API Key 3종) | 확인 |
| 애플의 IPA 형식 검사 | 확인 |
| 실제 파일 전송 및 빌드 등록 | 미확인 |

마지막 항목을 검증하지 않은 이유는 **업로드가 빌드 번호를 소모하기 때문**이다. v1.1.11은 이 수정이 main에 반영되기 전이라 Xcode 수동 업로드로 배포해야 하고, 거기에 빌드 24가 필요하다. 검증으로 24를 써버리면 수동 배포에 쓸 번호가 없어진다. 그래서 번호를 소모하지 않는 `altool --validate-app`까지만 수행했다. 방법은 [CI 사전 검증](ci-verification.md)에 정리했다.

`Gemfile` 수정이 다음 `/start` 릴리즈로 main에 반영되기 전까지 `/testflight`는 동작하지 않는다. v1.1.11은 기존 Xcode 수동 업로드로 배포한다. 자동화의 첫 실제 업로드는 v1.1.12에서 시도한다.

### 1차 도입 기록

PR #467이 실행 검증 없이 머지되어, 첫 실제 실행(v1.1.11, 이슈 #468)에서 문제 7가지가 한꺼번에 드러났다. 이후 검증 브랜치에서 `workflow_dispatch`로 8회 실행하며 순차적으로 해결했다.

관련 이슈는 #470(댓글 누락)과 #471(Archive 실패)이다. 재발 방지를 위한 사전 검증 절차는 [CI 사전 검증](ci-verification.md)에 정리했다.

## 설정별 존재 이유

아래 설정은 모두 실제 실패 로그를 보고 추가한 것이다. 근거 없이 제거하면 다시 깨진다.

| 설정 | 파일 | 없으면 생기는 일 |
| --- | --- | --- |
| `GH_REPO` | `testflight.yml` | 댓글 단계가 Checkout보다 먼저 실행되어 `gh`가 저장소를 찾지 못한다. 시작·성공·실패 댓글이 모두 실패한다. |
| `Select Xcode` 단계 | `testflight.yml` | 러너 기본 Xcode(16.4)가 선택되어 프로젝트 배포 타겟 26.0을 지원하지 못한다. |
| `-skipPackagePluginValidation` | `testflight.yml` | SwiftLint 빌드 툴 플러그인의 신뢰 승인이 CI에 없어 Archive가 실패한다. |
| `GYM_SKIP_CODESIGNING` | `testflight.yml` | Archive 시점 서명 설정이 SPM 패키지 타겟에까지 전역 적용되어 실패한다. |
| `GYM_EXPORT_TEAM_ID` | `testflight.yml` | export 시 팀 식별자가 없어 서명하지 못한다. |
| `FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT` | `testflight.yml` | SPM 패키지가 16개라 빌드 설정 조회가 기본 3초 안에 끝나지 않는다. |
| `gem "multi_json"` | `Gemfile` | fastlane이 로딩 단계에서 `Gem::LoadError`로 실패한다. 어느 gemspec에도 선언되지 않은 soft dependency라 락을 새로 만들어도 들어오지 않는다. |

서명은 Archive가 아니라 export 단계에서 이뤄진다. `Fastfile`의 `export_options`에 `provisioningProfiles`가 있으면 gym이 `signingStyle: manual`을 자동으로 넣고, `teamID`는 `GYM_EXPORT_TEAM_ID`에서 가져온다. 따라서 `Fastfile`에 이 두 값을 직접 적을 필요는 없다.

### 알아둘 제약

- `QueenCamAppStore` 프로파일 만료일은 **2026-10-19**다. 그 전에 갱신하고 `BUILD_PROVISION_PROFILE_BASE64`를 다시 등록해야 한다.
- 이 팀에는 폐기된 Apple Distribution 인증서가 함께 존재한다. 현재 시크릿에 든 인증서는 유효함을 실행으로 확인했다. 유효한 인증서의 SHA-1은 `8B53BBBE8DF73E8F70C8A24D5C902D8B079AD220`이며 `QueenCamAppStore`와 `QueenCamDis` 모두 이 인증서를 포함한다.
- 프로젝트 Release 구성이 지정하는 `QueenCamDis`는 등록 기기가 포함된 Ad Hoc 프로파일이다. 로컬 Xcode는 Organizer가 배포 시점에 App Store용으로 재서명해 주지만 CI에는 그 단계가 없다.
- 파일마다 읽어오는 브랜치가 다르다. 댓글 이벤트는 기본 브랜치(develop)의 `testflight.yml`을 실행하지만, `Gemfile`·`Fastfile`·Xcode 프로젝트는 Checkout이 가져오는 main 기준이다. 워크플로 수정은 develop 머지로 즉시 반영되지만, 나머지는 다음 `/start` 릴리즈로 main에 반영되기 전까지 적용되지 않는다.

## 자동화 범위

```text
포함: main 코드 Archive → TestFlight 업로드
제외: App Store 심사 제출·출시
```

App Store 심사 제출과 실제 출시는 계속 사람이 App Store Connect에서 판단하고 수행한다.

## 실행 흐름

### 기존 Release 자동화

`release.yml`은 이미 팀에서 사용하던 Git 릴리즈 작업이다. 릴리즈 이슈의 `/start vX.Y.Z` 댓글을 받으면 develop 기준 release 작업을 수행하고, 버전·빌드 번호·CHANGELOG를 갱신한 뒤 main 병합·태그 생성·develop 반영을 수행한다. 시작·성공·실패 댓글도 이 기존 워크플로가 남긴다.

### 이번에 추가한 TestFlight 자동화

```text
릴리즈 이슈에 /start vX.Y.Z
→ 기존 Release 워크플로가 main 병합·태그 생성
→ Release 성공 댓글 확인
→ 같은 릴리즈 이슈에 /testflight
→ TestFlight 시작 댓글
→ main 코드 Archive
→ TestFlight 업로드
→ TestFlight 성공 또는 실패 댓글
```

`/testflight`에는 버전 번호를 붙이지 않는다. `/start`가 이미 버전과 빌드 번호를 갱신해 main에 반영했기 때문에, `/testflight`는 그 main 상태를 Archive하고 업로드만 한다.

GitHub Actions 화면의 **Run workflow** 버튼도 유지한다. 이는 댓글 실행이 어려운 상황이나 재실행이 필요할 때 main을 직접 선택해 실행하는 수단이다.

`/testflight` 댓글로 실행한 경우에는 같은 릴리즈 이슈에 시작·성공·실패 댓글이 남는다. 각 댓글에는 해당 Actions 실행 링크가 포함된다. **Run workflow** 버튼 실행에는 연결된 이슈가 없으므로, Actions 화면에서 결과와 로그를 확인한다.

## `/testflight` 실행 조건

다음 조건을 모두 통과해야 실제 Archive·업로드 job이 실행된다.

| 조건 | 이유 |
| --- | --- |
| 일반 이슈 댓글 | PR 댓글로 배포가 시작되는 일을 막는다. |
| 이슈 제목이 `🎤 [Release]`로 시작 | 릴리즈 이슈에서만 실행한다. |
| 댓글이 정확히 `/testflight` | 의도하지 않은 문장으로 실행되는 일을 막는다. |
| 작성자가 OWNER·MEMBER·COLLABORATOR | 외부 사용자의 댓글로 실행되는 일을 막는다. |

댓글 이벤트는 기본 브랜치 기준으로 시작하지만, TestFlight 작업은 Checkout에서 main을 명시적으로 가져온다. 따라서 실제 Archive 대상은 항상 main이다.

## 서명과 업로드 인증

| 구분 | 수동 Xcode Archive | GitHub Actions TestFlight 자동화 |
| --- | --- | --- |
| 프로비저닝 프로파일 | `QueenCamDis` | `QueenCamAppStore` |
| 실행 환경 | 팀원의 로컬 Mac | GitHub 임시 macOS |
| 사용 목적 | 기존 수동 배포 흐름 | App Store Connect용 IPA export와 TestFlight 업로드 |

GitHub Actions는 실행 때마다 임시 macOS에 인증서와 `QueenCamAppStore` 프로파일을 복원하고, 실행이 끝나면 임시 Keychain과 파일을 제거한다.

## 자동화 실패 시 수동 fallback

자동화가 실패해도 기존 수동 Xcode 배포 흐름은 바뀌지 않는다. 급한 배포가 필요하면 기존처럼 Xcode에서 `QueenCamDis` 설정으로 Archive하고 TestFlight 업로드를 진행한다. GitHub Actions의 `QueenCamAppStore` 설정은 Fastlane을 통한 자동화용 IPA export에만 적용된다.

## GitHub Secrets

값은 문서·채팅·Git에 기록하지 않는다. 아래 Secret 이름과 역할만 관리한다.

| Secret 이름 | 역할 |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | Apple Distribution 인증서 `.p12` 파일 |
| `P12_PASSWORD` | `.p12` 파일 비밀번호 |
| `KEYCHAIN_PASSWORD` | GitHub runner 임시 Keychain 비밀번호 |
| `BUILD_PROVISION_PROFILE_BASE64` | `QueenCamAppStore` 프로비저닝 프로파일 |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API Key 식별자 |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect 팀 식별자 |
| `APP_STORE_CONNECT_PRIVATE_KEY` | App Store Connect API Key의 `.p8` 개인 키 내용 |

기존 `DEPLOY_KEY_SECRET`은 `release.yml`이 브랜치·태그를 push할 때 쓰는 SSH 키다. TestFlight 인증에는 사용하지 않는다.

## 다음 실제 릴리즈 체크리스트

1. 릴리즈 이슈에서 `/start vX.Y.Z`를 입력한다.
2. Release 워크플로가 성공했고 main 병합·태그 생성이 끝났다는 댓글을 확인한다.
3. 같은 릴리즈 이슈에 정확히 `/testflight`를 입력한다.
4. Actions의 TestFlight 실행에서 `archive-and-upload` job 성공을 확인한다.
5. App Store Connect TestFlight에 새 버전·빌드 번호가 나타나는지 확인한다.
6. 결과와 Actions 실행 링크를 이 문서와 #463 이슈에 기록한다.

## 실패 시 대응

로그의 에러 문구로 아래 표를 찾는다.

| 로그 문구 | 원인과 대처 |
| --- | --- |
| `failed to run git: fatal: not a git repository` | 댓글 단계에 `GH_REPO`가 없다. job 레벨 env를 확인한다. |
| `multi_json is not part of the bundle` | main의 `Gemfile`에 `multi_json` 선언이 없다. develop에는 있어도 Checkout은 main을 가져온다. |
| `Validate plug-in "SwiftLintBuildToolPlugin"` | `GYM_XCARGS`의 `-skipPackagePluginValidation`이 빠졌다. |
| `xcodebuild -showBuildSettings timed out` | `FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT`이 빠졌거나 값이 낮다. |
| `does not support provisioning profiles` | 서명 설정이 xcargs로 전역 적용되고 있다. `GYM_SKIP_CODESIGNING`으로 Archive 시점 서명을 끈다. |
| `deployment target ... but the range of supported deployment target versions is` | 러너 Xcode가 프로젝트 배포 타겟보다 낮다. `Select Xcode` 단계 로그에서 어떤 버전이 선택됐는지 확인한다. 러너 이미지에 필요한 Xcode가 아직 없으면 수동 업로드를 사용한다. |
| job이 건너뛰어짐 | 이슈 제목, 댓글이 정확히 `/testflight`인지, 작성자 권한을 확인한다. |
| 이슈에 아무 댓글도 남지 않음 | `GH_REPO` 설정을 확인한다. |
| 서명 실패 | 인증서·프로파일 Secret과 만료일을 확인한다. 폐기된 인증서가 등록됐을 수 있다. |
| Apple 인증 실패 | App Store Connect API Key 관련 3개 Secret과 키 상태를 확인한다. |
| 재실행이 필요한 상황 | App Store Connect에 같은 빌드 번호가 이미 올라갔는지 먼저 확인한다. |
| 배포가 급함 | 기존 Xcode 수동 Archive·TestFlight 업로드를 사용한다. |

같은 버전·빌드 번호는 다시 업로드할 수 없으므로, 실패로 보이더라도 App Store Connect에서 업로드 여부를 먼저 확인한다. 다만 Archive 단계 실패는 애플 서버에 아무것도 보내지 않으므로 빌드 번호를 소모하지 않는다.

워크플로를 고칠 때는 [CI 사전 검증](ci-verification.md) 절차를 따른다.

## 이후 방향

첫 실제 업로드가 성공하면 팀은 다음 중 하나를 선택한다.

1. 현재 `/testflight` 댓글 방식을 유지한다.
2. 릴리즈 태그 생성 뒤 TestFlight 업로드까지 자동 실행하도록 확장한다.

어느 경우에도 App Store 심사 제출·출시는 이번 자동화 범위 밖으로 유지한다.
