//
//  PhotoAspectRatioCroppingService.swift
//  QueenCam
//
//  Created by seungchan on 10/24/26.
//

import Foundation

/// 사진을 셔터 순간 비율로 가운데에서 자른다. 자르는 코드는 `+Image` 파일에 있다.
nonisolated final class PhotoAspectRatioCroppingService: PhotoAspectRatioCroppingServiceProtocol {
  static let logger = QueenLogger(category: "PhotoAspectRatioCroppingService")
}
