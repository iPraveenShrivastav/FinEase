import Foundation
import SwiftData

@Model
final class TransactionRecord {
    @Attribute(.unique) var id: UUID
    var amount: Double
    private var typeRaw: String
    private var categoryRaw: String
    var date: Date
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        category: FinanceCategory,
        date: Date,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.typeRaw = type.rawValue
        self.categoryRaw = category.rawValue
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    var category: FinanceCategory {
        get { FinanceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
