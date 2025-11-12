//
//  AVPlayerContainer.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import AVKit
import SwiftUI

struct AVPlayerContainer: UIViewControllerRepresentable {
  let player: AVPlayer

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let viewController = AVPlayerViewController()
    viewController.player = player
    viewController.showsPlaybackControls = false
    viewController.view.backgroundColor = .clear

    return viewController
  }

  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    //
  }
}
