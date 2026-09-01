# TestFlight 자동 업로드 안내

## 현재 상태

**설정·Secret 등록·정적 검증은 완료했으나, 첫 실제 실행(v1.1.11)은 실패했다. main Archive와 TestFlight 업로드는 아직 한 번도 성공하지 않았다.**

이 문서는 실제 업로드가 아직 성공했다고 주장하지 않는다. 성공한 첫 실행 결과와 Actions 링크는 성공 확인 후 이 문서에 추가한다.

### 첫 실행(v1.1.11) 실패 기록

| 항목 | 내용 |
| --- | --- |
| 릴리즈 이슈 | [#468](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/issues/468) |
| Actions 실행 | [33473681621](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/actions/runs/33473681621) |
| 실패 단계 | `Post TestFlight Start Comment` (첫 단계) |
| 오류 | `failed to run git: fatal: not a git repository` |

시작 댓글 단계가 Checkout보다 먼저 실행되는데, 그 시점에는 작업 디렉터리에 `.git`이 없어 `gh`가 대상 저장소를 추론하지 못했다. 같은 이유로 `Post TestFlight Failure Comment`도 함께 실패해서 실패 댓글이 이슈에 남지 않았다. Checkout·Archive·업로드 단계는 실행되지 않았다.

조치로 job 레벨에 `GH_REPO`를 지정해, Checkout 성공 여부와 무관하게 세 댓글 단계가 동작하도록 했다. Archive와 업로드 경로는 여전히 검증되지 않은 상태다.

### 서명 설정 보정

첫 실행에서는 확인하지 못했지만, Archive 단계에도 문제가 있었다. Xcode 프로젝트의 Release 구성은 수동 서명이면서 프로비저닝 프로파일로 `QueenCamDis`를 지정한다. `QueenCamDis`는 등록 기기 목록이 포함된 Ad Hoc 프로파일이라 로컬 Xcode에서는 Organizer가 배포 시점에 App Store용으로 다시 서명해 주지만, CI에는 `QueenCamAppStore`만 설치되므로 Archive 단계에서 프로파일을 찾지 못한다. Fastlane의 `export_options`는 Archive가 아니라 export 시점에만 적용되어 이 문제를 막지 못한다.

그래서 Archive 단계에 CI 전용 서명 값을 주입한다. `Fastfile`은 환경 중립으로 두고, GitHub Actions에서만 `GYM_XCARGS`로 프로파일과 서명 방식을 덮어쓴다.

| 설정 | 값 | 근거 |
| --- | --- | --- |
| `PROVISIONING_PROFILE_SPECIFIER` | `QueenCamAppStore` | App ID `D22ZM93S77.com.queendom.QueenCam` 일치, 등록 기기 없음(App Store 유형) |
| `CODE_SIGN_IDENTITY` | `Apple Distribution` | `QueenCamAppStore`에 포함된 인증서의 실제 Common Name |
| `CODE_SIGN_STYLE` | `Manual` | 프로젝트 Release 구성과 동일 |
| `DEVELOPMENT_TEAM` | `D22ZM93S77` | 프로파일 Team ID |

또한 Xcode 16부터 프로비저닝 프로파일 경로가 `~/Library/Developer/Xcode/UserData/Provisioning Profiles`로 바뀌었으므로, 기존 경로와 새 경로 양쪽에 설치한다.

이 보정은 실제 실행으로 아직 검증되지 않았다. Archive 로그의 `Provisioning profile:`과 `Signing Identity:` 줄에서 의도한 값이 선택됐는지 확인한다.

### 알아둘 제약

- `QueenCamAppStore` 프로파일 만료일은 **2026-10-19**다. 그 전에 갱신하고 `BUILD_PROVISION_PROFILE_BASE64`를 다시 등록해야 한다.
- 이 팀에는 폐기된(revoked) Apple Distribution 인증서가 함께 존재한다. `BUILD_CERTIFICATE_BASE64`에 폐기된 인증서가 들어 있으면 서명은 실패한다. 유효한 인증서의 SHA-1은 `8B53BBBE8DF73E8F70C8A24D5C902D8B079AD220`이며, `QueenCamAppStore`와 `QueenCamDis` 모두 이 인증서를 포함한다.
- 파일마다 읽어오는 브랜치가 다르다. 댓글 이벤트는 기본 브랜치(develop)의 `testflight.yml`을 실행하지만, `Fastfile`과 Xcode 프로젝트는 Checkout이 가져오는 main 기준이다. 워크플로 수정은 develop 머지로 즉시 반영되지만, `Fastfile`이나 Xcode 설정 수정은 다음 `/start` 릴리즈로 main에 반영되기 전까지 적용되지 않는다. 위 서명 보정을 `Fastfile`이 아니라 워크플로에 둔 이유이기도 하다.

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

| 관찰한 상황 | 먼저 확인할 것 |
| --- | --- |
| job이 건너뛰어짐 | 이슈 제목, 댓글이 정확히 `/testflight`인지, 작성자 권한, main 반영 여부 |
| 이슈에 아무 댓글도 남지 않음 | 워크플로의 `GH_REPO` 설정 여부. 없으면 Checkout 이전 단계에서 `gh`가 저장소를 찾지 못한다. |
| 서명 실패 | 인증서·프로파일 Secret 이름, 만료일, `QueenCamAppStore` 매핑 |
| Apple 인증 실패 | API Key 관련 3개 Secret 이름과 App Store Connect API Key 상태 |
| 재실행이 필요한 상황 | App Store Connect에 같은 빌드 번호가 이미 올라갔는지 먼저 확인 |
| 배포가 급함 | 기존 Xcode 수동 Archive·TestFlight 업로드를 사용 |

같은 버전·빌드 번호는 다시 업로드할 수 없으므로, 실패로 보이더라도 App Store Connect에서 업로드 여부를 먼저 확인한다.

## 이후 방향

첫 실제 업로드가 성공하면 팀은 다음 중 하나를 선택한다.

1. 현재 `/testflight` 댓글 방식을 유지한다.
2. 릴리즈 태그 생성 뒤 TestFlight 업로드까지 자동 실행하도록 확장한다.

어느 경우에도 App Store 심사 제출·출시는 이번 자동화 범위 밖으로 유지한다.
