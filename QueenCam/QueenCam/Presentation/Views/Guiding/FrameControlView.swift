//
//  FrameControlView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

struct FrameControlView: View {
    @StateObject private var vm = FrameViewModel()

    var body: some View {
      ZStack{
        // MARK: - 프레임 생성 및 이동
        GeometryReader { geo in
            ZStack {
                ForEach(vm.allFrames()) { frame in
                    FrameLayerView(frame: frame,
                               containerSize: geo.size) { start, translation in
                        vm.moveFrame(id: frame.id,
                                     start: start,
                                     translation: translation,
                                     container: geo.size)
                    }
                }
            }
            .contentShape(Rectangle())
        }.background(.clear)
        VStack {
            Spacer()
            
                Button {
                    vm.addFrame(at: CGPoint(x: 0.3, y: 0.4))
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.allFrames().count >= vm.maxFrames)
               
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .padding(.bottom, 24)
        }
      }
    }
}

#Preview {
    FrameControlView()
}
