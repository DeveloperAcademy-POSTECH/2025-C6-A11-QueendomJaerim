//
//  DynamicScreenUtils.swift
//  QueenCam
//
//  Created by 임영택 on 11/18/25.
//

import UIKit

struct DynamicModelUtils {
  private static let IPadModelName = "ipad"

  /// iPad 여부
  static var isiPad: Bool {
    let model = UIDevice.current.model
    return model.lowercased() == IPadModelName
  }
}
