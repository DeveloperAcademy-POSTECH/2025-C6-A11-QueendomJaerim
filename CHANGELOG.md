# Changelog

이 프로젝트의 중요한 변경 사항은 이 문서에 기록한다.

이 문서의 형식은 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 따르고,
이 프로젝트의 버저닝은 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)를 기준으로 수행한다.

## [Unreleased]

### Added

- 라이브 포토 재생 기능

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.0.1]

### Added

- 기본 프로젝트 구조
- 카메라 기본 기능 및 프리뷰 
- 네트워크 레이어
- 카메라 촬영에 설정할 수 있는 기능들
- 카메라 프리뷰 스트리밍
- 현재 네트워크 상태 모달
- 촬영한 사진 모델에게 전송
- 스트리밍 품질에 Very Low 단계 추가
- 포토 피커 및 촬영한 사진 확인할 수 있는 기능 추가
- 레퍼런스 기능
- 펜 가이드라인 작성
- 라이브 포토 모델에게 전송
- 프레임 가이드라인 작성
- 영어 로케일 추가
- 레퍼런스 이미지 관련 이벤트 (등록, 제거) 송수신
- 기기 회전 방향에 따른 이미지 저장
- 프레임 관련 이벤트 (등록, 업데이트, 제거) 송수신

### Changed

- 스트리밍 시작 화질 .high -> .medium
- .veryLow 화질 품질 조정
- 프레임 딜레이 판정 기준 1/8초 -> 1/3초로 완화
- 전송 FPS 고정 (30 frames / 1 second)
- 현재 프레임 화질을 표시하는 디버그용 오버레이 추가

### Fixed

- 연결이 끊겼는데도 카메라 프리뷰 캡쳐가 중단되지 않았던 문제
- Wi-Fi Aware 연결 후, 라이브 포토 촬영 시 앱이 크래시되는 문제
- 레퍼런스 삭제 후 재등록에 관한 상태 초기화 문제

[0.0.1]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/releases/tag/v0.0.1
[unreleased]: hhttps://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim
