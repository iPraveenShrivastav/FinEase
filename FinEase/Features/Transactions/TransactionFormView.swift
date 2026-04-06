import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    private let transaction: TransactionRecord?
    
    @State private var amountText: String
    @State private var date: Date
    @State private var notes: String
    
    // Category states
    @State private var selectedFinanceCategory: FinanceCategory?
    @State private var selectedCustomCategory: CustomCategoryRecord?
    
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var isCategorySheetPresented = false
    @State private var isDatePickerPresented = false
    
    init(transaction: TransactionRecord? = nil) {
        self.transaction = transaction
        _amountText = State(initialValue: transaction.map { String(format: "%.0f", $0.amount) } ?? "")
        _date = State(initialValue: transaction?.date ?? Date())
        _notes = State(initialValue: transaction?.notes ?? "")

        // Initialize category selection states from the provided transaction
        if let transaction = transaction {
            if let customName = transaction.customCategoryName, !customName.isEmpty {
                // If we had fetched the matching CustomCategoryRecord, we'd assign it here.
                // For now, leave selectedCustomCategory nil and keep default category as `.other`.
                _selectedFinanceCategory = State(initialValue: .other)
            } else {
                _selectedFinanceCategory = State(initialValue: transaction.category)
            }
        } else {
            // New transaction defaults
            _selectedFinanceCategory = State(initialValue: nil)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Input Block
                    VStack(alignment: .leading, spacing: 16) {
                        // Currency Pill
                        HStack(spacing: 4) {
                            Text("INR")
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6), in: Capsule())
                        
                        // Giant Amount
                        TextField("0.00", text: $amountText)
                            .font(.system(size: 80, weight: .thin, design: .rounded))
                            .foregroundStyle(.primary)
                            .keyboardType(.decimalPad)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .tint(FinanceTheme.accent)
                    }
                    .padding(.horizontal, 24)
                    
                    // Floating Interactive Pills
                    HStack(spacing: 12) {
                        // Category Pill
                        Button {
                            isCategorySheetPresented = true
                        } label: {
                            HStack {
                                if let custom = selectedCustomCategory {
                                    HStack {
                                        Image(systemName: custom.iconName)
                                        Text(custom.name)
                                    }
                                    .foregroundStyle(custom.tint)
                                } else if let defaultCat = selectedFinanceCategory {
                                    HStack {
                                        Image(systemName: defaultCat.icon)
                                        Text(defaultCat.rawValue)
                                    }
                                    .foregroundStyle(defaultCat.tint)
                                } else {
                                    HStack {
                                        Image(systemName: "circle.dashed")
                                        Text("Category")
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .font(.headline.weight(.medium))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 64)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        // Date Pill
                        Button {
                            isDatePickerPresented = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(date.formatted(date: .numeric, time: .omitted))
                                        .foregroundStyle(.primary)
                                    Text(date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 64)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Notes Add-on
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        TextField("Optional description...", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .padding()
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { saveTransaction(as: .expense) }) {
                    Text("Expense")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(FinanceTheme.expense, in: Capsule())
                        .foregroundStyle(.white)
                }
                
                Button(action: { saveTransaction(as: .income) }) {
                    Text("Income")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(FinanceTheme.income.opacity(0.15), in: Capsule())
                        .foregroundStyle(FinanceTheme.income)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .alert("Unable to Save", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $isCategorySheetPresented) {
            CategorySelectionView(
                selectedFinanceCategory: $selectedFinanceCategory,
                selectedCustomCategory: $selectedCustomCategory
            )
        }
        .sheet(isPresented: $isDatePickerPresented) {
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isDatePickerPresented = false }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.primary)
                    }
                }
                .padding()
                
                DatePicker("Select Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .tint(.primary)
                    .padding(.horizontal)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
        }
        .overlay {
            if isSaving {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func saveTransaction(as type: TransactionType) {
        let normalizedText = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalizedText), amount > 0 else {
            errorMessage = "Please enter a valid amount greater than zero."
            showingError = true
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let transaction {
            transaction.amount = amount
            transaction.type = type
            transaction.date = date
            transaction.notes = trimmedNotes
            
            if let custom = selectedCustomCategory {
                transaction.category = .other
                transaction.customCategoryName = custom.name
                transaction.customCategoryIcon = custom.iconName
                transaction.customCategoryRed = custom.colorRed
                transaction.customCategoryGreen = custom.colorGreen
                transaction.customCategoryBlue = custom.colorBlue
            } else if let defaultCat = selectedFinanceCategory {
                transaction.category = defaultCat
                transaction.customCategoryName = nil
            }
        } else {
            let newTransaction: TransactionRecord
            
            if let custom = selectedCustomCategory {
                newTransaction = TransactionRecord(
                    amount: amount,
                    type: type,
                    customCategory: custom,
                    date: date,
                    notes: trimmedNotes
                )
            } else {
                newTransaction = TransactionRecord(
                    amount: amount,
                    type: type,
                    category: selectedFinanceCategory ?? .other,
                    date: date,
                    notes: trimmedNotes
                )
            }
            
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
