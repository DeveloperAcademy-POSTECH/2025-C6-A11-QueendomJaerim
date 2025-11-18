//
//  NotificationServiceProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import Combine
import Foundation

protocol NotificationServiceProtocol: AnyObject {
  /// 현재 알림
  var currentNotification: DomainNotification? { get }

  /// 마지막 알림 상태를 방출하는 퍼블리셔입니다. 알림이 없으면 `nil`을 방출합니다.
  var lastNotificationPublisher: AnyPublisher<DomainNotification?, Never> { get }

  /// 새로운 알림을 등록하고 게시합니다.
  /// - Parameter notification: 표시할 알림 객체
  func registerNotification(_ notification: DomainNotification)

  /// 현재 표시 중인 알림을 즉시 제거합니다.
  func reset()

  /// 새로운 베이스 알림을 등록하고 게시합니다.
  /// - Parameter notification: 표시할 알림 객체. showingTime이 지정되어 있어도 사라지지 않고 상시 노출됩니다.
  func registerBaseNotification(_ notification: DomainNotification)

  /// 베이스 알림을 즉시 제거합니다.
  func resetBaseNotification()
}
