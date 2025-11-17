import Combine
import Foundation

@Observable
final class ThumbsUpViewModel {

  // MARK: - 네트워크
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  var animationTriger: Bool = false

  // 처음에는 안보이게 숨기기 위함
  private(set) var isShowInitialView = false

  init(networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService) {
    self.networkService = networkService

    bind()
  }

  func userTriggerThumbsUp() {
    isShowInitialView = true
    sendThumbsUpShowEvent()
    animationTriger.toggle()
  }
}

// MARK: Receiving network event
extension ThumbsUpViewModel {
  private func bind() {
    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .thumbsUp:
          self?.handleThumbsUpShowEvent()
        default: break
        }
      }
      .store(in: &cancellables)
  }

  /// Incomming Event
  private func handleThumbsUpShowEvent() {
    isShowInitialView = true
    animationTriger.toggle()
  }

  /// Outcomming Event
  private func sendThumbsUpShowEvent() {
    Task.detached {
      await self.networkService.send(for: .thumbsUp)
    }
  }
}
