//
//  SharingLogFile.swift
//  QueenCam
//
//  Created by 임영택 on 11/1/25.
//

import CoreTransferable
import UniformTypeIdentifiers

nonisolated struct SharingLogFile: Codable {
  let logContent: String
  let exportedAt: Date

  init?(url: URL) {
    let logData = try? Data(contentsOf: url)
    if let logData,
      let logContent = String(data: logData, encoding: .utf8) {
      self.logContent = logContent
      self.exportedAt = Date()
    } else {
      return nil
    }
  }
}

nonisolated extension SharingLogFile: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .utf8PlainText)
  }
}
