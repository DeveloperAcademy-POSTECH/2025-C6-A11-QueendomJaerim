//
//  VideoFramePayload.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import AVFoundation
import Foundation

struct VideoFramePayload: Codable {
  let hevcData: Data
  let quality: PreviewFrameQuality
}
