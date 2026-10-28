//
//  PhotoAspectRatioCroppingServiceProtocol.swift
//  QueenCam
//
//  Created by seungchan on 10/24/26.
//

import Foundation

nonisolated protocol PhotoAspectRatioCroppingServiceProtocol: Sendable {
  /// 사진 데이터를 비율에 맞게 가운데에서 자른다. 이미 그 비율이면 원본 데이터를, 자르지 못하면 nil을 돌려준다.
  func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data?
}
