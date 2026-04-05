import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]
    @Query(sort: \SavingsGoalRecord.createdAt, order: .reverse) private var goals: [SavingsGoalRecord]

    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]

    private var totalIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var balance: Double {
        totalIncome - totalExpense
    }

    private var activeGoal: SavingsGoalRecord? {
        let monthStart = Date().startOfMonth
        return goals.first {
            Calendar.current.isDate($0.monthAnchor, equalTo: monthStart, toGranularity: .month) &&
            Calendar.current.isDate($0.monthAnchor, equalTo: monthStart, toGranularity: .year)
        }
    }

    private var monthlySaved: Double {
        let monthStart = Date().startOfMonth
        let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date()
        let monthIncome = transactions
            .filter { $0.type == .income && $0.date >= monthStart && $0.date < monthEnd }
            .reduce(0) { $0 + $1.amount }
        let monthExpense = transactions
            .filter { $0.type == .expense && $0.date >= monthStart && $0.date < monthEnd }
            .reduce(0) { $0 + $1.amount }
        return max(0, monthIncome - monthExpense)
    }

    private var savingsProgress: Double {
        guard let activeGoal, activeGoal.targetAmount > 0 else { return 0 }
        return min(monthlySaved / activeGoal.targetAmount, 1)
    }

    private var weeklyExpensePoints: [DailyExpensePoint] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dailyTotal = transactions
                .filter { $0.type == .expense && calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }
            return DailyExpensePoint(date: day, amount: dailyTotal)
        }
    }

    private var recentTransactions: [TransactionRecord] {
        Array(transactions.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    MetricCard(
                        title: "Current Balance",
                        value: balance.asCurrency(),
                        subtitle: "Income - Expenses",
                        icon: "wallet.bifold.fill",
                        tint: balance >= 0 ? .teal : .orange
                    )

                    MetricCard(
                        title: "Total Income",
                        value: totalIncome.asCurrency(),
                        subtitle: "All time",
                        icon: "arrow.down.circle.fill",
                        tint: .green
                    )

                    MetricCard(
                        title: "Total Expenses",
                        value: totalExpense.asCurrency(),
                        subtitle: "All time",
                        icon: "arrow.up.circle.fill",
                        tint: .red
                    )

                    MetricCard(
                        title: "Savings Progress",
                        value: activeGoal == nil ? "No Goal" : savingsProgress.asPercent(),
                        subtitle: activeGoal == nil ? "Set a monthly target" : "\(monthlySaved.asCurrency()) saved",
                        icon: "target",
                        tint: .blue
                    )
                }

                SurfaceCard(title: "Weekly Expense Trend", subtitle: "Last 7 days") {
                    if weeklyExpensePoints.allSatisfy({ $0.amount == 0 }) {
                        EmptyStateView(
                            title: "No expenses this week",
                            message: "Add an expense transaction to see your weekly trend.",
                            symbol: "chart.bar"
                        )
                    } else {
                        Chart(weeklyExpensePoints) { point in
                            BarMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Expense", point.amount)
                            )
                            .foregroundStyle(.orange.gradient)
                            .cornerRadius(6)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                            }
                        }
                        .frame(height: 180)
                    }
                }

                SurfaceCard(title: "Recent Transactions", subtitle: "Latest activity") {
                    if recentTransactions.isEmpty {
                        EmptyStateView(
                            title: "No transactions yet",
                            message: "Start by adding your first income or expense.",
                            symbol: "list.bullet.rectangle"
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentTransactions) { transaction in
                                TransactionRowView(transaction: transaction, showChevron: false)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}
