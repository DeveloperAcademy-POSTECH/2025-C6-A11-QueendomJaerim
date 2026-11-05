//
//  CameraDelegatePenCompositeTests.swift
//  QueenCamTests
//
//  Created by seungchan on 11/4/26.
//

import AVFoundation
import Foundation
import Testing
import UIKit

@testable import QueenCam

@MainActor
@Suite("CameraDelegate 펜 합성 결과 Tests")
struct CameraDelegatePenCompositeTests {
  @Test("합성에 성공하면 합성본이 최종본이고 기본본을 따로 저장·전송한다")
  func keepsBothWhenCompositeSucceeds() {
    let original = makePhoto(label: "original")
    let composite = makePhoto(label: "composite")
    let delegate = makeDelegate(processor: { _ in composite })

    let outputs = delegate.resolveOutputs(for: original)

    #expect(outputs.final.imageData == composite.imageData)
    #expect(outputs.separateOriginal?.imageData == original.imageData)
    #expect(delegate.sendOutputs(outputs).map(\.imageData) == [original.imageData, composite.imageData])
  }

  @Test("합성에 실패하면 기본본 한 장만 저장·전송한다")
  func keepsOnlyOriginalWhenCompositeFails() {
    let original = makePhoto(label: "original")
    let delegate = makeDelegate(processor: { _ in nil })

    let outputs = delegate.resolveOutputs(for: original)

    #expect(outputs.final.imageData == original.imageData)
    #expect(outputs.separateOriginal == nil)
    #expect(delegate.sendOutputs(outputs).map(\.imageData) == [original.imageData])
  }

  @Test("펜 합성을 쓰지 않으면 기본본 한 장만 저장·전송한다")
  func keepsOnlyOriginalWithoutProcessor() {
    let original = makePhoto(label: "original")
    let delegate = makeDelegate(processor: nil)

    let outputs = delegate.resolveOutputs(for: original)

    #expect(outputs.final.imageData == original.imageData)
    #expect(outputs.separateOriginal == nil)
    #expect(delegate.sendOutputs(outputs).count == 1)
  }

  @Test("Live Photo도 합성에 실패하면 기본본 쌍 한 개만 쓴다")
  func keepsOnlyOriginalLivePhotoWhenCompositeFails() {
    let original = PhotoOuput.livePhoto(
      thumbnail: UIImage(),
      imageData: Data("still".utf8),
      videoData: Data("video".utf8)
    )
    let delegate = makeDelegate(processor: { _ in nil })

    let outputs = delegate.resolveOutputs(for: original)

    #expect(outputs.final.imageData == original.imageData)
    #expect(outputs.separateOriginal == nil)
    #expect(delegate.sendOutputs(outputs).count == 1)
  }

  @Test("1:1에서 자르기가 실패해 원본이 오면 펜을 합성하지 않고 원본 한 장만 저장·전송한다")
  func skipsCompositeWhenCropFails() throws {
    let original = try makeJPEGPhoto(width: 300, height: 400)
    let delegate = makeCompositingDelegate(ratio: .ratio1x1, cropResult: nil)

    let outputs = delegate.resolveOutputs(for: delegate.applyAspectRatio(to: original))

    #expect(outputs.separateOriginal == nil)
    #expect(delegate.sendOutputs(outputs).map(\.imageData) == [original.imageData])
  }

  @Test("1:1로 자르기에 성공하면 실제 합성까지 거쳐 기본본과 합성본 두 장을 저장·전송한다")
  func keepsBothWhenCropSucceedsWithRealCompositing() throws {
    let original = try makeJPEGPhoto(width: 300, height: 400)
    let cropped = try makeJPEGPhoto(width: 300, height: 300)
    let delegate = makeCompositingDelegate(ratio: .ratio1x1, cropResult: cropped.imageData)

    let outputs = delegate.resolveOutputs(for: delegate.applyAspectRatio(to: original))

    #expect(outputs.separateOriginal?.imageData == cropped.imageData)
    #expect(delegate.sendOutputs(outputs).count == 2)
  }

  @Test(
    "Live Photo를 1:1로 자르지 못하면(사진 실패·영상 실패·영상 읽기 실패) 펜을 합성하지 않고 원본 쌍 한 개만 저장·전송한다",
    arguments: LiveCropFailure.allCases
  )
  func skipsCompositeWhenLiveCropFails(failure: LiveCropFailure) async throws {
    let original = try makeJPEGPhoto(width: 300, height: 400)
    let movieURL = try makeMovieFile()
    let croppedImageData = try makeJPEGPhoto(width: 300, height: 300).imageData
    let croppingService = LiveCroppingStub(
      imageResult: failure == .image ? nil : croppedImageData,
      movieResult: failure.movieResult(croppedMovieURL: try makeMovieFile())
    )
    let delegate = makeCompositingDelegate(ratio: .ratio1x1, croppingService: croppingService)

    let livePhoto = try #require(
      await delegate.applyAspectRatio(
        toLivePhotoImageData: original.imageData,
        thumbnail: original.thumbnail,
        livePhotoMovieURL: movieURL
      )
    )
    let outputs = delegate.resolveOutputs(for: livePhoto.photoOutput)

    #expect(outputs.separateOriginal == nil)
    #expect(delegate.sendOutputs(outputs).map(\.imageData) == [original.imageData])
  }

  enum LiveCropFailure: CaseIterable {
    case image
    case movie
    case unreadableMovie

    func movieResult(croppedMovieURL: URL) -> URL? {
      switch self {
      case .image: croppedMovieURL
      case .movie: nil
      case .unreadableMovie: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      }
    }
  }

  private func makeMovieFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mov")
    try Data("movie".utf8).write(to: url)
    return url
  }

  private struct LiveCroppingStub: PhotoAspectRatioCroppingServiceProtocol {
    let imageResult: Data?
    let movieResult: URL?

    func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data? { imageResult }
    func crop(livePhotoMovieURL: URL, to ratio: PhotoAspectRatio) async -> URL? { movieResult }
  }

  private func makePhoto(label: String) -> PhotoOuput {
    .basicPhoto(thumbnail: UIImage(), imageData: Data(label.utf8))
  }

  private func makeJPEGPhoto(width: Int, height: Int) throws -> PhotoOuput {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
      UIColor.gray.setFill()
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    let data = try #require(image.jpegData(compressionQuality: 1))
    return .basicPhoto(thumbnail: try #require(UIImage(data: data)), imageData: data)
  }

  /// 촬영 때와 같이 실제 합성 서비스를 셔터 순간의 비율로 묶은 Delegate
  private func makeCompositingDelegate(ratio: PhotoAspectRatio, cropResult: Data?) -> CameraDelegate {
    makeCompositingDelegate(ratio: ratio, croppingService: FixedCroppingService(result: cropResult))
  }

  private func makeCompositingDelegate(
    ratio: PhotoAspectRatio,
    croppingService: PhotoAspectRatioCroppingServiceProtocol
  ) -> CameraDelegate {
    let compositingService = PhotoOverlayCompositingService()
    let stroke = DrawableStroke(id: UUID(), points: [CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.5, y: 0.75)], author: .photographer)

    return CameraDelegate(
      isCameraPosition: .back,
      aspectRatio: ratio,
      aspectRatioCroppingService: croppingService,
      photoOutputProcessor: { photoOutput in
        compositingService.composite(
          photoOutput: photoOutput,
          strokes: [stroke],
          aspectRatio: ratio,
          previewWidth: 300,
          quarterTurns: 0
        )
      }
    ) { _, _ in }
  }

  private struct FixedCroppingService: PhotoAspectRatioCroppingServiceProtocol {
    let result: Data?

    func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data? { result }
    func crop(livePhotoMovieURL: URL, to ratio: PhotoAspectRatio) async -> URL? { nil }
  }

  private func makeDelegate(processor: ((PhotoOuput) -> PhotoOuput?)?) -> CameraDelegate {
    CameraDelegate(
      isCameraPosition: .back,
      aspectRatio: .ratio4x3,
      aspectRatioCroppingService: UnusedCroppingService(),
      photoOutputProcessor: processor
    ) { _, _ in }
  }

  private struct UnusedCroppingService: PhotoAspectRatioCroppingServiceProtocol {
    func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data? { nil }
    func crop(livePhotoMovieURL: URL, to ratio: PhotoAspectRatio) async -> URL? { nil }
  }
}
