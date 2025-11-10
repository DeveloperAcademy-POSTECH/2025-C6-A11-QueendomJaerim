//
//  FrameLayerView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.

import SwiftUI

/// 한개의 프레임에 대한 모든 제스처 관리
struct FrameView: View {
  @Bindable var frameViewModel: FrameViewModel
  let frame: Frame
  let containerSize: CGSize
  /// 비율 조정하기 위해 프레임 선택 여부
  var isSelected: Bool
  /// 현재 사용자 역할(모델, 작가)
  var currentRole: Role?

  /// 이동 drag 제스쳐 시작할때의 초기 프레임
  @State private var frameMove: CGRect?
  /// 배율 magnify 제스쳐 시작할때의 초기 프레임
  @State private var frameScale: CGRect?
  /// 비율 조정 drag 제스쳐 시작할때의 초기 프레임
  @State private var cornerScale: CGRect?

  /// 현재 제스처 소유 여부
  @State private var didAcquireInteraction: Bool = false
  /// 제스쳐 활성화 가능 여부
  private var canInteract: Bool {
    let myRole = frameViewModel.currentRole ?? .photographer
    return frameViewModel.isFrameEnabled && (frameViewModel.interactingRole == nil || frameViewModel.interactingRole == myRole)
  }
  
  // 현재 토스트 근황
  @State private var hasShownRatioEditToast: Bool = false

  var body: some View {
    let rect = frame.rect
    let width = rect.width * containerSize.width
    let height = rect.height * containerSize.height
    let x = (rect.origin.x + rect.width / 2) * containerSize.width
    let y = (rect.origin.y + rect.height / 2) * containerSize.height

    /// 프레임 내부 및 스트로크(테두리) 색상
    let frameColor: AnyShapeStyle = {
      switch (isSelected, canInteract, currentRole) {
      // 모델이 현재 프레임의 비율을 수정하고 있는 경우
      case (true, true, .some(.model)):
        return AnyShapeStyle(.modelPrimary)
      // 작가가 현재 프레임의 비율을 수정하고 있는 경우
      case (true, true, .some(.photographer)):
        return AnyShapeStyle(.photographerPrimary)
      // 현재 내가 프레임을 수정하고 있지 않는 경우
      case (_, false, _):
        return AnyShapeStyle(.offWhite)
      // 현재 내가 드래그 중인 경우
      case (false, true, _):
        return AnyShapeStyle(
          LinearGradient(
            stops: [
              Gradient.Stop(color: .modelPrimary, location: 0.00),
              Gradient.Stop(color: .photographerPrimary, location: 1.00),
            ],
            startPoint: UnitPoint(x: 0.01, y: 0),
            endPoint: UnitPoint(x: 0.99, y: 1)
          )
        )
      default:
        return AnyShapeStyle(.modelPrimary)
      }
    }()

    ZStack(alignment: .center) {
      // 실제 1개의 프레임 본체
      Rectangle()
        .fill(Color.clear)
        .overlay(
          Rectangle()
            .stroke(frameColor, style: StrokeStyle(lineWidth: 2, dash: [10, 10]))
        )
        .frame(width: width, height: height)
        .background {
          Rectangle()
            .fill(frameColor)
            .opacity(0.15)
        }
        .position(x: x, y: y)
        .onTapGesture {
          if frameViewModel.isSelected(frame.id) {
            frameViewModel.selectFrame(nil)
          } else {
            frameViewModel.selectFrame(frame.id)
            if !hasShownRatioEditToast{
              frameViewModel.myFrameGuidingToast(type: .ratioEdit)
              hasShownRatioEditToast = true
            }
          }
        }
        .gesture(  // 프레임 이동
          // 현재 상대방이 수정 중이 아님 + 비율 조정 상태 아님
          canInteract && !isSelected
            ? DragGesture(minimumDistance: 2)
              .onChanged { value in
                if frameMove == nil { frameMove = frame.rect }
                if didAcquireInteraction == false {
                  acquireInteraction()
                }
                guard let start = frameMove else { return }
                frameViewModel.moveFrame(
                  id: frame.id,
                  start: start,
                  translation: value.translation,
                  container: containerSize
                )
              }
              .onEnded { _ in
                frameMove = nil
                if didAcquireInteraction {
                  releaseInteraction()
                }
              }
            : nil
        )
        .simultaneousGesture(  // 프레임 확대 및 축소
          // 현재 상대방이 수정 중이 아님 + 비율 조정 상태 아님
          canInteract && !isSelected
            ? MagnifyGesture()
              .onChanged { value in
                if frameScale == nil { frameScale = frame.rect }
                if didAcquireInteraction == false {
                  acquireInteraction()
                }
                guard let start = frameScale else { return }
                frameViewModel.resizeFrame(
                  id: frame.id,
                  start: start,
                  scale: value.magnification
                )
              }
              .onEnded { _ in
                frameScale = nil
                if didAcquireInteraction {
                  releaseInteraction()
                }
              }
            : nil
        )

      // Dimming+ 3x3 그리드 표시 + Corner 핸들
      // 현재 상대방이 수정 중이 아님 + 비율 조정 상태임
      if canInteract && isSelected {
        // Dimming 효과
        GeometryReader { geo in
          ZStack {
            Rectangle()
              .fill(Color.black.opacity(0.5))

            // 프레임 영역을 제외
            Rectangle()
              .frame(width: width+1, height: height+1)
              .position(x: x, y: y)
              .blendMode(.destinationOut)
          }
          .compositingGroup()
          .frame(width: geo.size.width, height: geo.size.height)
        }
        // 3x3 그리드
        let minX = rect.minX * containerSize.width
        let minY = rect.minY * containerSize.height
        let gridWidth = width
        let gridHeight = height

        let vertical1 = minX + gridWidth / 3
        let vertical2 = minX + gridWidth * 2 / 3
        let horizontal1 = minY + gridHeight / 3
        let horizontal2 = minY + gridHeight * 2 / 3

        Path { path in
          path.move(to: CGPoint(x: vertical1, y: minY))
          path.addLine(to: CGPoint(x: vertical1, y: minY + gridHeight))
          path.move(to: CGPoint(x: vertical2, y: minY))
          path.addLine(to: CGPoint(x: vertical2, y: minY + gridHeight))
          path.move(to: CGPoint(x: minX, y: horizontal1))
          path.addLine(to: CGPoint(x: minX + gridWidth, y: horizontal1))
          path.move(to: CGPoint(x: minX, y: horizontal2))
          path.addLine(to: CGPoint(x: minX + gridWidth, y: horizontal2))
        }
        .stroke(frameColor, style: StrokeStyle(lineWidth: 1))
        // Corner 핸들 표시
        let cornerList: [Corner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        ForEach(cornerList, id: \.self) { corner in
          Rectangle()
            .fill(frameColor)
            .frame(width: 11, height: 11)
            .position(cornerPosition(for: corner))
            .gesture(
              // 현재 상대방이 수정 중 아님
              canInteract
                ? DragGesture(minimumDistance: 0)
                  .onChanged { value in
                    if cornerScale == nil { cornerScale = frame.rect }
                    if didAcquireInteraction == false {
                      acquireInteraction()
                    }
                    guard let start = cornerScale else { return }
                    frameViewModel.resizeCorner(
                      id: frame.id,
                      corner: corner,
                      start: start,
                      translation: value.translation,
                      container: containerSize
                    )
                  }
                  .onEnded { _ in
                    cornerScale = nil
                    if didAcquireInteraction {
                      releaseInteraction()
                    }
                  }
                : nil
            )
        }
      }
    }
  }

  /// 모서리 핸들의 위치에 대한 함수
  private func cornerPosition(for corner: Corner) -> CGPoint {
    let rect = frame.rect
    switch corner {
    case .topLeft:
      return CGPoint(x: rect.minX * containerSize.width, y: rect.minY * containerSize.height)
    case .topRight:
      return CGPoint(x: rect.maxX * containerSize.width, y: rect.minY * containerSize.height)
    case .bottomLeft:
      return CGPoint(x: rect.minX * containerSize.width, y: rect.maxY * containerSize.height)
    case .bottomRight:
      return CGPoint(x: rect.maxX * containerSize.width, y: rect.maxY * containerSize.height)
    }
  }

  /// 제스쳐 소유권 획득
  private func acquireInteraction() {
    didAcquireInteraction = true
    frameViewModel.isInteracting = true
    frameViewModel.interactingRole = frameViewModel.currentRole ?? .photographer
    frameViewModel.sendFrameInteracting(true)
  }
  /// 제스쳐 소유권 해제
  private func releaseInteraction() {
    didAcquireInteraction = false
    frameViewModel.isInteracting = false
    frameViewModel.interactingRole = nil
    frameViewModel.sendFrameInteracting(false)
  }
}
