import SwiftUI

struct AnimatedNumberText: View, Animatable {
    var number: Double

    var animatableData: Double {
        get { number }
        set { number = newValue }
    }

    var body: some View {
        Text("\(Int(number))")
    }
}

struct BudgetHealthRing: View {
    let score: Double // 0 to 100
    let income: Double
    let expense: Double
    @State private var animateRing = false
    @State private var pulseGlow = false

    private var healthColor: Color {
        switch score {
        case 70...100: return Color(red: 0.18, green: 0.80, blue: 0.44)
        case 40..<70: return Color(red: 1.0, green: 0.76, blue: 0.03)
        default: return Color(red: 0.91, green: 0.30, blue: 0.24)
        }
    }

    private var healthEmoji: String {
        switch score {
        case 70...100: return "🟢"
        case 40..<70: return "🟡"
        default: return "🔴"
        }
    }

    private var healthLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Caution"
        default: return "Critical"
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(healthColor.opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: animateRing ? score / 100 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [healthColor.opacity(0.6), healthColor, healthColor.opacity(0.8)],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Glow
                Circle()
                    .fill(healthColor.opacity(pulseGlow ? 0.12 : 0.04))
                    .scaleEffect(pulseGlow ? 1.1 : 0.9)

                VStack(spacing: 2) {
                    AnimatedNumberText(number: animateRing ? score : 0)
                        .font(.system(.title2, design: .rounded).weight(.black))
                        .foregroundStyle(.primary)
                    Text(healthLabel)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90, height: 90)
            .onAppear {
                withAnimation(.spring(response: 1.4, dampingFraction: 0.8).delay(0.2)) {
                    animateRing = true
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }

            // Details
            VStack(alignment: .leading, spacing: 10) {
                Text("Budget Health")
                    .font(.subheadline.weight(.bold))

                VStack(alignment: .leading, spacing: 6) {
                    HealthMetricRow(
                        label: "Earned",
                        value: income.asCurrency(),
                        color: FinanceTheme.income
                    )
                    HealthMetricRow(
                        label: "Spent",
                        value: expense.asCurrency(),
                        color: FinanceTheme.expense
                    )

                    Divider()

                    HealthMetricRow(
                        label: "Remaining",
                        value: max(0, income - expense).asCurrency(),
                        color: healthColor
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Budget health score \(Int(score)) out of 100, \(healthLabel)")
        .accessibilityValue("Income \(income.asCurrency()), Expenses \(expense.asCurrency())")
    }
}

private struct HealthMetricRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }
}
