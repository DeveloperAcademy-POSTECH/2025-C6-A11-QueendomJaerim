//
//  VideoEncoderConfig+CustomConfig.swift
//  QueenCam
//
//  Created by 임영택 on 11/1/25.
//

import Foundation
import Transcoding

extension VideoEncoder.Config {
  nonisolated public static let queenCamCustomConfig = Self(
    maxKeyFrameInterval: 2,  // 키프레임 간격. 지정하지 않으면 최초 한 번만 키프레임 전송
    prioritizeEncodingSpeedOverQuality: true,
    realTime: true,
    enableLowLatencyRateControl: true,
  )
}
