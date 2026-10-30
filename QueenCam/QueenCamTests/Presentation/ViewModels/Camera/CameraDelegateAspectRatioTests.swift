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

  @Test("사진 자르기 함수는 Live Photo를 바꾸지 않는다")
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

  @Test("Live Photo 사진과 영상을 모두 자르면 자른 쌍을 쓰고 원본 영상 파일을 지운다")
  func usesCroppedPairWhenBothCropsSucceed() async throws {
    let still = try makeJPEGData(width: 4, height: 3)
    let croppedStill = try makeJPEGData(width: 3, height: 3)
    let movieURL = try makeMovieFile("original")
    let croppedMovieURL = try makeMovieFile("cropped")
    let delegate = makeDelegate(cropResult: croppedStill, movieCropResult: croppedMovieURL)

    let thumbnail = try #require(UIImage(data: still))

    let result = try #require(
      await delegate.applyAspectRatio(toLivePhotoImageData: still, thumbnail: thumbnail, livePhotoMovieURL: movieURL)
    )

    #expect(result.livePhotoMovieURL == croppedMovieURL)
    #expect(result.photoOutput.imageData == croppedStill)
    #expect(result.photoOutput.thumbnail.size == CGSize(width: 3, height: 3))
    #expect(videoData(of: result.photoOutput) == Data("cropped".utf8))
    #expect(!FileManager.default.fileExists(atPath: movieURL.path))
  }

  @Test("Live Photo 사진을 자르지 못하면 원본 쌍을 쓴다")
  func usesOriginalPairWhenImageCropFails() async throws {
    try await expectOriginalPair(cropResult: nil, movieCropResult: makeMovieFile("cropped"))
  }

  @Test("Live Photo 영상을 자르지 못하면 원본 쌍을 쓴다")
  func usesOriginalPairWhenMovieCropFails() async throws {
    try await expectOriginalPair(cropResult: makeJPEGData(width: 3, height: 3), movieCropResult: nil)
  }

  @Test("자른 영상을 읽지 못하면 원본 쌍을 쓴다")
  func usesOriginalPairWhenCroppedMovieIsUnreadable() async throws {
    let missingURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    try await expectOriginalPair(cropResult: makeJPEGData(width: 3, height: 3), movieCropResult: missingURL)
  }

  @Test("이미 같은 비율이라 원본 영상이 돌아오면 원본 쌍을 그대로 쓴다")
  func usesOriginalPairWhenAlreadyInRatio() async throws {
    let still = try makeJPEGData(width: 4, height: 3)
    let movieURL = try makeMovieFile("original")
    let delegate = makeDelegate(cropResult: still, movieCropResult: movieURL)

    let thumbnail = try #require(UIImage(data: still))

    let result = try #require(
      await delegate.applyAspectRatio(toLivePhotoImageData: still, thumbnail: thumbnail, livePhotoMovieURL: movieURL)
    )

    #expect(result.livePhotoMovieURL == movieURL)
    #expect(result.photoOutput.imageData == still)
    #expect(FileManager.default.fileExists(atPath: movieURL.path))
  }

  @Test("원본 영상을 읽지 못하면 nil을 돌려준다")
  func returnsNilWhenOriginalMovieIsUnreadable() async throws {
    let still = try makeJPEGData(width: 4, height: 3)
    let missingURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let delegate = makeDelegate(cropResult: nil)

    let thumbnail = try #require(UIImage(data: still))

    let result = await delegate.applyAspectRatio(
      toLivePhotoImageData: still,
      thumbnail: thumbnail,
      livePhotoMovieURL: missingURL
    )

    #expect(result == nil)
  }
}

extension CameraDelegateAspectRatioTests {
  private struct CroppingServiceStub: PhotoAspectRatioCroppingServiceProtocol {
    let result: Data?
    let movieResult: URL?

    func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data? {
      result
    }

    func crop(livePhotoMovieURL: URL, to ratio: PhotoAspectRatio) async -> URL? {
      movieResult
    }
  }

  private func makeDelegate(cropResult: Data?, movieCropResult: URL? = nil) -> CameraDelegate {
    CameraDelegate(
      isCameraPosition: .back,
      aspectRatio: .ratio16x9,
      aspectRatioCroppingService: CroppingServiceStub(result: cropResult, movieResult: movieCropResult)
    ) { _, _ in }
  }

  private func expectOriginalPair(cropResult: Data?, movieCropResult: URL?) async throws {
    let still = try makeJPEGData(width: 4, height: 3)
    let movieURL = try makeMovieFile("original")
    let delegate = makeDelegate(cropResult: cropResult, movieCropResult: movieCropResult)

    let thumbnail = try #require(UIImage(data: still))

    let result = try #require(
      await delegate.applyAspectRatio(toLivePhotoImageData: still, thumbnail: thumbnail, livePhotoMovieURL: movieURL)
    )

    #expect(result.livePhotoMovieURL == movieURL)
    #expect(result.photoOutput.imageData == still)
    #expect(videoData(of: result.photoOutput) == Data("original".utf8))
    #expect(FileManager.default.fileExists(atPath: movieURL.path))
  }

  private func makeMovieFile(_ contents: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mov")
    try Data(contents.utf8).write(to: url)
    return url
  }

  private func videoData(of photoOutput: PhotoOuput) -> Data? {
    guard case .livePhoto(_, _, let videoData) = photoOutput else { return nil }
    return videoData
  }

  private func makeBasicPhoto(width: Int, height: Int) throws -> PhotoOuput {
    let data = try makeJPEGData(width: width, height: height)
    return .basicPhoto(thumbnail: try #require(UIImage(data: data)), imageData: data)
  }

  private func makeJPEGData(width: Int, height: Int) throws -> Data {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
      UIColor.gray.setFill()
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    return try #require(image.jpegData(compressionQuality: 1))
  }
}
