# Localization

## UI 문구와 국제화

- UI에 노출되는 라이팅, 레이블, 버튼 문구, 섹션 타이틀은 가능한 한 `String`보다 `LocalizedStringKey`처럼 국제화 가능한 타입을 사용한다.
- 실제 다국어 리소스 생성, 번역 파일 작성, 문자열 테이블 분리는 별도 요청이 있을 때만 수행한다.
- 로그 메시지, 개발자 디버그 문자열, URL, 식별자처럼 사용자에게 직접 노출되지 않는 값은 이 규칙의 대상이 아니다.

예시: [QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/UIComponents/SettingSection.swift](../../QueenCam/QueenCam/Presentation/Views/Common/Settings/Main/UIComponents/SettingSection.swift)

```swift
struct SettingSection<Content: View> {
  let title: LocalizedStringKey
  let content: Content

  init(
    title: LocalizedStringKey,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.content = content()
  }
}
```
