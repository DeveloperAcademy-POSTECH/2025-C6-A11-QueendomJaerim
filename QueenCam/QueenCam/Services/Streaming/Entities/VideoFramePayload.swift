//
//  VideoFramePayload.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import AVFoundation
import Foundation

struct VideoFramePayload: Codable {
  let data: Data
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
  let timestamp: CMTime
}
