//
//  PenWriteView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/15/25.
import Foundation
import SwiftUI

/// 펜 가이드라인 작성 뷰
struct PenWriteView: View {
  @Bindable var penViewModel: PenViewModel
  var isPen: Bool
  var isMagicPen: Bool
  let role: Role?
  /// 현재 그리고 있는 Stroke의 좌표 (저장 전)
  @State private var tempPoints: [CGPoint] = []
  /// 작성 중인 스트로크 ID
  @State private var currentStrokeID: UUID?
  /// 첫 Stroke 작성 여부
  @State private var hasEverDrawn: Bool = false
  private var topColor = Color.offWhite
  private var photographerColor = Color.photographerPrimary
  private var modelColor = Color.modelPrimary
  private let magicAfter: TimeInterval = 0.7

  init(penViewModel: PenViewModel, isPen: Bool, isMagicPen: Bool, role: Role?) {
    self.penViewModel = penViewModel
    self.isPen = isPen
    self.isMagicPen = isMagicPen
    self.role = role
    self.penViewModel.currentRole = role
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {

        // 1) 일반 펜 전용 Canvas
        Canvas { context, _ in
          let outerColor = (role == .model) ? modelColor : photographerColor

          // 저장된 일반 펜 strokes
          drawStrokes(
            context: context,
            size: geo.size,
            strokes: penViewModel.strokes.filter { $0.points.count > 1 && !$0.isMagicPen },
            layers: [
              .stroke(color: topColor, width: 10),
              .stroke(color: outerColor, width: 7)
            ]
          )

          // 현재 드래그 중인 선(일반펜)
          if tempPoints.count > 1, !isMagicPen {
            drawTempPoints(
              context: context,
              size: geo.size,
              points: tempPoints,
              layers: [
                .stroke(color: topColor, width: 10),
                .stroke(color: outerColor, width: 7)
              ]
            )
          }
        }
        .background(.clear)

        // 2) 매직펜 전용 Canvas1: Blur
        Canvas { context, _ in
          let outerColor = (role == .model) ? modelColor : photographerColor

          // 저장된 매직펜 strokes (블러용)
          drawStrokes(
            context: context,
            size: geo.size,
            strokes: penViewModel.strokes.filter { $0.points.count > 1 && $0.isMagicPen },
            layers: [
              .stroke(color: outerColor, width: 10),
              .stroke(color: .offWhite, width: 5)
            ]
          )

          // 현재 드래그 중인 선(매직펜, 블러용)
          if tempPoints.count > 1, isMagicPen {
            drawTempPoints(
              context: context,
              size: geo.size,
              points: tempPoints,
              layers: [
                .stroke(color: outerColor, width: 10),
                .stroke(color: .offWhite, width: 5)
              ]
            )
          }
        }
        .drawingGroup()
        .blur(radius: 4)

        // 3) 매직펜 전용 Canvas2: topStroke는 !Blur
        Canvas { context, _ in
          // 저장된 매직펜 strokes (탑 하이라이트)
          drawStrokes(
            context: context,
            size: geo.size,
            strokes: penViewModel.strokes.filter { $0.points.count > 1 && $0.isMagicPen },
            layers: [
              .stroke(color: .offWhite, width: 3)
            ]
          )

          // 현재 드래그 중인 선(매직펜, 탑 하이라이트)
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
            hasEverDrawn = true
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
      if isPen && hasEverDrawn {
        // MARK: - 펜 툴바 Undo / Redo / clearAll
        PenToolBar(penViewModel: penViewModel) { action in
          switch action {
          case .deleteAll:
            penViewModel.deleteAll()
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
  // 저장된 선을 그림
  func drawStrokes(
    context: GraphicsContext,
    size: CGSize,
    strokes: [Stroke],
    layers: [StrokeLayer]
  ) {
    for stroke in strokes {
      let path = makePath(fromAbsolute: stroke.absolutePoints(in: size))
      for layer in layers {
        switch layer {
        case .stroke(let color, _):
          context.stroke(path, with: .color(color), style: layer.style)
        }
      }
    }
  }
  // 현재 드래그 중인 선을 그림
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
