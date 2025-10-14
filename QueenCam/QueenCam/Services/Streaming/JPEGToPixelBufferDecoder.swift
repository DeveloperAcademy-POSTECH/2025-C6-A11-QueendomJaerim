//
//  JPEGToPixelBufferDecoder.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import CoreImage
import Foundation

enum JPEGDecodeError: Error { case badData, createPixelBufferFailed, renderFailed }

final class JPEGToPixelBufferDecoder {
  private let ciCtx: CIContext
  private let colorSpace: CGColorSpace

  init(colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!) {
    // GPU 사용 CIContext (필요시 옵션 조정)
    self.ciCtx = CIContext(options: [.cacheIntermediates: false])
    self.colorSpace = colorSpace
  }

  /// JPEG Data -> CVPixelBuffer(BGRA)
  nonisolated func decode(
    _ data: Data,
    pixelFormat: OSType = kCVPixelFormatType_32BGRA
  ) throws -> CVPixelBuffer {

    // 1) 이미지 메타 파싱 (크기/방향)
    guard let src = CGImageSourceCreateWithData(data as CFData, nil),
      let cgi = CGImageSourceCreateImageAtIndex(
        src,
        0,
        [
          kCGImageSourceShouldCache: false
        ] as CFDictionary
      )
    else { throw JPEGDecodeError.badData }

    let width = cgi.width
    let height = cgi.height

    // 2) PixelBuffer 생성
    var pixelBuffer: CVPixelBuffer?
    let attrs: [CFString: Any] = [
      kCVPixelBufferPixelFormatTypeKey: pixelFormat,
      kCVPixelBufferWidthKey: width,
      kCVPixelBufferHeightKey: height,
      kCVPixelBufferIOSurfacePropertiesKey: [:],
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true
    ]
    guard CVPixelBufferCreate(nil, width, height, pixelFormat, attrs as CFDictionary, &pixelBuffer) == kCVReturnSuccess,
      let pixelBuffer = pixelBuffer
    else { throw JPEGDecodeError.createPixelBufferFailed }

    // 3) CIImage로 디코딩(Exif 방향 보정 포함)
    //    - CIImage(cgImage:)는 EXIF orientation이 없으므로, 필요시 이미지 속성에서 직접 보정
    let ciImage = CIImage(cgImage: cgi)  // 필요하면 .oriented(_:)로 보정

    // 4) 렌더링
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    ciCtx.render(ciImage, to: pixelBuffer, bounds: ciImage.extent, colorSpace: colorSpace)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

    return pixelBuffer
  }
}
