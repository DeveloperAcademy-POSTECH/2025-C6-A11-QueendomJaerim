//
//  WifiAwareTypes.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Network

typealias WiFiAwareConnection = NetworkConnection<Coder<NetworkEvent, NetworkEvent, NetworkJSONCoder>>
typealias WiFiAwareConnectionID = String
typealias WiFiAwareConnectionState = (WiFiAwareConnection, WiFiAwareConnection.State)
