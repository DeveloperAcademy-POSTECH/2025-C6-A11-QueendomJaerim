# Design System

## 컬러와 폰트

- 모든 컬러와 폰트는 우선적으로 `Presentation/DesignSystem`과 `Assets.xcassets/Colors`를 확인한다.
- 하드코딩한 `Color(red:green:blue:)`, `.system(size:weight:)`, 임의 hex 컬러를 새로 추가하기 전에 기존 토큰으로 표현 가능한지 확인한다.
- 피쳐에만 존재하는 색상이라도 반복 가능성이 있으면 디자인 시스템 토큰으로 승격하는 것을 우선 검토한다.
- 새 타이포그래피가 필요하면 `TypographyStyle`에 추가하는 방식을 우선한다.

컬러 토큰 위치 예시: [QueenCam/QueenCam/Resource/Assets.xcassets/Colors](../../QueenCam/QueenCam/Resource/Assets.xcassets/Colors)

폰트 시스템 예시: [QueenCam/QueenCam/Presentation/DesignSystem/Font+DesignSystem.swift](../../QueenCam/QueenCam/Presentation/DesignSystem/Font+DesignSystem.swift)

```swift
enum TypographyStyle: CaseIterable {
  case r12
  case sb16
  case b22
}

extension View {
  func typo(_ style: TypographyStyle) -> some View {
    self.modifier(TypographyModifier(style: style))
  }
}
```
