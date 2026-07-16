# 호환 최소 버전 xcconfig 설정 설계

## 목표

앱 호환 최소 버전 값을 Info.plist에 직접 작성하지 않고 공통 xcconfig에서 관리한다.

## 설계

- `Shared.xcconfig`에 `QUEENCAM_COMPATIBLE_MINIMUM_VERSION`을 정의한다.
- `Info.plist`의 `QueenCamCompatibleMinimumVersion` 값은 해당 빌드 설정을 치환한다.
- `VersionUtils.minimumVersionCompatibleWith`는 기존처럼 Bundle의 Info.plist 값을 읽고, 값 누락 시 `0.0.0`을 사용한다.
- 현재 앱 버전인 `MARKETING_VERSION`과 호환 최소 버전은 서로 다른 의미이므로 별도 설정으로 유지한다.

## 검증

- Debug와 Release 빌드 설정에서 호환 최소 버전 값을 확인한다.
- 빌드된 앱의 Info.plist에서 치환된 값을 확인한다.
- iOS Simulator Debug 빌드로 프로젝트 구성을 검증한다.
- 로직 변경이 없으므로 별도 단위 테스트는 추가하지 않는다.
