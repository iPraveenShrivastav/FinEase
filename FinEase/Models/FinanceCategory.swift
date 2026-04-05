import SwiftUI

enum FinanceCategory: String, CaseIterable, Identifiable, Codable {
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

    var icon: String {
        switch self {
        case .food:
            return "fork.knife"
        case .transport:
            return "car.fill"
        case .shopping:
            return "bag.fill"
        case .entertainment:
            return "gamecontroller.fill"
        case .utilities:
            return "bolt.fill"
        case .health:
            return "cross.case.fill"
        case .education:
            return "book.fill"
        case .rent:
            return "house.fill"
        case .salary:
            return "briefcase.fill"
        case .freelance:
            return "laptopcomputer"
        case .transfer:
            return "arrow.left.arrow.right"
        case .other:
            return "tag.fill"
        }
    }

    var tint: Color {
        switch self {
        case .food:
            return .orange
        case .transport:
            return .blue
        case .shopping:
            return .pink
        case .entertainment:
            return .purple
        case .utilities:
            return .yellow
        case .health:
            return .mint
        case .education:
            return .indigo
        case .rent:
            return .brown
        case .salary:
            return .green
        case .freelance:
            return .teal
        case .transfer:
            return .cyan
        case .other:
            return .gray
        }
    }
}
