//
//  PhotoAspectRatioCroppingServiceTests.swift
//  QueenCamTests
//
//  Created by seungchan on 10/24/26.
//

import CoreGraphics
import CoreVideo
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import QueenCam

@Suite("PhotoAspectRatioCroppingService Tests")
struct PhotoAspectRatioCroppingServiceTests {
  private let service = PhotoAspectRatioCroppingService()

  // 카메라처럼 픽셀은 가로로 눕혀 두고 "90도 돌려서 보여 줘"(orientation 6) 정보를 붙인 사진
  private func makeCameraLikeImageData(type: UTType = .jpeg) throws -> Data {
    try makeImageData(width: 400, height: 300, orientation: .right, type: type)
  }

  @Test("4:3 사진을 4:3으로 자르면 원본 데이터를 그대로 돌려준다")
  func returnsOriginalDataFor4x3() throws {
    let data = try makeCameraLikeImageData()

    #expect(service.crop(imageData: data, to: .ratio4x3) == data)
  }

  @Test("16:9로 자르면 사진의 긴 쪽을 따라 가운데를 자른다")
  func cropsTo16x9() throws {
    let cropped = try #require(service.crop(imageData: try makeCameraLikeImageData(), to: .ratio16x9))

    let info = try imageInfo(of: cropped)
    #expect(info.width == 400)
    #expect(info.height == 225)
  }

  @Test("자른 사진에 Live Photo 짝 식별자가 그대로 남는다", arguments: [UTType.jpeg, .heic])
  func keepsLivePhotoIdentifier(type: UTType) throws {
    let identifier = UUID().uuidString
    let data = try addingLivePhotoIdentifier(identifier, to: try makeCameraLikeImageData(type: type), type: type)

    let cropped = try #require(service.crop(imageData: data, to: .ratio16x9))

    #expect(try livePhotoIdentifier(in: cropped) == identifier)
  }

  @Test("1:1로 자르면 정사각형으로 가운데를 자른다")
  func cropsTo1x1() throws {
    let cropped = try #require(service.crop(imageData: try makeCameraLikeImageData(), to: .ratio1x1))

    let info = try imageInfo(of: cropped)
    #expect(info.width == 300)
    #expect(info.height == 300)
  }

  @Test("자른 사진도 원래 방향 정보를 그대로 가진다")
  func keepsOrientation() throws {
    let cropped = try #require(service.crop(imageData: try makeCameraLikeImageData(), to: .ratio16x9))

    #expect(try imageInfo(of: cropped).orientation == CGImagePropertyOrientation.right.rawValue)
  }

  @Test("자른 사진도 원래 형식으로 저장한다")
  func keepsImageFormat() throws {
    let cropped = try #require(service.crop(imageData: try makeCameraLikeImageData(), to: .ratio1x1))

    #expect(try imageInfo(of: cropped).type == UTType.jpeg.identifier)
  }

  @Test("HEIC 사진도 HEIC로 자른다", .enabled(if: Self.canEncodeHEIC))
  func cropsHEIC() throws {
    let cropped = try #require(
      service.crop(imageData: try makeCameraLikeImageData(type: .heic), to: .ratio16x9)
    )

    let info = try imageInfo(of: cropped)
    #expect(info.type == UTType.heic.identifier)
    #expect(info.width == 400)
    #expect(info.height == 225)
  }

  @Test("HDR 정보(gain map)도 같은 영역으로 잘라 유지한다")
  func keepsCroppedGainMap() throws {
    let data = try makeImageDataWithGainMap()

    let cropped = try #require(service.crop(imageData: data, to: .ratio16x9))

    // 본 사진 400×300 중 가운데 400×225(y 37~262)를 자르므로, 절반 크기 gain map은 y 18부터 200×113을 남긴다.
    let gainMap = try #require(try gainMapInfo(of: cropped))
    #expect(gainMap.width == 200)
    #expect(gainMap.height == 113)
    #expect(gainMap.firstRowValue == 18)
  }

  @Test("사진이 아닌 데이터는 자르지 못하고 nil을 돌려준다")
  func returnsNilForInvalidData() {
    #expect(service.crop(imageData: Data("not an image".utf8), to: .ratio16x9) == nil)
  }
}

private extension PhotoAspectRatioCroppingServiceTests {
  func addingLivePhotoIdentifier(_ identifier: String, to data: Data, type: UTType) throws -> Data {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
    properties[kCGImagePropertyMakerAppleDictionary as String] = ["17": identifier]

    let output = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, properties as CFDictionary)
    try #require(CGImageDestinationFinalize(destination))
    return output as Data
  }

  func livePhotoIdentifier(in data: Data) throws -> String? {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
    let makerApple = properties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any]
    return makerApple?["17"] as? String
  }

  struct ImageInfo {
    let width: Int
    let height: Int
    let orientation: UInt32?
    let type: String?
  }

  static var canEncodeHEIC: Bool {
    let types = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
    return types.contains(UTType.heic.identifier)
  }

  func makeImageData(width: Int, height: Int, orientation: CGImagePropertyOrientation, type: UTType) throws -> Data {
    let context = try #require(
      CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
      )
    )
    context.setFillColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())

    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil))
    let properties = [kCGImagePropertyOrientation as String: orientation.rawValue] as CFDictionary
    CGImageDestinationAddImage(destination, image, properties)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }

  struct GainMapInfo {
    let width: Int
    let height: Int
    let firstRowValue: UInt8
  }

  // 400×300 사진에 200×150, 1바이트 gain map을 붙인다. 각 줄의 값은 줄 번호라서 잘린 위치를 확인할 수 있다.
  func makeImageDataWithGainMap() throws -> Data {
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

    let gainMapWidth = 200
    let gainMapHeight = 150
    var gainMapBytes = [UInt8]()
    for row in 0..<gainMapHeight {
      gainMapBytes.append(contentsOf: [UInt8](repeating: UInt8(row), count: gainMapWidth))
    }
    let auxiliaryDataInfo: [String: Any] = [
      kCGImageAuxiliaryDataInfoData as String: Data(gainMapBytes),
      kCGImageAuxiliaryDataInfoDataDescription as String: [
        "Width": gainMapWidth,
        "Height": gainMapHeight,
        "BytesPerRow": gainMapWidth,
        "PixelFormat": Int(kCVPixelFormatType_OneComponent8)
      ],
      kCGImageAuxiliaryDataInfoMetadata as String: CGImageMetadataCreateMutable()
    ]

    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationAddAuxiliaryDataInfo(destination, kCGImageAuxiliaryDataTypeHDRGainMap, auxiliaryDataInfo as CFDictionary)
    #expect(CGImageDestinationFinalize(destination))

    // 테스트 준비 확인: 만든 사진에 gain map이 실제로 들어갔는지
    #expect(try gainMapInfo(of: data as Data)?.height == gainMapHeight)
    return data as Data
  }

  func gainMapInfo(of data: Data) throws -> GainMapInfo? {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    guard
      let info = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeHDRGainMap)
        as? [String: Any],
      let bytes = info[kCGImageAuxiliaryDataInfoData as String] as? Data,
      let description = info[kCGImageAuxiliaryDataInfoDataDescription as String] as? [String: Any],
      let width = description["Width"] as? Int,
      let height = description["Height"] as? Int,
      let firstByte = bytes.first
    else { return nil }

    return GainMapInfo(width: width, height: height, firstRowValue: firstByte)
  }

  func imageInfo(of data: Data) throws -> ImageInfo {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]

    return ImageInfo(
      width: image.width,
      height: image.height,
      orientation: properties?[kCGImagePropertyOrientation as String] as? UInt32,
      type: CGImageSourceGetType(source) as String?
    )
  }
}
