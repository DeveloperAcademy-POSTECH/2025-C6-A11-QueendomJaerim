# TestFlight 자동 업로드 안내

## 현재 상태

**설정·Secret 등록·정적 검증은 완료했고, 실제 main Archive와 TestFlight 업로드는 다음 릴리즈에서 처음 검증한다.**

이 문서는 실제 업로드가 아직 성공했다고 주장하지 않는다. 첫 실행 결과와 Actions 링크는 성공 확인 후 이 문서에 추가한다.

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
