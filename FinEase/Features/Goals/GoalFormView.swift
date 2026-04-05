import SwiftUI
import SwiftData

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoalRecord.createdAt, order: .reverse) private var goals: [SavingsGoalRecord]

    private let goal: SavingsGoalRecord?

    @State private var title: String
    @State private var targetAmountText: String
    @State private var monthDate: Date
    @State private var showingError = false
    @State private var errorMessage = ""

    init(goal: SavingsGoalRecord? = nil) {
        self.goal = goal
        _title = State(initialValue: goal?.title ?? "Monthly Savings Challenge")
        _targetAmountText = State(initialValue: goal.map { String(format: "%.2f", $0.targetAmount) } ?? "")
        _monthDate = State(initialValue: goal?.monthAnchor ?? Date().startOfMonth)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal == nil ? "Create Monthly Goal" : "Update Monthly Goal")
                                .font(.headline)
                            Text("Set a clear target to keep your spending intentional.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "target")
                            .font(.title3)
                            .foregroundStyle(FinanceTheme.accent)
                            .padding(10)
                            .background(FinanceTheme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.vertical, 2)
                }
                .listRowBackground(Color.clear)

                Section("Goal Details") {
                    TextField("Title", text: $title)

                    TextField("Target amount", text: $targetAmountText)
                        .keyboardType(.decimalPad)

                    DatePicker("Month", selection: $monthDate, displayedComponents: .date)
                }
            }
            .scrollContentBackground(.hidden)
            .background(FinanceScreenBackground())
            .navigationTitle(goal == nil ? "Create Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveGoal() }
                        .fontWeight(.semibold)
                }
            }
        }
        .alert("Unable to Save", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func saveGoal() {
        let normalizedText = targetAmountText.replacingOccurrences(of: ",", with: ".")
        guard let targetAmount = Double(normalizedText), targetAmount > 0 else {
            errorMessage = "Please enter a valid target amount greater than zero."
            showingError = true
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = trimmedTitle.isEmpty ? "Monthly Savings Challenge" : trimmedTitle
        let monthAnchor = monthDate.startOfMonth

        if let goal {
            goal.title = resolvedTitle
            goal.targetAmount = targetAmount
            goal.monthAnchor = monthAnchor
        } else if let existingGoal = goals.first(where: {
            Calendar.current.isDate($0.monthAnchor, equalTo: monthAnchor, toGranularity: .month) &&
            Calendar.current.isDate($0.monthAnchor, equalTo: monthAnchor, toGranularity: .year)
        }) {
            existingGoal.title = resolvedTitle
            existingGoal.targetAmount = targetAmount
            existingGoal.monthAnchor = monthAnchor
        } else {
            let newGoal = SavingsGoalRecord(
                title: resolvedTitle,
                targetAmount: targetAmount,
                monthAnchor: monthAnchor
            )
            modelContext.insert(newGoal)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Something went wrong while saving your goal."
            showingError = true
        }
    }
}
