import SwiftUI

enum FinanceTheme {
    static let accent = Color(red: 0.07, green: 0.58, blue: 0.52)
    static let income = Color(red: 0.12, green: 0.68, blue: 0.43)
    static let expense = Color(red: 0.86, green: 0.36, blue: 0.27)

    static let backgroundTop = Color(red: 0.95, green: 0.97, blue: 0.99)
    static let backgroundBottom = Color(red: 0.90, green: 0.93, blue: 0.96)

    static let heroTop = Color(red: 0.09, green: 0.24, blue: 0.36)
    static let heroBottom = Color(red: 0.06, green: 0.42, blue: 0.39)

    static let cardFill = Color.white.opacity(0.70)
    static let cardStroke = Color.white.opacity(0.90)
    static let cardShadow = Color.black.opacity(0.04)

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
    
    static let glassGradient = LinearGradient(
        colors: [.white.opacity(0.4), .white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassEffect: ViewModifier {
    var cornerRadius: CGFloat = 24
    var opacity: Double = 0.8

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .background(FinanceTheme.glassGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.6), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: FinanceTheme.cardShadow, radius: 12, x: 0, y: 6)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassEffect(cornerRadius: cornerRadius))
    }
}

struct FinanceScreenBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            FinanceTheme.screenGradient
            Circle()
                .fill(FinanceTheme.accent.opacity(0.15))
                .blur(radius: 60)
                .frame(width: 300, height: 300)
                .offset(x: animate ? 180 : 150, y: animate ? -300 : -320)
            Circle()
                .fill(FinanceTheme.income.opacity(0.08))
                .blur(radius: 80)
                .frame(width: 350, height: 350)
                .offset(x: animate ? -180 : -170, y: animate ? 300 : 320)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
