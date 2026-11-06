//
//  NetworkService+Version.swift
//  QueenCam
//
//  Created by 임영택 on 11/17/25.
//

import Foundation

extension NetworkService {
  var versionCheckTimeout: TimeInterval { 10 }

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

    isCounterpartVersionVerified = true
  }

  func handleVersionCheckTimer() {
    defer {
      self.versionCheckTimer?.invalidate()
      self.versionCheckTimer = nil
    }

    guard isCounterpartVersionVerified else {
      self.stop(byUser: true, userReason: "친구 앱의 버전을 확인할 수 없습니다.\n친구 앱을 최신 버전으로 업데이트 해주세요.")
      return
    }
  }

  /// 이전 연결의 알람이 남으면 다음 연결 중에 울려 연결을 끊으므로, 통과 표시와 함께 지운다.
  func resetVersionCheck() {
    isCounterpartVersionVerified = false
    versionCheckTimer?.invalidate()
    versionCheckTimer = nil
  }
}
