//
//  NetworkEvent.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

enum NetworkEvent: Sendable {
  /// Wake Up Event. 처음 연결되면 Publisher는 임의의 메시지를 받아야 이후 이벤트를 받을 수 있다
  /// 모델 -> 작가
  case startSession

  /// 스트리밍 시작 명령
  case startStreaming

  /// 디버그용 핑 명령
  case ping(Date)

  /// 프리뷰 프레임 (작가 -> 모델)
  case previewFrame(VideoFramePayload)

  /// 렌더링 상태 (모델 -> 작가)
  case renderState(RenderingState)

  /// 촬영 결과물. (작가 -> 모델)  라이브포토인 경우 영상을 포함한다.
  case photoResult(imageData: Data, videoData: Data?)
  
  /// 등록된 레퍼런스 (모델 -> 작가)
  case referenceImage(imageData: Data)
}

nonisolated extension NetworkEvent: Codable {
}

enum RenderingState: Codable, Sendable {
  case unstable
  case stable
}
