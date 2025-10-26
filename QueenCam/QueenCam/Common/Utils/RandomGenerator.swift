//
//  RandomGenerator.swift
//  QueenCam
//
//  Created by 임영택 on 10/22/25.
//

import Foundation

struct RandomGenerator {
  static func string(length: Int) -> String {
      let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in characters.randomElement()! })
  }
}
