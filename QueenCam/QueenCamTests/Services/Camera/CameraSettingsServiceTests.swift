//
//  CameraSettingsServiceTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 6/21/26.
//

import Foundation
import Testing

@testable import QueenCam

// 같은 UserDefaults 키를 쓰므로 순서대로 실행한다.
@Suite("CameraSettingsService Tests", .serialized)
struct CameraSettingsServiceTests {
  @Test("펜 가이드 함께 저장 설정 기본값은 꺼짐이다")
  func saveGuidingOverlayImageDefaultIsOff() {
    UserDefaults.standard.removeObject(forKey: "saveGuidingOverlayImageOn")

    let service = CameraSettingsService()

    #expect(service.saveGuidingOverlayImageOn == false)
  }

  @Test("저장된 사진 비율이 없으면 4:3이다")
  func photoAspectRatioDefaultIs4x3() {
    UserDefaults.standard.removeObject(forKey: "photoAspectRatio")

    let service = CameraSettingsService()

    #expect(service.photoAspectRatio == .ratio4x3)
  }

  @Test("저장한 사진 비율을 앱을 다시 실행해도 읽을 수 있다")
  func photoAspectRatioPersistsAcrossInstances() {
    defer { UserDefaults.standard.removeObject(forKey: "photoAspectRatio") }

    CameraSettingsService().photoAspectRatio = .ratio16x9

    #expect(CameraSettingsService().photoAspectRatio == .ratio16x9)
  }

  @Test("알 수 없는 사진 비율 값이 저장되어 있으면 4:3이다")
  func unknownPhotoAspectRatioFallsBackTo4x3() {
    defer { UserDefaults.standard.removeObject(forKey: "photoAspectRatio") }
    UserDefaults.standard.set("5:4", forKey: "photoAspectRatio")

    #expect(CameraSettingsService().photoAspectRatio == .ratio4x3)
  }
}
