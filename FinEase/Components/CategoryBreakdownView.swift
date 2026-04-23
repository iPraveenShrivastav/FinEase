import SwiftUI

struct CategoryBreakdownItem: Identifiable {
    let name: String
    let icon: String
    let tint: Color
    let amount: Double
    let percentage: Double
    var id: String { name }
}

struct CategoryBreakdownView: View {
    let categories: [CategoryBreakdownItem]
    @State private var animateBars = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if categories.isEmpty {
                EmptyStateView(
                    title: "No spending yet",
                    message: "Your category breakdown will appear here.",
                    symbol: "chart.bar.fill"
                )
            } else {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    CategoryBarRow(
                        item: category,
                        animate: animateBars,
                        delay: Double(index) * 0.08
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) {
                animateBars = true
            }
        }
    }
}

private struct CategoryBarRow: View {
    let item: CategoryBreakdownItem
    let animate: Bool
    let delay: Double

    @State private var showBar = false

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(item.tint.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: item.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(item.tint)
                    }

                    Text(item.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(item.amount.asCurrency())
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Text("\(item.percentage, specifier: "%.0f")%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(item.tint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.tint.opacity(0.12), in: Capsule())
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(item.tint.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [item.tint.opacity(0.7), item.tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: showBar ? geo.size.width * (item.percentage / 100) : 0, height: 6)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay + 0.2)) {
                showBar = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.amount.asCurrency()), \(item.percentage, specifier: "%.0f") percent of spending")
    }
}
