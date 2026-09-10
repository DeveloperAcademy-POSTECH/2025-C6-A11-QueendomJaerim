# CI 사전 검증

## 왜 필요한가

CI/CD 워크플로는 문법 검사만으로 동작을 보장할 수 없다. 로컬 Mac에는 이미 갖춰져 있지만 GitHub 러너에는 없는 것들이 많기 때문이다.

| 로컬 Mac | GitHub 러너 |
| --- | --- |
| Xcode가 설치·선택되어 있음 | 여러 버전이 설치되어 있고 기본값이 프로젝트와 안 맞을 수 있음 |
| 인증서·프로파일이 키체인에 있음 | 매번 새로 설치해야 함 |
| SPM 빌드 툴 플러그인을 승인해둔 상태 | 승인 기록도, 승인할 UI도 없음 |
| Organizer가 배포 시점에 재서명 | 그 단계가 없음 |

TestFlight 자동화 1차 도입 시 이 계열의 문제 6가지가 첫 실제 릴리즈에서 한꺼번에 드러났다. 사전 검증으로 릴리즈 전에 모두 잡을 수 있는 문제였다.

## 어디까지 애플 서버와 무관한가

```text
빌드 → 코드 서명 → IPA 생성    애플 서버 접촉 없음, 빌드 번호 소모 없음
업로드                          애플 서버 접촉, 빌드 번호 소모
```

코드 서명은 러너에 설치한 인증서와 프로파일로 로컬에서 이뤄진다. 따라서 **Archive까지만 수행하면 애플 쪽에는 아무것도 가지 않으면서 인증서 유효성까지 검증된다.** 실제 릴리즈 없이 대부분의 위험을 제거할 수 있다.

### 업로드 경로 검증

업로드 직전까지 확인하려면 `xcrun altool --validate-app`을 쓴다. 애플 서버에 IPA를 보내 인증과 형식을 검사하지만, 빌드를 만들지 않으므로 **빌드 번호를 소모하지 않는다.** Xcode Organizer의 `Validate App` 버튼과 같은 검사다.

```bash
mkdir -p "$HOME/.appstoreconnect/private_keys"
printf '%s' "$APP_STORE_CONNECT_PRIVATE_KEY" \
  > "$HOME/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"

xcrun altool --validate-app \
  -f build/QueenCam.ipa \
  -t ios \
  --apiKey "$APP_STORE_CONNECT_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
```

통과하면 다음이 확인된다.

| 항목 | 확인됨 |
| --- | --- |
| App Store Connect API Key 3종이 유효한가 | 예 |
| `.p8` 키 내용이 온전한가 (줄바꿈·헤더 누락 없음) | 예 |
| 애플이 이 IPA를 받아줄 형식인가 (아이콘, 권한, 개인정보 매니페스트 등) | 예 |
| 실제 파일 전송이 되는가 | 아니오 |

업로드 실패 원인은 대부분 앞의 세 가지다. 전송 자체는 인증이 통과하면 대개 성공하고, 실패해도 일시적이라 재실행으로 해결된다.

검사 후 키 파일은 반드시 지운다.

```bash
rm -rf "$HOME/.appstoreconnect"
```

## 검증 절차

```bash
# 1. 실제 배포 대상과 같은 파일 상태에서 시작한다
git checkout -b verify/작업이름 origin/main

# 2. 워크플로를 검증용으로 바꾼다 (이 브랜치에서만)
#    - job의 if 조건에서 브랜치 제한 제거
#    - checkout ref를 ${{ github.ref }}로 변경
#    - 업로드 없이 Archive만 수행하는 랜을 추가하고 그것을 실행
git push -u origin verify/작업이름

# 3. 실행
gh workflow run TestFlight --ref verify/작업이름

# 4. 실패하면 로그를 보고 고친 뒤 다시 실행한다. 초록불이 될 때까지 반복한다.
gh run list --workflow=TestFlight --limit 1
gh run view <실행ID> --log-failed

# 5. 초록불이 되면 검증된 수정만 develop에 PR한다
# 6. 검증 브랜치를 삭제한다
git push origin --delete verify/작업이름
```

댓글 단계는 `github.event_name == 'issue_comment'` 조건으로 막혀 있으므로, `workflow_dispatch` 실행에서는 릴리즈 이슈에 알림이 가지 않는다.

## 주의: dispatch 경로를 막지 말 것

`workflow_dispatch` 트리거를 특정 브랜치로 제한하면 이 검증 경로 자체가 사라진다.

```yaml
# 이 조건이 있으면 다른 브랜치에서 Run workflow를 눌러도 job이 건너뛰어진다
if: github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'
```

TestFlight 워크플로는 이 제한을 유지한다. 실수로 임의 브랜치에서 실행해 TestFlight에 잘못된 빌드가 올라가는 것을 막기 위해서다. 대신 검증이 필요할 때는 위 절차대로 검증 브랜치에서 이 조건을 일시적으로 푼다.

## 실행 시간

SPM 패키지 캐시가 없어 한 번 실행에 5~6분이 걸린다. 실패는 순차적으로 드러나므로 문제가 N개면 최소 N번 실행해야 한다.
