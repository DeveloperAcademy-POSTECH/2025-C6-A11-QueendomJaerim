# Testing

## 테스트 정책

- 테스트 작성은 모든 작업에서 필수는 아니다.
- 그래도 새 코드는 최대한 테스트 용이하게 작성한다.
- 복잡도가 있는 로직을 새로 구현했다면 작업 중 또는 완료 전에 사용자에게 테스트를 작성할지 물어본다.
- 순수 함수, 매퍼, 상태 전이, 포맷팅, 권한/네트워크 상태 분기처럼 입출력이 분명한 로직은 테스트 후보로 우선 검토한다.
- 테스트를 작성하지 않았다면 최종 응답에서 테스트를 실행하지 않았거나 추가하지 않은 이유를 짧게 알린다.

테스트하기 쉬운 형태의 예시:

[QueenCam/QueenCam/Services/Ports/Network/Mappers/FrameMapper.swift](../../QueenCam/QueenCam/Services/Ports/Network/Mappers/FrameMapper.swift)

```swift
struct FrameMapper {
  static func convert(frame: Frame) -> FramePayload {
    FramePayload(
      id: frame.id,
      origin: GraphicMapper.convert(cgPoint: frame.rect.origin),
      size: GraphicMapper.convert(cgSize: frame.rect.size)
    )
  }
}
```

이런 순수 변환 로직은 입력과 출력이 명확하므로 단위 테스트를 붙이기 쉽다.
