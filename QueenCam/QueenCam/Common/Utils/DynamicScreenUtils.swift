//
//  DynamicScreenUtils.swift
//  QueenCam
//
//  Created by 임영택 on 11/18/25.
//

import UIKit

struct DynamicScreenUtils {
  /// 높이를 너비로 나누었을 때 이 값보다 작으면 뷰를 조정한다. iPad 11 인치 대응.
  private static var shortRatioThreshold: CGFloat {
    2.0
  }

  /// 화면 비율이 짧은 비율인지 여부. 짧은 비율이면 뷰를 조정한다. iPad 11 인치 대응.
  static var isShortScreen: Bool {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene

    let screenHeight = windowScene?.screen.bounds.height ?? 0.0
    let screenWidth = windowScene?.screen.bounds.width ?? 0.0

    return screenHeight / screenWidth < shortRatioThreshold
  }
}
