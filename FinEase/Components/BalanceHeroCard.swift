import SwiftUI

struct BalanceHeroCard: View {
    let balance: Double
    let income: Double
    let expense: Double
    let monthlySaved: Double
    let savingsProgress: Double
    let hasGoal: Bool
    
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Balance")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                    Text(balance.asCurrency())
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: "creditcard.and.123")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 14) {
                HeroValuePill(
                    title: "Income",
                    value: income.asCurrency(),
                    icon: "arrow.down.forward.circle.fill",
                    tint: FinanceTheme.income
                )

                HeroValuePill(
                    title: "Expense",
                    value: expense.asCurrency(),
                    icon: "arrow.up.forward.circle.fill",
                    tint: FinanceTheme.expense
                )
            }

            if hasGoal {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Monthly Savings Goal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                        Spacer()
                        Text("\(monthlySaved.asCurrency()) saved")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.2))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(LinearGradient(colors: [.white.opacity(0.8), .white], startPoint: .leading, endPoint: .trailing))
                                .frame(width: appear ? proxy.size.width * CGFloat(savingsProgress) : 0, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text(savingsProgress.asPercent())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(FinanceTheme.heroGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
                .blendMode(.overlay)
        )
        .shadow(color: FinanceTheme.heroBottom.opacity(0.3), radius: 20, y: 12)
        .opacity(appear ? 1 : 0.8)
        .scaleEffect(appear ? 1 : 0.96)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appear = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Balance summary")
        .accessibilityValue("Available balance \(balance.asCurrency()), income \(income.asCurrency()), expense \(expense.asCurrency())")
        .accessibilityHint(hasGoal ? "Includes monthly savings progress" : "Set a goal to track monthly savings")
    }
}

private struct HeroValuePill: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .environment(\.colorScheme, .dark)
    }
}
