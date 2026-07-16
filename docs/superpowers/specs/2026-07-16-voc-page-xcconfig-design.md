# VOC 페이지 URL 설정 설계

## 목표

설정 화면의 의견 보내기 URL을 새 Google Forms 주소로 변경하고, Swift 코드에 URL을 하드코딩하지 않는다.

## 설계

- 공통 xcconfig에 `VOC_PAGE_URL` 빌드 설정을 정의한다.
- Debug와 Release 구성 모두 해당 xcconfig를 사용한다.
- `Info.plist`의 `VOCPageURL` 값에 `$(VOC_PAGE_URL)`을 지정해 빌드 시 치환한다.
- `SettingsMainView`는 `Bundle.main.infoDictionary`에서 `VOCPageURL` 문자열을 읽어 `URL`로 변환한다.
- 값이 없거나 유효하지 않으면 기존 `openURL` 흐름이 `nil`을 받아 `QueenLogger`로 오류를 기록한다.

## 검증

- `xcodebuild -showBuildSettings`로 Debug와 Release 모두 새 설정값을 해석하는지 확인한다.
- 프로젝트 빌드로 xcconfig 연결, Info.plist 치환, Swift 컴파일을 확인한다.
- 구성 중심 변경이므로 별도 단위 테스트는 추가하지 않는다.
