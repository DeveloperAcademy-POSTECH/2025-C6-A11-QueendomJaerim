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

  @State private var tempPoints: [CGPoint] = []  // 현재 그리고 있는 선의 좌표(임시)
  private var outerColor = Color.white
  private var innerColor = Color.orange
  private let magicAfter: TimeInterval = 0.7

  init(penViewModel: PenViewModel, isPen: Bool, isMagicPen: Bool) {
    self.penViewModel = penViewModel
    self.isPen = isPen
    self.isMagicPen = isMagicPen
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
            context.stroke(path, with: .color(innerColor), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
          // 현재 드래그 중인 선
          if tempPoints.count > 1 {
            var path = Path()
            path.addLines(
              tempPoints.map {
                CGPoint(x: $0.x * geo.size.width, y: $0.y * geo.size.height)
              }
            )
            context.stroke(path, with: .color(outerColor), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .color(innerColor), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
        }
        .background(.clear)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              let relativePoint = CGPoint(x: value.location.x / geo.size.width, y: value.location.y / geo.size.height)
              tempPoints.append(relativePoint)
            }
            .onEnded { _ in
              guard !tempPoints.isEmpty else { return }
              let stroke = Stroke(points: tempPoints)
              penViewModel.strokes.append(stroke)

              if isMagicPen {
                DispatchQueue.main.asyncAfter(deadline: .now() + magicAfter) {
                  penViewModel.strokes.removeAll { $0.id == stroke.id }
                }
              }
              tempPoints.removeAll()
              penViewModel.redoStrokes.removeAll()
            }
        )
      }
      if isPen {
        // MARK: - 버튼 툴바 Undo / Redo / clearAll
        GuidingToolBarView { action in
          switch action {
          case .clearAll:
            penViewModel.clearAll()
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
