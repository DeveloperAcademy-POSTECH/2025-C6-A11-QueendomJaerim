//
//  ReferenceImageEventType.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

import Foundation

enum ReferenceImageEventType: Codable, Sendable {
  case remove
  case register(imageData: Data)
  case reset
}
