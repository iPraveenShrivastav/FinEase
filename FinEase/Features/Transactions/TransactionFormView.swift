import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let transaction: TransactionRecord?

    @State private var amountText: String
    @State private var type: TransactionType
    @State private var category: FinanceCategory
    @State private var date: Date
    @State private var notes: String
    @State private var showingError = false
    @State private var errorMessage = ""

    init(transaction: TransactionRecord? = nil) {
        self.transaction = transaction
        _amountText = State(initialValue: transaction.map { String(format: "%.2f", $0.amount) } ?? "")
        _type = State(initialValue: transaction?.type ?? .expense)
        _category = State(initialValue: transaction?.category ?? .food)
        _date = State(initialValue: transaction?.date ?? Date())
        _notes = State(initialValue: transaction?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Category", selection: $category) {
                        ForEach(FinanceCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }

                Section("Notes") {
                    TextField("Optional note", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(transaction == nil ? "Add Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                }
            }
        }
        .alert("Unable to Save", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func saveTransaction() {
        let normalizedText = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalizedText), amount > 0 else {
            errorMessage = "Please enter a valid amount greater than zero."
            showingError = true
            return
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let transaction {
            transaction.amount = amount
            transaction.type = type
            transaction.category = category
            transaction.date = date
            transaction.notes = trimmedNotes
        } else {
            let newTransaction = TransactionRecord(
                amount: amount,
                type: type,
                category: category,
                date: date,
                notes: trimmedNotes
            )
            modelContext.insert(newTransaction)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Something went wrong while saving your transaction."
            showingError = true
        }
    }
}
