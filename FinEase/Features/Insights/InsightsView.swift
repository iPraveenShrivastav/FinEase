import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]

    private var monthStart: Date {
        Date().startOfMonth
    }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date()
    }

    private var currentMonthExpenseByCategory: [CategorySpendPoint] {
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense && $0.date >= monthStart && $0.date < monthEnd }) { $0.category }
        return grouped
            .map { category, items in
                CategorySpendPoint(category: category, amount: items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.amount > $1.amount }
    }

    private var highestSpendingCategory: CategorySpendPoint? {
        currentMonthExpenseByCategory.first
    }

    private var thisWeekExpense: Double {
        let start = Date().startOfWeek
        return transactions
            .filter { $0.type == .expense && $0.date >= start }
            .reduce(0) { $0 + $1.amount }
    }

    private var lastWeekExpense: Double {
        let thisWeekStart = Date().startOfWeek
        guard let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else {
            return 0
        }

        return transactions
            .filter { $0.type == .expense && $0.date >= lastWeekStart && $0.date < thisWeekStart }
            .reduce(0) { $0 + $1.amount }
    }

    private var weekOverWeekChange: Double {
        if lastWeekExpense == 0 {
            return thisWeekExpense == 0 ? 0 : 100
        }
        return ((thisWeekExpense - lastWeekExpense) / lastWeekExpense) * 100
    }

    private var monthlyExpenseTrend: [MonthlyTrendPoint] {
        let calendar = Calendar.current
        let currentStart = Date().startOfMonth

        return (0..<6).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: currentStart),
                  let end = calendar.date(byAdding: .month, value: 1, to: month)
            else {
                return nil
            }

            let expense = transactions
                .filter { $0.type == .expense && $0.date >= month && $0.date < end }
                .reduce(0) { $0 + $1.amount }

            return MonthlyTrendPoint(month: month, expense: expense)
        }
    }

    private var frequentTransactionType: TransactionType? {
        guard !transactions.isEmpty else { return nil }
        let incomeCount = transactions.filter { $0.type == .income }.count
        let expenseCount = transactions.count - incomeCount
        return incomeCount >= expenseCount ? .income : .expense
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if transactions.isEmpty {
                    EmptyStateView(
                        title: "No insight data yet",
                        message: "Add transactions to unlock spending trends and category insights.",
                        symbol: "chart.xyaxis.line"
                    )
                } else {
                    SurfaceCard(title: "Top Spending Category", subtitle: "This month") {
                        if let highestSpendingCategory {
                            HStack {
                                Label(highestSpendingCategory.category.rawValue, systemImage: highestSpendingCategory.category.icon)
                                    .font(.headline)
                                    .foregroundStyle(highestSpendingCategory.category.tint)
                                Spacer()
                                Text(highestSpendingCategory.amount.asCurrency())
                                    .font(.headline)
                            }
                        } else {
                            EmptyStateView(
                                title: "No expenses this month",
                                message: "Log an expense to see category insights.",
                                symbol: "tray"
                            )
                        }
                    }

                    SurfaceCard(title: "Week-over-Week", subtitle: "Expense comparison") {
                        HStack(spacing: 12) {
                            MetricCard(
                                title: "This Week",
                                value: thisWeekExpense.asCurrency(),
                                subtitle: "Expenses",
                                icon: "calendar",
                                tint: .orange
                            )

                            MetricCard(
                                title: "Last Week",
                                value: lastWeekExpense.asCurrency(),
                                subtitle: "Expenses",
                                icon: "calendar.badge.minus",
                                tint: .blue
                            )
                        }

                        HStack {
                            Label(
                                weekOverWeekChange >= 0 ? "Up by \(abs(weekOverWeekChange).asPercentValue())" : "Down by \(abs(weekOverWeekChange).asPercentValue())",
                                systemImage: weekOverWeekChange >= 0 ? "arrow.up.right" : "arrow.down.right"
                            )
                            .foregroundStyle(weekOverWeekChange >= 0 ? .red : .green)
                            .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }

                    SurfaceCard(title: "Monthly Expense Trend", subtitle: "Last 6 months") {
                        Chart(monthlyExpenseTrend) { point in
                            AreaMark(
                                x: .value("Month", point.month, unit: .month),
                                y: .value("Expense", point.expense)
                            )
                            .foregroundStyle(.blue.opacity(0.15))

                            LineMark(
                                x: .value("Month", point.month, unit: .month),
                                y: .value("Expense", point.expense)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                            PointMark(
                                x: .value("Month", point.month, unit: .month),
                                y: .value("Expense", point.expense)
                            )
                            .foregroundStyle(.blue)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                        .frame(height: 220)
                    }

                    SurfaceCard(title: "Category Breakdown", subtitle: "This month") {
                        if currentMonthExpenseByCategory.isEmpty {
                            EmptyStateView(
                                title: "No expense categories yet",
                                message: "Record an expense to view your category distribution.",
                                symbol: "chart.bar.xaxis"
                            )
                        } else {
                            Chart(currentMonthExpenseByCategory) { point in
                                BarMark(
                                    x: .value("Category", point.category.rawValue),
                                    y: .value("Amount", point.amount)
                                )
                                .foregroundStyle(point.category.tint.gradient)
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                }
                            }
                            .frame(height: 220)
                        }
                    }

                    SurfaceCard(title: "Frequent Transaction Type") {
                        if let frequentTransactionType {
                            HStack {
                                Label(frequentTransactionType.rawValue, systemImage: frequentTransactionType.icon)
                                    .font(.headline)
                                    .foregroundStyle(frequentTransactionType.tint)
                                Spacer()
                                Text("Based on count")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
    }
}
