import Combine
import Foundation

@Observable
final class ThumbsUpViewModel {
  private(set) var testString: String?

  // MARK: - 네트워크
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  // MARK: - 타이머를 이용해 자동으로 닫히도록
  private var timer: Timer?
  // 뷰가 화면에 머무르는 시간
  private var timerInterval: TimeInterval = 0.5

  init(networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService) {
    self.networkService = networkService

    bind()
  }

  func register(testString: String?) {
    guard self.testString == nil else {
      return
    }

    guard let testString else { return }
    self.testString = testString
    self.sendThumbsUpCommand(command: .register(test: testString))

    startAutoDeleteTimer()
  }

  func onDelete() {  // 초기화
    timer?.invalidate()
    timer = nil

    guard testString != nil else { return }

    testString = nil
    self.sendThumbsUpCommand(command: .remove)
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
        case .thumbsUp(let eventType):
          self?.handleThumbsUpShowEvent(eventType: eventType)
        default: break
        }
      }
      .store(in: &cancellables)
  }

  private func handleThumbsUpShowEvent(eventType: ThumbsUpEventType) {
    switch eventType {
    case .register(let test):
      self.testString = test
      startAutoDeleteTimer()
    case .remove:
      timer?.invalidate()
      timer = nil
      self.testString = nil
    }
  }
}

// MARK: Sending network event
extension ThumbsUpViewModel {
  private func sendThumbsUpCommand(command: ThumbsUpNetworkCommand) {
    if case .register(let test) = command {
      sendThumbsUpShowEvent(testString: test)
    } else {
      sendThumbsUpRemoveEvent()
    }
  }

  private func sendThumbsUpShowEvent(testString: String) {
    Task.detached { [weak self] in
      guard let self else { return }

      await self.networkService.send(for: .thumbsUp(.register(test: testString)))
    }
  }

  private func sendThumbsUpRemoveEvent() {
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .thumbsUp(.remove))
    }
  }
}

// MARK: - 타이머 로직
extension ThumbsUpViewModel {
  private func startAutoDeleteTimer() {
    // 기존 타이머가 있다면 취소
    timer?.invalidate()

    // 새로운 타이머를 설정
    timer = Timer.scheduledTimer(
      withTimeInterval: timerInterval,
      repeats: false
    ) { [weak self] _ in
      // 시간이 만료되면 onDelete()를 호출
      self?.onDelete()
    }
  }
}

private enum ThumbsUpNetworkCommand {
  case remove
  case register(test: String)
}
