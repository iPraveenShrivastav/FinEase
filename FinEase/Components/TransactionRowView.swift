import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionRecord
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(transaction.category.tint.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(transaction.category.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.notes.isEmpty ? transaction.category.rawValue : transaction.notes)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountLabel)
                    .font(.subheadline.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(transaction.type.tint)
                Text(transaction.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(showChevron ? "Double tap to edit this transaction" : "Recent transaction summary")
    }

    private var amountLabel: String {
        let sign = transaction.type == .income ? "+" : "-"
        return "\(sign)\(transaction.amount.asCurrency())"
    }

    private var accessibilityLabelText: String {
        let title = transaction.notes.isEmpty ? transaction.category.rawValue : transaction.notes
        return "\(transaction.type.rawValue) transaction, \(title), \(amountLabel), on \(transaction.date.formatted(date: .long, time: .omitted))"
    }
}
