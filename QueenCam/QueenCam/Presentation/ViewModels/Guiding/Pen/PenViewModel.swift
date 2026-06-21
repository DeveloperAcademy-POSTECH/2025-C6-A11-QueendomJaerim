//
//  PenViewModel.swift
//  QueenCam
//
//  Created by 윤보라 on 10/15/25.
//
import Combine
import Foundation
import SwiftUI

@Observable
final class PenViewModel {
  /// 이전 세션에 그려진 모든 선(stroke)들 - Undo 불가
  var persistedStrokes: [Stroke] = []
  /// 현재 세션 중 그려진 모든 선(stroke)들
  var strokes: [Stroke] = []
  /// 사용자가 전체삭제 했던 선(stroke)들
  var deleteStrokes: [[Stroke]] = []
  /// 현재 사용자의 역할(모델, 작가, 미연결)
  var currentRole: Role?
  /// 미연결(nil)인 경우 작가로 역할 부여
  private var myRole: Role { currentRole ?? .photographer }
  /// 세션 동안 내가 한 번이라도 그렸는지 여부
  var hasEverDrawn: Bool = false

  // 가이드 최초 1회
  private var hasShownPenToast: Bool = false
  private var hasShownMagicPenToast: Bool = false
  // 가이드 사용시 레퍼런스 확대 최초 1회
  private var hasShownPenReferenceLargeToast: Bool = false
  private var hasShownMagicPenReferenceLargeToast: Bool = false

  // MARK: - Stroke Repository
  private let strokeRepository: GuidingStrokeRepositoryProtocol
  private var strokeSnapshotTask: Task<Void, Never>?

  // MARK: - Toast
  let notificationService: NotificationServiceProtocol

  init(
    strokeRepository: GuidingStrokeRepositoryProtocol = DependencyContainer.defaultContainer.guidingStrokeRepository,
    notificationService: NotificationServiceProtocol = DependencyContainer.defaultContainer.notificationService
  ) {
    self.strokeRepository = strokeRepository
    self.notificationService = notificationService

    bindStrokeSnapshots()
  }

  deinit {
    strokeSnapshotTask?.cancel()
  }

  // MARK: - 드로잉 시작/진행 업데이트
  func add(initialPoints: [CGPoint], isMagicPen: Bool, author: Role) -> UUID {
    if author == myRole && hasEverDrawn == false {
      hasEverDrawn = true
    }

    return strokeRepository.add(initialPoints: initialPoints, isMagicPen: isMagicPen, author: author)
  }

  /// 진행 중 스트로크의 포인트를 갱신 +  .replace 이벤트를 전송
  func updateStroke(id: UUID, points: [CGPoint], endDrawing: Bool) {
    strokeRepository.updateStroke(id: id, points: points, endDrawing: endDrawing, author: myRole)
  }
  // MARK: - 세션 종료 후 Stroke 저장
  /// 펜 툴 해제(세션 종료) 시 본인 stroke를 strokes에서 persistedStrokes로 이관
  func saveStroke() {
    strokeRepository.saveStroke(for: myRole)
  }

  // MARK: - 스트로크 삭제
  /// 펜 가이딩 개별 획(stroke)  삭제 - 매직펜
  func remove(_ id: UUID) {
    strokeRepository.remove(id, author: myRole)
  }

  /// 본인이 생성한 펜 가이딩 전체 삭제
  func deleteAll() {
    strokeRepository.deleteAll(for: myRole)
  }

  /// 펜 가이딩 초기화
  func reset() {
    hasEverDrawn = false

    strokeRepository.reset()
  }

  // MARK: - 스트로크 실행취소/재실행
  func undo() {
    strokeRepository.undo(for: myRole)
  }

  // MARK: - 토스트
  enum GuidingType {
    case pen
    case magicPen
  }
  // 툴 사용 중 레퍼런스 확대 - 최초 1회
  func showToolReferenceLargeToast(type: GuidingType) {
    switch type {
    case .pen:
      guard !hasShownPenReferenceLargeToast else { return }
      notificationService.registerNotification(DomainNotification.make(type: .toolUsingEnlargeReference))
      hasShownPenReferenceLargeToast = true
    case .magicPen:
      guard !hasShownMagicPenReferenceLargeToast else { return }
      notificationService.registerNotification(DomainNotification.make(type: .toolUsingEnlargeReference))
      hasShownMagicPenReferenceLargeToast = true
    }
  }
  // 처음으로 펜+ 매직펜 툴 선택 할때 토스트
  func showFirstToolToast(type: GuidingType) {
    switch type {
    case .pen:
      guard !hasShownPenToast else { return }
      notificationService.registerNotification(DomainNotification.make(type: .firstPenToolSelected))
      hasShownPenToast = true
    case .magicPen:
      guard !hasShownMagicPenToast else { return }
      notificationService.registerNotification(DomainNotification.make(type: .firstMagicToolSelected))
      hasShownMagicPenToast = true
    }
  }
  // 지우개로 펜 가이드라인 지울때마다의 토스트
  func showEraseGuidingLineToast() {
    notificationService.registerNotification(DomainNotification.make(type: .penEraserSelected))
  }
}

extension PenViewModel {
  private func bindStrokeSnapshots() {
    let initialSnapshot = strokeRepository.currentSnapshot()
    persistedStrokes = initialSnapshot.persistedStrokes
    strokes = initialSnapshot.strokes
    deleteStrokes = initialSnapshot.deleteStrokes

    strokeSnapshotTask = Task { [weak self, strokeRepository] in
      for await snapshot in strokeRepository.snapshots {
        await MainActor.run {
          self?.persistedStrokes = snapshot.persistedStrokes
          self?.strokes = snapshot.strokes
          self?.deleteStrokes = snapshot.deleteStrokes
        }
      }
    }
  }
}
