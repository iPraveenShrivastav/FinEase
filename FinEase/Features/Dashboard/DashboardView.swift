import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]
    @Query(sort: \SavingsGoalRecord.createdAt, order: .reverse) private var goals: [SavingsGoalRecord]
    @State private var isLoading = true
    @State private var showItems = [false, false, false, false, false]
    @State private var showingAddExpense = false
    @State private var showingAddIncome = false

    // MARK: - Core Computations

    private var monthStart: Date { Date().startOfMonth }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date()
    }

    private var monthTransactions: [TransactionRecord] {
        transactions.filter { $0.date >= monthStart && $0.date < monthEnd }
    }

    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var balance: Double { totalIncome - totalExpense }

    private var monthIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var monthExpense: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var activeGoal: SavingsGoalRecord? {
        goals.first {
            Calendar.current.isDate($0.monthAnchor, equalTo: monthStart, toGranularity: .month) &&
            Calendar.current.isDate($0.monthAnchor, equalTo: monthStart, toGranularity: .year)
        }
    }

    private var monthlySaved: Double {
        max(0, monthIncome - monthExpense)
    }

    private var savingsProgress: Double {
        guard let activeGoal, activeGoal.targetAmount > 0 else { return 0 }
        return min(monthlySaved / activeGoal.targetAmount, 1)
    }

    // MARK: - Spending Streak

    private var spendingStreak: Int {
        guard !transactions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            let hasTransaction = transactions.contains {
                $0.date >= checkDate && $0.date < dayEnd
            }
            if hasTransaction {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Budget Health Score

    private var budgetHealthScore: Double {
        guard monthIncome > 0 else {
            return monthExpense > 0 ? 10 : 50
        }
        let ratio = monthExpense / monthIncome
        switch ratio {
        case 0..<0.4: return 95
        case 0.4..<0.6: return 80
        case 0.6..<0.75: return 65
        case 0.75..<0.85: return 45
        case 0.85..<1.0: return 25
        default: return 10
        }
    }

    // MARK: - Smart Nudges

    private var smartNudge: SmartNudge {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfMonth = calendar.component(.day, from: today)

        // Check if spending is accelerating
        if monthIncome > 0 && monthExpense > monthIncome * 0.85 {
            return SmartNudge(
                icon: "exclamationmark.triangle.fill",
                title: "Spending Alert",
                message: "You've used \(Int((monthExpense / monthIncome) * 100))% of your income this month. Consider slowing down.",
                tint: FinanceTheme.expense
            )
        }

        // Check top category dominance
        if let topCat = categoryBreakdown.first, topCat.percentage > 40 {
            return SmartNudge(
                icon: "chart.bar.fill",
                title: "\(topCat.name) Dominates",
                message: "\(Int(topCat.percentage))% of your spending goes to \(topCat.name). Try diversifying your budget.",
                tint: topCat.tint
            )
        }

        // Savings encouragement
        if monthlySaved > 0 && activeGoal != nil {
            return SmartNudge(
                icon: "star.fill",
                title: "Great Progress!",
                message: "You've saved \(monthlySaved.asCurrency()) this month. Keep it up!",
                tint: FinanceTheme.income
            )
        }

        // Early month tip
        if dayOfMonth <= 7 {
            return SmartNudge(
                icon: "lightbulb.fill",
                title: "Fresh Start",
                message: "New month, new budget! Set a savings goal and track every expense.",
                tint: FinanceTheme.accent
            )
        }

        // Default streak motivation
        if spendingStreak >= 3 {
            return SmartNudge(
                icon: "flame.fill",
                title: "\(spendingStreak)-Day Streak!",
                message: "You've been tracking consistently. Consistency is the key to financial health.",
                tint: .orange
            )
        }

        return SmartNudge(
            icon: "sparkles",
            title: "Track Everything",
            message: "Log every transaction to get accurate insights and smarter recommendations.",
            tint: FinanceTheme.accent
        )
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: [CategoryBreakdownItem] {
        let expenses = monthTransactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return [] }
        let total = expenses.reduce(0) { $0 + $1.amount }
        let grouped = Dictionary(grouping: expenses, by: { $0.displayCategoryName })
        let items = grouped.map { (name, txns) -> CategoryBreakdownItem in
            let amount = txns.reduce(0) { $0 + $1.amount }
            let firstTxn = txns.first
            return CategoryBreakdownItem(
                name: name,
                icon: firstTxn?.displayCategoryIcon ?? "tag.fill",
                tint: firstTxn?.displayTint ?? .gray,
                amount: amount,
                percentage: total > 0 ? (amount / total) * 100 : 0
            )
        }
        return items.sorted { $0.amount > $1.amount }
    }

    // MARK: - Greeting

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            FinanceScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) { // Increased layout spacing for breathing room

                    // ─── Section 1: Greeting + Streak ───
                    headerSection
                        .opacity(showItems[0] ? 1 : 0)
                        .offset(y: showItems[0] ? 0 : 20)

                    // ─── Section 2: Quick Actions ───
                    QuickActionsBar(
                        onAddExpense: { showingAddExpense = true },
                        onAddIncome: { showingAddIncome = true }
                    )
                    .padding(.horizontal, 20)
                    .opacity(showItems[1] ? 1 : 0)
                    .offset(y: showItems[1] ? 0 : 20)

                    // ─── Section 3: Hero Card ───
                    heroSection
                        .padding(.horizontal, 20)
                        .opacity(showItems[2] ? 1 : 0)
                        .offset(y: showItems[2] ? 0 : 20)

                    // ─── Section 4: Budget Health + Smart Nudge ───
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "Financial Health", badge: "Live")

                        BudgetHealthRing(
                            score: budgetHealthScore,
                            income: monthIncome,
                            expense: monthExpense
                        )
                        .padding(.horizontal, 20)

                        SmartNudgeCard(nudge: smartNudge)
                            .padding(.horizontal, 20)
                    }
                    .opacity(showItems[3] ? 1 : 0)
                    .offset(y: showItems[3] ? 0 : 20)

                    // ─── Section 5: Category Breakdown ───
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "Spending Breakdown", badge: "This Month")

                        SurfaceCard(title: "By Category", subtitle: "Where your money goes") {
                            CategoryBreakdownView(categories: Array(categoryBreakdown.prefix(6))) // Shows up to 6 categories
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(showItems[4] ? 1 : 0)
                    .offset(y: showItems[4] ? 0 : 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 48) // Increased bottom padding
            }
            .scrollIndicators(.hidden)
            .disabled(isLoading)

            if isLoading {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()
                    .backdropFilter(blur: 4)
                LoadingStateView(message: "Loading dashboard...")
            }
        }
        .navigationTitle("Overview")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            for i in 0..<showItems.count {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(Double(i) * 0.1)) {
                    showItems[i] = true
                }
            }
        }
        .task {
            guard isLoading else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            isLoading = false
        }
        .fullScreenCover(isPresented: $showingAddExpense) {
            TransactionFormView()
        }
        .fullScreenCover(isPresented: $showingAddIncome) {
            TransactionFormView()
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(.title, design: .rounded).weight(.bold))

                    Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SpendingStreakBadge(streakDays: spendingStreak)
            }
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greeting). \(Date().formatted(.dateTime.weekday(.wide).day().month(.wide))). Streak \(spendingStreak) days")
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Balance section
            BalanceHeroCard(
                balance: balance,
                income: totalIncome,
                expense: totalExpense,
                monthlySaved: monthlySaved,
                savingsProgress: savingsProgress,
                hasGoal: activeGoal != nil
            )
            // (Removed sparkline per request)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, badge: String?) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FinanceTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FinanceTheme.accent.opacity(0.15), in: Capsule())
            }
        }
        .padding(.horizontal, 24)
    }
}
