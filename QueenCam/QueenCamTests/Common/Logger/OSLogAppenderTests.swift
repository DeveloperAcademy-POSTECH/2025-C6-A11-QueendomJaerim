//
//  OSLogAppenderTests.swift
//  QueenCamTests
//
//  Created by seungchan on 10/30/26.
//

import Foundation
import Testing

@testable import QueenCam

@Suite("OSLogAppender Tests")
struct OSLogAppenderTests {
  @Test("여러 스레드가 같은 새 카테고리로 동시에 기록해도 앱이 종료되지 않는다")
  func writesToNewCategoryConcurrently() {
    for round in 0..<400 {
      DispatchQueue.concurrentPerform(iterations: 8) { _ in
        OSLogAppender.shared.write(category: "OSLogAppenderTests-\(round)", message: "message", level: .debug)
      }
    }
  }
}
