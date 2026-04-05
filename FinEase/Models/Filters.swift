enum TransactionTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"

    var id: String { rawValue }

    var type: TransactionType? {
        switch self {
        case .all:
            return nil
        case .income:
            return .income
        case .expense:
            return .expense
        }
    }
}

enum CategoryFilter: String, CaseIterable, Identifiable {
    case all = "All Categories"
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case health = "Health"
    case education = "Education"
    case rent = "Rent"
    case salary = "Salary"
    case freelance = "Freelance"
    case transfer = "Transfer"
    case other = "Other"

    var id: String { rawValue }

    var category: FinanceCategory? {
        switch self {
        case .all:
            return nil
        case .food:
            return .food
        case .transport:
            return .transport
        case .shopping:
            return .shopping
        case .entertainment:
            return .entertainment
        case .utilities:
            return .utilities
        case .health:
            return .health
        case .education:
            return .education
        case .rent:
            return .rent
        case .salary:
            return .salary
        case .freelance:
            return .freelance
        case .transfer:
            return .transfer
        case .other:
            return .other
        }
    }
}
