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

  @Test("촬영마다 셔터 순간의 비율로 자르고 처리 순서가 뒤바뀌어도 섞이지 않는다")
  func eachShotCropsWithItsOwnRatio() async throws {
    let still = try makeJPEGData(width: 4, height: 3)
    let thumbnail = try #require(UIImage(data: still))
    let service = RatioEchoCroppingServiceStub()
    let squareDelegate = makeDelegate(aspectRatio: .ratio1x1, croppingService: service)
    let wideDelegate = makeDelegate(aspectRatio: .ratio16x9, croppingService: service)
    let photo = PhotoOuput.basicPhoto(thumbnail: thumbnail, imageData: still)

    // 1:1을 먼저 찍었지만 16:9의 처리가 먼저 끝나는 순서로 처리한다.
    let wideResult = wideDelegate.applyAspectRatio(to: photo)
    let squareResult = squareDelegate.applyAspectRatio(to: photo)

    #expect(wideResult.imageData == Data("16:9".utf8))
    #expect(squareResult.imageData == Data("1:1".utf8))

    let wideLive = try #require(
      await wideDelegate.applyAspectRatio(
        toLivePhotoImageData: still,
        thumbnail: thumbnail,
        livePhotoMovieURL: makeMovieFile("original")
      )
    )
    let squareLive = try #require(
      await squareDelegate.applyAspectRatio(
        toLivePhotoImageData: still,
        thumbnail: thumbnail,
        livePhotoMovieURL: makeMovieFile("original")
      )
    )

    #expect(wideLive.photoOutput.imageData == Data("16:9".utf8))
    #expect(videoData(of: wideLive.photoOutput) == Data("16:9".utf8))
    #expect(squareLive.photoOutput.imageData == Data("1:1".utf8))
    #expect(videoData(of: squareLive.photoOutput) == Data("1:1".utf8))
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

  /// 전달받은 비율 이름을 결과로 돌려줘서 어떤 비율로 잘랐는지 확인하게 한다.
  private struct RatioEchoCroppingServiceStub: PhotoAspectRatioCroppingServiceProtocol {
    func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data? {
      Data(ratio.rawValue.utf8)
    }

    func crop(livePhotoMovieURL: URL, to ratio: PhotoAspectRatio) async -> URL? {
      let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("mov")
      try? Data(ratio.rawValue.utf8).write(to: url)
      return url
    }
  }

  private func makeDelegate(cropResult: Data?, movieCropResult: URL? = nil) -> CameraDelegate {
    makeDelegate(
      aspectRatio: .ratio16x9,
      croppingService: CroppingServiceStub(result: cropResult, movieResult: movieCropResult)
    )
  }

  private func makeDelegate(
    aspectRatio: PhotoAspectRatio,
    croppingService: PhotoAspectRatioCroppingServiceProtocol
  ) -> CameraDelegate {
    CameraDelegate(
      isCameraPosition: .back,
      aspectRatio: aspectRatio,
      aspectRatioCroppingService: croppingService
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
