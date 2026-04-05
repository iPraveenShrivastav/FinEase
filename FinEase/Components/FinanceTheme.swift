import SwiftUI

enum FinanceTheme {
    static let accent = Color(red: 0.07, green: 0.58, blue: 0.52)
    static let income = Color(red: 0.12, green: 0.68, blue: 0.43)
    static let expense = Color(red: 0.86, green: 0.36, blue: 0.27)

    static let backgroundTop = Color(red: 0.96, green: 0.98, blue: 1.00)
    static let backgroundBottom = Color(red: 0.92, green: 0.95, blue: 0.98)

    static let heroTop = Color(red: 0.09, green: 0.24, blue: 0.36)
    static let heroBottom = Color(red: 0.07, green: 0.49, blue: 0.45)

    static let cardFill = Color.white.opacity(0.88)
    static let cardStroke = Color.white.opacity(0.85)
    static let cardShadow = Color.black.opacity(0.08)

    static let screenGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroGradient = LinearGradient(
        colors: [heroTop, heroBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct FinanceScreenBackground: View {
    var body: some View {
        ZStack {
            FinanceTheme.screenGradient
            Circle()
                .fill(Color.white.opacity(0.30))
                .frame(width: 260, height: 260)
                .offset(x: 150, y: -320)
            Circle()
                .fill(FinanceTheme.accent.opacity(0.10))
                .frame(width: 280, height: 280)
                .offset(x: -170, y: 320)
        }
        .ignoresSafeArea()
    }
}
