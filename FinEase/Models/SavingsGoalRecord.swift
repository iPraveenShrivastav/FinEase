import Foundation
import SwiftData

@Model
final class SavingsGoalRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var targetAmount: Double
    var monthAnchor: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Double,
        monthAnchor: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.monthAnchor = monthAnchor.startOfMonth
        self.createdAt = createdAt
    }

    var monthLabel: String {
        monthAnchor.formatted(.dateTime.month(.wide).year())
    }
}
