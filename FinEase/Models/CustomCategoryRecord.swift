import Foundation
import SwiftData
import SwiftUI

@Model
final class CustomCategoryRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorRed: Double
    var colorGreen: Double
    var colorBlue: Double
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorRed: Double = 0.5,
        colorGreen: Double = 0.5,
        colorBlue: Double = 0.5,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorRed = colorRed
        self.colorGreen = colorGreen
        self.colorBlue = colorBlue
        self.createdAt = createdAt
    }
    
    @Transient
    var tint: Color {
        Color(red: colorRed, green: colorGreen, blue: colorBlue)
    }
}
