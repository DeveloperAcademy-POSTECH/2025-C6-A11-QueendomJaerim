# QueenCam 네트워크 모듈 사용 가이드 🧑‍💻

이 문서는 QueenCam 앱의 Wi-Fi Aware 네트워킹 구조를 설명하고, `NetworkService`를 사용하여 뷰 모델(View Model)에서 네트워크 기능을 구현하는 방법을 안내합니다.

## 🏛️ 네트워크 아키텍처 개요

우리 앱의 네트워크 레이어는 **세 가지 핵심 객체**로 구성된 계층적 구조를 가집니다. 각 객체는 명확하게 정의된 책임을 가지며, 이를 통해 코드의 유지보수성과 테스트 용이성을 높였습니다.

1.  **`ConnectionManager` (연결 관리자 - Low Level)**

      * **역할**: 실제 `WiFiAwareConnection` 객체들의 생명주기를 관리하는 가장 낮은 레벨의 관리자입니다.
      * **주요 책임**:
          * 활성화된 각 연결의 상태(`ready`, `failed` 등)를 감시합니다.
          * 각 연결로부터 들어오는 데이터(`NetworkEvent`)를 수신하고 스트림으로 전달합니다.
          * 데이터 전송, 연결 중단 등 개별 연결에 대한 직접적인 제어를 담당합니다.
          * 모든 작업은 `actor`를 통해 동시성으로부터 안전하게 처리됩니다.

2.  **`NetworkManager` (탐색 및 설정 관리자 - Mid Level)**

      * **역할**: 다른 기기를 탐색(`browse`)하거나 연결을 수신 대기(`listen`)하는 역할을 합니다.
      * **주요 책임**:
          * **Host (Publisher) 모드**: `NetworkListener`를 사용하여 다른 기기의 연결 요청을 기다립니다.
          * **Viewer (Subscriber) 모드**: `NetworkBrowser`를 사용하여 주변의 Host를 탐색합니다.
          * 새로운 연결이 성공적으로 수립되면, 해당 연결 객체를 `ConnectionManager`에 전달하여 관리를 위임합니다.

3.  **`NetworkService` (네트워크 서비스 - High Level / Facade)**

      * **역할**: **우리가 뷰 모델에서 사용할 유일한 퍼블릭 인터페이스**입니다. 복잡한 내부 동작을 숨기고 간단한 API를 제공하는 Facade 패턴 역할을 합니다.
      * **주요 책임**:
          * `ConnectionManager`와 `NetworkManager`를 소유하고 이벤트를 조정합니다.
          * 내부 매니저들로부터 오는 저수준 이벤트(`LocalEvent`, `NetworkEvent`)를 수신하여, UI가 이해하기 쉬운 고수준 상태(`NetworkState`)로 변환합니다.
          * **Combine Publisher** (`networkStatePublisher`, `deviceConnectionsPublisher`, `networkEventPublisher`)를 통해 뷰 모델에 현재 네트워크 상태, 연결 목록, 수신된 이벤트를 비동기적으로 전달합니다.
          * 뷰 모델로부터 `run()`, `stop()`, `send()`와 같은 간단한 명령을 받아 내부 로직을 실행합니다.

**흐름 요약**:
`ViewModel`은 `NetworkService`에 명령을 내립니다. `NetworkService`는 `NetworkManager`를 사용해 기기를 찾고 연결을 맺게 한 뒤, 생성된 연결을 `ConnectionManager`에 넘겨 관리하게 합니다. `ConnectionManager`와 `NetworkManager`에서 발생하는 모든 이벤트는 다시 `NetworkService`로 수집되어 가공된 후, Publisher를 통해 `ViewModel`로 전달됩니다.

## 🚀 `NetworkService` 사용 방법

`PreviewModel`의 예시처럼, 뷰 모델에서 네트워크 기능을 사용하는 것은 매우 간단합니다. 다음 세 단계를 따르면 됩니다.

### 1\. 의존성 주입 (Dependency Injection)

뷰 모델을 초기화할 때 `NetworkServiceProtocol`을 외부에서 주입받습니다. 이렇게 하면 뷰 모델이 구체적인 `NetworkService` 클래스에 의존하지 않게 되어 테스트가 쉬워집니다.

```swift
// PreviewModel.swift

final class PreviewModel {
    private let networkService: NetworkServiceProtocol
    private var cancellables: Set<AnyCancellable> = []

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        bind() // 초기화 시점에 바인딩을 시작합니다.
    }

    // ...
}
```

### 2\. 상태 바인딩 (Bind to Publishers)

`init` 시점에서 `bind()` 메서드를 호출하여 `NetworkService`가 제공하는 Publisher들을 구독합니다. 이를 통해 네트워크 상태 변화나 수신된 데이터를 실시간으로 반영할 수 있습니다.

  * `networkStatePublisher`: 현재 네트워크의 상태(`stopped`, `publishing`, `browsing`, `connected` 등)를 알려줍니다. UI 상태를 업데이트하는 데 사용하세요.
  * `deviceConnectionsPublisher`: 현재 연결된 기기 목록과 상세 정보(`ConnectionDetail`)를 제공합니다.
  * `networkEventPublisher`: 다른 기기로부터 수신된 `NetworkEvent` (예: 프리뷰 프레임, 렌더링 상태 보고)를 전달합니다.

<!-- end list -->

```swift
// (예) PreviewModel.swift

private func bind() {
    // 1. 네트워크 상태 변화 구독
    networkService.networkStatePublisher
        .compactMap { $0 }
        .sink { [weak self] state in
            self?.networkState = state
            // 예: 연결이 완료되면 전송 버튼 활성화
            self?.transferEnabled = (state == .host(.publishing) || state == .viewer(.connected))
        }
        .store(in: &cancellables)

    // 2. 연결된 기기 목록 구독
    networkService.deviceConnectionsPublisher
        .compactMap { $0 }
        .sink { [weak self] connections in
            self?.connections = connections
        }
        .store(in: &cancellables)

    // 3. 네트워크 이벤트 수신 구독
    networkService.networkEventPublisher
        .compactMap { $0 }
        .sink { [weak self] event in
            switch event {
            case .previewFrame(let framePayload):
                self?.handleReceivedFrame(framePayload) // 수신된 프레임 처리
            case .renderState(let state):
                self?.handleReceivedRenderStateReport(state) // 수신된 상태 보고 처리
            default: break
            }
        }
        .store(in: &cancellables)
}
```

### 3\. 액션 호출 (Call Methods)

사용자의 입력이나 로직에 따라 `NetworkService`의 메서드를 호출하여 네트워크 동작을 제어합니다.

  * **`run(for: WAPairedDevice)`**: 네트워크 기능을 시작합니다. `NetworkService`의 `mode` 프로퍼티 값(.host 또는 .viewer)에 따라 자동으로 리스닝 또는 브라우징을 시작합니다.
  * **`stop()`**: 모든 네트워크 활동과 연결을 중단합니다.
  * **`send(for: NetworkEvent)`**: 연결된 모든 기기에 `NetworkEvent`를 전송합니다.

<!-- end list -->

```swift
// (예) PreviewModel
// Photographer's Intent (Host)
extension PreviewModel {
    func startCapture() {
        isTransfering = true

        Task.detached { [weak self] in
            guard let self else { return }
            let framePayloadStream = await self.previewCaptureService.framePayloadStream
            
            // 캡처된 프레임 스트림을 반복하며 네트워크로 전송
            for await payload in framePayloadStream {
                await self.networkService.send(for: .previewFrame(payload))
            }
        }
    }
}

// Model's Intent (Viewer)
extension PreviewModel {
    // 프레임 렌더링이 불안정할 때 Host에게 상태 보고
    func frameDidSkipped() {
        Task.detached { [weak self] in
            await self?.networkService.send(for: .renderState(.unstable))
        }
    }
}
```

### 요약

  * **구조**: `NetworkService`가 `NetworkManager`와 `ConnectionManager`를 감싸는 3계층 구조입니다.
  * **사용**: 뷰 모델에서는 **오직 `NetworkService`만 사용**합니다.
  * **구현**:
    1.  `NetworkServiceProtocol`을 **의존성 주입** 받으세요.
    2.  `init`에서 `bind()`를 호출하여 **Publisher들을 구독**하고 상태를 업데이트하세요.
    3.  필요할 때 `run()`, `stop()`, `send()` 같은 **메서드를 호출**하여 네트워크를 제어하세요.

이 가이드를 통해 다른 뷰 모델에서도 쉽고 일관된 방식으로 네트워크 기능을 구현할 수 있을 것입니다. 궁금한 점이 있다면 언제든지 물어보세요\! 😊
