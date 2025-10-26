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
  @Binding var isPen: Bool
  @Binding var isDisappearPen: Bool
  @State private var tempPoints: [CGPoint] = []  // 현재 그리고 있는 선의 좌표(임시)
  private var outerColor = Color.white
  private var innerColor = Color.orange

  init(penViewModel: PenViewModel, isPen: Binding<Bool>, isDisappearPen: Binding<Bool>) {
    self.penViewModel = penViewModel
    self._isPen = isPen
    self._isDisappearPen = isDisappearPen
  }

  var body: some View {
    VStack {
      GeometryReader { _ in
        // MARK: - 실제 드로잉 영역
        Canvas { context, _ in
          // 이미 strokes에 저장된 모든 선들 그리기
          if isPen {
            for stroke in penViewModel.strokes {
              guard stroke.points.count > 1 else { continue }
              var path = Path()  // Line을 담는 객체
              path.addLines(stroke.points)
              context.stroke(path, with: .color(outerColor), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
              context.stroke(path, with: .color(innerColor), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
          } else {
            for stroke in penViewModel.disappearStokes {
              guard stroke.points.count > 1 else { continue }
              var path = Path()
              path.addLines(stroke.points)
              context.stroke(path, with: .color(outerColor), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
              context.stroke(path, with: .color(innerColor), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                penViewModel.disappearStokes.removeAll()
              }
            }
          }

          // 지금 드래그 중인 선들(tempPoints) 그리기: 아직 저장 안된 stroke
          if tempPoints.count > 1 {
            var path = Path()
              path.addLines(tempPoints)
            context.stroke(path, with: .color(outerColor), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .color(innerColor), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
        }
        .background(.clear)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              tempPoints.append(value.location)
            }
            .onEnded { _ in
              guard !tempPoints.isEmpty else { return }
              if isPen {
                penViewModel.strokes.append(Pen(points: tempPoints))
              } else {
                penViewModel.disappearStokes.append(Pen(points: tempPoints))
              }
              tempPoints.removeAll()
              penViewModel.redoStrokes.removeAll()
            }
        )
      }
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
