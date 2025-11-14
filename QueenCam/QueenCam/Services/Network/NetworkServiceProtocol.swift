//
//  NetworkServiceProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Combine
import Foundation
import WiFiAware

protocol NetworkServiceProtocol: AnyObject {
  // MARK: - Settable Properties
  /// 네트워크 모드 (호스트 / 뷰어)
  var mode: NetworkType? { get set }

  // MARK: - Observable Properties
  /// 연결 가능한 기기 목록을 방출하는 퍼블리셔입니다.
  var deviceConnectionsPublisher: AnyPublisher<[WAPairedDevice: ConnectionDetail], Never> { get }

  /// 마지막으로 발생한 에러를 방출하는 퍼블리셔입니다.
  var lastErrorPublisher: AnyPublisher<Error?, Never> { get }

  /// 현재 네트워크 상태
  var networkState: NetworkState? { get }

  /// 현재 네트워크 상태를 방출하는 퍼블리셔입니다.
  var networkStatePublisher: AnyPublisher<NetworkState?, Never> { get }

  /// 수신된 네트워크 이벤트를 방출하는 퍼블리셔입니다.
  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> { get }
  
  /// 기기별 퍼포먼스 레포트를 방출하는 퍼블리셔입니다.
  var deviceReportsPublisher: AnyPublisher<[WAPairedDevice: WAPerformanceReport], Never> { get }

  // MARK: - Methods
  /// 네트워크 서비스를 시작합니다.
  func run(for device: WAPairedDevice)

  /// 네트워크 서비스를 재시작합니다.
  func reconnect(for device: WAPairedDevice)

  /// 네트워크 서비스를 중지합니다.
  func stop(byUser: Bool)

  /// 사용자 요청으로 네트워크 연결을 중단합니다.
  func disconnect()

  /// 이벤트를 보냅니다.
  func send(for event: NetworkEvent) async
}
