# Concurrency

## 기본 기조

- 새 비동기 코드는 되도록 Classic GCD보다 Swift Modern Concurrency를 우선한다.
- `async/await`, `Task`, `TaskGroup`, `AsyncSequence`, actor, `Sendable`을 먼저 검토한다.
- `DispatchQueue.async`, `DispatchGroup`, `DispatchSemaphore`, manual queue hopping은 기존 코드와의 호환, 특정 프레임워크 콜백 브리징, 성능상 명확한 이유가 있을 때만 사용한다.
- GCD를 사용해야 한다면 이유를 코드 구조로 드러내고, 범위를 작게 유지한다.
- 단순히 메인 스레드로 돌아가기 위해 `DispatchQueue.main.async`를 쓰기보다 `@MainActor`, `MainActor.run`, 메서드 단위 actor 격리를 먼저 검토한다.
- 콜백 기반 API를 감쌀 때는 `withCheckedContinuation` 또는 `withCheckedThrowingContinuation`을 사용해 호출부를 `async` 형태로 유지하는 것을 우선한다.
- 취소가 필요한 작업은 GCD work item보다 Swift concurrency의 task cancellation 전파를 우선한다.

권장 예시:

```swift
func loadThumbnail(scale: CGFloat) async {
  await photosLibraryObserver.loadThumbnail(scale: scale)
}
```

메인 액터 전환이 필요한 경우:

```swift
await MainActor.run {
  self.thumbnailImage = image
}
```

콜백 API 브리징 예시:

```swift
func requestValue() async throws -> Value {
  try await withCheckedThrowingContinuation { continuation in
    legacyClient.request { result in
      continuation.resume(with: result)
    }
  }
}
```

## Actor 격리 판단

- `@MainActor`는 기본값처럼 붙이지 않는다.
- 객체가 수행하는 작업의 종류, UI 상태 접근 여부, 액터 격리 필요성, 호출 빈도, 성능 비용을 함께 보고 결정한다.
- SwiftUI View, UI 상태를 직접 갱신하는 ViewModel, UIKit/AppKit 객체를 만지는 코드는 `@MainActor` 후보로 우선 검토한다.
- 네트워크, 파일 I/O, 인코딩/디코딩, 이미지 처리, 계산량이 큰 변환, 스트리밍 처리처럼 UI와 직접 관련 없는 작업은 메인 액터에 묶지 않는 방향을 우선 검토한다.
- 공유 mutable state를 보호해야 한다면 `@MainActor`로 밀어 넣기보다 해당 상태의 소유권에 맞는 actor, 불변 값 전달, 프로토콜 경계 분리를 먼저 검토한다.
- 빈번하게 호출되는 경로에 불필요한 액터 hop이 생기지 않는지 확인한다.
- `nonisolated`, `Sendable`, `@preconcurrency` 같은 도구는 의미를 이해하고 최소 범위로 사용한다.

## `@MainActor`를 붙이기 좋은 경우

- `@Observable` ViewModel이 SwiftUI View와 직접 바인딩되는 상태를 소유한다.
- UIKit, SwiftUI, Photos 권한 UI, 카메라 세션 UI 상태처럼 메인 스레드 제약이 있는 API를 직접 다룬다.
- 메서드 대부분이 UI 상태를 읽거나 갱신하고, 백그라운드 작업은 별도 서비스로 위임되어 있다.

예시: UI 상태와 권한 흐름을 다루는 ViewModel은 `@MainActor` 격리가 자연스럽다.

[QueenCam/QueenCam/Presentation/ViewModels/Camera/CameraViewModel.swift](../../QueenCam/QueenCam/Presentation/ViewModels/Camera/CameraViewModel.swift)

```swift
@Observable
@MainActor
final class CameraViewModel {
  var isCameraPermissionGranted = false
  var isPhotosPermissionGranted = false
  var isMicPermissionGranted = false

  func switchGrid() {
    isShowGrid.toggle()
    cameraSettingsService.gridOn = isShowGrid
  }
}
```

## `@MainActor`를 피하거나 분리할 경우

- 객체의 핵심 작업이 네트워크 이벤트 처리, 파일 쓰기, 이미지/비디오 처리, DTO 변환, 순수 계산이다.
- 메인 액터에 올리면 프레임 드랍이나 입력 지연을 만들 수 있다.
- 일부 UI 업데이트만 필요하고 대부분의 작업은 백그라운드에서 처리할 수 있다.
- 테스트에서 메인 액터 의존성이 불필요하게 커진다.

예시: 순수 변환 매퍼는 메인 액터 격리가 필요 없다.

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

## 작업 전 질문

- 이 타입은 UI 상태를 직접 소유하거나 갱신하는가?
- 이 타입의 메서드가 메인 스레드 제약이 있는 API를 호출하는가?
- 공유 mutable state 보호가 필요한가, 아니면 값 전달/불변 모델로 해결 가능한가?
- 호출 빈도가 높아 액터 hop 비용이 문제가 될 수 있는가?
- 무거운 작업을 메인 액터에 묶어 사용자 입력이나 렌더링을 막지 않는가?
- 더 작은 범위의 메서드 단위 `@MainActor` 또는 별도 actor가 더 적절한가?
