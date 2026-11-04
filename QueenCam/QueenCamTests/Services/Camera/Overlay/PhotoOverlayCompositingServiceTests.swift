//
//  PhotoOverlayCompositingServiceTests.swift
//  QueenCamTests
//
//  Created by seungchan on 11/4/26.
//

import CoreGraphics
import Testing
import UIKit

@testable import QueenCam

@Suite("PhotoOverlayCompositingService Tests")
struct PhotoOverlayCompositingServiceTests {
  private let service = PhotoOverlayCompositingService()
  private let background = UIColor(white: 0.5, alpha: 1)

  @Test("4:3 세로 사진에서 펜이 프리뷰와 같은 자리에 그려진다")
  func drawsStrokeAtPreviewPositionForPortrait4x3() throws {
    // 프리뷰 가운데에서 위아래 중간 구간의 세로선
    let output = composite(
      imageSize: CGSize(width: 300, height: 400),
      points: [CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.5, y: 0.75)],
      ratio: .ratio4x3,
      quarterTurns: 0
    )

    let image = try #require(output)
    #expect(isPen(image, x: 150, y: 200))
    #expect(!isPen(image, x: 50, y: 200))
    #expect(!isPen(image, x: 150, y: 50))
  }

  @Test("1:1 사진 전체를 프리뷰 기준으로 쓴다")
  func drawsStrokeAcrossWholeSquarePhoto() throws {
    // 3:4 칸 기준이면 가장자리 근처는 비어 있어야 하지만, 이제 사진 왼쪽 끝 가까이에도 그려진다.
    let output = composite(
      imageSize: CGSize(width: 400, height: 400),
      points: [CGPoint(x: 0.1, y: 0.25), CGPoint(x: 0.1, y: 0.75)],
      ratio: .ratio1x1,
      quarterTurns: 0
    )

    let image = try #require(output)
    #expect(isPen(image, x: 40, y: 200))
    #expect(!isPen(image, x: 150, y: 200))
  }

  @Test("16:9는 화면에서 숨긴 위아래만큼 펜을 안쪽으로 옮긴다")
  func shiftsStrokeInsideHiddenBandFor16x9() throws {
    // 9:16 저장 사진(225x400). 프리뷰 맨 위(y=0)는 사진 위에서 약 2.4% 아래(y≈9.5)에 해당한다.
    let output = composite(
      imageSize: CGSize(width: 225, height: 400),
      points: [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 0.5)],
      ratio: .ratio16x9,
      quarterTurns: 0
    )

    let image = try #require(output)
    #expect(isPen(image, x: 112, y: 20))
    #expect(!isPen(image, x: 112, y: 1))
  }

  @Test("가로로 찍은 사진은 펜을 사진 방향에 맞춰 돌려 그린다")
  func rotatesStrokeForLandscapePhoto() throws {
    // 세로 화면의 세로선(x=0.5, y 0.25~0.75)은 시계 방향으로 한 번 돌면 가로선(y=0.5, x 0.25~0.75)이 된다.
    let output = composite(
      imageSize: CGSize(width: 400, height: 300),
      points: [CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.5, y: 0.75)],
      ratio: .ratio4x3,
      quarterTurns: 1
    )

    let image = try #require(output)
    #expect(isPen(image, x: 200, y: 150))
    #expect(!isPen(image, x: 200, y: 50))
    #expect(!isPen(image, x: 20, y: 150))
  }

  @Test("펜 두께는 프리뷰 폭 기준으로 화면과 같은 비율이다")
  func scalesLineWidthByPreviewWidth() throws {
    // 사진 짧은 변 300px, 프리뷰 폭 150pt이면 2배다. 화면의 10pt 테두리는 20px, 7pt 색 선은 14px이다.
    let output = composite(
      imageSize: CGSize(width: 300, height: 400),
      points: [CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.5, y: 0.75)],
      ratio: .ratio4x3,
      quarterTurns: 0,
      previewWidth: 150
    )

    let image = try #require(output)
    // 테두리 폭 20px이면 가운데(150)에서 ±10px까지 칠해진다. 가장자리 픽셀은 흐려지므로 여유를 두고 본다.
    #expect(isPen(image, x: 157, y: 200))
    #expect(!isPen(image, x: 163, y: 200))
    #expect(isPen(image, x: 143, y: 200))
    #expect(!isPen(image, x: 137, y: 200))
  }

  @Test("펜이 없으면 사진을 그대로 돌려준다")
  func returnsOriginalWithoutStrokes() throws {
    let imageData = try #require(makeImage(size: CGSize(width: 300, height: 400)).jpegData(compressionQuality: 1))
    let original = PhotoOuput.basicPhoto(thumbnail: UIImage(data: imageData) ?? .init(), imageData: imageData)

    let result = service.composite(
      photoOutput: original,
      strokes: [],
      aspectRatio: .ratio4x3,
      previewWidth: 300,
      quarterTurns: 0
    )

    #expect(result?.imageData == imageData)
  }

  @Test("사진을 읽을 수 없으면 합성에 실패해 nil을 돌려준다")
  func returnsNilWhenImageCannotBeRead() {
    let unreadable = PhotoOuput.basicPhoto(thumbnail: UIImage(), imageData: Data("not an image".utf8))
    let stroke = DrawableStroke(
      id: UUID(),
      points: [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.8, y: 0.8)],
      author: .photographer
    )

    let result = service.composite(
      photoOutput: unreadable,
      strokes: [stroke],
      aspectRatio: .ratio4x3,
      previewWidth: 300,
      quarterTurns: 0
    )

    #expect(result == nil)
  }
}

private extension PhotoOverlayCompositingServiceTests {
  func composite(
    imageSize: CGSize,
    points: [CGPoint],
    ratio: PhotoAspectRatio,
    quarterTurns: Int,
    previewWidth: CGFloat? = nil
  ) -> UIImage? {
    guard let imageData = makeImage(size: imageSize).jpegData(compressionQuality: 1) else { return nil }

    let original = PhotoOuput.basicPhoto(thumbnail: UIImage(data: imageData) ?? .init(), imageData: imageData)
    let stroke = DrawableStroke(id: UUID(), points: points, author: .photographer)

    // 두께 배율 1이 되도록 프리뷰 폭을 사진 짧은 변과 같게 둔다.
    let result = service.composite(
      photoOutput: original,
      strokes: [stroke],
      aspectRatio: ratio,
      previewWidth: previewWidth ?? min(imageSize.width, imageSize.height),
      quarterTurns: quarterTurns
    )

    return result?.thumbnail
  }

  func makeImage(size: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true

    return UIGraphicsImageRenderer(size: size, format: format).image { context in
      background.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
  }

  /// 해당 픽셀이 펜(흰 테두리 또는 색 선)으로 칠해졌는지, 배경 회색과 충분히 다른지로 본다.
  func isPen(_ image: UIImage, x: Int, y: Int) -> Bool {
    guard let cgImage = image.cgImage, x >= 0, y >= 0, x < cgImage.width, y < cgImage.height else { return false }

    var pixel = [UInt8](repeating: 0, count: 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard
      let context = CGContext(
        data: &pixel,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return false }

    context.draw(cgImage, in: CGRect(x: -x, y: -(cgImage.height - 1 - y), width: cgImage.width, height: cgImage.height))

    let backgroundValue = 0.5 * 255
    return pixel[0..<3].contains { abs(Double($0) - backgroundValue) > 25 }
  }
}
