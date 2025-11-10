//
//  PenWriteView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/15/25.
import Foundation
import SwiftUI

/// 펜 가이드라인 작성 뷰
struct PenWriteView: View {
  var penViewModel: PenViewModel
  var isPen: Bool
  var isMagicPen: Bool
  let role: Role?
  
  init(penViewModel: PenViewModel, isPen: Bool, isMagicPen: Bool, role: Role?) {
    self.penViewModel = penViewModel
    self.isPen = isPen
    self.isMagicPen = isMagicPen
    self.role = role
    self.penViewModel.currentRole = role
  }
  
  /// 현재 그리고 있는 Stroke의 좌표 (저장 전)
  @State private var tempPoints: [CGPoint] = []
  /// 작성 중인 스트로크 ID
  @State private var currentStrokeID: UUID?
  
  private var topColor = Color.offWhite
  private var photographerColor = Color.photographerPrimary
  private var modelColor = Color.modelPrimary
  private let magicAfter: TimeInterval = 0.7

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // MARK: - 저장된 Stroke
        PenDisplayView(penViewModel: penViewModel)
        
        // MARK: - 저장 안된, 현재 그리고 있는 Stroke
        let author = role ?? .photographer
        let outerColor = (author == .model) ? modelColor : photographerColor
        // 1) 일반펜
        if tempPoints.count > 1, !isMagicPen {
          Canvas { context, _ in
              drawTempPoints(
                context: context,
                size: geo.size,
                points: tempPoints,
                layers: [
                  .stroke(color: topColor, width: 10),
                  .stroke(color: outerColor, width: 7),
                ]
              )
          }
          .background(.clear)
        }

        // 2) 매직펜 전용
        // 매직펜 Blur 레이어
        Canvas { context, _ in
          if tempPoints.count > 1, isMagicPen {
            drawTempPoints(
              context: context,
              size: geo.size,
              points: tempPoints,
              layers: [
                .stroke(color: outerColor, width: 10),
                .stroke(color: .offWhite, width: 5),
              ]
            )
          }
        }
        .drawingGroup()
        .blur(radius: 4)

        // 매직펜 !Blur 레이어
        Canvas { context, _ in
          if tempPoints.count > 1, isMagicPen {
            drawTempPoints(
              context: context,
              size: geo.size,
              points: tempPoints,
              layers: [
                .stroke(color: .offWhite, width: 3)
              ]
            )
          }
        }
      }
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            let author = role ?? .photographer
            let relativePoint = CGPoint(
              x: geo.size.width > 0 ? value.location.x / geo.size.width : 0,
              y: geo.size.height > 0 ? value.location.y / geo.size.height : 0
            )
            tempPoints.append(relativePoint)

            if currentStrokeID == nil {
              currentStrokeID = penViewModel.add(initialPoints: tempPoints, isMagicPen: isMagicPen, author: author)
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
    .overlay(alignment: .bottomLeading) {
      // 펜 모드일 때, 내가 한 번이라도 그린 적이 있으면 노출
      if isPen && penViewModel.hasEverDrawn {
        // MARK: - 펜 툴바 Undo / Redo / clearAll
        PenToolBar(penViewModel: penViewModel) { action in
          switch action {
          case .deleteAll:
            penViewModel.deleteAll()
            penViewModel.showEraseGuidingLineToast()
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

private extension PenWriteView {
  enum StrokeLayer {
    case stroke(color: Color, width: CGFloat)

    var style: StrokeStyle {
      StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
    }

    private var lineWidth: CGFloat {
      switch self {
      case .stroke(_, let width): return width
      }
    }
  }
  func makePath(fromAbsolute points: [CGPoint]) -> Path {
    var path = Path()
    path.addLines(points)
    return path
  }
  func makePath(fromRelative points: [CGPoint], in size: CGSize) -> Path {
    let abs = points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
    return makePath(fromAbsolute: abs)
  }
  func drawTempPoints(
    context: GraphicsContext,
    size: CGSize,
    points: [CGPoint],
    layers: [StrokeLayer]
  ) {
    let path = makePath(fromRelative: points, in: size)
    for layer in layers {
      switch layer {
      case .stroke(let color, _):
        context.stroke(path, with: .color(color), style: layer.style)
      }
    }
  }
}
