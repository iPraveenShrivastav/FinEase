import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionRecord.date, order: .reverse) private var transactions: [TransactionRecord]

    @State private var showingAddSheet = false
    @State private var editingTransaction: TransactionRecord?
    @State private var searchText = ""
    @State private var typeFilter: TransactionTypeFilter = .all
    @State private var categoryFilter: CategoryFilter = .all
    @State private var isDateRangeEnabled = false
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()

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

            if isDateRangeEnabled {
                let start = startDate.startOfDay
                let end = endDate.endOfDay
                if transaction.date < start || transaction.date > end {
                    return false
                }
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
        typeFilter != .all || categoryFilter != .all || isDateRangeEnabled || !searchText.isEmpty
    }

    var body: some View {
        List {
            Section("Filters") {
                Picker("Type", selection: $typeFilter) {
                    ForEach(TransactionTypeFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Menu {
                    ForEach(CategoryFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            categoryFilter = filter
                        }
                    }
                } label: {
                    HStack {
                        Label("Category", systemImage: "line.3.horizontal.decrease.circle")
                        Spacer()
                        Text(categoryFilter.rawValue)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("Use date range", isOn: $isDateRangeEnabled)

                if isDateRangeEnabled {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                if hasActiveFilters {
                    Button("Reset Filters") {
                        typeFilter = .all
                        categoryFilter = .all
                        isDateRangeEnabled = false
                        searchText = ""
                    }
                    .foregroundStyle(.orange)
                }
            }

            if groupedTransactions.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No matching transactions",
                        message: "Try adjusting filters or add a new transaction.",
                        symbol: "magnifyingglass"
                    )
                    .listRowSeparator(.hidden)
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
                        }
                        .onDelete { offsets in
                            deleteTransactions(at: offsets, from: group.items)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search amount, category, notes")
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add transaction")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            TransactionFormView()
        }
        .sheet(item: $editingTransaction) { transaction in
            TransactionFormView(transaction: transaction)
        }
    }

    private func deleteTransactions(at offsets: IndexSet, from source: [TransactionRecord]) {
        for index in offsets {
            modelContext.delete(source[index])
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to delete transactions: \(error.localizedDescription)")
        }
    }
}
