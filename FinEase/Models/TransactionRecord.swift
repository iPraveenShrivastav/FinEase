import Foundation
import SwiftData
import SwiftUI

@Model
final class TransactionRecord {
    @Attribute(.unique) var id: UUID
    var amount: Double
    private var typeRaw: String
    private var categoryRaw: String
    var date: Date
    var notes: String
    var createdAt: Date

    // Custom category fields
    var customCategoryName: String?
    var customCategoryIcon: String?
    var customCategoryRed: Double?
    var customCategoryGreen: Double?
    var customCategoryBlue: Double?

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

    /// Convenience init for custom categories
    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        customCategory: CustomCategoryRecord,
        date: Date,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.typeRaw = type.rawValue
        self.categoryRaw = FinanceCategory.other.rawValue
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
        self.customCategoryName = customCategory.name
        self.customCategoryIcon = customCategory.iconName
        self.customCategoryRed = customCategory.colorRed
        self.customCategoryGreen = customCategory.colorGreen
        self.customCategoryBlue = customCategory.colorBlue
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    var category: FinanceCategory {
        get { FinanceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var displayCategoryName: String {
        if let customName = customCategoryName, !customName.isEmpty {
            return customName
        }
        return categoryRaw
    }

    var displayCategoryIcon: String {
        if let customIcon = customCategoryIcon, !customIcon.isEmpty {
            return customIcon
        }
        return category.icon
    }

    var displayTint: Color {
        if let r = customCategoryRed, let g = customCategoryGreen, let b = customCategoryBlue {
            return Color(red: r, green: g, blue: b)
        }
        return category.tint
    }
}
