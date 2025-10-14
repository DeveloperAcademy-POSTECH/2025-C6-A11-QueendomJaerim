//
//  VideoFramePayload.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation
import AVFoundation

struct VideoFramePayload: Codable {
  let frameData: Data
  let originalSize: CGSize
  let scaledSize: CGSize
  let quality: PreviewFrameQuality
  let timestamp: Date
}

struct VideoFrameDecoded {
  let frame: CVPixelBuffer
  let originalSize: CGSize
  let scaledSize: CGSize
  let quality: PreviewFrameQuality
  let timestamp: Date
}
