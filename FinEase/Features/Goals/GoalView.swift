import SwiftUI
import SwiftData

struct GoalView: View {
    @Query(sort: \SavingsGoalRecord.createdAt, order: .reverse) private var goals: [SavingsGoalRecord]
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]

    @State private var showingGoalForm = false
    @State private var editingGoal: SavingsGoalRecord?

    private var monthStart: Date {
        Date().startOfMonth
    }

    private var currentGoal: SavingsGoalRecord? {
        goals.first {
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

    private var progress: Double {
        guard let currentGoal, currentGoal.targetAmount > 0 else { return 0 }
        return min(savedAmount / currentGoal.targetAmount, 1)
    }

    private var remainingAmount: Double {
        guard let currentGoal else { return 0 }
        return max(currentGoal.targetAmount - savedAmount, 0)
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

    var body: some View {
        ZStack {
            FinanceScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SurfaceCard(title: "Monthly Challenge", subtitle: "\(daysLeftThisMonth) days left this month") {
                        Text("Stay intentional with spending and keep building your savings habit one day at a time.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let currentGoal {
                        SurfaceCard(title: currentGoal.title, subtitle: currentGoal.monthLabel) {
                            VStack(spacing: 16) {
                                GoalProgressRing(progress: progress)

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Target")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(currentGoal.targetAmount.asCurrency())
                                            .font(.headline)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Remaining")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(remainingAmount.asCurrency())
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
                                        value: progress.asPercent(),
                                        subtitle: "Of target",
                                        icon: "speedometer",
                                        tint: FinanceTheme.accent
                                    )
                                }

                                Button("Edit Goal") {
                                    editingGoal = currentGoal
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(FinanceTheme.accent)
                            }
                        }
                    } else {
                        SurfaceCard(title: "Monthly Savings Challenge") {
                            EmptyStateView(
                                title: "No active goal",
                                message: "Set a target for this month and track your progress automatically.",
                                symbol: "target"
                            )

                            Button("Create Goal") {
                                showingGoalForm = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(FinanceTheme.accent)
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
    }
}
