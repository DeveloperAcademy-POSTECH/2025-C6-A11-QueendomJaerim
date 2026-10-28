//
//  CameraDelegateAspectRatioTests.swift
//  QueenCamTests
//
//  Created by seungchan on 10/24/26.
//

import AVFoundation
import Foundation
import Testing
import UIKit

@testable import QueenCam

@MainActor
@Suite("CameraDelegate 비율 적용 Tests")
struct CameraDelegateAspectRatioTests {
  @Test("자르기에 실패하면 원본 사진을 그대로 쓴다")
  func usesOriginalWhenCropFails() throws {
    let original = try makeBasicPhoto(width: 4, height: 3)
    let delegate = makeDelegate(cropResult: nil)

    let result = delegate.applyAspectRatio(to: original)

    #expect(result.imageData == original.imageData)
  }

  @Test("자르기에 성공하면 자른 사진과 그 사진의 썸네일을 쓴다")
  func usesCroppedPhotoWhenCropSucceeds() throws {
    let original = try makeBasicPhoto(width: 4, height: 3)
    let croppedData = try makeJPEGData(width: 3, height: 3)
    let delegate = makeDelegate(cropResult: croppedData)

    let result = delegate.applyAspectRatio(to: original)

    #expect(result.imageData == croppedData)
    #expect(result.thumbnail.size == CGSize(width: 3, height: 3))
  }

  @Test("이미 같은 비율이라 원본 데이터가 돌아오면 원본을 그대로 쓴다")
  func usesOriginalWhenAlreadyInRatio() throws {
    let original = try makeBasicPhoto(width: 4, height: 3)
    let delegate = makeDelegate(cropResult: original.imageData)

    let result = delegate.applyAspectRatio(to: original)

    #expect(result.imageData == original.imageData)
    #expect(result.thumbnail === original.thumbnail)
  }

  @Test("Live Photo는 아직 자르지 않는다")
  func keepsLivePhoto() throws {
    let still = try makeJPEGData(width: 4, height: 3)
    let original = PhotoOuput.livePhoto(
      thumbnail: try #require(UIImage(data: still)),
      imageData: still,
      videoData: Data("video".utf8)
    )
    let delegate = makeDelegate(cropResult: try makeJPEGData(width: 3, height: 3))

    let result = delegate.applyAspectRatio(to: original)

    guard case .livePhoto(_, let imageData, let videoData) = result else {
      Issue.record("Live Photo가 일반 사진으로 바뀌었다")
      return
    }
    #expect(imageData == still)
    #expect(videoData == Data("video".utf8))
  }
}

private extension CameraDelegateAspectRatioTests {
  struct CroppingServiceStub: PhotoAspectRatioCroppingServiceProtocol {
    let result: Data?

    func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data? {
      result
    }
  }

  func makeDelegate(cropResult: Data?) -> CameraDelegate {
    CameraDelegate(
      isCameraPosition: .back,
      aspectRatio: .ratio16x9,
      aspectRatioCroppingService: CroppingServiceStub(result: cropResult)
    ) { _, _ in }
  }

  func makeBasicPhoto(width: Int, height: Int) throws -> PhotoOuput {
    let data = try makeJPEGData(width: width, height: height)
    return .basicPhoto(thumbnail: try #require(UIImage(data: data)), imageData: data)
  }

  func makeJPEGData(width: Int, height: Int) throws -> Data {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
      UIColor.gray.setFill()
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    return try #require(image.jpegData(compressionQuality: 1))
  }
}
