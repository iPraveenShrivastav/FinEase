import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]
    @Query(sort: \SavingsGoalRecord.createdAt, order: .reverse) private var goals: [SavingsGoalRecord]
    @State private var isLoading = true
    @State private var showItems = [false, false, false, false]
    
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

    // Top categories for the month
    private struct CategorySpending: Identifiable {
        let name: String
        let displayTint: Color
        let amount: Double
        var id: String { name }
    }
    
    private var topCategories: [CategorySpending] {
        let monthStart = Date().startOfMonth
        let expensesThisMonth = transactions.filter { $0.type == .expense && $0.date >= monthStart }
        let grouped = Dictionary(grouping: expensesThisMonth, by: { $0.displayCategoryName })
        let sums = grouped.map { (key, transactions) in
            CategorySpending(
                name: key,
                displayTint: transactions.first?.displayTint ?? .gray,
                amount: transactions.reduce(0) { $0 + $1.amount }
            )
        }
        return Array(sums.sorted(by: { $0.amount > $1.amount }).prefix(4))
    }

    private var recentTransactions: [TransactionRecord] {
        Array(transactions.prefix(4))
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
        ZStack(alignment: .top) {
            FinanceScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greeting)
                            .font(.system(.title, design: .rounded).weight(.bold))
                        Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(greeting). \(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))")
                    .opacity(showItems[0] ? 1 : 0)
                    .offset(y: showItems[0] ? 0 : 20)
                    .padding(.horizontal, 24)
                    
                    // Hero Card
                    BalanceHeroCard(
                        balance: balance,
                        income: totalIncome,
                        expense: totalExpense,
                        monthlySaved: monthlySaved,
                        savingsProgress: savingsProgress,
                        hasGoal: activeGoal != nil
                    )
                    .padding(.horizontal, 20)
                    .opacity(showItems[1] ? 1 : 0)
                    .offset(y: showItems[1] ? 0 : 20)

                    // Top Categories Insights
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Analytics")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Text("This Month")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(FinanceTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(FinanceTheme.accent.opacity(0.15), in: Capsule())
                        }
                        .padding(.horizontal, 24)
                        
                        SurfaceCard(title: "Top Spending", subtitle: "Where your money went") {
                            if topCategories.isEmpty {
                                EmptyStateView(
                                    title: "No expense data",
                                    message: "Spend a little and see the charts come alive.",
                                    symbol: "chart.pie.fill"
                                )
                            } else {
                                VStack(spacing: 20) {
                                    Chart(topCategories) { category in
                                        SectorMark(
                                            angle: .value("Amount", category.amount),
                                            innerRadius: .ratio(0.65),
                                            angularInset: 2.0
                                        )
                                        .cornerRadius(6)
                                        .foregroundStyle(category.displayTint.gradient)
                                    }
                                    .frame(height: 160)
                                    
                                    // Legend
                                    HStack(spacing: 16) {
                                        ForEach(topCategories) { category in
                                            VStack(spacing: 4) {
                                                Circle()
                                                    .fill(category.displayTint)
                                                    .frame(width: 8, height: 8)
                                                Text(category.name)
                                                    .font(.caption2.weight(.medium))
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(showItems[2] ? 1 : 0)
                    .offset(y: showItems[2] ? 0 : 20)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.title3.weight(.bold))
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            if recentTransactions.isEmpty {
                                EmptyStateView(
                                    title: "No transactions",
                                    message: "Start by logging an entry.",
                                    symbol: "list.bullet.rectangle"
                                )
                                .padding(.vertical, 32)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, transaction in
                                        TransactionRowView(transaction: transaction, showChevron: true)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 4)
                                        
                                        if index < recentTransactions.count - 1 {
                                            Divider()
                                                .padding(.leading, 56)
                                                .padding(.vertical, 4)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                        .padding(.horizontal, 20)
                    }
                    .opacity(showItems[3] ? 1 : 0)
                    .offset(y: showItems[3] ? 0 : 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
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
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(i) * 0.1)) {
                    showItems[i] = true
                }
            }
        }
        .task {
            guard isLoading else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            isLoading = false
        }
    }
}
