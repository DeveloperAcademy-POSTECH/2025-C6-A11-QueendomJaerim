# Git And Collaboration

## 커밋, 이슈, PR 컨벤션

- 커밋 메시지, 이슈 제목/본문, PR 제목/본문을 작성하기 전에는 이 프로젝트의 최근 Git 커밋, 최근 이슈, 최근 PR을 먼저 읽고 형식을 맞춘다.
- 로컬에서 확인 가능한 커밋은 `git log --oneline -n 20` 등으로 먼저 본다.
- GitHub 이슈와 PR은 사용 가능한 도구가 있으면 최근 항목을 조회하고, 접근 권한이나 네트워크 제한으로 확인할 수 없으면 그 사실을 사용자에게 알린다.
- 커밋 제목은 `[Type] scope: 내용` 형식을 사용한다.
- 제목 아래에는 빈 줄을 두고, 무엇을 왜 바꿨는지 1~2문장으로 적는다.
- AI 도구가 커밋에 포함된 코드·문서·설정을 직접 작성했다면, 본문 뒤 빈 줄 다음에 실제 작성 도구를 밝히는 `Co-authored-by` trailer를 추가한다. Codex가 작성한 경우에는 `Co-authored-by: Codex <noreply@openai.com>`을 사용한다. 다른 도구가 실제 작성한 경우에는 그 도구에 맞는 식별자를 사용하며, 작성하지 않은 도구 이름을 넣지 않는다.
- `git add`, `git commit`, `git commit --amend` 등 Git 이력을 바꾸는 작업 전에는 반드시 커밋 범위, 대상 파일, 제목, 본문을 사용자에게 제안하고 명시적 승인을 받는다. 사용자의 일반적인 “진행” 요청만으로는 커밋을 만들지 않는다.
- 이모지, PR 번호, 릴리즈 브랜치 머지 메시지는 기존 히스토리에 맞춰 필요한 경우에만 사용한다.

최근 커밋 예시:

```text
[Feat] settings: 설정 페이지
[Fix] frame: 프레임 켜기/끄기 신호 분기처리
[Docs] release: v1.1.7 CHANGELOG.md
```

AI가 작성한 커밋 예시:

```text
[Chore] ci: TestFlight 업로드 자동화 설정 추가

GitHub Actions와 Fastlane으로 main 기준 Archive 및 TestFlight 업로드를 수행하도록 구성합니다.

Co-authored-by: Codex <noreply@openai.com>
```

## 금지 사항

- `dev` 브랜치에 직접 커밋하지 않는다.
- `main` 브랜치에 직접 커밋하지 않는다.
- 직접 커밋이 필요한 작업이라면 새 작업 브랜치를 만들고 커밋한다.
- 사용자가 명시적으로 요청하지 않은 destructive git 명령을 실행하지 않는다.
