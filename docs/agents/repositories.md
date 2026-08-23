# Repositories

## 레이어 위치와 역할

- `QueenCam/QueenCam/Repositories`는 영속 저장소와의 데이터 입출력을 담당하는 데이터 레이어다.
- `Repositories`는 `Network`와 동등한 외부 데이터 계층이며, `Services` 아래에 두지 않는다.
- SwiftData, 파일 시스템, 캐시처럼 구체적인 저장 기술을 직접 다루는 Repository 구현체는 이 디렉토리에 둔다.
- Repository를 사용하는 유즈케이스와 도메인 정책은 `Services`에 두고, 서비스가 의존하는 프로토콜을 통해 구현 세부 사항을 분리한다.

## 의존성 방향

```text
Presentation → Services → Repository Protocol ← Repositories
                          ↑
                Common/Dependencies에서 조립
```

- `Presentation`은 구체 Repository 구현체를 직접 생성하거나 참조하지 않는다.
- `Services`는 Repository 프로토콜에 의존하고 조회·저장 결과를 도메인 동작으로 구성한다.
- `Repositories`의 구현체는 서비스가 요구하는 Repository 프로토콜을 준수한다.
- `Common/Dependencies`의 `DependencyContainer`가 구체 구현체를 생성해 서비스에 주입한다.
- `Network`와 `Repositories`는 서로 직접 의존하지 않는 형제 데이터 레이어로 유지한다. 두 데이터 소스를 조합하는 정책은 `Services`가 담당한다.

## Repository 책임

- 공개 메서드는 `find`, `insert`, `update`, `upsert`처럼 저장 기술에 대한 원자적 조회·쓰기 동작으로 제한한다.
- 신규 항목 판정, 메타데이터 병합, 연결 이력 갱신처럼 도메인 의미가 있는 정책은 Repository에 두지 않는다.
- 여러 읽기·쓰기를 원자적으로 처리해야 한다면 도메인 중립적인 API를 제공하고, 구체적인 충돌 해결 정책은 호출하는 서비스가 주입한다.
- SwiftData `@Model`처럼 저장 컨텍스트에 격리된 타입은 외부로 직접 노출하지 않고 불변 `Sendable` 스냅샷으로 변환한다.
- 저장 기술 또는 데이터 소스가 늘어나 관련 파일이 여러 개가 되면 `Repositories/<Feature>` 하위 디렉토리로 묶는다.

예시: [DeviceRepository.swift](../../QueenCam/QueenCam/Repositories/DeviceRepository.swift)는 SwiftData 조회와 원자적 upsert를 담당한다. 신규 기기 판정과 메타데이터 병합 정책은 `Services/Device`의 `WAPairedDeviceRegistry`가 담당한다.
