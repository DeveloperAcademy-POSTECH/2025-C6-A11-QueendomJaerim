# Presentation

## MVVM 기본 원칙

- 프레젠테이션 레이어는 MVVM을 기본 아키텍처로 사용한다.
- View는 화면 선언, 바인딩, 사용자 액션 전달에 집중한다.
- 상태 변경, 사이드 이펙트, 서비스 호출, 권한 요청, 네트워크 이벤트 처리는 ViewModel 또는 더 안쪽 계층에 둔다.
- ViewModel은 가능하면 프로토콜 타입 의존성을 주입받아 테스트 가능한 형태로 유지한다.

예시: `CameraViewModel`은 `NetworkServiceProtocol`, `CameraSettingsServiceProtocol`, `NotificationServiceProtocol`을 주입받아 View 밖에서 상태와 동작을 관리한다.

[QueenCam/QueenCam/Presentation/ViewModels/Camera/CameraViewModel.swift](../../QueenCam/QueenCam/Presentation/ViewModels/Camera/CameraViewModel.swift)

```swift
@Observable
@MainActor
final class CameraViewModel {
  let networkService: NetworkServiceProtocol
  let cameraSettingsService: CameraSettingsServiceProtocol
  private let notificationService: NotificationServiceProtocol

  init(
    previewCaptureService: PreviewCaptureService,
    networkService: NetworkServiceProtocol,
    cameraSettingsService: CameraSettingsServiceProtocol,
    notificationService: NotificationServiceProtocol
  ) {
    self.networkService = networkService
    self.cameraSettingsService = cameraSettingsService
    self.notificationService = notificationService
  }
}
```

## View 내부 순수 함수 예외

- View가 read-only이고 외부 상태를 변경하지 않는 값 변환 정도라면 View 안에 함수로 인라인해도 된다.
- 이 함수는 순수 함수 형태여야 한다. 같은 입력에 같은 출력을 반환하고, 서비스 호출, 저장소 접근, 네트워크 요청, 로깅, 알림 등록 같은 사이드 이펙트를 만들지 않는다.
- 변환 로직이 커지거나 여러 화면에서 반복되면 ViewModel, 매퍼, 유틸, 디자인 시스템 컴포넌트로 이동한다.

허용 예시:

```swift
private func title(for role: Role) -> LocalizedStringKey {
  switch role {
  case .photographer:
    return "작가 가이드"
  case .model:
    return "모델 가이드"
  }
}
```

피해야 할 예시:

```swift
private func titleAndTrack(for role: Role) -> LocalizedStringKey {
  analyticsService.track(...)
  return role.displayName
}
```
