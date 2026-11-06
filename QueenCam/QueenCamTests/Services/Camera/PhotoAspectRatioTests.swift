//
//  PhotoAspectRatioTests.swift
//  QueenCamTests
//
//  Created by seungchan on 10/23/26.
//

import Foundation
import Testing

@testable import QueenCam

@Suite("PhotoAspectRatio Tests")
struct PhotoAspectRatioTests {
  @Test("상단 버튼 순서대로 4:3 → 16:9 → 1:1 → 4:3 순환한다")
  func cyclesInButtonOrder() {
    #expect(PhotoAspectRatio.ratio4x3.next() == .ratio16x9)
    #expect(PhotoAspectRatio.ratio16x9.next() == .ratio1x1)
    #expect(PhotoAspectRatio.ratio1x1.next() == .ratio4x3)
  }

  @Test("저장·전송에 쓰는 문자열 값이 고정되어 있다")
  func rawValuesAreStable() throws {
    #expect(PhotoAspectRatio(rawValue: "4:3") == .ratio4x3)
    #expect(PhotoAspectRatio(rawValue: "16:9") == .ratio16x9)
    #expect(PhotoAspectRatio(rawValue: "1:1") == .ratio1x1)

    let data = try JSONEncoder().encode(PhotoAspectRatio.ratio16x9)
    #expect(String(data: data, encoding: .utf8) == "\"16:9\"")
  }

  @Test("긴 변과 짧은 변의 정수 비를 제공한다")
  func longAndShortSides() {
    #expect(PhotoAspectRatio.ratio4x3.longSide == 4)
    #expect(PhotoAspectRatio.ratio4x3.shortSide == 3)
    #expect(PhotoAspectRatio.ratio16x9.longSide == 16)
    #expect(PhotoAspectRatio.ratio16x9.shortSide == 9)
    #expect(PhotoAspectRatio.ratio1x1.longSide == 1)
    #expect(PhotoAspectRatio.ratio1x1.shortSide == 1)
  }
}
