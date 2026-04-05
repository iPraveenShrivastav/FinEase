import SwiftUI

struct BalanceHeroCard: View {
    let balance: Double
    let income: Double
    let expense: Double
    let monthlySaved: Double
    let savingsProgress: Double
    let hasGoal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    .padding(10)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Monthly Savings Goal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                        Spacer()
                        Text("\(monthlySaved.asCurrency()) saved")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    ProgressView(value: savingsProgress)
                        .tint(.white)
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)

                    Text(savingsProgress.asPercent())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(FinanceTheme.heroGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 16, y: 10)
    }
}

private struct HeroValuePill: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
