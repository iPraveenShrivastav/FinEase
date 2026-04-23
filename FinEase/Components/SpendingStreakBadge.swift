import SwiftUI

struct SpendingStreakBadge: View {
    let streakDays: Int
    @State private var pulse = false

    var body: some View {
        if streakDays > 0 {
            HStack(spacing: 5) {
                Text("🔥")
                    .font(.system(size: 14))
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                Text("\(streakDays) day\(streakDays == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
            )
            .onAppear { pulse = true }
            .accessibilityLabel("Tracking streak: \(streakDays) day\(streakDays == 1 ? "" : "s")")
        }
    }
}
