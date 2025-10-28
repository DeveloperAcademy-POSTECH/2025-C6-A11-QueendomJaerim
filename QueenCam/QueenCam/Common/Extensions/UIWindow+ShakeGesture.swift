//
//  UIWindow+ShakeGesture.swift
//  QueenCam
//
//  Created by 임영택 on 10/17/25.
//

import Foundation
import UIKit

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    super.motionEnded(motion, with: event)
    NotificationCenter.default.post(name: .QueenCamDeviceDidShakeNotification, object: event)
  }
}
