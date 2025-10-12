//
//  NetworkManagerProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation
import Network
import WiFiAware

protocol NetworkManagerProtocol {
    var localEvents: AsyncStream<LocalEvent> { get }
    var networkEvents: AsyncStream<NetworkEvent> { get }
    
    func listen() async throws
    func browse() async throws
    func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async
    func sendToAll(_ event: NetworkEvent) async
}
