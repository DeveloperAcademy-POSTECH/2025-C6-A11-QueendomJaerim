//
//  TimeInterval+CMTimeConverter.swift
//  QueenCam
//
//  Created by 임영택 on 10/21/25.
//

import CoreMedia
import Foundation

extension TimeInterval {
  func toCMTime() -> CMTime {
    let scale = CMTimeScale(NSEC_PER_SEC)
    let cmTime = CMTime(value: CMTimeValue(self * Double(scale)), timescale: scale)
    return cmTime
  }
}
