import SwiftUI
import SwiftData
import Charts

struct SpendingHeatmapView: View {
    let transactions: [TransactionRecord]
    @Environment(\.colorScheme) private var colorScheme

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }()

    private let daysToShow = 90
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 4

    private var calendar: Calendar { Calendar.current }

    private var today: Date {
        Date().startOfDay
    }

    private var startDate: Date {
        calendar.date(byAdding: .day, value: -(daysToShow - 1), to: today) ?? today
    }

    // Matrix of Weeks. Each week has 7 days.
    private var heatmapData: [[Date?]] {
        let firstDay = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)) ?? startDate

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []
        var current = firstDay

        while current <= today {
            if current < startDate {
                currentWeek.append(nil) // Empty cell outside window
            } else {
                currentWeek.append(current)
            }

            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }

    private var dailySpending: [Date: Double] {
        var totals: [Date: Double] = [:]
        for transaction in transactions where transaction.type == .expense && transaction.date >= startDate {
            let day = transaction.date.startOfDay
            totals[day, default: 0] += transaction.amount
        }
        return totals
    }

    private func spending(for date: Date?) -> Double {
        guard let date else { return 0 }
        return dailySpending[date.startOfDay] ?? 0
    }

    private var maxSpending: Double {
        max(dailySpending.values.max() ?? 0, 1)
    }

    private func color(for amount: Double) -> Color {
        guard amount > 0 else { return Color(.systemGray6) }
        let ratio = pow(amount / maxSpending, 0.7)
        let baseOpacity = colorScheme == .dark ? 0.28 : 0.22
        let maxOpacity = colorScheme == .dark ? 0.95 : 1.0
        return FinanceTheme.accent.opacity(baseOpacity + (maxOpacity - baseOpacity) * ratio)
    }

    private func isToday(_ date: Date?) -> Bool {
        guard let date else { return false }
        return calendar.isDateInToday(date)
    }

    private var weekdaySymbols: [String] {
        let symbols = Self.weekdayFormatter.shortWeekdaySymbols ?? calendar.shortWeekdaySymbols
        guard !symbols.isEmpty else { return [] }
        let firstIndex = max(0, calendar.firstWeekday - 1)
        let ordered = Array(symbols[firstIndex...] + symbols[..<firstIndex])
        return ordered.map { String($0.prefix(2)) }
    }

    private func dayLabel(for dayIndex: Int) -> String? {
        let visibleRows: Set<Int> = [0, 2, 4, 6]
        guard visibleRows.contains(dayIndex) else { return nil }
        return weekdaySymbols.indices.contains(dayIndex) ? weekdaySymbols[dayIndex] : nil
    }

    private var monthLabels: [Int: String] {
        var labels: [Int: String] = [:]
        for (index, week) in heatmapData.enumerated() {
            guard let date = week.compactMap({ $0 }).first else { continue }
            let day = calendar.component(.day, from: date)
            if day <= 7 {
                labels[index] = Self.monthFormatter.string(from: date)
            }
        }
        return labels
    }

    private var activeDayCount: Int {
        dailySpending.count
    }

    private var averageDailySpend: Double {
        guard activeDayCount > 0 else { return 0 }
        let total = dailySpending.values.reduce(0, +)
        return total / Double(activeDayCount)
    }

    private var peakDayLabel: String {
        guard let peak = dailySpending.max(by: { $0.value < $1.value }) else {
            return "No activity"
        }
        return Self.dayFormatter.string(from: peak.key)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                SpendingClockView(transactions: transactions)
                VStack(alignment: .leading, spacing: 10) {
                    HeatmapStatRow(title: "Active days", value: "\(activeDayCount) of \(daysToShow)")
                    HeatmapStatRow(title: "Avg per active day", value: averageDailySpend.asCurrency())
                    HeatmapStatRow(title: "Peak day", value: peakDayLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let label = dayLabel(for: dayIndex)
                        Text(label ?? " ")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(height: cellSize)
                            .opacity(label == nil ? 0 : 1)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: cellSpacing) {
                            ForEach(0..<heatmapData.count, id: \.self) { weekIndex in
                                Text(monthLabels[weekIndex] ?? "")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: cellSize, alignment: .leading)
                            }
                        }

                        HStack(spacing: cellSpacing) {
                            ForEach(0..<heatmapData.count, id: \.self) { weekIndex in
                                let week = heatmapData[weekIndex]
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<week.count, id: \.self) { dayIndex in
                                        let date = week[dayIndex]
                                        let amount = spending(for: date)
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(date == nil ? Color.clear : color(for: amount))
                                            .frame(width: cellSize, height: cellSize)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                    .stroke(
                                                        FinanceTheme.cardStroke.opacity(date == nil ? 0 : 0.55),
                                                        lineWidth: date == nil ? 0 : 0.6
                                                    )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                    .stroke(isToday(date) ? FinanceTheme.accent.opacity(0.9) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            HStack(spacing: 8) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray6), FinanceTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 120, height: 10)
                    .overlay(
                        Capsule()
                            .stroke(FinanceTheme.cardStroke.opacity(0.6), lineWidth: 0.6)
                    )

                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct HeatmapStatRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .monospacedDigit()
        }
    }
}

private struct SpendingClockView: View {
    let transactions: [TransactionRecord]

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "h a"
        return formatter
    }()

    private let ringWidth: CGFloat = 12
    private let segmentInset: Double = 0.004

    private var calendar: Calendar { Calendar.current }

    private var startDate: Date {
        calendar.date(byAdding: .day, value: -30, to: Date().startOfDay) ?? Date()
    }

    private var hourlyTotals: [Double] {
        var totals = Array(repeating: 0.0, count: 24)
        for transaction in transactions where transaction.type == .expense && transaction.date >= startDate {
            let hour = calendar.component(.hour, from: transaction.date)
            totals[hour] += transaction.amount
        }
        return totals
    }

    private var maxTotal: Double {
        max(hourlyTotals.max() ?? 0, 1)
    }

    private var peakHour: Int? {
        guard let maxValue = hourlyTotals.max(), maxValue > 0 else { return nil }
        return hourlyTotals.firstIndex(of: maxValue)
    }

    private var peakLabel: String {
        guard let hour = peakHour,
              let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())
        else {
            return "No activity"
        }
        return Self.hourFormatter.string(from: date)
    }

    private func color(for hour: Int) -> Color {
        let value = hourlyTotals[hour]
        guard value > 0 else { return Color(.systemGray5) }
        let ratio = pow(value / maxTotal, 0.7)
        return FinanceTheme.accent.opacity(0.25 + 0.75 * ratio)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(FinanceTheme.cardStroke.opacity(0.7), lineWidth: ringWidth)

            ForEach(0..<24, id: \.self) { hour in
                let start = (Double(hour) / 24.0) + segmentInset
                let end = (Double(hour + 1) / 24.0) - segmentInset
                Circle()
                    .trim(from: start, to: end)
                    .stroke(color(for: hour), style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 4) {
                Text("Peak hour")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(peakLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .monospacedDigit()
            }
        }
        .frame(width: 120, height: 120)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spending by hour")
        .accessibilityValue(peakLabel)
        .accessibilityHint("Shows the most active spending hours over the last 30 days")
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
