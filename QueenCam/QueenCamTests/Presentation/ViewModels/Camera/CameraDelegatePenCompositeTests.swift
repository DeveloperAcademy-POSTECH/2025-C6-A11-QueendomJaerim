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

  private func makePhoto(label: String) -> PhotoOuput {
    .basicPhoto(thumbnail: UIImage(), imageData: Data(label.utf8))
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
