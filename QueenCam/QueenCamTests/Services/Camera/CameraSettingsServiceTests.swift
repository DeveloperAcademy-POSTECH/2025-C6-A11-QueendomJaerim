//
//  CameraSettingsServiceTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 6/21/26.
//

import Foundation
import Testing

@testable import QueenCam

@Suite("CameraSettingsService Tests")
struct CameraSettingsServiceTests {
  @Test("펜 가이드 함께 저장 설정 기본값은 켜짐이다")
  func saveGuidingOverlayImageDefaultIsOn() {
    UserDefaults.standard.removeObject(forKey: "saveGuidingOverlayImageOn")

    let service = CameraSettingsService()

    #expect(service.saveGuidingOverlayImageOn == true)
  }
}
