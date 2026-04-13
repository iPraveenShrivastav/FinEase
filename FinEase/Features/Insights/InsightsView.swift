import SwiftUI
import SwiftData
import Charts

// MARK: - Haptic Helper
struct HapticManager {
    static let shared = HapticManager()
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Activity Bubble Matrix (New Heatmap)
struct SpendingBubbleMatrixView: View {
    let transactions: [TransactionRecord]
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateDots = false

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private let daysToShow = 35 // 5 weeks
    private let cellSpacing: CGFloat = 12

    private var calendar: Calendar { Calendar.current }

    private var today: Date {
        Date().startOfDay
    }

    private var startDate: Date {
        calendar.date(byAdding: .day, value: -(daysToShow - 1), to: today) ?? today
    }

    private var heatmapData: [[Date?]] {
        let firstDay = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)) ?? startDate

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []
        var current = firstDay

        while current <= today {
            if current < startDate {
                currentWeek.append(nil)
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

    // Dynamic Sizing Map
    private func dotSize(for amount: Double) -> CGFloat {
        guard amount > 0 else { return 6 }
        let ratio = amount / maxSpending
        return 8 + (CGFloat(ratio) * 10) // Size between 8 and 18
    }

    // Color Opacity Map
    private func dotColor(for amount: Double) -> Color {
        guard amount > 0 else {
            return colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
        }
        let ratio = amount / maxSpending
        let baseOpacity = colorScheme == .dark ? 0.4 : 0.3
        return FinanceTheme.accent.opacity(baseOpacity + (1.0 - baseOpacity) * ratio)
    }

    private func dotGlowRadius(for amount: Double) -> CGFloat {
        let ratio = amount / maxSpending
        return ratio > 0.7 ? 6 : 0
    }

    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return calendar.isDateInToday(date)
    }

    private var activeDayCount: Int { dailySpending.count }
    private var averageDailySpend: Double {
        guard activeDayCount > 0 else { return 0 }
        return dailySpending.values.reduce(0, +) / Double(activeDayCount)
    }

    private var peakDayLabel: String {
        guard let peak = dailySpending.max(by: { $0.value < $1.value }) else { return "None" }
        return Self.dayFormatter.string(from: peak.key)
    }

    var body: some View {
        VStack(spacing: 24) {
            // The Bubble Matrix Engine
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: cellSpacing) {
                    ForEach(0..<heatmapData.count, id: \.self) { weekIndex in
                        let week = heatmapData[weekIndex]
                        VStack(alignment: .center, spacing: cellSpacing) {
                            ForEach(0..<week.count, id: \.self) { dayIndex in
                                let date = week[dayIndex]
                                let amount = spending(for: date)
                                let isPlaceholder = date == nil
                                
                                ZStack {
                                    if isPlaceholder {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 18, height: 18)
                                    } else {
                                        let size = dotSize(for: amount)
                                        Circle()
                                            .fill(dotColor(for: amount))
                                            .frame(width: animateDots ? size : 0, height: animateDots ? size : 0)
                                            .shadow(color: dotColor(for: amount).opacity(0.8), radius: dotGlowRadius(for: amount))
                                            .overlay(
                                                Circle()
                                                    .stroke(FinanceTheme.accent, lineWidth: isToday(date) ? 1.5 : 0)
                                                    .padding(-4)
                                                    .opacity(isToday(date) ? 0.8 : 0)
                                            )
                                    }
                                }
                                .frame(width: 18, height: 18) // Container remains static for alignment
                            }
                        }
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(weekIndex) * 0.05)) {
                                animateDots = true
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .accessibilityLabel("Activity Bubble Matrix")
            
            Divider().opacity(0.5)

            // Matrix Stats
            HStack(spacing: 20) {
                BubbleMatrixStatView(title: "Active Days", value: "\(activeDayCount)", icon: "flame.fill", tint: .orange)
                BubbleMatrixStatView(title: "Avg Spend", value: averageDailySpend.asCurrency(), icon: "chart.bar.fill", tint: FinanceTheme.accent)
                BubbleMatrixStatView(title: "Peak Day", value: peakDayLabel, icon: "star.fill", tint: .yellow)
            }
        }
    }
}

private struct BubbleMatrixStatView: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Time of Day Card View
struct SpendingTimeCardView: View {
    let transactions: [TransactionRecord]
    @State private var animateRing = false

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "h a"
        return formatter
    }()

    private let ringWidth: CGFloat = 16
    private let segmentInset: Double = 0.008
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

    private var maxTotal: Double { max(hourlyTotals.max() ?? 0, 1) }
    
    private var peakHour: Int? {
        guard let maxValue = hourlyTotals.max(), maxValue > 0 else { return nil }
        return hourlyTotals.firstIndex(of: maxValue)
    }

    private var peakLabel: String {
        guard let hour = peakHour,
              let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())
        else { return "No Activity" }
        return Self.hourFormatter.string(from: date)
    }

    private func color(for hour: Int) -> Color {
        let value = hourlyTotals[hour]
        guard value > 0 else { return Color(.systemGray5).opacity(0.3) }
        let ratio = value / maxTotal
        return FinanceTheme.accent.opacity(0.3 + 0.7 * ratio)
    }

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray6).opacity(0.5), lineWidth: ringWidth)
                
                ForEach(0..<24, id: \.self) { hour in
                    let start = (Double(hour) / 24.0) + segmentInset
                    let end = (Double(hour + 1) / 24.0) - segmentInset
                    let value = hourlyTotals[hour]
                    let isPeak = hour == peakHour
                    
                    Circle()
                        .trim(from: animateRing ? start : start, to: animateRing ? end : start)
                        .stroke(color(for: hour), style: StrokeStyle(lineWidth: isPeak ? ringWidth + 4 : ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: color(for: hour).opacity(isPeak ? 0.6 : 0), radius: isPeak ? 8 : 0)
                }
            }
            .frame(width: 130, height: 130)
            .padding(.vertical, 10)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                    animateRing = true
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peak Hour")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(peakLabel)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .monospacedDigit()
                }
                
                Text("Most of your spending happens around this time over the last 30 days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Peak spending hour is \(peakLabel)")
    }
}

// MARK: - Main Insights View
struct InsightsView: View {
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]
    @State private var isLoading = true
    
    // Staggered Animation States
    @State private var showHeader = false
    @State private var showCards = [Bool](repeating: false, count: 5)

    private var monthStart: Date { Date().startOfMonth }
    private var monthEnd: Date { Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date() }

    private var currentMonthExpenseByCategory: [CategorySpendPoint] {
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense && $0.date >= monthStart && $0.date < monthEnd }) { $0.category }
        return grouped
            .map { category, items in
                CategorySpendPoint(category: category, amount: items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.amount > $1.amount }
    }

    private var highestSpendingCategory: CategorySpendPoint? { currentMonthExpenseByCategory.first }
    private var thisWeekExpense: Double {
        let start = Date().startOfWeek
        return transactions.filter { $0.type == .expense && $0.date >= start }.reduce(0) { $0 + $1.amount }
    }

    private var lastWeekExpense: Double {
        let thisWeekStart = Date().startOfWeek
        guard let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) else { return 0 }
        return transactions.filter { $0.type == .expense && $0.date >= lastWeekStart && $0.date < thisWeekStart }.reduce(0) { $0 + $1.amount }
    }

    private var weekOverWeekChange: Double {
        if lastWeekExpense == 0 { return thisWeekExpense == 0 ? 0 : 100 }
        return ((thisWeekExpense - lastWeekExpense) / lastWeekExpense) * 100
    }

    private var monthlyExpenseTrend: [MonthlyTrendPoint] {
        let calendar = Calendar.current
        let currentStart = Date().startOfMonth
        return (0..<6).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: currentStart),
                  let end = calendar.date(byAdding: .month, value: 1, to: month) else { return nil }
            let expense = transactions.filter { $0.type == .expense && $0.date >= month && $0.date < end }.reduce(0) { $0 + $1.amount }
            return MonthlyTrendPoint(month: month, expense: expense)
        }
    }

    private func triggerEntranceAnimations() {
        HapticManager.shared.impact(style: .rigid)
        withAnimation(.easeOut(duration: 0.6)) { showHeader = true }
        for i in 0..<showCards.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(i) * 0.1 + 0.1)) {
                showCards[i] = true
            }
        }
    }

    var body: some View {
        ZStack {
            FinanceScreenBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if transactions.isEmpty {
                        EmptyStateView(
                            title: "No insight data yet",
                            message: "Add transactions to unlock spending trends and category insights.",
                            symbol: "chart.xyaxis.line.magnifyingglass"
                        )
                        .padding(.top, 40)
                    } else {
                        // Header Statement
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Pulse")
                                .font(.system(.title, design: .rounded).weight(.heavy))
                            Text("Understand your spending rhythm.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .opacity(showHeader ? 1 : 0)
                        .offset(y: showHeader ? 0 : 10)
                        
                        // Card 1: Pulse Highlights
                        if showCards[0] {
                            SurfaceCard(title: "This Month", subtitle: "Top spending drivers") {
                                VStack(spacing: 16) {
                                    if let highest = highestSpendingCategory {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(highest.category.tint.opacity(0.15))
                                                    .frame(width: 48, height: 48)
                                                Image(systemName: highest.category.icon)
                                                    .font(.title3)
                                                    .foregroundStyle(highest.category.tint)
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(highest.category.rawValue)
                                                    .font(.headline)
                                                Text("Top Category")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(highest.amount.asCurrency())
                                                .font(.system(.headline, design: .rounded).weight(.bold))
                                                .monospacedDigit()
                                        }
                                    }
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Card 2: Week-over-Week
                        if showCards[1] {
                            SurfaceCard(title: "Velocity", subtitle: "Week-over-week comparison") {
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

                                HStack(spacing: 8) {
                                    Image(systemName: weekOverWeekChange >= 0 ? "trendup" : "trenddown")
                                        .foregroundStyle(weekOverWeekChange >= 0 ? FinanceTheme.expense : FinanceTheme.income)
                                    Text("\(abs(weekOverWeekChange).asPercentValue()) \(weekOverWeekChange >= 0 ? "increase" : "decrease")")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(weekOverWeekChange >= 0 ? FinanceTheme.expense : FinanceTheme.income)
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Card 3: Monthly Curve
                        if showCards[2] {
                            SurfaceCard(title: "6-Month Trajectory", subtitle: "Tracking overall flow") {
                                Chart(monthlyExpenseTrend) { point in
                                    AreaMark(
                                        x: .value("Month", point.month, unit: .month),
                                        y: .value("Expense", point.expense)
                                    )
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [FinanceTheme.accent.opacity(0.3), FinanceTheme.accent.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                    LineMark(
                                        x: .value("Month", point.month, unit: .month),
                                        y: .value("Expense", point.expense)
                                    )
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(FinanceTheme.accent)
                                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    // Add glow shadow
                                    .shadow(color: FinanceTheme.accent.opacity(0.4), radius: 6, y: 4)

                                    PointMark(
                                        x: .value("Month", point.month, unit: .month),
                                        y: .value("Expense", point.expense)
                                    )
                                    .foregroundStyle(FinanceTheme.backgroundTop)
                                    .symbolSize(80)

                                    PointMark(
                                        x: .value("Month", point.month, unit: .month),
                                        y: .value("Expense", point.expense)
                                    )
                                    .foregroundStyle(FinanceTheme.accent)
                                    .symbolSize(40)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .month)) { _ in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                                    }
                                }
                                .frame(height: 180)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Card 4: New Heatmap Matrix
                        if showCards[3] {
                            SurfaceCard(title: "Activity Matrix", subtitle: "Daily tracking intensity") {
                                SpendingBubbleMatrixView(transactions: transactions)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Card 5: Extracted Time of Day
                        if showCards[4] {
                            SurfaceCard(title: "Time Context", subtitle: "When you spend") {
                                SpendingTimeCardView(transactions: transactions)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 20) // extra padding at end of scroll
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .disabled(isLoading)

            if isLoading {
                Color.black.opacity(0.05).ignoresSafeArea()
                LoadingStateView(message: "Discovering Trends...")
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !isLoading { triggerEntranceAnimations() }
        }
        .task {
            guard isLoading else { return }
            try? await Task.sleep(nanoseconds: 400_000_000)
            isLoading = false
            triggerEntranceAnimations()
        }
    }
}

