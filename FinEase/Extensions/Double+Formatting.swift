import Foundation

extension Double {
    func asCurrency() -> String {
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatted(.currency(code: currencyCode))
    }

    func asPercent() -> String {
        formatted(.percent.precision(.fractionLength(0)))
    }

    func asPercentValue() -> String {
        "\(self.formatted(.number.precision(.fractionLength(1))))%"
    }
}
