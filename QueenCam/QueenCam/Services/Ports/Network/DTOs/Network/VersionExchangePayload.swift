//
//  VersionExchangePayload.swift
//  QueenCam
//
//  Created by 임영택 on 11/17/25.
//

import Foundation

struct VersionExchangePayload: Codable {
  let version: Int
  let requiredMinimumVersion: Int
}
