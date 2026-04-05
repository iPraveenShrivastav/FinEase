import SwiftUI

enum TransactionType: String, CaseIterable, Identifiable, Codable {
    case income = "Income"
    case expense = "Expense"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .income:
            return .green
        case .expense:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .income:
            return "arrow.down.circle.fill"
        case .expense:
            return "arrow.up.circle.fill"
        }
    }
}
