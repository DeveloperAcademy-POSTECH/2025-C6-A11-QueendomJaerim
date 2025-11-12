# Changelog

이 프로젝트의 중요한 변경 사항은 이 문서에 기록한다.

이 문서의 형식은 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 따르고,
이 프로젝트의 버저닝은 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)를 기준으로 수행한다.

## [Unreleased]

### Added

- 타이포그라피 시스템 업데이트
- 페어링 및 연결 하이파이 디자인 적용

### Changed

- 가이딩 토글 버튼에 따른 비활성화 상태 변경
- Appearance를 Dark로 고정

### Deprecated


### Removed


### Fixed

- 연속 사진 촬영시 사진 저장 안되는 이슈 수정

- `v0.3.3`에서 에셋 이미지 일부 누락되었던 문제 수정
- 재연결시 이전 커넥션을 잘 정리하지 않았던 문제 수정

### Security


## [0.3.3] (2025-11-07)

### Added

- CameraView에서 화면이 꺼지지 않도록 수정

### Changed

- 화질 조정 관련 패러미터 수정
- 스프리밍 Unstable 판정이 조금 더 어렵게 수정

## [0.3.2] (2025-11-06)

### Fixed

- PreviewPlayerView 패딩으로 인해 모델 뷰 레이아웃이 깨지는 문제

## [0.3.1] (2025-11-06)

### Fixed

- PreviewPlayerView 주변 패딩 제거

## [0.3.0] (2025-11-06)

### Added

- 커스텀 로거 구현
- 앱 실행시 본인의 최근 이미지 썸네일로 설정
- 펜 수정 툴바(전체삭제, 실행 취소) 노출 및 활성화 조건 추가
- 매직펜 하이파이 디자인 추가(블러효과)
- 권한 거부에 따른 UI 추가
- 하드웨어 버튼을 통한 촬영
- 프레임 비율 조정 시, 프레임 내 그리드와 디밍 효과 추가
- 양방향 프레임의 수정 점유권에 따른 하이파이 구현
- 정상적으로 상대가 연결을 종료했을 때 오버레이 표시

### Changed

- 작가 2차 하이파이 구현
- 포토 디테일 뷰 하이 파이
- Encoder에서 2초마다 한 번 키프레임을 전송하도록 설정 수정
- 가이딩 선택 및 노출 조건 추가
- 펜과 매직펜 구분 프로퍼티 추가
- 화면 내 레퍼런스 위치 및 배치 수정
- 원본 이미지의 비율을 고려하여 레퍼런스 크기 조절
- 재연결 뷰 하이파이 디자인 적용
- 손가락 위치를 기준으로 핀치 제스처 작동
- Target에서 iPad, Mac 제외
- Orientation을 Portrait로 고정

### Removed

- FrameDisplayView
- Frame의 Color 프로퍼티
- NetworkStateModalView 제거하고, 시스템 기본 UI인 Menu로 대체

### Fixed

- 연결이 오래 지속되어 유실되었을 때, 작가만 재연결이 시도하고 모델은 재연결을 시도하지 않는 문제 해결
- PhotosPickerView에서 썸네일 이미지를 레퍼런스 이미지로 선택하면 정방형 이미지가 로드되던 문제
- PhotosPickerView와 PhotoDetailView 체크박스 상태 동기화 이슈 해결
- 레퍼런스 삭제시 PhotoPicker 초기화가 안된 문제 해결
-  프레임의 동시 수정 관련된 문제 해결
- SampleBufferDisplayView에서 매번 화질 관련 지표를 리셋하여 적응형 화질 매커니즘이 동작하지 않았던 문제

## [0.2.0] 테스트 플라이트 마일스톤 (2025-11-01)

### Added

- 프레임의 크기와 비율 변경 기능
- 스와이프를 이용한 사진 탐색 기능
- 갤러리에 있는 사진 확대/축소 제스처들 추가
- 펜과 매직펜 관련 이벤트(등록,업데이트,삭제) 송수신
- 역할 서로 바꾸기
- 가이드 숨김 기능 
- 커스텀 폰트 및 색상
- 기본 컴포넌트
- 상태 토스트

### Changed

- 펜 가이드라인 상대위치 반영 추가
- 프레임 비율과 크기 변경 네트워크 이벤트 추가
- 작가와 모델의 펜과 매직펜 구분 추가
- 생상자에게만 펜과 매직펜 수정 권한 부여 추가
- 연결 취소/유실 + 역할 바꾸기 시 가이딩(펜, 프레임, 레퍼런스) 초기화 추가
- 상단 툴바 디자인 적용
- 앱 아이콘 변경
- 디스플레이 네임 "찍자"로 변경
- 디스플레이 네임 "ZZikZZa"로 변경
- 이미지 비율에 따라 레퍼런스 크기 조절
- 작가 모델 1차 하이파이

### Fixed

- 카메라 전/후면 전환 후 라이브 포토 이슈 수정

## [0.1.0]

### Added

- 라이브 포토 재생 기능
- 핀치를 이용한 카메라 프리뷰 줌인, 줌아웃 기능
- 커넥션 헬스 체크
- Graceful Disconnection
- 레퍼런스의 이동 기능
- 사라지는 펜 기능
- 연결 유실 시 재연결

### Changed

- 카메라 프리뷰 스트리밍에 HEVC 코덱 적용
- 카메라 세팅 관련 로컬 저장 적용

### Fixed

- 접근 권한 거부에 따른 앱 크래시 나는 이슈 수정
- HEVC 코덱 적용 이후, 작가 재연결시 가끔 스트리밍이 안되었던 문제


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

[0.3.3]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim/releases/tag/v0.0.1
[unreleased]: hhttps://github.com/DeveloperAcademy-POSTECH/2025-C6-A11-QueendomJaerim
