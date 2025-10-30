//
//  LWWValue.swift
//  QueenCam
//
//  Created by 임영택 on 10/28/25.
//

import Foundation

struct LWWRegister: Sendable, Codable {
  let actorId: String
  let timestamp: Date
}

extension LWWRegister: CustomStringConvertible {
  var description: String {
    "LWWValue(actorId: \(actorId), timestamp: \(timestamp))"
  }
}
