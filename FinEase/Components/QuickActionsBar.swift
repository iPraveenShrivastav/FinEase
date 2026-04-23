import SwiftUI

struct QuickActionsBar: View {
    let onAddExpense: () -> Void
    let onAddIncome: () -> Void

    @State private var appear = false

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Expense",
                icon: "arrow.up.circle.fill",
                tint: FinanceTheme.expense,
                action: onAddExpense
            )

            QuickActionButton(
                title: "Income",
                icon: "arrow.down.circle.fill",
                tint: FinanceTheme.income,
                action: onAddIncome
            )
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appear = true
            }
        }
    }
}

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(FinanceTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.12), tint.opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.15), radius: 8, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.25)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("Add \(title)")
        .accessibilityHint("Opens form to add new \(title.lowercased())")
    }
}
