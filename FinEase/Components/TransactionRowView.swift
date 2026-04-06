import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionRecord
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(transaction.displayTint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.displayIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(transaction.displayTint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.notes.isEmpty ? transaction.displayCategoryName : transaction.notes)
                    .font(.body.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(amountLabel)
                    .font(.callout.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(transaction.type.tint)
                Text(transaction.type.rawValue)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(showChevron ? "Double tap to edit this transaction" : "Recent transaction summary")
    }

    private var amountLabel: String {
        let sign = transaction.type == .income ? "+" : "-"
        return "\(sign)\(transaction.amount.asCurrency())"
    }

    private var accessibilityLabelText: String {
        let title = transaction.notes.isEmpty ? transaction.displayCategoryName : transaction.notes
        return "\(transaction.type.rawValue) transaction, \(title), \(amountLabel), on \(transaction.date.formatted(date: .long, time: .omitted))"
    }
}
