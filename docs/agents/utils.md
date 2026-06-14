# Utils

## 자체 추상 레이어 우선

- 새 코드를 작성하기 전에 이미 구현된 자체 래퍼, 유틸, extension, 프로토콜 추상화가 있는지 먼저 확인한다.
- 표준 라이브러리나 플랫폼 API를 직접 호출하기 전에 프로젝트에서 감싼 레이어가 있다면 그 레이어를 우선 사용한다.
- 같은 목적의 새 유틸을 만들기 전에 `Common/Utils`, `Common/Extensions`, `Common/Logger`, `Common/Dependencies`, `Services/Ports`를 먼저 검색한다.
- 기존 추상 레이어로 표현하기 어렵다면 새 유틸을 만들 수 있지만, 이름과 위치는 기존 구조에 맞춘다.
- 앱 전역에서 반복될 가능성이 있는 래퍼는 피쳐 디렉토리보다 `Common` 또는 적절한 서비스 경계에 둔다.

## 로깅

- 표준 출력은 금지한다. 새 코드에 `print`, `debugPrint`, `dump`, `NSLog`를 추가하지 않는다.
- 런타임 로그는 `QueenLogger`를 사용한다.
- 로그 카테고리는 타입 또는 기능 이름을 기준으로 명확하게 작성한다.
- 디버그 전용 로그는 `QueenLogger.debug`를 사용한다. `QueenLogger` 내부에서 `DEBUG` 조건을 처리한다.
- 사용자에게 보여야 하는 오류는 로그에만 남기지 말고 ViewModel 상태, 알림 서비스, 토스트 등 기존 UI 경로로 전달한다.

예시: [QueenCam/QueenCam/Common/Logger/QueenLogger.swift](../../QueenCam/QueenCam/Common/Logger/QueenLogger.swift)

```swift
nonisolated public final class QueenLogger {
  public func info(_ message: @autoclosure () -> String) {
    let message = message()
    log(level: .info, message: message)
  }

  public func debug(_ message: @autoclosure () -> String) {
    let message = message()
    #if DEBUG
    log(level: .debug, message: message)
    #endif
  }
}
```

사용 예시: [QueenCam/QueenCam/Common/Utils/VersionUtils.swift](../../QueenCam/QueenCam/Common/Utils/VersionUtils.swift)

```swift
struct VersionUtils {
  private static let logger = QueenLogger(category: "VersionUtils")

  static func getVersionString(from versionNumber: Int) -> String {
    guard versionNumber >= 0 else {
      logger.warning("음수 버전 번호는 지원하지 않습니다. input=\(versionNumber)")
      return "0.0.0"
    }

    let majorVersion = versionNumber / 10_000_000
    return "\(majorVersion).0.0"
  }
}
```

피해야 할 예시:

```swift
print("디코딩 실패: \(error)")
debugPrint(value)
NSLog("request failed")
```

## 공통 유틸 위치

- 버전 파싱과 호환성 판단은 `VersionUtils`를 우선 확인한다.
- 앱 언어/Locale 판단은 `LocaleUtils`를 우선 확인한다.
- 랜덤 문자열 생성은 `RandomGenerator`를 우선 확인한다.
- 시간 변환, UIKit 이벤트, Notification 이름처럼 타입별 확장이 이미 있으면 해당 extension을 사용한다.

예시: [QueenCam/QueenCam/Common/Utils/LocaleUtils.swift](../../QueenCam/QueenCam/Common/Utils/LocaleUtils.swift)

```swift
struct LocaleUtils {
  static var currentLocale: Locale {
    if let firstLocale = appLocales.first {
      return Locale.from(identifier: firstLocale)
    }

    return .korean
  }
}
```

예시: [QueenCam/QueenCam/Common/Extensions/TimeInterval+CMTimeConverter.swift](../../QueenCam/QueenCam/Common/Extensions/TimeInterval+CMTimeConverter.swift)

```swift
extension TimeInterval {
  func toCMTime() -> CMTime {
    let scale = CMTimeScale(NSEC_PER_SEC)
    let cmTime = CMTime(value: CMTimeValue(self * Double(scale)), timescale: scale)
    return cmTime
  }
}
```

## 새 유틸 추가 기준

- 피쳐 내부에서 한 번만 쓰이는 작은 변환은 피쳐 내부 private 함수 또는 타입으로 둔다.
- 두 곳 이상에서 반복되거나 도메인 규칙을 담는다면 공통 유틸, 매퍼, 서비스 중 적절한 위치로 이동한다.
- 테스트 가능한 순수 로직이라면 사이드 이펙트를 제거하고 입력/출력이 드러나는 API로 만든다.
- 로깅, 설정, 네트워크, 알림, 분석처럼 이미 자체 레이어가 있는 영역은 직접 플랫폼 API를 호출하지 않는다.
