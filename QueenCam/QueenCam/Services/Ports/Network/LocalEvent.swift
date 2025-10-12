//
//  LocalEvent.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation
import WiFiAware

enum LocalEvent: Sendable {
  case browserRunning
  case connecting
  case browserStopped(WAError?)

  case listenerRunning
  case listenerStopped(WAError?)

  enum ConnectionEvent {
    case ready(WAPairedDevice, ConnectionDetail)
    case performance(WAPairedDevice, ConnectionDetail)
    case stopped(WAPairedDevice, WiFiAwareConnectionID, WAError?)
  }
  case connection(ConnectionEvent)
}

struct ConnectionDetail: Sendable, Equatable {
  let connection: WiFiAwareConnection
  let performanceReport: WAPerformanceReport

  public static func == (lhs: ConnectionDetail, rhs: ConnectionDetail) -> Bool {
    return lhs.performanceReport.localTimestamp == rhs.performanceReport.localTimestamp
  }
}
