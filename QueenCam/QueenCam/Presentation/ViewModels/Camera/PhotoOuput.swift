//
//  PhotoOuput.swift
//  QueenCam
//
//  Created by 임영택 on 10/15/25.
//

import Foundation
import UIKit

enum PhotoOuput {
  case basicPhoto(thumbnail: UIImage, imageData: Data)
  case livePhoto(thumbnail: UIImage, imageData: Data, videoData: Data)

  var thumbnail: UIImage {
    switch self {
    case .basicPhoto(let thumbnail, _):
      return thumbnail
    case .livePhoto(let thumbnail, _, _):
      return thumbnail
    }
  }

  var imageData: Data {
    switch self {
    case .basicPhoto(_, let imageData):
      return imageData
    case .livePhoto(_, let imageData, _):
      return imageData
    }
  }
}
