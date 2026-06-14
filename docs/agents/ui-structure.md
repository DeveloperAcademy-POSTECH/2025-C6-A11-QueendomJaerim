# UI Structure

## 디렉토리와 네이밍

- 기능은 피쳐 단위 디렉토리로 묶는다.
- 페이지 격의 SwiftUI 뷰는 `~View`로 네이밍한다.
- 페이지 내부에서만 쓰이는 작은 컴포넌트는 해당 피쳐의 `UIComponents` 디렉토리에 둔다.
- 여러 화면에서 반복될 가능성이 있거나 디자인 토큰과 강하게 결합된 컴포넌트는 `Presentation/DesignSystem` 또는 `Presentation/DesignSystem/Components`에 둔다.
- HIG 기본 Shape, SwiftUI 기본 Shape, 반복되는 버튼/섹션/패널 구조를 페이지에서 직접 계속 조립하지 않는다. 먼저 컴포넌트화하고 페이지에서는 조합한다.

피쳐 디렉토리와 페이지 뷰 예시: [QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/SettingsMainView.swift](../../QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/SettingsMainView.swift)

```swift
struct SettingsMainView {
  let navigationRouter: NavigationRouter
  let role: Role?
}

extension SettingsMainView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        SettingSection(title: "찍자 이용 가이드") {
          SettingBanner {
            if let role {
              guideSheetItem = GuideSheetItem(role: role)
            } else {
              isConfirmingRole.toggle()
            }
          }
        }
      }
    }
  }
}
```

피쳐 전용 컴포넌트 예시: [QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/UIComponents/SettingSectionItem.swift](../../QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/UIComponents/SettingSectionItem.swift)

```swift
struct SettingSectionItem {
  let action: () -> Void
  var title: LocalizedStringKey?
  var supplementayText: LocalizedStringKey?
  var disabled: Bool = false
}
```

반복 가능한 디자인 시스템 컴포넌트 예시: [QueenCam/QueenCam/Presentation/DesignSystem/Components/CircleButton.swift](../../QueenCam/QueenCam/Presentation/DesignSystem/Components/CircleButton.swift)

```swift
struct CircleButton: View {
  let systemImage: String
  let isActive: Bool
  let action: () -> Void
}
```
