//
//  LogAppending.swift
//  QueenCam
//
//  Created by 임영택 on 11/3/25.
//

import Foundation

nonisolated protocol LogAppending {
  func write(category: String, message: String, level: LogLevel)
}
