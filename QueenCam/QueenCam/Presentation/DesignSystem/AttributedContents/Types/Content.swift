//
//  ContentNode.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

enum ContentNode {
  case text(text: String, style: TextStyle)
  case inlineImage(type: ImageType, style: TextStyle)
}

enum TextStyle {
  case normal
  case highlighted
}

enum ImageType {
  case assetImage(assetName: String)
  case systemImage(systemName: String)
}
