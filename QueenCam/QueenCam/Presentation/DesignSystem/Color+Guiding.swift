//
//  Color+Guiding.swift
//  QueenCam
//
//  Created by 임영택 on 6/14/26.
//

import SwiftUI
import UIKit

extension Color {
  static func guidingStrokeOuter(for role: Role) -> Color {
    switch role {
    case .model:
      return .modelPrimary
    case .photographer:
      return .photographerPrimary
    }
  }
}

extension UIColor {
  static func guidingStrokeOuter(for role: Role) -> UIColor {
    switch role {
    case .model:
      return .modelPrimary
    case .photographer:
      return .photographerPrimary
    }
  }
}

