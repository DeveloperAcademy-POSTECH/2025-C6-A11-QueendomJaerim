//
//  NetworkEvent.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

enum NetworkEvent: Sendable {
  case startSession  // Wake Up Event. 처음 연결되면 Publisher는 임의의 메시지를 받아야 이후 이벤트를 받을 수 있다
  case startStreaming
  case ping(Date)
  case previewFrame(VideoFramePayload)
  case renderState(RenderingState)
  case photoResult(Data)
}

nonisolated extension NetworkEvent: Codable {
}

enum RenderingState: Codable, Sendable {
  case unstable
  case stable
}
