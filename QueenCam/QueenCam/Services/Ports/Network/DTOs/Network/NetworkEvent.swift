//
//  NetworkEvent.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

enum NetworkEvent: Sendable {
  // MARK: - Infra Level Events
  
  /// Wake Up Event. 처음 연결되면 Publisher는 임의의 메시지를 받아야 이후 이벤트를 받을 수 있다
  /// 모델 -> 작가
  case startSession

  /// 헬스 체크 요청. 랜덤 문자열을 담아서 보낸다. (모델 -> 작가)
  case healthCheckRequest(String)

  /// 헬스 체크 응답. 받은 코드를 담아서 보낸다. (작가 -> 모델)
  case healthCheckResponse(String)

  /// 사용자 요청에 의한 연결 중단 예정 통지. Graceful Disconnection에 활용한다.
  case willDisconnect

  /// 디버그용 핑 명령
  case ping(Date)

  // MARK: - Domain Level Events

  /// 프리뷰 프레임 (작가 -> 모델)
  case previewFrame(VideoFramePayload)

  /// 렌더링 상태 (모델 -> 작가)
  case renderState(RenderingState)

  /// 촬영 결과물. (작가 -> 모델)  라이브포토인 경우 영상을 포함한다.
  case photoResult(imageData: Data, videoData: Data?)

  /// 등록된 레퍼런스 (모델 -> 작가)
  case referenceImage(ReferenceImageEventType)

  /// 프레임 이벤트
  case frameUpdated(FrameEventType)

  /// 펜 이벤트
  case penUpdated(PenEventType)

  /// 역할 바꾸기 요청. 상대의 새 역할을 제안한다
  case changeRole(RolePayload, LWWRegister)
}

nonisolated extension NetworkEvent: Codable {
}
