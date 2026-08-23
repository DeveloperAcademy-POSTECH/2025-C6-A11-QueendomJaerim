# Architecture

## 클린 아키텍처 지향

- 의존성 방향은 바깥 계층이 안쪽 정책을 바라보도록 유지한다.
- UI는 사용자 입력과 상태 표현에 집중하고, 네트워크/저장소/시스템 API 세부 구현에 직접 의존하지 않는다.
- 앱 공통 기능은 프로토콜, 서비스, 매퍼, DTO, 엔티티 경계를 분리해 테스트 가능하게 둔다.
- 외부 프레임워크나 플랫폼 API에 강하게 묶인 구현은 가능한 한 서비스 또는 어댑터 뒤에 둔다.

예시: 네트워크 연결 세부 구현은 `ConnectionManagerProtocol` 뒤에 숨기고, 상위 계층은 프로토콜에 의존한다.

[QueenCam/QueenCam/Services/Ports/Network/ConnectionManagerProtocol.swift](../../QueenCam/QueenCam/Services/Ports/Network/ConnectionManagerProtocol.swift)

```swift
protocol ConnectionManagerProtocol: Sendable {
  var localEvents: AsyncStream<LocalEvent> { get }
  var networkEvents: AsyncStream<NetworkEvent> { get }

  func add(_ connection: WiFiAwareConnection) async
  func setupConnection(to endpoint: WAEndpoint) async
  func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async
  func sendToAll(_ event: NetworkEvent) async
}
```

예시: 네트워크 DTO와 UI/도메인 모델 사이 변환은 매퍼에 둔다.

[QueenCam/QueenCam/Services/Ports/Network/Mappers/FrameMapper.swift](../../QueenCam/QueenCam/Services/Ports/Network/Mappers/FrameMapper.swift)

```swift
struct FrameMapper {
  static func convert(payload: FramePayload) -> Frame {
    Frame(
      id: payload.id,
      rect: CGRect(
        origin: GraphicMapper.convert(pointPayload: payload.origin),
        size: GraphicMapper.convert(sizePayload: payload.size)
      )
    )
  }
}
```

## DI 정책

- 앱 전역 의존성은 `DependencyContainer`를 기준으로 등록하고 주입한다.
- 서비스 구현체를 뷰나 뷰모델 내부에서 직접 생성하기 전에, 컨테이너 또는 기존 주입 경로가 있는지 먼저 확인한다.
- 테스트 가능한 경계를 유지하기 위해 서비스는 가능한 한 프로토콜 타입으로 노출한다.
- 새 서비스가 네트워크, 저장소, 설정, 알림, 분석처럼 앱 공통 의존성이라면 `Common/Dependencies`의 컨테이너에 등록하는 방식을 우선 검토한다.

예시: [QueenCam/QueenCam/Common/Dependencies/DenpencyContainer.swift](../../QueenCam/QueenCam/Common/Dependencies/DenpencyContainer.swift)

```swift
final class DependencyContainer {
  static let defaultContainer: DependencyContainer = .init()

  lazy var connectionManager: ConnectionManagerProtocol = ConnectionManager()
  lazy var networkManager: NetworkManagerProtocol = NetworkManager(connectionManager: connectionManager)
  lazy var networkService: NetworkServiceProtocol = NetworkService(
    networkManager: networkManager,
    connectionManager: connectionManager
  )
}
```

## Repository와 Service 책임

- 구체적인 Repository 구현체는 `Network`와 동등한 외부 데이터 계층인 `QueenCam/QueenCam/Repositories`에 둔다. 상세한 배치 및 의존성 규칙은 [Repositories](repositories.md)를 참고한다.
- Repository를 사용하는 유즈케이스와 도메인 정책은 `Services`에 두고, 서비스는 Repository 프로토콜에 의존한다.
- Repository는 영속 모델과 영속 컨텍스트를 직접 다루는 데이터 계층이다.
- Repository의 공개 메서드는 `find`, `insert`, `update`, `upsert`처럼 조회·저장 동작이 드러나는 로우레벨 원자 작업으로 제한한다.
- 새 항목 판정, 메타데이터 갱신, 연결 이력 기록처럼 도메인 의미가 있는 유즈케이스는 Repository를 참조하는 Service에서 구성한다.
- 여러 읽기·쓰기의 원자성이 필요하면 도메인 메서드를 Repository에 추가하지 않는다. 대신 충돌 해결 클로저를 받는 `upsert` 등 도메인 중립적인 원자 작업을 Repository가 제공하고, Service가 병합 정책을 주입한다.
- SwiftData `@Model`처럼 영속 컨텍스트에 격리된 참조 타입은 Repository 밖으로 직접 반환하지 않는다. 필요한 경우 불변 `Sendable` 스냅샷으로 변환해 전달한다.

예시: Wi-Fi Aware 기기 이력에서는 [DeviceRepository](../../QueenCam/QueenCam/Repositories/DeviceRepository.swift)가 식별자 조회와 원자적 upsert만 담당한다. 신규 기기 판정, OS 메타데이터 병합, 최근 연결 시각 갱신은 `WAPairedDeviceRegistry`가 구성한다.
