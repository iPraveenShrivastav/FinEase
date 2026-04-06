import SwiftUI
import SwiftData
import Charts

struct SpendingHeatmapView: View {
    let transactions: [TransactionRecord]
    
    // Matrix of Weeks. Each week has 7 days.
    private var heatmapData: [[Date?]] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        let startOf90Days = calendar.date(byAdding: .day, value: -90, to: today)!
        let firstDay = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOf90Days)) ?? startOf90Days
        
        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []
        var current = firstDay
        
        while current <= today {
            if current < startOf90Days {
                currentWeek.append(nil) // Empty cell outside 90 day window
            } else {
                currentWeek.append(current)
            }
            
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }
        
        return weeks
    }

    private func spending(for date: Date?) -> Double {
        guard let date = date else { return 0 }
        return transactions.filter {
            $0.type == .expense && Calendar.current.isDate($0.date, inSameDayAs: date)
        }.reduce(0) { $0 + $1.amount }
    }

    private var maxSpending: Double {
        let calendar = Calendar.current
        let today = Date().startOfDay
        guard let start = calendar.date(byAdding: .day, value: -90, to: today) else { return 100 }
        
        let groups = Dictionary(grouping: transactions.filter { $0.type == .expense && $0.date >= start }) { $0.date.startOfDay }
        let maxDay = groups.values.map { dayTxs in dayTxs.reduce(0) { $0 + $1.amount } }.max() ?? 100
        return maxDay == 0 ? 1 : maxDay
    }

    private func color(for amount: Double) -> Color {
        if amount <= 0 { return Color(.systemGray6) }
        let ratio = amount / maxSpending
        
        if ratio <= 0.25 { return FinanceTheme.accent.opacity(0.3) }
        if ratio <= 0.5 { return FinanceTheme.accent.opacity(0.6) }
        if ratio <= 0.75 { return FinanceTheme.accent.opacity(0.8) }
        return FinanceTheme.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<heatmapData.count, id: \.self) { weekIndex in
                        let week = heatmapData[weekIndex]
                        VStack(spacing: 4) {
                            ForEach(0..<week.count, id: \.self) { dayIndex in
                                let date = week[dayIndex]
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(date == nil ? Color.clear : color(for: spending(for: date)))
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Legend
            HStack(spacing: 6) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray6)).frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 3).fill(FinanceTheme.accent.opacity(0.3)).frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 3).fill(FinanceTheme.accent.opacity(0.6)).frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 3).fill(FinanceTheme.accent.opacity(0.8)).frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 3).fill(FinanceTheme.accent).frame(width: 12, height: 12)
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct InsightsView: View {
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]
    @State private var isLoading = true

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
        ZStack {
            FinanceScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if transactions.isEmpty {
                        EmptyStateView(
                            title: "No insight data yet",
                            message: "Add transactions to unlock spending trends and category insights.",
                            symbol: "chart.xyaxis.line"
                        )
                    } else {
                        SurfaceCard(title: "Insight Pulse", subtitle: "This month at a glance") {
                            VStack(spacing: 12) {
                                if let highestSpendingCategory {
                                    HStack {
                                        Label(highestSpendingCategory.category.rawValue, systemImage: highestSpendingCategory.category.icon)
                                            .font(.headline)
                                            .foregroundStyle(highestSpendingCategory.category.tint)
                                        Spacer()
                                        Text(highestSpendingCategory.amount.asCurrency())
                                            .font(.headline)
                                    }
                                }

                                if let frequentTransactionType {
                                    HStack {
                                        Label("Frequent Type", systemImage: frequentTransactionType.icon)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(frequentTransactionType.rawValue)
                                            .font(.caption.weight(.bold))
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(frequentTransactionType.tint.opacity(0.15), in: Capsule())
                                    }
                                }
                            }
                        }

                        SurfaceCard(title: "Week-over-Week", subtitle: "Expense comparison") {
                            HStack(spacing: 12) {
                                MetricCard(
                                    title: "This Week",
                                    value: thisWeekExpense.asCurrency(),
                                    subtitle: "Expenses",
                                    icon: "calendar",
                                    tint: FinanceTheme.expense
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
                                .foregroundStyle(weekOverWeekChange >= 0 ? FinanceTheme.expense : FinanceTheme.income)
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
                                .foregroundStyle(FinanceTheme.accent.opacity(0.18))

                                LineMark(
                                    x: .value("Month", point.month, unit: .month),
                                    y: .value("Expense", point.expense)
                                )
                                .foregroundStyle(FinanceTheme.accent)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                                PointMark(
                                    x: .value("Month", point.month, unit: .month),
                                    y: .value("Expense", point.expense)
                                )
                                .foregroundStyle(FinanceTheme.accent)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .month)) { _ in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                                }
                            }
                            .frame(height: 220)
                            .accessibilityLabel("Monthly expense trend chart")
                            .accessibilityHint("Shows six months of expense totals")
                        }

                        SurfaceCard(title: "Activity Heatmap", subtitle: "Daily spending intensity (Last 90 days)") {
                            if transactions.isEmpty {
                                EmptyStateView(
                                    title: "No data available",
                                    message: "Keep recording transactions to see your spending map.",
                                    symbol: "square.fill.on.square"
                                )
                            } else {
                                SpendingHeatmapView(transactions: transactions)
                                    .accessibilityLabel("Spending heat map")
                                    .accessibilityHint("Shows spending intensity over the last 90 days")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .disabled(isLoading)

            if isLoading {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()

                LoadingStateView(message: "Loading insights...")
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard isLoading else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            isLoading = false
        }
    }
}
