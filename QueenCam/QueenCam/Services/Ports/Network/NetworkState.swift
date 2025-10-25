//
//  NetworkState.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

nonisolated enum HostState: Sendable {
  case stopped
  case cancelled // 유저가 연결을 취소함 (-> 곧 stopped 상태가 된다)
  case lost // 연결이 유실됨 (-> 추가적인 액션을 필요로 한다)
  case publishing
}

nonisolated enum ViewerState: Sendable {
  case stopped
  case cancelled // 유저가 연결을 취소함 (-> 곧 stopped 상태가 된다)
  case lost // 연결이 유실됨 (-> 추가적인 액션을 필요로 한다)
  case browsing
  case connecting
  case connected
}

nonisolated enum NetworkState: Equatable, Sendable, CustomDebugStringConvertible {
  case host(HostState)
  case viewer(ViewerState)

  var debugDescription: String {
    switch self {
    case .host(let hostState):
      "HOST(\(hostState))"
    case .viewer(let viewerState):
      "VIEWER(\(viewerState))"
    }
  }
}

nonisolated enum NetworkType: Sendable {
  case host
  case viewer
}
