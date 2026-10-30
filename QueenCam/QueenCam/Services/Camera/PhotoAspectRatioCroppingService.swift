//
//  PhotoAspectRatioCroppingService.swift
//  QueenCam
//
//  Created by seungchan on 10/24/26.
//

import Foundation

/// 사진과 Live Photo 영상을 셔터 순간 비율로 가운데에서 자른다.
/// 일반 사진은 `+Image`, Live Photo 영상은 `+LivePhotoMovie` 파일에서 다룬다.
nonisolated final class PhotoAspectRatioCroppingService: PhotoAspectRatioCroppingServiceProtocol {
  static let logger = QueenLogger(category: "PhotoAspectRatioCroppingService")
}
