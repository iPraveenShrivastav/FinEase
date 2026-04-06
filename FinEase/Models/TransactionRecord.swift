import Foundation
import SwiftData
import SwiftUI

@Model
final class TransactionRecord {
    @Attribute(.unique) var id: UUID
    var amount: Double
    private var typeRaw: String
    private var categoryRaw: String
    
    // Fallbacks for custom categories
    var customCategoryName: String?
    var customCategoryIcon: String?
    var customCategoryRed: Double?
    var customCategoryGreen: Double?
    var customCategoryBlue: Double?
    
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
    
    // New initializer for custom categories
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
        self.categoryRaw = "CUSTOM_\(customCategory.id.uuidString)"
        self.customCategoryName = customCategory.name
        self.customCategoryIcon = customCategory.iconName
        self.customCategoryRed = customCategory.colorRed
        self.customCategoryGreen = customCategory.colorGreen
        self.customCategoryBlue = customCategory.colorBlue
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
    }

    @Transient
    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    @Transient
    var category: FinanceCategory {
        get { FinanceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    @Transient
    var displayCategoryName: String {
        if categoryRaw.starts(with: "CUSTOM_"), let name = customCategoryName {
            return name
        }
        return category.rawValue
    }
    
    @Transient
    var displayIcon: String {
        if categoryRaw.starts(with: "CUSTOM_"), let icon = customCategoryIcon {
            return icon
        }
        return category.icon
    }
    
    @Transient
    var displayTint: Color {
        if categoryRaw.starts(with: "CUSTOM_"), let r = customCategoryRed, let g = customCategoryGreen, let b = customCategoryBlue {
            return Color(red: r, green: g, blue: b)
        }
        return category.tint
    }
}
