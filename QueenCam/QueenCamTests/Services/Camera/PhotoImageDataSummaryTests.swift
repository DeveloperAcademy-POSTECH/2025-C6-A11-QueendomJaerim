//
//  PhotoImageDataSummaryTests.swift
//  QueenCamTests
//
//  Created by seungchan on 10/24/26.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import QueenCam

@Suite("PhotoImageDataSummary Tests")
struct PhotoImageDataSummaryTests {
  @Test("사진의 픽셀 크기·방향·형식·보조 정보를 한 줄로 요약한다")
  func summarizesImage() throws {
    let summary = try #require(PhotoImageDataSummary.make(from: try makeImageData()))

    #expect(summary.description == "400x300 orientation=6 type=public.jpeg aux=[none]")
  }

  @Test("사진이 아닌 데이터는 요약하지 않는다")
  func returnsNilForInvalidData() {
    #expect(PhotoImageDataSummary.make(from: Data("not an image".utf8)) == nil)
  }

  @Test("비율이 맞고 HDR 정보가 남으면 둘 다 ✅로 판정한다")
  func verdictPasses() {
    let before = summary(width: 4032, height: 3024, aux: ["hdrGainMap", "isoGainMap"])
    let after = summary(width: 4032, height: 2268, aux: ["hdrGainMap", "isoGainMap"])

    #expect(PhotoImageDataSummary.verdict(ratio: .ratio16x9, before: before, after: after) == "16:9 촬영 → 비율 ✅ HDR ✅")
  }

  @Test("세로로 저장된 사진도 긴 변 기준으로 비율을 판정한다")
  func verdictUsesLongSide() {
    let before = summary(width: 3024, height: 4032, aux: [])
    let after = summary(width: 2268, height: 4032, aux: [])

    #expect(PhotoImageDataSummary.verdict(ratio: .ratio16x9, before: before, after: after) == "16:9 촬영 → 비율 ✅ HDR -")
  }

  @Test("비율이 다르거나 HDR 정보가 빠지면 ❌로 판정한다")
  func verdictFails() {
    let before = summary(width: 4032, height: 3024, aux: ["hdrGainMap"])
    let after = summary(width: 4032, height: 3024, aux: [])

    #expect(PhotoImageDataSummary.verdict(ratio: .ratio1x1, before: before, after: after) == "1:1 촬영 → 비율 ❌ HDR ❌")
  }

  private func summary(width: Int, height: Int, aux: [String]) -> PhotoImageDataSummary {
    PhotoImageDataSummary(width: width, height: height, orientation: 6, type: "public.heic", auxiliaryDataNames: aux)
  }

  private func makeImageData() throws -> Data {
    let context = try #require(
      CGContext(
        data: nil,
        width: 400,
        height: 300,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
      )
    )
    let image = try #require(context.makeImage())

    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
    let properties = [kCGImagePropertyOrientation as String: CGImagePropertyOrientation.right.rawValue] as CFDictionary
    CGImageDestinationAddImage(destination, image, properties)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }
}
