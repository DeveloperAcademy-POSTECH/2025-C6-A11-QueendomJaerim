# AGENTS.md

이 문서는 이 저장소에서 작업하는 에이전트와 LLM 기반 도구를 위한 인덱스다. 코드 변경 전에는 현재 코드 구조, 최근 커밋, 이슈, PR 흐름을 먼저 확인하고 기존 컨벤션을 우선한다.

## 기본 원칙

- 기존 아키텍처와 네이밍을 우선한다.
- 변경 범위는 요청된 기능과 직접 관련된 파일로 좁게 유지한다.
- 사용자 또는 다른 작업자가 만든 변경 사항을 되돌리지 않는다.
- 새 규칙을 만들기보다 이미 있는 `Presentation`, `Services`, `Common`, `DesignSystem` 패턴을 따른다.

## 작업 가이드

- 클린 아키텍처 지향과 DI 정책은 [Architecture](docs/agents/architecture.md)를 참고한다.
- 프레젠테이션 레이어의 MVVM 기준, View/ViewModel 역할 분리, 순수 함수 예외는 [Presentation](docs/agents/presentation.md)을 참고한다.
- 피쳐 단위 디렉토리, `~View` 네이밍, `UIComponents`와 `DesignSystem` 구분은 [UI Structure](docs/agents/ui-structure.md)를 참고한다.
- 컬러, 폰트, 디자인 토큰 사용 방식은 [Design System](docs/agents/design-system.md)을 참고한다.
- 로깅, 공통 유틸, 자체 구현 추상 레이어 사용 기준은 [Utils](docs/agents/utils.md)를 참고한다.
- Actor 격리, `@MainActor` 적용 판단, Swift Concurrency 사용 기준은 [Concurrency](docs/agents/concurrency.md)를 참고한다.
- 파일 헤더와 주석 작성 기준은 [File Comments](docs/agents/file-comments.md)를 참고한다.
- UI 문구와 국제화 가능한 문자열 타입 사용 기준은 [Localization](docs/agents/localization.md)을 참고한다.
- 테스트 작성 판단과 테스트 용이성 기준은 [Testing](docs/agents/testing.md)을 참고한다.
- `CHANGELOG.md` 갱신 기준은 [Changelog](docs/agents/changelog.md)를 참고한다.
- 커밋, 브랜치, 이슈, PR 컨벤션과 금지 사항은 [Git And Collaboration](docs/agents/git-and-collaboration.md)을 참고한다.

## 작업 전 체크리스트

- 관련 피쳐 디렉토리와 `DesignSystem`을 먼저 확인했는가?
- 새 의존성이 DI 컨테이너 또는 기존 주입 경로에 맞는가?
- 페이지 뷰에서 반복 UI를 직접 조립하지 않고 컴포넌트화했는가?
- UI 문구가 국제화 가능한 타입으로 표현되어 있는가?
- 컬러와 폰트가 디자인 시스템을 우선 참조하는가?
- 표준 출력 대신 `QueenLogger`를 사용했는가?
- 이미 구현된 자체 래퍼, 유틸, 추상 레이어를 우선 확인했는가?
- `@MainActor`나 커스텀 actor 격리가 실제 작업 성격과 성능 요구에 맞는가?
- 파일 헤더의 작성자가 LLM 또는 도구 이름으로 들어가지 않았는가?
- 복잡도가 있는 로직을 새로 구현했다면 사용자에게 테스트 작성 여부를 물었는가?
- 작업 완료 후 `CHANGELOG.md`의 `[Unreleased]` 섹션에 내용을 정리했는가?
- 커밋, 이슈, PR 작성 전 최근 컨벤션을 확인했는가?
