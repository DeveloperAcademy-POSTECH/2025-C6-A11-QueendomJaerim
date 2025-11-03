//
//  QueenLogger.swift
//  QueenCam
//
//  Created by 임영택 on 11/01/25.
//

import Foundation
import OSLog

nonisolated public final class QueenLogger {
  private let subsystem: String
  private let category: String
  private let osLogger: Logger

  private let appenders: [LogAppending] = [
    LogFileAppender.shared,
    OSLogAppender.shared
  ]

  public init(category: String) {
    self.subsystem = Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam"
    self.category = category
    self.osLogger = Logger(subsystem: subsystem, category: category)
  }

  public func info(_ message: @autoclosure () -> String) {
    let message = message()
    log(level: .info, message: message)
  }

  public func debug(_ message: @autoclosure () -> String) {
    let message = message()
    #if DEBUG
    log(level: .debug, message: message)
    #endif
  }

  public func warning(_ message: @autoclosure () -> String) {
    let message = message()
    log(level: .warning, message: message)
  }

  public func error(_ message: @autoclosure () -> String) {
    let message = message()
    log(level: .error, message: message)
  }

  private func log(level: LogLevel, message: String) {
    appenders.forEach { appender in
      appender.write(category: category, message: message, level: level)
    }
  }
}
