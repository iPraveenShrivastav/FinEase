import Foundation

struct DailyExpensePoint: Identifiable {
    let date: Date
    let amount: Double
    var id: Date { date }
}

struct CategorySpendPoint: Identifiable {
    let category: FinanceCategory
    let amount: Double
    var id: String { category.rawValue }
}

struct MonthlyTrendPoint: Identifiable {
    let month: Date
    let expense: Double
    var id: Date { month }
}
