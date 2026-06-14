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
