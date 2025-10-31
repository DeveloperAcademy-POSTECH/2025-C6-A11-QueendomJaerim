//
//  StateToastContainerViewModel.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import Combine
import Foundation

@Observable
final class StateToastContainerViewModel {
  var lastNotificationMessage: DomainNotification?

  @ObservationIgnored private let notificationService = DependencyContainer.defaultContainer.notificationService
  @ObservationIgnored private var cancellables: Set<AnyCancellable> = []

  init() {
    bind()
  }

  func bind() {
    notificationService.lastNotificationPublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] lastNotification in
        self?.lastNotificationMessage = lastNotification
      }
      .store(in: &cancellables)
  }
}
