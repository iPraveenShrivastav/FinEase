import SwiftUI
import UIKit

enum FinanceTheme {
    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let accent = Color(red: 0.07, green: 0.58, blue: 0.52)
    static let income = Color(red: 0.12, green: 0.68, blue: 0.43)
    static let expense = Color(red: 0.86, green: 0.36, blue: 0.27)

    static let backgroundTop = dynamicColor(
        light: UIColor(red: 0.95, green: 0.97, blue: 0.99, alpha: 1.0),
        dark: UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1.0)
    )
    static let backgroundBottom = dynamicColor(
        light: UIColor(red: 0.90, green: 0.93, blue: 0.96, alpha: 1.0),
        dark: UIColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1.0)
    )

    static let heroTop = Color(red: 0.09, green: 0.24, blue: 0.36)
    static let heroBottom = Color(red: 0.06, green: 0.42, blue: 0.39)

    static let cardFill = dynamicColor(
        light: UIColor(white: 1.0, alpha: 0.70),
        dark: UIColor(red: 0.12, green: 0.14, blue: 0.17, alpha: 0.92)
    )
    static let cardStroke = dynamicColor(
        light: UIColor(white: 1.0, alpha: 0.90),
        dark: UIColor(white: 1.0, alpha: 0.10)
    )
    static let cardShadow = dynamicColor(
        light: UIColor(white: 0.0, alpha: 0.04),
        dark: UIColor(white: 0.0, alpha: 0.50)
    )

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
        colors: [
            dynamicColor(
                light: UIColor(white: 1.0, alpha: 0.40),
                dark: UIColor(white: 1.0, alpha: 0.16)
            ),
            dynamicColor(
                light: UIColor(white: 1.0, alpha: 0.10),
                dark: UIColor(white: 1.0, alpha: 0.04)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let glassStroke = dynamicColor(
        light: UIColor(white: 1.0, alpha: 0.60),
        dark: UIColor(white: 1.0, alpha: 0.18)
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
                    .stroke(FinanceTheme.glassStroke, lineWidth: 1)
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    private var accentGlowOpacity: Double {
        colorScheme == .dark ? 0.10 : 0.15
    }

    private var incomeGlowOpacity: Double {
        colorScheme == .dark ? 0.05 : 0.08
    }
    
    var body: some View {
        ZStack {
            FinanceTheme.screenGradient
            Circle()
                .fill(FinanceTheme.accent.opacity(accentGlowOpacity))
                .blur(radius: 60)
                .frame(width: 300, height: 300)
                .offset(x: animate ? 180 : 150, y: animate ? -300 : -320)
            Circle()
                .fill(FinanceTheme.income.opacity(incomeGlowOpacity))
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
