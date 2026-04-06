import SwiftUI

struct CashFlowSummaryCard: View {
    let income: Double
    let expense: Double

    private var net: Double {
        income - expense
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("Net Flow")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(net.asCurrency())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(net >= 0 ? FinanceTheme.income : FinanceTheme.expense)
            }
            
            HStack(spacing: 24) {
                CashFlowMetric(title: "Income", value: income.asCurrency(), icon: "arrow.down", tint: FinanceTheme.income)
                
                Divider()
                    .frame(height: 24)
                
                CashFlowMetric(title: "Expense", value: expense.asCurrency(), icon: "arrow.up", tint: FinanceTheme.expense)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Monthly cash flow")
        .accessibilityValue("Income \(income.asCurrency()), Expense \(expense.asCurrency()), Net \(net.asCurrency())")
        .accessibilityHint("Summary for current month")
    }
}

private struct CashFlowMetric: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .padding(4)
                .background(tint.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
        }
    }
}
