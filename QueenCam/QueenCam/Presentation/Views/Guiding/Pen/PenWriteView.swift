//
//  PenView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/15/25.
//

import SwiftUI

struct PenWriteView: View {
  @StateObject private var viewModel = PenViewModel()
  @State private var tempPoints: [CGPoint] = [] // 현재 그리고 있는 선의 좌표(임시)
  @State private var isDrawing = false
    var body: some View {
      VStack {
        GeometryReader { geo in
          // MARK: - 실제 드로잉 영역
          Canvas { context, size in
            // 이미 strokes에 저장된 모든 선들 그리기
            for stroke in viewModel.strokes {
              guard stroke.points.count > 1 else { continue }
              var path = Path() // Line을 담는 객체
              path.addLines(stroke.points)
              context.stroke(path, with: .color(.white), style: StrokeStyle( lineWidth: 8, lineCap: .round, lineJoin:  .round))
              context.stroke(path, with: .color(.orange), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
            // 지금 드래그 중인 선들(tempPoints) 그리기: 아직 저장 안된 stroke
            if tempPoints.count > 1 {
              var path = Path()
              path.addLines(tempPoints)
              context.stroke(path, with: .color(.white), style: StrokeStyle( lineWidth: 8, lineCap: .round, lineJoin: .round))
              context.stroke(path, with: .color(.orange), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
          }
          .background(.clear)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                // 새로운 획 시작 지점
                tempPoints.append(value.location)
              }
              .onEnded { value in
                // 드래그 끝 - tempPoints을 Pen으로 저장
                guard !tempPoints.isEmpty else { return }
                viewModel.strokes.append(Pen(points: tempPoints))
                tempPoints.removeAll()
              }
          )
        }
        // MARK: - 버튼 툴바 Undo / Redo / clearAll
        ToolBarView { action in
          switch action {
          case .clearAll:
            viewModel.clearAll()
//             print("전체 삭제")
          case .undo:
            viewModel.undo()
//             print("Undo 실행 - 남은 획 수 \(viewModel.strokes.count)")
          case .redo:
            viewModel.redo()
//             print("Redo 실행 - 총 획 수: \(viewModel.redoStrokes.count)")
          }
        }
      }
    }
}

#Preview {
    PenWriteView()
}
