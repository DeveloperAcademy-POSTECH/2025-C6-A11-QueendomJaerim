//
//  ConnectionManagerProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation
import Network
import WiFiAware

protocol ConnectionManagerProtocol: Sendable {
  var localEvents: AsyncStream<LocalEvent> { get }
  var networkEvents: AsyncStream<NetworkEvent> { get }

  func add(_ connection: WiFiAwareConnection) async
  func setupConnection(to endpoint: WAEndpoint) async
  func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async
  func sendToAll(_ event: NetworkEvent) async
  func monitor() async throws
  func stop(_ connection: WiFiAwareConnection) async
  func invalidate(_ id: WiFiAwareConnectionID) async
}
