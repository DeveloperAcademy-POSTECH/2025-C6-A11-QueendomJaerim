//
//  Notification.Name+.swift
//  QueenCam
//
//  Created by 임영택 on 10/28/25.
//

import Foundation

extension Notification.Name {
  /// 디바이스 흔들기 제스쳐 알림
  static let QueenCamDeviceDidShakeNotification = NSNotification.Name("QueenCam.DeviceDidShakeNotification")
  
  /// 역할 변경 알림. userInfo에 "newRole"을 키로, 새로운 역할의 Role 값을 같이 실어 보낸다
  static let QueenCamRoleChangedNotification = Notification.Name("QueenCam.RoleChangedNotification")
}
