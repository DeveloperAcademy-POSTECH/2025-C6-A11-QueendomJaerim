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
}
