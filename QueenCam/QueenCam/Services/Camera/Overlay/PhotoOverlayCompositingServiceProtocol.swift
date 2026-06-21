//
//  PhotoOverlayCompositingServiceProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import Foundation

protocol PhotoOverlayCompositingServiceProtocol {
  func composite(photoOutput: PhotoOuput, strokes: [DrawableStroke]) -> PhotoOuput
}
