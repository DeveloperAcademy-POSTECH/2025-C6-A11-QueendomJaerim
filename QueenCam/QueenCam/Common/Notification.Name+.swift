//
//  Notification.Name+.swift
//  QueenCam
//
//  Created by 임영택 on 10/28/25.
//

import Foundation

extension Notification.Name {
  /// 디바이스 흔들기 제스쳐 알림
  static let QueenCamDeviceDidShakeNotification = Notification.Name("QueenCam.DeviceDidShakeNotification")

  /// 역할 변경 알림. userInfo에 "newRole"을 키로, 새로운 역할의 Role 값을 같이 실어 보낸다
  static let QueenCamRoleChangedNotification = Notification.Name("QueenCam.RoleChangedNotification")
  
  /// 애널리틱스 이벤트 알림. 반드시 userInfo에 "event"를 키로 해서, AnalyticsEvent 타입 객체를 보내야한다.
  static let QueenCamAnalyticsEventNotification = Notification.Name("QueenCam.AnalyticsEventNotification")
}
