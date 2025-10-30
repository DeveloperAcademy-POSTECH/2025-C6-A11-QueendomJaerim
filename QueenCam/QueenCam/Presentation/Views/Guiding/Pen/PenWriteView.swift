//
//  PenWriteView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/15/25.
import Foundation
import SwiftUI

/// 펜 가이드라인 작성 뷰 (only 모델)
struct PenWriteView: View {
  @Bindable var penViewModel: PenViewModel
  var isPen: Bool
  var isMagicPen: Bool
  let role: Role?

  @State private var tempPoints: [CGPoint] = []  // 현재 그리고 있는 선의 좌표(임시)
  @State private var currentStrokeID: UUID?  // 진행 중 스트로크 ID
  private var outerColor = Color.white
  private var photographerColor = Color.blue
  private var modelColor = Color.orange
  private let magicAfter: TimeInterval = 0.7

  init(penViewModel: PenViewModel, isPen: Bool, isMagicPen: Bool, role: Role?) {
    self.penViewModel = penViewModel
    self.isPen = isPen
    self.isMagicPen = isMagicPen
    self.role = role
    self.penViewModel.currentRole = role
  }

  var body: some View {
    VStack {
      GeometryReader { geo in
        // MARK: - 실제 드로잉 영역
        Canvas { context, _ in
          for stroke in penViewModel.strokes where stroke.points.count > 1 {
            var path = Path()
            path.addLines(stroke.absolutePoints(in: geo.size))
            context.stroke(path, with: .color(outerColor), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            let innerColor = stroke.author == .model ? modelColor : photographerColor
            context.stroke(path, with: .color(innerColor), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
          // 현재 드래그 중인 선
          if tempPoints.count > 1 {
            var path = Path()
            path.addLines(tempPoints.map { CGPoint(x: $0.x * geo.size.width, y: $0.y * geo.size.height) })
            context.stroke(path, with: .color(outerColor), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            let innerColor = (role == .model) ? modelColor : photographerColor
            context.stroke(path, with: .color(innerColor), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
        }
        .background(.clear)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              let relativePoint = CGPoint(
                x: geo.size.width > 0 ? value.location.x / geo.size.width : 0,
                y: geo.size.height > 0 ? value.location.y / geo.size.height : 0
              )
              tempPoints.append(relativePoint)

              // 첫 onChanged에서 시작(.add), 이후에는 진행 업데이트(.replace)
              if currentStrokeID == nil {
                guard let role else { return }
                currentStrokeID = penViewModel.add(initialPoints: tempPoints, author: role)
              } else if let id = currentStrokeID {
                penViewModel.updateStroke(id: id, points: tempPoints)
              }
            }
            .onEnded { _ in
              guard let id = currentStrokeID, !tempPoints.isEmpty else {
                tempPoints.removeAll()
                currentStrokeID = nil
                return
              }

              // 마지막 상태 반영(.replace)
              penViewModel.updateStroke(id: id, points: tempPoints)

              if isMagicPen {
                DispatchQueue.main.asyncAfter(deadline: .now() + magicAfter) {
                  penViewModel.remove(id)
                }
              }

              tempPoints.removeAll()
              currentStrokeID = nil
              penViewModel.redoStrokes.removeAll()
            }
        )
      }
      if isPen {
        // MARK: - 버튼 툴바 Undo / Redo / clearAll
        GuidingToolBarView { action in
          switch action {
          case .clearAll:
            penViewModel.removeAll()
          case .undo:
            penViewModel.undo()
          case .redo:
            penViewModel.redo()
          }
        }
      }
    }
  }
}
