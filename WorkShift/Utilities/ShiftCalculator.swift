import Foundation

enum ShiftCalculator {
    static func percentAmount(revenue: Decimal, percentRate: Int) -> Decimal {
        revenue * Decimal(percentRate) / 100
    }

    static func income(baseSalary: Decimal, revenue: Decimal, percentRate: Int, adjustmentsTotal: Decimal = 0) -> Decimal {
        baseSalary + percentAmount(revenue: revenue, percentRate: percentRate) + adjustmentsTotal
    }
}
