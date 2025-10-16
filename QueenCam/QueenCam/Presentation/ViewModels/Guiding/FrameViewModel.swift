//
//  FrameViewModel.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//


import Foundation
import SwiftUI
import Combine

final class FrameViewModel: ObservableObject {
    @Published private(set) var frames: [Frame] = []
   
    func allFrames() -> [Frame] { frames }

    //MARK: - 프레임 추가
    let maxFrames = 5 //프레임은 최대 5개까지 혀용
    private let colors: [Color] = [
           .green.opacity(0.5),
           .blue.opacity(0.5),
           .pink.opacity(0.5),
           .orange.opacity(0.5),
           .purple.opacity(0.5)
       ]


    func addFrame(at origin: CGPoint,
                  size: CGSize = .init(width: 0.3, height: 0.4)) { //origin은 사각형의 왼쪽 상당의 CGPoint(상대 위치, 0.5는 정중앙)
        guard frames.count < maxFrames else { return }

        // 화면 밖으로 나가지 않도록 원점 보정(Clamp,클램프)
        let nx = min(max(origin.x, 0), 1 - size.width)
        let ny = min(max(origin.y, 0), 1 - size.height)
        
        let rect = CGRect(origin: .init(x: nx, y: ny), size: size)
        let color = colors[frames.count % colors.count]
        frames.append(Frame(rect: rect, color: color))
    }

    //MARK: - 프레임 이동
    func moveFrame(id: UUID, start: CGRect,
                   translation: CGSize, container: CGSize) {
    
        guard let idx = frames.firstIndex(where: { $0.id == id }) else { return }

        // 상대 단위로 변환
        let dx = container.width  > 0 ? translation.width  / container.width  : 0
        let dy = container.height > 0 ? translation.height / container.height : 0

        var new = start
        new.origin.x += dx
        new.origin.y += dy

        // 경계 안으로 보정
        new.origin.x = min(max(new.origin.x, 0), 1 - new.size.width)
        new.origin.y = min(max(new.origin.y, 0), 1 - new.size.height)

        frames[idx].rect = new
    }
    
    //MARK: - 프레임의 삭제 및 복구
    func remove(_ id: UUID) {
        frames.removeAll { $0.id == id }
    }
}

