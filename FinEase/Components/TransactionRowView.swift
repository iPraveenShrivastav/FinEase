import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionRecord
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.category.tint.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(transaction.category.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.notes.isEmpty ? transaction.category.rawValue : transaction.notes)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountLabel)
                    .font(.subheadline.weight(.bold))
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
        .padding(.vertical, 4)
    }

    private var amountLabel: String {
        let sign = transaction.type == .income ? "+" : "-"
        return "\(sign)\(transaction.amount.asCurrency())"
    }
}
