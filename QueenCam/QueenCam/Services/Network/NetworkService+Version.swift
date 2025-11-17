//
//  NetworkService+Version.swift
//  QueenCam
//
//  Created by 임영택 on 11/17/25.
//

import Foundation

extension NetworkService {
  var versionCheckTimeout: TimeInterval { 2 }

  private var version100: Int { // myVersion 이벤트를 1.0.0 이전에서는 지원하지 않음
    10_000_000
  }

  // MARK: 최소 버전 확인
  func handleMyVersionEvent(for counterpartVersionInfo: VersionExchangePayload) {
    let counterpartVersion = counterpartVersionInfo.version
    let counterpartRequestedMinimumVersion = counterpartVersionInfo.requiredMinimumVersion

    let myVersion = VersionUtils.currentVersion
    let myRequestingMinimumVersion = VersionUtils.minimumVersionCompatibleWith

    if myVersion < counterpartRequestedMinimumVersion {
      self.stop(
        byUser: true,
        userReason:
        """
        내 앱의 버전이 낮아서 연결할 수 없습니다.
        최소 \(VersionUtils.getVersionString(from: counterpartRequestedMinimumVersion)) 버전으로 앱을 업데이트 해주세요.
        """
      )
      return
    }

    if counterpartVersion < myRequestingMinimumVersion {
      self.stop(
        byUser: true,
        userReason:
        """
        친구 앱의 버전이 낮아서 연결할 수 없습니다.
        최소 \(VersionUtils.getVersionString(from: myRequestingMinimumVersion)) 버전으로 앱을 업데이트 해주세요.
        """
      )
      return
    }
  }
}
