# Deployment

## CI/CD 작업 기준

- CI/CD 워크플로는 YAML 문법 검증만으로 머지하지 않는다. 실제 실행으로 성공을 확인한 뒤 머지한다.
- 검증은 실제 릴리즈 없이 가능하다. Archive까지만 수행하면 애플 서버에 아무것도 보내지 않으면서 코드 서명까지 검증된다. 절차는 [CI 사전 검증](../deployment/ci-verification.md)을 따른다.
- 워크플로에 설정을 추가할 때는 왜 필요한지를 주석과 문서에 남긴다. 근거 없는 설정은 다음 사람이 제거했다가 다시 깨뜨린다.
- 이미 붙인 설정 중 필요성이 확인되지 않은 것은 제거하고 다시 실행해 확인한다.

## 파일별 반영 경로

`issue_comment`로 실행하는 워크플로는 기본 브랜치의 워크플로 파일을 사용하지만, Checkout이 가져오는 파일은 지정한 ref 기준이다. TestFlight 자동화는 main을 Checkout한다.

| 파일 | 실행 시 어디서 읽히나 | 반영 시점 |
| --- | --- | --- |
| `.github/workflows/*.yml` | 기본 브랜치(develop) | develop 머지 즉시 |
| `Gemfile`, `fastlane/Fastfile`, Xcode 프로젝트 | Checkout이 가져오는 main | 다음 `/start` 릴리즈 |

`Gemfile`이나 `Fastfile` 수정은 develop에 머지해도 즉시 반영되지 않는다. main 직접 PR 대신 다음 정상 릴리즈를 기다리는 것을 우선한다.

## 운영 문서

- TestFlight 자동 업로드의 실행 방법, 설정 근거, 실패 대응은 [TestFlight 자동 업로드 안내](../deployment/testflight-automation.md)를 참고한다.
