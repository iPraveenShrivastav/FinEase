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

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<18:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    var body: some View {
        ZStack {
            FinanceScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                        Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    BalanceHeroCard(
                        balance: balance,
                        income: totalIncome,
                        expense: totalExpense,
                        monthlySaved: monthlySaved,
                        savingsProgress: savingsProgress,
                        hasGoal: activeGoal != nil
                    )

                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        MetricCard(
                            title: "Total Income",
                            value: totalIncome.asCurrency(),
                            subtitle: "All transactions",
                            icon: "arrow.down.circle.fill",
                            tint: FinanceTheme.income
                        )

                        MetricCard(
                            title: "Total Expenses",
                            value: totalExpense.asCurrency(),
                            subtitle: "All transactions",
                            icon: "arrow.up.circle.fill",
                            tint: FinanceTheme.expense
                        )

                        MetricCard(
                            title: "Savings Progress",
                            value: activeGoal == nil ? "No Goal" : savingsProgress.asPercent(),
                            subtitle: activeGoal == nil ? "Set monthly target" : "\(monthlySaved.asCurrency()) this month",
                            icon: "target",
                            tint: FinanceTheme.accent
                        )
                    }

                    SurfaceCard(title: "Weekly Expense Trend", subtitle: "Last 7 days") {
                        if weeklyExpensePoints.allSatisfy({ $0.amount == 0 }) {
                            EmptyStateView(
                                title: "No expenses this week",
                                message: "Add an expense transaction to reveal your daily spend trend.",
                                symbol: "chart.bar"
                            )
                        } else {
                            Chart(weeklyExpensePoints) { point in
                                BarMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value("Expense", point.amount)
                                )
                                .foregroundStyle(FinanceTheme.expense.gradient)
                                .cornerRadius(7)
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
                            .frame(height: 190)
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
                            VStack(spacing: 4) {
                                ForEach(recentTransactions) { transaction in
                                    TransactionRowView(transaction: transaction, showChevron: false)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}
