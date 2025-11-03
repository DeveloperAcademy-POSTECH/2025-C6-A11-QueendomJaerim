//
//  SharingLogFile.swift
//  QueenCam
//
//  Created by 임영택 on 11/1/25.
//

import CoreTransferable
import UIKit
import UniformTypeIdentifiers

nonisolated struct SharingLogFile: Codable {
  let logContent: String
  let deviceInfo: DeviceInfo
  let exportedAt: Date

  init(url: URL, deviceInfo: DeviceInfo) {
    let logData = try? Data(contentsOf: url)
    if let logData,
      let logContent = String(data: logData, encoding: .utf8) {
      self.logContent = logContent
    } else {
      self.logContent = ""
    }

    self.deviceInfo = deviceInfo
    self.exportedAt = Date()
  }
}

nonisolated extension SharingLogFile: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .utf8PlainText) { logFile in
      // 파일 본문
      let fileContent = """
        ==== Device Info ====
        OS: \(logFile.deviceInfo.osName) \(logFile.deviceInfo.osVersion)
        Identifier: \(logFile.deviceInfo.deviceIdentifier)
        Exported At: \(logFile.exportedAt.formatted())

        ==== Logs ====

        \(logFile.logContent)
        """

      // 파일 이름
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd_HHmmss"
      let dateString = formatter.string(from: logFile.exportedAt)

      // "QueenCam-Log-2025-11-03_143000.txt"
      let fileName = "QueenCam-Log-\(dateString).txt"

      // 임시 디렉토리 URL
      let tempDirectory = FileManager.default.temporaryDirectory
      let fileURL = tempDirectory.appendingPathComponent(fileName)

      // 파일 저장
      do {
        try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
      } catch {
        throw error
      }

      return SentTransferredFile(fileURL)
    }
  }
}

nonisolated struct DeviceInfo: Codable {
  let osName: String
  let osVersion: String
  let deviceIdentifier: String

  @MainActor
  static var defaultValue: Self {
    .init(
      osName: UIDevice.current.systemName,
      osVersion: UIDevice.current.systemVersion,
      deviceIdentifier: UIDevice.current.deviceIdentifier
    )
  }
}

extension UIDevice {
  // see: https://stackoverflow.com/a/26962452
  var deviceIdentifier: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }

    return identifier
  }
}
