//
//  OSLogAppender.swift
//  QueenCam
//
//  Created by 임영택 on 11/3/25.
//

import Foundation
import OSLog
import os

/// 카테고리별 os.Logger로 시스템 로그를 남기는 싱글톤 클래스입니다.
/// 로거 맵을 잠금으로 보호해 여러 스레드의 QueenLogger가 동시에 기록해도 충돌(Race Condition)하지 않습니다.
nonisolated final class OSLogAppender: LogAppending {
  /// 앱 전체에서 유일하게 사용될 싱글톤 인스턴스
  static let shared = OSLogAppender()

  /// 카테고리에 대한 로거 인스턴스 맵. 여러 스레드에서 동시에 기록하므로 잠금으로 보호한다.
  private let osLoggers = OSAllocatedUnfairLock(initialState: [String: Logger]())

  /// QueenLogger로부터 로그 데이터를 받아 시스템 로그에 남깁니다.
  public func write(category: String, message: String, level: LogLevel) {
    let logger = osLoggers.withLock { osLoggers in
      if let logger = osLoggers[category] { return logger }

      let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: category)
      osLoggers[category] = logger
      return logger
    }

    switch level {
    case .error: logger.error("\(message, privacy: .public)")
    case .warning: logger.warning("\(message, privacy: .public)")
    case .info: logger.info("\(message, privacy: .public)")
    case .debug: logger.debug("\(message, privacy: .public)")
    }
  }
}
