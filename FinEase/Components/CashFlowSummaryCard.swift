import SwiftUI

struct CashFlowSummaryCard: View {
    let income: Double
    let expense: Double

    private var net: Double {
        income - expense
    }

    var body: some View {
        HStack(spacing: 10) {
            CashFlowMetric(title: "Income", value: income.asCurrency(), icon: "arrow.down.circle.fill", tint: FinanceTheme.income)
            CashFlowMetric(title: "Expense", value: expense.asCurrency(), icon: "arrow.up.circle.fill", tint: FinanceTheme.expense)
            CashFlowMetric(title: "Net", value: net.asCurrency(), icon: "equal.circle.fill", tint: net >= 0 ? FinanceTheme.accent : FinanceTheme.expense)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FinanceTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FinanceTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: FinanceTheme.cardShadow, radius: 10, y: 6)
    }
}

private struct CashFlowMetric: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
