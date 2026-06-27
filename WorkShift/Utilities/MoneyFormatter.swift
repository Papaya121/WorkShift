import Foundation

enum MoneyFormatter {
    private static let _formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        return formatter
    }()

    static func string(_ value: Decimal, currency: String = "₽") -> String {
        let number = value as NSDecimalNumber
        let formatted = _formatter.string(from: number) ?? "0"
        return "\(formatted) \(currency)"
    }

    static func calendarString(_ value: Decimal, currency: String = "₽") -> String {
        var source = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, 0, .plain)
        let number = rounded as NSDecimalNumber
        return "\(number.stringValue) \(currency)"
    }

    static func decimal(from text: String) -> Decimal? {
        let normalized = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}
