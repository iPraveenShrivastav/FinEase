import SwiftUI
import SwiftData

struct GoalView: View {
    @Query(sort: \SavingsGoalRecord.createdAt, order: .reverse) private var goals: [SavingsGoalRecord]
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]

    @State private var isLoading = true
    @State private var showingGoalForm = false
    @State private var editingGoal: SavingsGoalRecord?

    private var monthStart: Date {
        Date().startOfMonth
    }

    private var activeGoals: [SavingsGoalRecord] {
        goals.filter {
            Calendar.current.isDate($0.monthAnchor, equalTo: monthStart, toGranularity: .month) &&
            Calendar.current.isDate($0.monthAnchor, equalTo: monthStart, toGranularity: .year)
        }
    }

    private var thisMonthTransactions: [TransactionRecord] {
        let end = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date()
        return transactions.filter { $0.date >= monthStart && $0.date < end }
    }

    private var monthIncome: Double {
        thisMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthExpense: Double {
        thisMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var savedAmount: Double {
        max(0, monthIncome - monthExpense)
    }

    private var monthTitle: String {
        monthStart.formatted(.dateTime.month(.wide).year())
    }

    private var savingsTone: String {
        if savedAmount == 0 {
            return "Start strong with your first intentional save this month."
        }

        if let firstGoal = activeGoals.first {
            if progress(for: firstGoal) >= 1 {
                return "Excellent momentum. You have already reached your active goal."
            }
            if progress(for: firstGoal) >= 0.75 {
                return "You are very close. Keep this pace for the final stretch."
            }
        }

        return "Steady progress compounds. Every no-spend day gives this target more room."
    }

    private func progress(for goal: SavingsGoalRecord) -> Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(savedAmount / goal.targetAmount, 1)
    }

    private func remainingAmount(for goal: SavingsGoalRecord) -> Double {
        return max(goal.targetAmount - savedAmount, 0)
    }

    private var expenseDays: Set<Date> {
        Set(thisMonthTransactions.filter { $0.type == .expense }.map { $0.date.startOfDay })
    }

    private var noSpendDays: Int {
        let calendar = Calendar.current
        let today = Date().startOfDay
        guard let dayCount = calendar.dateComponents([.day], from: monthStart, to: today).day else {
            return 0
        }

        return (0...dayCount).reduce(0) { count, offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monthStart) else {
                return count
            }
            return expenseDays.contains(day.startOfDay) ? count : count + 1
        }
    }

    private var activeNoSpendStreak: Int {
        let calendar = Calendar.current
        var day = Date().startOfDay
        var streak = 0

        while day >= monthStart {
            if expenseDays.contains(day) {
                break
            }
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previousDay.startOfDay
        }

        return streak
    }

    private var daysLeftThisMonth: Int {
        guard let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }
        let value = Calendar.current.dateComponents([.day], from: Date().startOfDay, to: monthEnd.startOfDay).day ?? 0
        return max(0, value)
    }

    private func statusMeta(for goal: SavingsGoalRecord) -> (label: String, icon: String, tint: Color) {
        let value = progress(for: goal)

        if value >= 1 {
            return ("Completed", "checkmark.seal.fill", FinanceTheme.income)
        }
        if value >= 0.75 {
            return ("Almost There", "sparkles", FinanceTheme.accent)
        }
        if value >= 0.4 {
            return ("On Track", "bolt.fill", .orange)
        }
        return ("Needs Focus", "flag.fill", .red)
    }

    private var streakMessage: String {
        if activeNoSpendStreak == 0 {
            return "Start a new no-spend streak today to boost your monthly savings."
        }
        return "Great discipline. Your current no-spend streak is helping your goal."
    }

    var body: some View {
        ZStack {
            FinanceScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(monthTitle) Focus")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                Text(savingsTone)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                            }

                            Spacer()

                            Text("\(daysLeftThisMonth)d left")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.18), in: Capsule())
                        }

                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Saved")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                                Text(savedAmount.asCurrency())
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .monospacedDigit()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Active Goals")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                                Text("\(activeGoals.count)")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .monospacedDigit()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [FinanceTheme.heroTop.opacity(0.96), FinanceTheme.heroBottom.opacity(0.96)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.25), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: FinanceTheme.cardShadow, radius: 14, y: 8)

                    SurfaceCard(title: "Monthly Challenge", subtitle: "\(daysLeftThisMonth) days left this month") {
                        Text("Stay intentional with spending and keep building your savings habit one day at a time.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if activeGoals.isEmpty {
                        SurfaceCard(title: "Monthly Savings Challenge") {
                            EmptyStateView(
                                title: "No active goal",
                                message: "Set targets like 'Emergency Fund' or 'Laptop' for this month.",
                                symbol: "target"
                            )

                            Button {
                                showingGoalForm = true
                            } label: {
                                Label("Create Goal", systemImage: "plus.circle.fill")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(FinanceTheme.accent)
                            .accessibilityHint("Creates a new monthly savings goal")
                        }
                    } else {
                        ForEach(activeGoals) { goal in
                            SurfaceCard(title: goal.title, subtitle: goal.monthLabel) {
                                let status = statusMeta(for: goal)

                                VStack(spacing: 16) {
                                    HStack {
                                        Label(status.label, systemImage: status.icon)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .foregroundStyle(status.tint)
                                            .background(status.tint.opacity(0.14), in: Capsule())

                                        Spacer()

                                        Text(progress(for: goal).asPercent())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    }

                                    GoalProgressRing(progress: progress(for: goal))

                                    ProgressView(value: progress(for: goal))
                                        .tint(status.tint)
                                        .scaleEffect(x: 1, y: 1.2, anchor: .center)

                                    Text(progress(for: goal) >= 1
                                         ? "Target achieved for this month. You can stretch it even further."
                                         : "\(remainingAmount(for: goal).asCurrency()) left to complete this challenge.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Target")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(goal.targetAmount.asCurrency())
                                                .font(.headline)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Remaining")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(remainingAmount(for: goal).asCurrency())
                                                .font(.headline)
                                        }
                                    }

                                    HStack(spacing: 12) {
                                        MetricCard(
                                            title: "Saved",
                                            value: savedAmount.asCurrency(),
                                            subtitle: "This month",
                                            icon: "leaf.fill",
                                            tint: FinanceTheme.income
                                        )

                                        MetricCard(
                                            title: "Progress",
                                            value: progress(for: goal).asPercent(),
                                            subtitle: "Of target",
                                            icon: "speedometer",
                                            tint: FinanceTheme.accent
                                        )
                                    }

                                    Button {
                                        editingGoal = goal
                                    } label: {
                                        Label("Edit Goal", systemImage: "square.and.pencil")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                    .tint(FinanceTheme.accent)
                                    .accessibilityHint("Opens the monthly goal editor")
                                }
                            }
                        }
                    }

                    SurfaceCard(title: "Challenge Snapshot", subtitle: "Current month") {
                        HStack(spacing: 12) {
                            MetricCard(
                                title: "No-Spend Days",
                                value: "\(noSpendDays)",
                                subtitle: "Total days",
                                icon: "calendar.badge.checkmark",
                                tint: .mint
                            )

                            MetricCard(
                                title: "Current Streak",
                                value: "\(activeNoSpendStreak)",
                                subtitle: "Days in a row",
                                icon: "flame.fill",
                                tint: .orange
                            )
                        }

                        Text(streakMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SurfaceCard(title: "How This Goal Works") {
                        Text("Your monthly saved amount is calculated as income minus expenses for the current month. Keep spending lower than income to hit your target faster.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .disabled(isLoading)

            if isLoading {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()

                LoadingStateView(message: "Loading goal insights...")
            }
        }
        .navigationTitle("Savings Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingGoalForm = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(FinanceTheme.accent.gradient, in: Circle())
                }
                .accessibilityLabel("Create monthly goal")
                .accessibilityHint("Opens a form to create a savings goal")
            }
        }
        .sheet(isPresented: $showingGoalForm) {
            GoalFormView()
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $editingGoal) { goal in
            GoalFormView(goal: goal)
                .presentationDetents([.medium, .large])
        }
        .task {
            guard isLoading else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            isLoading = false
        }
    }
}
