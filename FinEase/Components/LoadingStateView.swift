import SwiftUI

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FinanceTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FinanceTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: FinanceTheme.cardShadow, radius: 10, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading")
        .accessibilityValue(message)
    }
}
