import SwiftUI

struct PairingGuideV2View: View {
  @Environment(\.dismiss) private var dismiss

  let role: Role

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ConnectionV2RoleBadge(role: role)

          Text("페어링을 시작할게요")
            .typo(.b22)
            .foregroundStyle(.contentPrimary)
            .padding(.top, 12)

          Text("기기 간 연결을 위해, 먼저 페어링을 통해\n기기를 등록하는 과정이 필요해요.")
            .typo(.m14Line22)
            .foregroundStyle(.gray400)
            .padding(.top, 4)

          ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            PairingGuideStepView(number: index + 1, step: step, role: role)
              .padding(.top, 24)
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
      }
      .scrollIndicators(.hidden)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        ConnectionV2PrimaryButton(title: "이해했어요", role: role, isEnabled: true) {
          dismiss()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("닫기", systemImage: "xmark") {
            dismiss()
          }
          .labelStyle(.iconOnly)
          .foregroundStyle(.contentPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
      .background(.connectionBackground)
    }
    .preferredColorScheme(.dark)
  }

  private var steps: [PairingGuideStep] {
    [
      PairingGuideStep(
        title: "양쪽에서 동시에 시도해주세요.",
        description: "모델과 촬영, 양 방향에서 동시에 페어링을 시도해주세요."
      ),
      PairingGuideStep(
        title: role == .model ? "코드 번호를 입력해주세요." : "코드 번호를 알려주세요.",
        description: role == .model
          ? "촬영자 기기에 나오는 코드를 모델 기기에 입력해주세요."
          : "촬영자 기기에 나오는 코드를 모델에게 알려주세요."
      ),
      PairingGuideStep(
        title: "페어링이 끝나면 직접 창을 닫아주세요.",
        description: "창이 자동으로 닫히지 않아요. 페어링이 완료되었다면, 직접 창을 닫아주세요."
      )
    ]
  }
}

private struct PairingGuideStep {
  let title: LocalizedStringKey
  let description: LocalizedStringKey
}

private struct PairingGuideStepView: View {
  let number: Int
  let step: PairingGuideStep
  let role: Role

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top, spacing: 12) {
        Text("\(number)")
          .typo(.sb12)
          .foregroundStyle(.gray950)
          .frame(width: 23, height: 23)
          .background(role.connectionV2PrimaryColor, in: .rect(cornerRadius: 5))

        VStack(alignment: .leading, spacing: 4) {
          Text(step.title)
            .typo(.sb16)
            .foregroundStyle(.contentPrimary)
          Text(step.description)
            .typo(.m14Line22)
            .foregroundStyle(.gray400)
        }
      }

      RoundedRectangle(cornerRadius: 14)
        .fill(.gray900)
        .frame(maxWidth: .infinity)
        .aspectRatio(353 / 213, contentMode: .fit)
    }
  }
}

#Preview("모델 페어링 가이드") {
  PairingGuideV2View(role: .model)
}

#Preview("촬영 페어링 가이드") {
  PairingGuideV2View(role: .photographer)
}
