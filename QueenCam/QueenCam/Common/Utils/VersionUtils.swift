//
//  VersionUtils.swift
//  QueenCam
//
//  Created by 임영택 on 11/17/25.
//

import Foundation

struct VersionUtils {
  private init() {}

  private static let logger = QueenLogger(category: "VersionUtils")

  private static var infoDictionary: [String: Any] {
    Bundle.main.infoDictionary ?? [:]
  }

  static var currentVersion: Int {
    let versionString = infoDictionary["CFBundleShortVersionString"] as? String ?? "0.0.0"
    return getVersionNumber(from: versionString)
  }

  static var minimumVersionCompatibleWith: Int {
    let versionString = infoDictionary["QueenCamCompatibleMinimumVersion"] as? String ?? "0.0.0"  // Custom Key in Info.plist
    return getVersionNumber(from: versionString)
  }

  static func getVersionString(from versionNumber: Int) -> String {
    guard versionNumber >= 0 else {
      logger.warning("음수 버전 번호는 지원하지 않습니다. input=\(versionNumber)")
      return "0.0.0"
    }

    let majorMultiplier = 10_000_000
    let minorMultiplier = 100_000

    // 1. Major 버전 추출 (가장 큰 단위로 나눗셈)
    let majorVersion = versionNumber / majorMultiplier

    // 2. 나머지에서 Minor 버전 추출
    let remainderAfterMajor = versionNumber % majorMultiplier
    let minorVersion = remainderAfterMajor / minorMultiplier

    // 3. 최종 남은 값이 Patch 버전
    let patchVersion = remainderAfterMajor % minorMultiplier

    return "\(majorVersion).\(minorVersion).\(patchVersion)"
  }

  private static func getVersionNumber(from versionString: String) -> Int {
    let versions = versionString.split(separator: ".").compactMap { Int($0) }
    guard versions.count == 3 else {
      logger.warning("버전을 파싱할 수 없었습니다. input=\(versionString)")
      return 0
    }

    let majorVersion = versions[0]
    let minorVersion = versions[1]
    let patchVersion = versions[2]

    return majorVersion * 10_000_000 + minorVersion * 100_000 + patchVersion
  }
}
