import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]

    @State private var isLoading = true
    @State private var isDeleting = false
    @State private var showingAddSheet = false
    @State private var editingTransaction: TransactionRecord?
    @State private var pendingDeleteTransactions: [TransactionRecord] = []
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var searchText = ""
    @State private var typeFilter: TransactionTypeFilter = .all
    @State private var categoryFilter: CategoryFilter = .all

    private struct TransactionGroup: Identifiable {
        let date: Date
        let items: [TransactionRecord]
        var id: Date { date }
    }

    private var filteredTransactions: [TransactionRecord] {
        transactions.filter { transaction in
            if let selectedType = typeFilter.type, transaction.type != selectedType {
                return false
            }

            if let selectedCategory = categoryFilter.category, transaction.category != selectedCategory {
                return false
            }



            if searchText.isEmpty {
                return true
            }

            let search = searchText.lowercased()
            let amountText = String(format: "%.2f", transaction.amount)
            return transaction.notes.lowercased().contains(search) ||
                transaction.category.rawValue.lowercased().contains(search) ||
                transaction.type.rawValue.lowercased().contains(search) ||
                amountText.contains(search)
        }
    }

    private var groupedTransactions: [TransactionGroup] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.date.startOfDay }
        return grouped.keys.sorted(by: >).map { date in
            let items = grouped[date, default: []].sorted { $0.date > $1.date }
            return TransactionGroup(date: date, items: items)
        }
    }

    private var hasActiveFilters: Bool {
        typeFilter != .all || categoryFilter != .all || !searchText.isEmpty
    }

    private var monthStart: Date {
        Date().startOfMonth
    }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date()
    }

    private var monthIncome: Double {
        transactions
            .filter { $0.type == .income && $0.date >= monthStart && $0.date < monthEnd }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthExpense: Double {
        transactions
            .filter { $0.type == .expense && $0.date >= monthStart && $0.date < monthEnd }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            FinanceScreenBackground()

            List {
                Section {
                    CashFlowSummaryCard(income: monthIncome, expense: monthExpense)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }



                if groupedTransactions.isEmpty {
                    Section {
                        EmptyStateView(
                            title: "No matching transactions",
                            message: "Try adjusting filters or add a new transaction.",
                            symbol: "magnifyingglass"
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(groupedTransactions) { group in
                        Section(group.date.formatted(.dateTime.weekday(.wide).day().month().year())) {
                            ForEach(group.items) { transaction in
                                Button {
                                    editingTransaction = transaction
                                } label: {
                                    TransactionRowView(transaction: transaction, showChevron: true)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Double tap to edit this transaction")
                            }
                            .onDelete { offsets in
                                prepareDelete(at: offsets, from: group.items)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listSectionSpacing(14)
            .disabled(isLoading || isDeleting)
            // Add top padding for our floating filter bar
            .safeAreaPadding(.top, 50)
            
            // Custom floating filter bar
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Menu {
                            Picker("Type", selection: $typeFilter) {
                                ForEach(TransactionTypeFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        } label: {
                            FilterChip(title: typeFilter == .all ? "Type" : typeFilter.rawValue, isActive: typeFilter != .all)
                        }

                        Menu {
                            Picker("Category", selection: $categoryFilter) {
                                ForEach(CategoryFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        } label: {
                            FilterChip(title: categoryFilter == .all ? "Category" : categoryFilter.rawValue, isActive: categoryFilter != .all)
                        }
                        
                        if hasActiveFilters {
                            Button(action: {
                                withAnimation {
                                    typeFilter = .all
                                    categoryFilter = .all
                                    searchText = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, FinanceTheme.expense)
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(.white.opacity(0.3)), alignment: .bottom)
                
                Spacer()
            }

            if isLoading || isDeleting {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()

                LoadingStateView(message: isDeleting ? "Deleting transaction..." : "Loading transactions...")
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search amount, category, notes")
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(FinanceTheme.accent.gradient, in: Circle())
                }
                .accessibilityLabel("Add transaction")
                .accessibilityHint("Opens a form to create a new transaction")
            }
        }
        .confirmationDialog(
            pendingDeleteTransactions.count > 1 ? "Delete \(pendingDeleteTransactions.count) transactions?" : "Delete transaction?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                confirmDeleteTransactions()
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteTransactions = []
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Unable to Delete", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            TransactionFormView()
        }
        .fullScreenCover(item: $editingTransaction) { transaction in
            TransactionFormView(transaction: transaction)
        }
        .task {
            guard isLoading else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            isLoading = false
        }
    }

    private func prepareDelete(at offsets: IndexSet, from source: [TransactionRecord]) {
        pendingDeleteTransactions = offsets.compactMap { index in
            guard source.indices.contains(index) else { return nil }
            return source[index]
        }
        showingDeleteConfirmation = !pendingDeleteTransactions.isEmpty
    }

    private func confirmDeleteTransactions() {
        guard !pendingDeleteTransactions.isEmpty else { return }

        isDeleting = true
        defer { isDeleting = false }

        for transaction in pendingDeleteTransactions {
            modelContext.delete(transaction)
        }

        pendingDeleteTransactions = []

        do {
            try modelContext.save()
        } catch {
            deleteErrorMessage = "Something went wrong while deleting the selected transaction."
            showingDeleteError = true
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .foregroundStyle(isActive ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isActive ? FinanceTheme.accent : Color.white.opacity(0.8), in: Capsule())
        .overlay(Capsule().stroke(isActive ? FinanceTheme.accent : .gray.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
