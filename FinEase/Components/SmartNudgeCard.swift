import SwiftUI

struct SmartNudge: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let tint: Color
}

struct SmartNudgeCard: View {
    let nudge: SmartNudge
    @State private var appear = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(nudge.tint.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: nudge.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(nudge.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(nudge.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)

                Text(nudge.message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FinanceTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [nudge.tint.opacity(0.08), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(nudge.tint.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: FinanceTheme.cardShadow, radius: 8, y: 4)
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                appear = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(nudge.title). \(nudge.message)")
    }
}
