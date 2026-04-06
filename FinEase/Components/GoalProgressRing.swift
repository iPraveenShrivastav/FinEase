import SwiftUI

struct GoalProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(FinanceTheme.accent.opacity(0.16), lineWidth: 16)

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [FinanceTheme.income, FinanceTheme.accent, .blue],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)

            VStack(spacing: 4) {
                Text(progress.asPercent())
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text("Completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 170, height: 170)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Savings goal progress")
        .accessibilityValue("\(progress.asPercent()) complete")
        .accessibilityHint("Tracks your monthly progress toward the goal")
    }
}
