import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label {
                    Text(title)
                        .font(.caption.weight(.semibold))
                } icon: {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(tint)
                        .padding(5)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .foregroundStyle(.secondary)
                Spacer()
            }

            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FinanceTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FinanceTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: FinanceTheme.cardShadow, radius: 10, y: 5)
    }
}
